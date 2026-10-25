module KromSetleri

// A cyberware item the player owns but has not installed, with its quality for tie-breaking.
public struct KromOwnedItem {
  let item: ItemID;
  let quality: Int32;
}

// What loading a set does: remove these, then install these; the rest could not be found.
public class KromPlan {
  public let unequip: array<KromSlotItem>;
  public let equip: array<KromSlotItem>;
  public let missing: array<KromSlotItem>;
}

// Same body area and same cyberware record. Slots are ignored on purpose: the game picks the
// slot itself when installing, so a piece can sit in a different slot than when it was saved.
func KromSameRecordInArea(a: KromSlotItem, b: KromSlotItem) -> Bool {
  return Equals(a.area, b.area) && ItemID.GetTDBID(a.item) == ItemID.GetTDBID(b.item);
}

// Pure planning step: no game calls, so it can be tested at boot.
public func KromPlanLoadout(equipped: array<KromSlotItem>, target: array<KromSlotItem>, owned: array<KromOwnedItem>) -> ref<KromPlan> {
  let plan = new KromPlan();
  let used: array<Bool>;
  for o in owned {
    ArrayPush(used, false);
  }

  // Each installed piece keeps at most one matching set entry, so two copies of a record in the
  // set need two installed copies to both count as already in place.
  let satisfied: array<Bool>;
  for t in target {
    ArrayPush(satisfied, false);
  }
  for cur in equipped {
    let match = -1;
    let i = 0;
    while i < ArraySize(target) {
      if match < 0 && !satisfied[i] && KromSameRecordInArea(cur, target[i]) {
        match = i;
      }
      i += 1;
    }
    if match < 0 {
      ArrayPush(plan.unequip, cur);
    } else {
      satisfied[match] = true;
    }
  }

  let w = 0;
  while w < ArraySize(target) {
    let want = target[w];
    let already = satisfied[w];
    w += 1;
    if !already {
      // Exact item first, otherwise the highest-quality unused copy of the same record.
      let pick = -1;
      let i = 0;
      while i < ArraySize(owned) {
        if !used[i] && owned[i].item == want.item {
          pick = i;
        }
        i += 1;
      }
      if pick < 0 {
        i = 0;
        while i < ArraySize(owned) {
          if !used[i] && ItemID.GetTDBID(owned[i].item) == ItemID.GetTDBID(want.item)
            && (pick < 0 || owned[i].quality > owned[pick].quality) {
            pick = i;
          }
          i += 1;
        }
      }
      if pick < 0 {
        ArrayPush(plan.missing, want);
      } else {
        used[pick] = true;
        ArrayPush(plan.equip, KromSlotItem(want.area, want.slot, owned[pick].item));
      }
    }
  }
  return plan;
}
