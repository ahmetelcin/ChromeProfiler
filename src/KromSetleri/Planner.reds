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

func KromSameRecordInSlot(a: KromSlotItem, b: KromSlotItem) -> Bool {
  return Equals(a.area, b.area) && a.slot == b.slot && ItemID.GetTDBID(a.item) == ItemID.GetTDBID(b.item);
}

// Pure planning step: no game calls, so it can be tested at boot.
public func KromPlanLoadout(equipped: array<KromSlotItem>, target: array<KromSlotItem>, owned: array<KromOwnedItem>) -> ref<KromPlan> {
  let plan = new KromPlan();
  let used: array<Bool>;
  for o in owned {
    ArrayPush(used, false);
  }

  for cur in equipped {
    let keep = false;
    for want in target {
      if KromSameRecordInSlot(cur, want) {
        keep = true;
      }
    }
    if !keep {
      ArrayPush(plan.unequip, cur);
    }
  }

  for want in target {
    let already = false;
    for cur in equipped {
      if KromSameRecordInSlot(cur, want) {
        already = true;
      }
    }
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
