module KromSetleri

// Reading and changing installed cyberware from the ripperdoc screen, through the screen's own
// equip/unequip logic so capacity, perk requirements, sounds and arm styles behave like vanilla.
// Reminder: store every returned array in a local before use (redscript 0.5 temporaries).

// Higher is better; used only to pick between copies of the same cyberware.
public func KromQualityRank(quality: gamedataQuality) -> Int32 {
  switch quality {
    case gamedataQuality.Common: return 1;
    case gamedataQuality.CommonPlus: return 2;
    case gamedataQuality.Uncommon: return 3;
    case gamedataQuality.UncommonPlus: return 4;
    case gamedataQuality.Rare: return 5;
    case gamedataQuality.RarePlus: return 6;
    case gamedataQuality.Epic: return 7;
    case gamedataQuality.EpicPlus: return 8;
    case gamedataQuality.Legendary: return 9;
    case gamedataQuality.LegendaryPlus: return 10;
    case gamedataQuality.LegendaryPlusPlus: return 11;
    case gamedataQuality.Iconic: return 12;
    default: return 0;
  }
}

@addMethod(RipperDocGameController)
public func KromIsRealRipperdoc() -> Bool {
  return Equals(this.m_screen, CyberwareScreenType.Ripperdoc);
}

@addMethod(RipperDocGameController)
public func KromCurrentCyberware() -> array<KromSlotItem> {
  let result: array<KromSlotItem>;
  let player = this.m_player;
  let data = EquipmentSystem.GetData(player);
  if !IsDefined(data) {
    return result;
  }
  let areas = data.GetAllCyberwareEquipmentAreas();
  for area in areas {
    let slots = data.GetNumberOfSlots(area);
    let slot = 0;
    while slot < slots {
      let id = data.GetItemInEquipSlot(area, slot);
      if ItemID.IsValid(id) {
        ArrayPush(result, KromSlotItem(area, slot, id));
      }
      slot += 1;
    }
  }
  return result;
}

// Cyberware in the player's inventory that is not installed right now.
@addMethod(RipperDocGameController)
public func KromOwnedCyberware() -> array<KromOwnedItem> {
  let result: array<KromOwnedItem>;
  let player = this.m_player;
  let data = EquipmentSystem.GetData(player);
  if !IsDefined(data) {
    return result;
  }
  let areas = data.GetAllCyberwareEquipmentAreas();
  let list: array<wref<gameItemData>>;
  GameInstance.GetTransactionSystem(player.GetGame()).GetItemList(player, list);
  for itemData in list {
    if IsDefined(itemData) {
      let id = itemData.GetID();
      let record = RPGManager.GetItemRecord(id);
      if IsDefined(record) && IsDefined(record.EquipArea()) && !data.IsEquipped(id) {
        let area = record.EquipArea().Type();
        if ArrayContains(areas, area) {
          ArrayPush(result, KromOwnedItem(id, KromQualityRank(RPGManager.GetItemDataQuality(itemData))));
        }
      }
    }
  }
  return result;
}

@addMethod(RipperDocGameController)
public func KromSaveCurrent(index: Int32, name: String) -> Bool {
  let current = this.KromCurrentCyberware();
  return KromSetleriSystem.Get(this.m_player.GetGame()).SaveSet(index, name, current);
}

// --- Loading a set, one piece at a time -------------------------------------------------------
// Vanilla equip requests are processed later and the slot grid only refreshes afterwards, so
// doing a whole set in one call works on stale state. Each removal or install therefore runs on
// its own step, a few UI frames apart; removals all go first so capacity frees up. What did not
// get installed is worked out at the end from what is really installed.

public class KromApplyStepEvent extends Event {
  public let wait: Int32;
}

@addField(RipperDocGameController)
private let m_kromQueue: array<KromSlotItem>;

@addField(RipperDocGameController)
private let m_kromQueueIsInstall: array<Bool>;

@addField(RipperDocGameController)
private let m_kromTarget: array<KromSlotItem>;

@addField(RipperDocGameController)
private let m_kromTargetName: String;

@addField(RipperDocGameController)
private let m_kromBusy: Bool;

@addField(RipperDocGameController)
private let m_kromSavedHoverArea: gamedataEquipmentArea;

@addField(RipperDocGameController)
private let m_kromSavedSlotIndex: Int32;

