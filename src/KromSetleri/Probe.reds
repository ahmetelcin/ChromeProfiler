// Temporary: proves which persistent field types survive a save/load round trip. Removed in Task 3.
module KromSetleri

public class KromProbeSystem extends ScriptableSystem {
  private persistent let m_name: CName;
  private persistent let m_items: array<ItemID>;
  private persistent let m_areas: array<gamedataEquipmentArea>;

  private func OnPlayerAttach(request: ref<PlayerAttachRequest>) -> Void {
    let player = request.owner as PlayerPuppet;
    if !IsDefined(player) {
      return;
    }
    if Equals(this.m_name, n"None") || Equals(this.m_name, n"") {
      this.m_name = StringToName("Krom Probe " + ToString(RandRange(1000, 9999)));
      let item = EquipmentSystem.GetData(player).GetItemInEquipSlot(gamedataEquipmentArea.SystemReplacementCW, 0);
      ArrayPush(this.m_items, item);
      ArrayPush(this.m_areas, gamedataEquipmentArea.SystemReplacementCW);
      ModLog(n"KromSetleri", "KromProbe: wrote " + NameToString(this.m_name) + " item=" + TDBID.ToStringDEBUG(ItemID.GetTDBID(item)));
    } else {
      ModLog(n"KromSetleri", "KromProbe: read name=" + NameToString(this.m_name) + " items=" + ToString(ArraySize(this.m_items))
        + " item0=" + TDBID.ToStringDEBUG(ItemID.GetTDBID(this.m_items[0])) + " area0=" + ToString(this.m_areas[0]));
    }
  }
}
