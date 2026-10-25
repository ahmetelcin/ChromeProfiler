module KromSetleri
import Codeware.UI.*

// The LOADOUTS button and the menu it opens, drawn over the ripperdoc screen.
// Reminder: store every returned array in a local before use (redscript 0.5 temporaries).
public class KromLoadoutsPanel {
  private let m_owner: wref<RipperDocGameController>;
  private let m_button: ref<SimpleButton>;
  private let m_overlay: wref<inkCanvas>;
  private let m_list: wref<inkVerticalPanel>;
  private let m_details: wref<inkVerticalPanel>;
  private let m_status: wref<inkText>;
  private let m_newButton: ref<SimpleButton>;
  private let m_setButtons: array<ref<SimpleButton>>;
  private let m_actionButtons: array<ref<SimpleButton>>;
  private let m_nameInput: ref<HubTextInput>;
  private let m_confirmButton: ref<SimpleButton>;
  private let m_selected: Int32;

  public static func Create(owner: ref<RipperDocGameController>) -> ref<KromLoadoutsPanel> {
    let self = new KromLoadoutsPanel();
    self.m_owner = owner;
    self.m_selected = -1;
    self.Build(owner.GetRootCompoundWidget());
    return self;
  }

  // --- layout -------------------------------------------------------------------------------

  private func Build(root: wref<inkCompoundWidget>) -> Void {
    let button = SimpleButton.Create();
    button.SetText(KromText.Button());
    button.SetWidth(360.0);
    let buttonRoot = button.GetRootWidget();
    buttonRoot.SetAnchor(inkEAnchor.BottomRight);
    buttonRoot.SetAnchorPoint(Vector2(1.0, 1.0));
    buttonRoot.SetMargin(inkMargin(0.0, 0.0, 140.0, 190.0));
    button.Reparent(root);
    button.RegisterToCallback(n"OnBtnClick", this, n"OnToggle");
    this.m_button = button;

    let overlay = new inkCanvas();
    overlay.SetName(n"KromLoadoutsOverlay");
    overlay.SetAnchor(inkEAnchor.Fill);
    overlay.SetVisible(false);
    overlay.SetInteractive(true);
    overlay.Reparent(root);
    this.m_overlay = overlay;

    let dim = new inkRectangle();
    dim.SetAnchor(inkEAnchor.Fill);
    dim.SetTintColor(ThemeColors.PureBlack());
    dim.SetOpacity(0.82);
    dim.SetInteractive(true);
    dim.Reparent(overlay);

    let frame = new inkCanvas();
    frame.SetAnchor(inkEAnchor.Centered);
    frame.SetAnchorPoint(Vector2(0.5, 0.5));
    frame.SetSize(Vector2(2300.0, 1400.0));
    frame.Reparent(overlay);

    let frameBg = new inkRectangle();
    frameBg.SetAnchor(inkEAnchor.Fill);
    frameBg.SetTintColor(ThemeColors.BlackPearl());
    frameBg.SetOpacity(0.95);
    frameBg.Reparent(frame);

    let title = KromLoadoutsPanel.MakeText(KromText.Title(), 64, ThemeColors.ElectricBlue());
    title.SetMargin(inkMargin(60.0, 40.0, 0.0, 0.0));
    title.Reparent(frame);

    let list = new inkVerticalPanel();
    list.SetMargin(inkMargin(60.0, 160.0, 0.0, 0.0));
    list.SetChildMargin(inkMargin(0.0, 0.0, 0.0, 14.0));
    list.Reparent(frame);
    this.m_list = list;

    let details = new inkVerticalPanel();
    details.SetMargin(inkMargin(1180.0, 170.0, 0.0, 0.0));
    details.SetChildMargin(inkMargin(0.0, 0.0, 0.0, 8.0));
    details.Reparent(frame);
    this.m_details = details;

    let input = HubTextInput.Create();
    input.SetMaxLength(28);
    input.SetWidth(900.0);
    let inputRoot = input.GetRootWidget();
    inputRoot.SetAnchor(inkEAnchor.BottomLeft);
    inputRoot.SetAnchorPoint(Vector2(0.0, 1.0));
    inputRoot.SetMargin(inkMargin(60.0, 0.0, 0.0, 260.0));
    inputRoot.SetVisible(false);
    input.Reparent(frame);
    this.m_nameInput = input;

    let confirm = KromLoadoutsPanel.MakeButton(KromText.Confirm(), 300.0);
    let confirmRoot = confirm.GetRootWidget();
    confirmRoot.SetAnchor(inkEAnchor.BottomLeft);
    confirmRoot.SetAnchorPoint(Vector2(0.0, 1.0));
    confirmRoot.SetMargin(inkMargin(1000.0, 0.0, 0.0, 250.0));
    confirmRoot.SetVisible(false);
    confirm.Reparent(frame);
    confirm.RegisterToCallback(n"OnBtnClick", this, n"OnConfirmRename");
    this.m_confirmButton = confirm;

    let actions = new inkHorizontalPanel();
    actions.SetAnchor(inkEAnchor.BottomLeft);
    actions.SetAnchorPoint(Vector2(0.0, 1.0));
    actions.SetMargin(inkMargin(60.0, 0.0, 0.0, 120.0));
    actions.SetChildMargin(inkMargin(0.0, 0.0, 24.0, 0.0));
    actions.Reparent(frame);
    this.AddAction(actions, KromText.Load(), n"OnLoad");
    this.AddAction(actions, KromText.Overwrite(), n"OnOverwrite");
    this.AddAction(actions, KromText.Rename(), n"OnRename");
    this.AddAction(actions, KromText.Delete(), n"OnDelete");
    this.AddAction(actions, KromText.Close(), n"OnClose");

    let status = KromLoadoutsPanel.MakeText("", 40, ThemeColors.Dandelion());
    status.SetAnchor(inkEAnchor.BottomLeft);
    status.SetAnchorPoint(Vector2(0.0, 1.0));
    status.SetMargin(inkMargin(60.0, 0.0, 0.0, 50.0));
    status.Reparent(frame);
    this.m_status = status;
  }

