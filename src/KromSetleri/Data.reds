module KromSetleri

// One installed cyberware piece: which body area, which slot in it, and which exact item.
public struct KromSlotItem {
  let area: gamedataEquipmentArea;
  let slot: Int32;
  let item: ItemID;
}

public class KromSet {
  public let name: String;
  public let items: array<KromSlotItem>;
}