@addMethod(RipperDocGameController)
public func KromIsLoading() -> Bool {
  return this.m_kromBusy;
}

// Starts loading set `index`; the panel's OnApplyFinished is called when it is done.
@addMethod(RipperDocGameController)
public func KromStartApply(index: Int32) -> Bool {
  if this.m_kromBusy {
    return false;
  }
  let sets = KromSetleriSystem.Get(this.m_player.GetGame()).GetSets();
  if index < 0 || index >= ArraySize(sets) {
    return false;
  }
  let chosen = sets[index];
  let equipped = this.KromCurrentCyberware();
  let owned = this.KromOwnedCyberware();
  let plan = KromPlanLoadout(equipped, chosen.items, owned);

  ArrayClear(this.m_kromQueue);
  ArrayClear(this.m_kromQueueIsInstall);
  let removals = plan.unequip;
  for r in removals {
    ArrayPush(this.m_kromQueue, r);
    ArrayPush(this.m_kromQueueIsInstall, false);
  }
  let installs = plan.equip;
  for e in installs {
    ArrayPush(this.m_kromQueue, e);
    ArrayPush(this.m_kromQueueIsInstall, true);
  }
  this.m_kromTarget = chosen.items;
  this.m_kromTargetName = chosen.name;
  this.m_kromSavedHoverArea = this.m_hoverArea;
  this.m_kromSavedSlotIndex = this.m_equippedSlotIndex;
  this.m_kromBusy = true;
  this.KromQueueStep(0);
  return true;
}

@addMethod(RipperDocGameController)
private func KromQueueStep(wait: Int32) -> Void {
  let evt = new KromApplyStepEvent();
  evt.wait = wait;
  this.QueueEvent(evt);
}

@addMethod(RipperDocGameController)
protected cb func OnKromApplyStep(evt: ref<KromApplyStepEvent>) -> Bool {
  if !this.m_kromBusy {
    return false;
  }
  if evt.wait > 0 {
    this.KromQueueStep(evt.wait - 1);
    return true;
  }
  if ArraySize(this.m_kromQueue) == 0 {
    this.KromFinishApply();
    return true;
  }
  let entry = this.m_kromQueue[0];
  let isInstall = this.m_kromQueueIsInstall[0];
  ArrayErase(this.m_kromQueue, 0);
  ArrayErase(this.m_kromQueueIsInstall, 0);

  let player = this.m_player;
  let data = EquipmentSystem.GetData(player);
  let itemData = GameInstance.GetTransactionSystem(player.GetGame()).GetItemData(player, entry.item);
  if IsDefined(itemData) {
    // The screen's equip logic reads the hovered area, as if the player pointed at it.
    this.m_hoverArea = entry.area;
    if isInstall {
      if !data.IsEquipped(entry.item) && this.CheckIfCanEquip(itemData, entry.area) {
        this.EquipCyberware(itemData);
      }
    } else {
      if data.IsEquipped(entry.item) {
        this.UnequipCyberware(itemData, null, true);
      }
    }
  }
  this.UpdateCapacityBar(false);
  this.InvalidateMinigridsNextFrame();
  this.KromQueueStep(KromApplyFramesBetweenSteps());
  return true;
}

public func KromApplyFramesBetweenSteps() -> Int32 = 4

@addMethod(RipperDocGameController)
private func KromFinishApply() -> Void {
  this.m_hoverArea = this.m_kromSavedHoverArea;
  this.m_equippedSlotIndex = this.m_kromSavedSlotIndex;
  this.m_kromBusy = false;
  this.UpdateCapacityBar(false);
  this.UpdateArmorBar(false);
  this.InvalidateMinigridsNextFrame();
  this.RefreshInventoryNextFrame();

  // Whatever the set asks for that is not installed now could not be installed.
  let current = this.KromCurrentCyberware();
  let none: array<KromOwnedItem>;
  let left = KromPlanLoadout(current, this.m_kromTarget, none);
  let missing: array<String>;
  let notInstalled = left.missing;
  for m in notInstalled {
    ArrayPush(missing, KromLoadoutsPanel.ItemName(m.item));
  }
  if IsDefined(this.m_kromPanel) {
    this.m_kromPanel.OnApplyFinished(this.m_kromTargetName, missing);
  }
}