  private func AddAction(parent: ref<inkHorizontalPanel>, label: String, handler: CName) -> Void {
    let button = KromLoadoutsPanel.MakeButton(label, 380.0);
    button.Reparent(parent);
    button.RegisterToCallback(n"OnBtnClick", this, handler);
    ArrayPush(this.m_actionButtons, button);
  }

  private static func MakeButton(label: String, width: Float) -> ref<SimpleButton> {
    let button = SimpleButton.Create();
    button.SetText(label);
    button.SetWidth(width);
    return button;
  }

  private static func MakeText(text: String, size: Int32, color: HDRColor) -> ref<inkText> {
    let label = new inkText();
    label.SetText(text);
    label.SetFontFamily("base\\gameplay\\gui\\fonts\\raj\\raj.inkfontfamily");
    label.SetFontStyle(n"Medium");
    label.SetFontSize(size);
    label.SetTintColor(color);
    return label;
  }

  // --- refresh ------------------------------------------------------------------------------

  private func Sets() -> array<ref<KromSet>> {
    let owner = this.m_owner;
    let sets = KromSetleriSystem.Get(owner.GetPlayerControlledObject().GetGame()).GetSets();
    return sets;
  }

  private func Refresh() -> Void {
    let sets = this.Sets();
    if this.m_selected >= ArraySize(sets) {
      this.m_selected = ArraySize(sets) - 1;
    }
    this.m_list.RemoveAllChildren();
    ArrayClear(this.m_setButtons);
    let i = 0;
    while i < ArraySize(sets) {
      let label = (i == this.m_selected ? "▸ " : "") + sets[i].name;
      let button = KromLoadoutsPanel.MakeButton(label, 1000.0);
      button.Reparent(this.m_list);
      button.RegisterToCallback(n"OnBtnClick", this, n"OnPickSet");
      ArrayPush(this.m_setButtons, button);
      i += 1;
    }
    let newButton = KromLoadoutsPanel.MakeButton(KromText.NewSet(), 1000.0);
    newButton.Reparent(this.m_list);
    newButton.RegisterToCallback(n"OnBtnClick", this, n"OnNewSet");
    newButton.GetRootWidget().SetVisible(ArraySize(sets) < KromSetStore.MaxSets());
    this.m_newButton = newButton;
    this.RefreshDetails(sets);
    let hasSelection = this.m_selected >= 0;
    // Yükle, Üstüne kaydet, Adlandır, Sil need a selected set; Kapat does not.
    let k = 0;
    while k < 4 {
      this.m_actionButtons[k].SetDisabled(!hasSelection);
      k += 1;
    }
  }

  private func RefreshDetails(sets: array<ref<KromSet>>) -> Void {
    this.m_details.RemoveAllChildren();
    if ArraySize(sets) == 0 {
      KromLoadoutsPanel.MakeText(KromText.Empty(), 40, ThemeColors.PureWhite()).Reparent(this.m_details);
      return;
    }
    if this.m_selected < 0 {
      KromLoadoutsPanel.MakeText(KromText.PickSet(), 40, ThemeColors.PureWhite()).Reparent(this.m_details);
      return;
    }
    let owner = this.m_owner;
    let equipped = owner.KromCurrentCyberware();
    let owned = owner.KromOwnedCyberware();
    let chosen = sets[this.m_selected];
    let items = chosen.items;
    for entry in items {
      let available = KromLoadoutsPanel.IsAvailable(entry, equipped, owned);
      let text = KromText.Area(entry.area) + " · " + KromLoadoutsPanel.ItemName(entry.item) + (available ? "" : KromText.NotOwned());
      let color = available ? ThemeColors.PureWhite() : ThemeColors.Bittersweet();
      KromLoadoutsPanel.MakeText(text, 38, color).Reparent(this.m_details);
    }
  }

