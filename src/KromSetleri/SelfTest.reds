// In-game self-tests. They run once per game boot and log PASS/FAIL lines to
// bin/x64/plugins/cyber_engine_tweaks/gamelog.log under [KromSetleri].
module KromSetleri

public func KromDebug_SelfTest() -> Bool = true

// Runs when the player puppet attaches, which also happens in the main-menu scene, so no save is
// needed. Note for all code here: always store a returned array in a local before using it;
// redscript 0.5 reads a call's temporary array result as freed memory.
public class KromSelfTestSystem extends ScriptableSystem {
  private func OnPlayerAttach(request: ref<PlayerAttachRequest>) -> Void {
    if !KromDebug_SelfTest() {
      return;
    }
    KromSelfTest_StorageSave();
    KromSelfTest_StorageMaxTen();
    KromSelfTest_StorageDelete();
    KromSelfTest_Planner();
    ModLog(n"KromSetleri", "SelfTest: done");
  }
}

public func KromCheck(name: String, ok: Bool) -> Void {
  ModLog(n"KromSetleri", (ok ? "PASS " : "FAIL ") + name);
}

func KromTestA() -> KromSlotItem {
  return KromSlotItem(gamedataEquipmentArea.SystemReplacementCW, 0, ItemID.FromTDBID(t"Items.AdvancedSandevistanApogeePlusPlus"));
}

func KromTestB() -> KromSlotItem {
  return KromSlotItem(gamedataEquipmentArea.EyesCW, 0, ItemID.FromTDBID(t"Items.KiroshiOptics"));
}

func KromTestTwo() -> array<KromSlotItem> {
  let two: array<KromSlotItem>;
  ArrayPush(two, KromTestA());
  ArrayPush(two, KromTestB());
  return two;
}

public func KromSelfTest_StorageSave() -> Void {
  // ItemID.FromTDBID makes a new random seed on every call, so the set is built from these exact values.
  let a = KromTestA();
  let b = KromTestB();
  let two: array<KromSlotItem>;
  ArrayPush(two, a);
  ArrayPush(two, b);
  // Storage_SaveAppendsAndReadsBack
  let sys = new KromSetStore();
  let saved = sys.SaveSet(-1, "Netrunner", two);
  let sets = sys.GetSets();
  KromCheck("Storage_SaveAppendsAndReadsBack",
    saved && ArraySize(sets) == 1 && Equals(sets[0].name, "Netrunner") && ArraySize(sets[0].items) == 2
    && Equals(sets[0].items[0].area, a.area) && sets[0].items[0].slot == a.slot && sets[0].items[0].item == a.item
    && Equals(sets[0].items[1].area, b.area) && sets[0].items[1].item == b.item);
}

public func KromSelfTest_StorageMaxTen() -> Void {
  let two = KromTestTwo();
  // Storage_MaxTenSets
  let full = new KromSetStore();
  let i = 0;
  while i < KromSetStore.MaxSets() {
    full.SaveSet(-1, "Set " + ToString(i + 1), two);
    i += 1;
  }
  let eleventh = full.SaveSet(-1, "Set 11", two);
  let fullSets = full.GetSets();
  let count = ArraySize(fullSets);
  KromCheck("Storage_MaxTenSets", KromSetStore.MaxSets() == 10 && !eleventh && count == 10);
  if eleventh || count != 10 {
    ModLog(n"KromSetleri", "  MaxTenSets: max=" + ToString(KromSetStore.MaxSets()) + " eleventh=" + ToString(eleventh) + " count=" + ToString(count));
  }
}

public func KromSelfTest_StorageDelete() -> Void {
  let b = KromTestB();
  let two = KromTestTwo();
  // Storage_DeleteReindexes
  let one: array<KromSlotItem>;
  ArrayPush(one, b);
  let abc = new KromSetStore();
  abc.SaveSet(-1, "A", two);
  abc.SaveSet(-1, "B", one);
  abc.SaveSet(-1, "C", one);
  abc.DeleteSet(1);
  let left = abc.GetSets();
  KromCheck("Storage_DeleteReindexes",
    ArraySize(left) == 2 && Equals(left[0].name, "A") && Equals(left[1].name, "C")
    && ArraySize(left[0].items) == 2 && ArraySize(left[1].items) == 1 && left[1].items[0].item == b.item);

  // Storage_Rename
  abc.RenameSet(0, "Tank");
  let renamed = abc.GetSets();
  KromCheck("Storage_Rename", Equals(renamed[0].name, "Tank"));

  // Storage_OverwriteKeepsIndex
  abc.SaveSet(1, "C", two);
  let after = abc.GetSets();
  KromCheck("Storage_OverwriteKeepsIndex", ArraySize(after) == 2 && Equals(after[1].name, "C") && ArraySize(after[1].items) == 2);
}

