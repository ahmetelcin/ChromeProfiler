module KromSetleri

// All player-facing text. Turkish when the game's on-screen language is Turkish, English otherwise.
public abstract class KromText {
  public static func IsTurkish() -> Bool {
    let settings = GameInstance.GetSettingsSystem(GetGameInstance());
    if !IsDefined(settings) {
      return false;
    }
    let language = settings.GetVar(n"/language", n"OnScreen") as ConfigVarListName;
    return IsDefined(language) && Equals(language.GetValue(), n"tr-tr");
  }

  public static func Pick(tr: String, en: String) -> String = KromText.IsTurkish() ? tr : en

  public static func Button() -> String = "LOADOUTS"
  public static func Title() -> String = KromText.Pick("Loadouts · Krom setleri", "Loadouts · Chrome sets")
  public static func NewSet() -> String = KromText.Pick("+ Şu anki kromları yeni set yap", "+ Save current chrome as a new set")
  public static func Load() -> String = KromText.Pick("Yükle", "Load")
  public static func Overwrite() -> String = KromText.Pick("Üstüne kaydet", "Overwrite")
  public static func Rename() -> String = KromText.Pick("Adlandır", "Rename")
  public static func Delete() -> String = KromText.Pick("Sil", "Delete")
  public static func Close() -> String = KromText.Pick("Kapat", "Close")
  public static func Confirm() -> String = KromText.Pick("Tamam", "OK")
  public static func NotOwned() -> String = KromText.Pick(" · envanterde yok", " · not in inventory")
  public static func Empty() -> String = KromText.Pick("Henüz set yok. Şu anki kromlarını kaydetmek için yukarıdaki satıra bas.", "No sets yet. Click the line above to save your current chrome.")
  public static func PickSet() -> String = KromText.Pick("Bir set seç.", "Pick a set.")
  public static func DefaultName(n: Int32) -> String = "Set " + ToString(n)
  public static func Full() -> String = KromText.Pick("En fazla " + ToString(KromSetStore.MaxSets()) + " set kaydedilebilir.", "You can save at most " + ToString(KromSetStore.MaxSets()) + " sets.")

  public static func Loaded(name: String) -> String = KromText.Pick(name + " takıldı", name + " installed")
  public static func Loading() -> String = KromText.Pick("Yükleniyor…", "Loading…")

  public static func LoadedWithMissing(name: String, missing: array<String>) -> String {
    let list = "";
    let i = 0;
    while i < ArraySize(missing) {
      list += (i > 0 ? ", " : "") + missing[i];
      i += 1;
    }
    let count = ToString(ArraySize(missing));
    return KromText.Pick(name + " takıldı · " + count + " implant takılamadı: " + list,
      name + " installed · " + count + " could not be installed: " + list);
  }

  public static func Saved(name: String) -> String = KromText.Pick(name + " kaydedildi", name + " saved")
  public static func Deleted(name: String) -> String = KromText.Pick(name + " silindi", name + " deleted")

  public static func Area(area: gamedataEquipmentArea) -> String {
    switch area {
      case gamedataEquipmentArea.FrontalCortexCW: return KromText.Pick("Frontal Korteks", "Frontal Cortex");
      case gamedataEquipmentArea.SystemReplacementCW: return KromText.Pick("İşletim Sistemi", "Operating System");
      case gamedataEquipmentArea.ArmsCW: return KromText.Pick("Kollar", "Arms");
      case gamedataEquipmentArea.EyesCW: return KromText.Pick("Yüz", "Face");
      case gamedataEquipmentArea.MusculoskeletalSystemCW: return KromText.Pick("İskelet", "Skeleton");
      case gamedataEquipmentArea.HandsCW: return KromText.Pick("Eller", "Hands");
      case gamedataEquipmentArea.NervousSystemCW: return KromText.Pick("Sinir Sistemi", "Nervous System");
      case gamedataEquipmentArea.CardiovascularSystemCW: return KromText.Pick("Dolaşım Sistemi", "Circulatory System");
      case gamedataEquipmentArea.IntegumentarySystemCW: return KromText.Pick("Örtü Sistemi", "Integumentary System");
      case gamedataEquipmentArea.LegsCW: return KromText.Pick("Bacaklar", "Legs");
      default: return ToString(area);
    }
  }
}