  private static func IsAvailable(entry: KromSlotItem, equipped: array<KromSlotItem>, owned: array<KromOwnedItem>) -> Bool {
    let record = ItemID.GetTDBID(entry.item);
    for e in equipped {
      if ItemID.GetTDBID(e.item) == record {
        return true;
      }
    }
    for o in owned {
      if ItemID.GetTDBID(o.item) == record {
        return true;
      }
    }
    return false;
  }

  private static func ItemName(item: ItemID) -> String {
    let record = RPGManager.GetItemRecord(item);
    if IsDefined(record) {
      let name = GetLocalizedTextByKey(record.DisplayName());
      if StrLen(name) > 0 {
        return name;
      }
    }
    return TDBID.ToStringDEBUG(ItemID.GetTDBID(item));
  }

  private func Say(text: String) -> Void {
    this.m_status.SetText(text);
  }

  private func HideRename() -> Void {
    this.m_nameInput.GetRootWidget().SetVisible(false);
    this.m_confirmButton.GetRootWidget().SetVisible(false);
  }

  // --- handlers -----------------------------------------------------------------------------

  protected cb func OnToggle(widget: wref<inkWidget>) -> Bool {
    let show = !this.m_overlay.IsVisible();
    this.m_overlay.SetVisible(show);
    if show {
      this.HideRename();
      this.Say("");
      this.Refresh();
    }
  }

  protected cb func OnClose(widget: wref<inkWidget>) -> Bool {
    this.m_overlay.SetVisible(false);
  }

  protected cb func OnPickSet(widget: wref<inkWidget>) -> Bool {
    let i = 0;
    while i < ArraySize(this.m_setButtons) {
      if this.m_setButtons[i].GetRootWidget() == widget {
        this.m_selected = i;
      }
      i += 1;
    }
    this.HideRename();
    this.Refresh();
  }

  protected cb func OnNewSet(widget: wref<inkWidget>) -> Bool {
    let sets = this.Sets();
    let name = KromText.DefaultName(ArraySize(sets) + 1);
    let owner = this.m_owner;
    if owner.KromSaveCurrent(-1, name) {
      this.m_selected = ArraySize(sets);
      this.Say(KromText.Saved(name));
    } else {
      this.Say(KromText.Full());
    }
    this.Refresh();
  }

  protected cb func OnLoad(widget: wref<inkWidget>) -> Bool {
    let sets = this.Sets();
    if this.m_selected < 0 || this.m_selected >= ArraySize(sets) {
      return false;
    }
    let name = sets[this.m_selected].name;
    let owner = this.m_owner;
    let plan = owner.KromApplySet(this.m_selected);
    if !IsDefined(plan) {
      return false;
    }
    let missing = plan.missing;
    if ArraySize(missing) == 0 {
      this.Say(KromText.Loaded(name));
    } else {
      let names: array<String>;
      for m in missing {
        ArrayPush(names, KromLoadoutsPanel.ItemName(m.item));
      }
      this.Say(KromText.LoadedWithMissing(name, names));
    }
    this.Refresh();
  }

  protected cb func OnOverwrite(widget: wref<inkWidget>) -> Bool {
    let sets = this.Sets();
    if this.m_selected < 0 || this.m_selected >= ArraySize(sets) {
      return false;
    }
    let name = sets[this.m_selected].name;
    let owner = this.m_owner;
    owner.KromSaveCurrent(this.m_selected, name);
    this.Say(KromText.Saved(name));
    this.Refresh();
  }

  protected cb func OnRename(widget: wref<inkWidget>) -> Bool {
    let sets = this.Sets();
    if this.m_selected < 0 || this.m_selected >= ArraySize(sets) {
      return false;
    }
    this.m_nameInput.SetText(sets[this.m_selected].name);
    this.m_nameInput.GetRootWidget().SetVisible(true);
    this.m_confirmButton.GetRootWidget().SetVisible(true);
  }

  protected cb func OnConfirmRename(widget: wref<inkWidget>) -> Bool {
    let name = this.m_nameInput.GetText();
    if StrLen(name) > 0 && this.m_selected >= 0 {
      let owner = this.m_owner;
      KromSetleriSystem.Get(owner.GetPlayerControlledObject().GetGame()).RenameSet(this.m_selected, name);
      this.Say(KromText.Saved(name));
    }
    this.HideRename();
    this.Refresh();
  }

  protected cb func OnDelete(widget: wref<inkWidget>) -> Bool {
    let sets = this.Sets();
    if this.m_selected < 0 || this.m_selected >= ArraySize(sets) {
      return false;
    }
    let name = sets[this.m_selected].name;
    let owner = this.m_owner;
    KromSetleriSystem.Get(owner.GetPlayerControlledObject().GetGame()).DeleteSet(this.m_selected);
    this.m_selected = -1;
    this.Say(KromText.Deleted(name));
    this.Refresh();
  }
}

@addField(RipperDocGameController)
private let m_kromPanel: ref<KromLoadoutsPanel>;

@wrapMethod(RipperDocGameController)
protected cb func OnInitialize() -> Bool {
  let result = wrappedMethod();
  if this.KromIsRealRipperdoc() {
    this.m_kromPanel = KromLoadoutsPanel.Create(this);
  }
  return result;
}
