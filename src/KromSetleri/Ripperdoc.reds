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

// Points the screen's equip logic at one area/slot, the way hovering it in the UI would.
@addMethod(RipperDocGameController)
private func KromTarget(entry: KromSlotItem) -> wref<gameItemData> {
  this.m_hoverArea = entry.area;
  this.m_equippedSlotIndex = entry.slot;
  let player = this.m_player;
  return GameInstance.GetTransactionSystem(player.GetGame()).GetItemData(player, entry.item);
}

// Loads set `index`. Pairs that change the same area and slot are swapped in one vanilla call;
// pure removals run before pure installs so capacity frees up first. Anything that could not be
// installed ends up in the returned plan's `missing`.
@addMethod(RipperDocGameController)
public func KromApplySet(index: Int32) -> ref<KromPlan> {
  let sets = KromSetleriSystem.Get(this.m_player.GetGame()).GetSets();
  if index < 0 || index >= ArraySize(sets) {
    return null;
  }
  let target = sets[index];
  let equipped = this.KromCurrentCyberware();
  let owned = this.KromOwnedCyberware();
  let plan = KromPlanLoadout(equipped, target.items, owned);

  let unequip = plan.unequip;
  let equip = plan.equip;
  let swapped: array<Bool>;
  for e in equip {
    ArrayPush(swapped, false);
  }

  // Pure removals first.
  for u in unequip {
    let pair = -1;
    let i = 0;
    while i < ArraySize(equip) {
      if pair < 0 && !swapped[i] && Equals(equip[i].area, u.area) && equip[i].slot == u.slot {
        pair = i;
      }
      i += 1;
    }
    if pair < 0 {
      let old = this.KromTarget(u);
      if IsDefined(old) {
        this.UnequipCyberware(old, null, true);
      }
    } else {
      swapped[pair] = true;
    }
  }

  // Swaps in place, then pure installs.
  let k = 0;
  while k < ArraySize(equip) {
    let e = equip[k];
    let ok = false;
    let next = this.KromTarget(e);
    if IsDefined(next) {
      if swapped[k] {
        let player = this.m_player;
        let oldId = EquipmentSystem.GetData(player).GetItemInEquipSlot(e.area, e.slot);
        let old = GameInstance.GetTransactionSystem(player.GetGame()).GetItemData(player, oldId);
        ok = IsDefined(old) && this.CheckIfCanEquip(next, old) && this.UnequipCyberware(old, next, true);
      } else {
        ok = this.CheckIfCanEquip(next, e.area) && this.EquipCyberware(next);
      }
    }
    if !ok {
      ArrayPush(plan.missing, e);
    }
    k += 1;
  }

  this.UpdateCapacityBar(false);
  this.UpdateArmorBar(false);
  this.InvalidateMinigridsNextFrame();
  this.RefreshInventoryNextFrame();
  return plan;
}
