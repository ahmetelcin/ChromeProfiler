module KromSetleri

// All player-facing text, in Turkish.
public abstract class KromText {
  public static func Button() -> String = "LOADOUTS"
  public static func Title() -> String = "Loadouts · Krom setleri"
  public static func NewSet() -> String = "+ Şu anki kromları yeni set yap"
  public static func Load() -> String = "Yükle"
  public static func Overwrite() -> String = "Üstüne kaydet"
  public static func Rename() -> String = "Adlandır"
  public static func Delete() -> String = "Sil"
  public static func Close() -> String = "Kapat"
  public static func Confirm() -> String = "Tamam"
  public static func NotOwned() -> String = " · envanterde yok"
  public static func Empty() -> String = "Henüz set yok. Şu anki kromlarını kaydetmek için yukarıdaki satıra bas."
  public static func PickSet() -> String = "Bir set seç."
  public static func DefaultName(n: Int32) -> String = "Set " + ToString(n)
  public static func Full() -> String = "En fazla " + ToString(KromSetStore.MaxSets()) + " set kaydedilebilir."

  public static func Loaded(name: String) -> String = name + " takıldı"

  public static func LoadedWithMissing(name: String, missing: array<String>) -> String {
    let list = "";
    let i = 0;
    while i < ArraySize(missing) {
      list += (i > 0 ? ", " : "") + missing[i];
      i += 1;
    }
    return name + " takıldı · " + ToString(ArraySize(missing)) + " implant takılamadı: " + list;
  }

  public static func Saved(name: String) -> String = name + " kaydedildi"
  public static func Deleted(name: String) -> String = name + " silindi"

  public static func Area(area: gamedataEquipmentArea) -> String {
    switch area {
      case gamedataEquipmentArea.FrontalCortexCW: return "Frontal Korteks";
      case gamedataEquipmentArea.SystemReplacementCW: return "İşletim Sistemi";
      case gamedataEquipmentArea.ArmsCW: return "Kollar";
      case gamedataEquipmentArea.EyesCW: return "Yüz";
      case gamedataEquipmentArea.MusculoskeletalSystemCW: return "İskelet";
      case gamedataEquipmentArea.HandsCW: return "Eller";
      case gamedataEquipmentArea.NervousSystemCW: return "Sinir Sistemi";
      case gamedataEquipmentArea.CardiovascularSystemCW: return "Dolaşım Sistemi";
      case gamedataEquipmentArea.IntegumentarySystemCW: return "Örtü Sistemi";
      case gamedataEquipmentArea.LegsCW: return "Bacaklar";
      default: return ToString(area);
    }
  }
}
