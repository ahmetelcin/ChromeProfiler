module KromSetleri

// The set data and every operation on it, as a plain object. Stored as flat parallel arrays:
// entry k belongs to set entrySet[k]. Kept separate from the ScriptableSystem because creating
// a ScriptableSystem with `new` (as tests would) crashes the game.
public class KromSetStore {
  public let setNames: array<CName>;
  public let entrySet: array<Int32>;
  public let entryArea: array<gamedataEquipmentArea>;
  public let entrySlot: array<Int32>;
  public let entryItem: array<ItemID>;

  public static func MaxSets() -> Int32 = 10

  // Builds each set in a local before adding it: pushing into `sets[i].items` directly
  // corrupted memory (garbage set counts, then crashes).
  public func GetSets() -> array<ref<KromSet>> {
    let sets: array<ref<KromSet>>;
    let i = 0;
    while i < ArraySize(this.setNames) {
      let set = new KromSet();
      set.name = NameToString(this.setNames[i]);
      let items: array<KromSlotItem>;
      let k = 0;
      while k < ArraySize(this.entrySet) {
        if this.entrySet[k] == i {
          ArrayPush(items, KromSlotItem(this.entryArea[k], this.entrySlot[k], this.entryItem[k]));
        }
        k += 1;
      }
      set.items = items;
      ArrayPush(sets, set);
      i += 1;
    }
    return sets;
  }

  // index == -1 appends a new set; returns false when MaxSets() sets already exist.
  public func SaveSet(index: Int32, name: String, items: array<KromSlotItem>) -> Bool {
    let target = index;
    if target < 0 {
      if ArraySize(this.setNames) >= KromSetStore.MaxSets() {
        return false;
      }
      ArrayPush(this.setNames, StringToName(name));
      target = ArraySize(this.setNames) - 1;
    } else {
      if target >= ArraySize(this.setNames) {
        return false;
      }
      this.setNames[target] = StringToName(name);
      this.RemoveEntries(target);
    }
    for entry in items {
      ArrayPush(this.entrySet, target);
      ArrayPush(this.entryArea, entry.area);
      ArrayPush(this.entrySlot, entry.slot);
      ArrayPush(this.entryItem, entry.item);
    }
    return true;
  }

  public func RenameSet(index: Int32, name: String) -> Void {
    if index >= 0 && index < ArraySize(this.setNames) {
      this.setNames[index] = StringToName(name);
    }
  }

  public func DeleteSet(index: Int32) -> Void {
    if index < 0 || index >= ArraySize(this.setNames) {
      return;
    }
    this.RemoveEntries(index);
    ArrayErase(this.setNames, index);
    let k = 0;
    while k < ArraySize(this.entrySet) {
      if this.entrySet[k] > index {
        this.entrySet[k] -= 1;
      }
      k += 1;
    }
  }

  private func RemoveEntries(index: Int32) -> Void {
    let k = ArraySize(this.entrySet) - 1;
    while k >= 0 {
      if this.entrySet[k] == index {
        ArrayErase(this.entrySet, k);
        ArrayErase(this.entryArea, k);
        ArrayErase(this.entrySlot, k);
        ArrayErase(this.entryItem, k);
      }
      k -= 1;
    }
  }
}

// Keeps the sets in the save file. Persistent fields only use types the game itself persists
// (CName, Int32, ItemID, gamedataEquipmentArea and arrays of them); KromSetStore does the work.
public class KromSetleriSystem extends ScriptableSystem {
  private persistent let m_setNames: array<CName>;
  private persistent let m_entrySet: array<Int32>;
  private persistent let m_entryArea: array<gamedataEquipmentArea>;
  private persistent let m_entrySlot: array<Int32>;
  private persistent let m_entryItem: array<ItemID>;

  public static func Get(game: GameInstance) -> ref<KromSetleriSystem> {
    return GameInstance.GetScriptableSystemsContainer(game).Get(n"KromSetleri.KromSetleriSystem") as KromSetleriSystem;
  }

  public func GetSets() -> array<ref<KromSet>> {
    return this.Load().GetSets();
  }

  public func SaveSet(index: Int32, name: String, items: array<KromSlotItem>) -> Bool {
    let store = this.Load();
    let ok = store.SaveSet(index, name, items);
    this.Keep(store);
    return ok;
  }

  public func RenameSet(index: Int32, name: String) -> Void {
    let store = this.Load();
    store.RenameSet(index, name);
    this.Keep(store);
  }

  public func DeleteSet(index: Int32) -> Void {
    let store = this.Load();
    store.DeleteSet(index);
    this.Keep(store);
  }

  private func Load() -> ref<KromSetStore> {
    let store = new KromSetStore();
    store.setNames = this.m_setNames;
    store.entrySet = this.m_entrySet;
    store.entryArea = this.m_entryArea;
    store.entrySlot = this.m_entrySlot;
    store.entryItem = this.m_entryItem;
    return store;
  }

  private func Keep(store: ref<KromSetStore>) -> Void {
    this.m_setNames = store.setNames;
    this.m_entrySet = store.entrySet;
    this.m_entryArea = store.entryArea;
    this.m_entrySlot = store.entrySlot;
    this.m_entryItem = store.entryItem;
  }
}