func KromCopy(record: TweakDBID, seed: Int32) -> ItemID {
  return ItemID.CreateFromSeedWithOffset(record, Cast<Uint32>(seed), 0);
}

func KromOwned(item: ItemID, quality: Int32) -> KromOwnedItem {
  return KromOwnedItem(item, quality);
}

public func KromSelfTest_Planner() -> Void {
  let os1 = KromCopy(t"Items.AdvancedSandevistanApogeePlusPlus", 101);
  let os2 = KromCopy(t"Items.MilitechParaline", 102);
  let eye = KromCopy(t"Items.KiroshiOptics", 103);
  let heart = KromCopy(t"Items.BloodPumpLegendary", 104);

  // Planner_EquippedMatchIsNoop
  let cur: array<KromSlotItem>;
  ArrayPush(cur, KromSlotItem(gamedataEquipmentArea.SystemReplacementCW, 0, os1));
  ArrayPush(cur, KromSlotItem(gamedataEquipmentArea.EyesCW, 0, eye));
  let owned: array<KromOwnedItem>;
  let p = KromPlanLoadout(cur, cur, owned);
  KromCheck("Planner_EquippedMatchIsNoop", ArraySize(p.unequip) == 0 && ArraySize(p.equip) == 0 && ArraySize(p.missing) == 0);

  // Planner_UnequipsComeFirst: switching the OS gives one unequip (old OS) and one equip (new OS)
  let target: array<KromSlotItem>;
  ArrayPush(target, KromSlotItem(gamedataEquipmentArea.SystemReplacementCW, 0, os2));
  ArrayPush(target, KromSlotItem(gamedataEquipmentArea.EyesCW, 0, eye));
  let ownedOs2: array<KromOwnedItem>;
  ArrayPush(ownedOs2, KromOwned(os2, 3));
  p = KromPlanLoadout(cur, target, ownedOs2);
  KromCheck("Planner_UnequipsComeFirst",
    ArraySize(p.unequip) == 1 && p.unequip[0].item == os1 && ArraySize(p.equip) == 1 && p.equip[0].item == os2 && ArraySize(p.missing) == 0);

  // Planner_PrefersExactItemThenSameRecord
  let exactTarget: array<KromSlotItem>;
  ArrayPush(exactTarget, KromSlotItem(gamedataEquipmentArea.CardiovascularSystemCW, 0, heart));
  let none: array<KromSlotItem>;
  let heartLow = KromCopy(t"Items.BloodPumpLegendary", 201);
  let heartHigh = KromCopy(t"Items.BloodPumpLegendary", 202);
  let ownedExact: array<KromOwnedItem>;
  ArrayPush(ownedExact, KromOwned(heartHigh, 5));
  ArrayPush(ownedExact, KromOwned(heart, 1));
  let pExact = KromPlanLoadout(none, exactTarget, ownedExact);
  let ownedCopies: array<KromOwnedItem>;
  ArrayPush(ownedCopies, KromOwned(heartLow, 2));
  ArrayPush(ownedCopies, KromOwned(heartHigh, 5));
  let pCopy = KromPlanLoadout(none, exactTarget, ownedCopies);
  KromCheck("Planner_PrefersExactItemThenSameRecord",
    ArraySize(pExact.equip) == 1 && pExact.equip[0].item == heart
    && ArraySize(pCopy.equip) == 1 && pCopy.equip[0].item == heartHigh && pCopy.equip[0].slot == 0);

  // Planner_NoDoubleUseOfOneItem: two slots want the same record, only one copy is owned
  let twoHearts: array<KromSlotItem>;
  ArrayPush(twoHearts, KromSlotItem(gamedataEquipmentArea.CardiovascularSystemCW, 0, heartLow));
  ArrayPush(twoHearts, KromSlotItem(gamedataEquipmentArea.CardiovascularSystemCW, 1, heartHigh));
  let ownedOne: array<KromOwnedItem>;
  ArrayPush(ownedOne, KromOwned(heart, 3));
  p = KromPlanLoadout(none, twoHearts, ownedOne);
  KromCheck("Planner_NoDoubleUseOfOneItem", ArraySize(p.equip) == 1 && ArraySize(p.missing) == 1);

  // Planner_MissingWhenNotOwned
  let noneOwned: array<KromOwnedItem>;
  p = KromPlanLoadout(none, exactTarget, noneOwned);
  KromCheck("Planner_MissingWhenNotOwned", ArraySize(p.equip) == 0 && ArraySize(p.missing) == 1 && p.missing[0].item == heart);
}
