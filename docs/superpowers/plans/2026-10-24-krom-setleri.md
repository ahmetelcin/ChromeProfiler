# Krom Setleri Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a LOADOUTS button to the Cyberpunk 2077 2.5 ripperdoc screen. It opens an in-game menu that saves the equipped cyberware into named sets and re-equips a set from owned items only.

**Architecture:** Pure redscript, no DLL.
- A `ScriptableSystem` stores the sets in the save using flat persistent arrays.
- A pure planner function turns (equipped, target set, owned items) into an unequip/equip/missing plan. Self-tests that log PASS/FAIL cover it.
- The ripperdoc controller is extended with `@wrapMethod`/`@addMethod` only. It hosts the button, the Codeware `InMenuPopup`, and applies plans through the game's own `UnequipCyberware`/`EquipCyberware`.

**Tech Stack:** redscript 0.5.32, Codeware (2.5 PR #63 build), game 2.5 (3.0.88.46235), installed `engine/tools/scc.exe` for offline compilation.

**Spec:** `C:\Users\merci\cp2077-build\krom-setleri\docs\2026-10-24-krom-setleri-design.md`

## Global Constraints

- Only usable when `RipperDocGameController.m_screen == CyberwareScreenType.Ripperdoc`. It must not appear for `Glamdoc` or `Inventory`.
- No `@replaceMethod` anywhere. Only `@wrapMethod`, `@addMethod`, `@addField` and new classes.
- Never create items, never add or remove money. Equip only items that are present in the player's inventory.
- Use the game's own equip logic (`RipperDocGameController.EquipCyberware(itemData: wref<gameItemData>) -> Bool`, `UnequipCyberware(itemData: wref<gameItemData>, opt itemToEquip: wref<gameItemData>, opt skipRefresh: Bool) -> Bool`). No direct `EquipRequest`s.
- Maximum 10 sets. UI text is Turkish.
- Persistent fields use only types the vanilla game persists: `Int32`, `CName`, `ItemID`, `gamedataEquipmentArea` and arrays of these. No `String`, no nested arrays.
- Each task ends with `bash /c/Users/merci/cp2077-build/tools/offline-compile.sh ArchiveXL Codeware TweakXL mod_settings` reporting `errors: 0`. The script copies `r6/scripts` (including `KromSetleri`) and the plugin scripts.
- Source of truth: `C:\Users\merci\cp2077-build\krom-setleri\src\KromSetleri\*.reds`.
  - Deploy by copying to `D:\SteamLibrary\steamapps\common\Cyberpunk 2077\r6\scripts\KromSetleri\` with `deploy.sh`.
  - Back up saves before the first in-game test with `backup-saves.sh`.

## Review Focus

1. **Two copies of the same cyberware** (same TweakDBID, different ItemID). Loading must pick the exact saved ItemID when owned; otherwise the owned copy of that TweakDBID with the highest quality. Test: `Planner_PrefersExactItemThenSameRecord`.
2. **A set item that was sold, or is now installed in another slot of the same set.** It must be reported as missing, not equipped twice. Test: `Planner_NoDoubleUseOfOneItem`.
3. **Capacity overflow mid-load.** Unequips must run before equips. An equip that `CheckIfCanEquip` rejects is reported in the summary and does not stop the rest. Test: `Planner_UnequipsComeFirst` plus the in-game checklist item "set over capacity".
4. **A save from before the mod, or the mod removed.** The system starts with zero sets, and a save made with the mod loads cleanly without it. In-game checklist items 6 and 7.
5. **The menu is opened outside a real ripperdoc** (Hub → Cyberware, Glamdoc). The button must not exist there. In-game checklist item 1.

---

### Task 1: Project scaffold and persistence probe

Prove that the chosen persistent types, especially runtime-created `CName` set names, survive save/load before anything is built on them.

**Files:**
- Create: `krom-setleri/deploy.sh`. Copies `src/KromSetleri/` to the game's `r6/scripts/KromSetleri/`.
- Create: `krom-setleri/backup-saves.sh`. Copies `%USERPROFILE%\Saved Games\CD Projekt Red\Cyberpunk 2077` to `C:\Users\merci\cp2077-build\original-backup\saves-<timestamp>`.
- Create: `krom-setleri/src/KromSetleri/Probe.reds`. Temporary; deleted in Task 3.
- Create: `krom-setleri/.gitignore` (empty) and run `git init` in `krom-setleri/`.

**Interfaces:**
- Produces: `deploy.sh` and `backup-saves.sh` used by every later task.

- [ ] **Step 1: Write the probe.**
  - Define `public class KromProbeSystem extends ScriptableSystem` with three fields:
    - `persistent let m_name: CName`
    - `persistent let m_items: array<ItemID>`
    - `persistent let m_areas: array<gamedataEquipmentArea>`
  - In `OnAttach()`:
    - If `m_name == n"None"`: set `m_name = StringToName("Krom Probe " + ToString(GetGameTime()))`, fill both arrays with the player's currently equipped `SystemReplacementCW` slot 0 item and area, and log `KromProbe: wrote <name>`.
    - Otherwise: log `KromProbe: read name=<NameToString(m_name)> items=<ArraySize(m_items)>`.
    - Log through `ModLog(n"KromSetleri", ...)`.
- [ ] **Step 2: Offline compile.** Run the global compile command; expected `errors: 0`.
- [ ] **Step 3: In-game round trip.**
  1. Run `backup-saves.sh` and `deploy.sh`.
  2. Load a save, wait 10 s, make a manual save, quit.
  3. Relaunch and load that save.
  4. `r6/logs/redscript_rCURRENT.log` (or `red4ext/logs`) must contain `KromProbe: read name=Krom Probe ... items=1`.
  5. If the name reads back empty, switch set names to `array<Int32>` codepoint storage in Task 2 (decision recorded in the Task 2 commit message).
- [ ] **Step 4: Commit.** `git add -A && git commit -m "chore: scaffold and persistence probe"`

### Task 2: Data model and storage system

**Files:**
- Create: `src/KromSetleri/Data.reds`
- Create: `src/KromSetleri/Storage.reds`

**Interfaces:**
- Produces (`Data.reds`):
  - `public struct KromSlotItem { let area: gamedataEquipmentArea; let slot: Int32; let item: ItemID; }`
  - `public class KromSet { public let name: String; public let items: array<KromSlotItem>; }`
- Produces (`Storage.reds`): `public class KromSetleriSystem extends ScriptableSystem` with:
  - `public static func Get(game: GameInstance) -> ref<KromSetleriSystem>`
  - `public func GetSets() -> array<ref<KromSet>>`
  - `public func SaveSet(index: Int32, name: String, items: array<KromSlotItem>) -> Bool`. `index == -1` appends; returns `false` when 10 sets already exist.
  - `public func RenameSet(index: Int32, name: String) -> Void`
  - `public func DeleteSet(index: Int32) -> Void`
  - `public static func MaxSets() -> Int32` returns `10`.
- Storage layout (persistent, flat; per Task 1 result):
  - `m_setNames: array<CName>`
  - `m_entrySet: array<Int32>`
  - `m_entryArea: array<gamedataEquipmentArea>`
  - `m_entrySlot: array<Int32>`
  - `m_entryItem: array<ItemID>`
  - Entries of set i are those with `m_entrySet[k] == i`. Delete re-indexes the higher sets.

- [ ] **Step 1: Write failing self-tests.** In `src/KromSetleri/SelfTest.reds`, add `public static func KromSelfTest_Storage(sys: ref<KromSetleriSystem>) -> Void`. It logs `PASS`/`FAIL <name>` via `ModLog(n"KromSetleri", ...)` and checks:
  - `Storage_SaveAppendsAndReadsBack`: save 2 items as "Netrunner"; `GetSets()` size 1, name "Netrunner", 2 items, same areas, slots and ItemIDs.
  - `Storage_MaxTenSets`: the 11th `SaveSet(-1, …)` returns `false`.
  - `Storage_DeleteReindexes`: with sets A, B, C, delete B; `GetSets()` names are A, C and C keeps its items.
  - `Storage_Rename`: rename index 0 to "Tank" and read it back.

  Tests run on a scratch instance created with `new KromSetleriSystem()`, never the live system. Call it from a temporary `@wrapMethod(PlayerPuppet) OnGameAttached()` guarded by `const KromDebug_SelfTest: Bool = true` in `SelfTest.reds`.
- [ ] **Step 2: Compile.** It must fail because `KromSetleriSystem` does not exist yet.
- [ ] **Step 3: Implement `Data.reds` and `Storage.reds`** per the interfaces above. `Get` uses `GameInstance.GetScriptableSystemsContainer(game).Get(n"KromSetleri.KromSetleriSystem")` with the module name `KromSetleri`.
- [ ] **Step 4: Compile, deploy, load a save.** The log must show 4 `PASS` lines and no `FAIL`.
- [ ] **Step 5: Commit.** `git commit -am "feat: persistent loadout storage"`

### Task 3: Loadout planner (pure logic)

**Files:**
- Create: `src/KromSetleri/Planner.reds`
- Modify: `src/KromSetleri/SelfTest.reds` (add planner tests)
- Delete: `src/KromSetleri/Probe.reds`

**Interfaces:**
- Consumes: `KromSlotItem` (Task 2).
- Produces:
  - `public struct KromOwnedItem { let item: ItemID; let quality: Int32; }`
  - `public class KromPlan { public let unequip: array<KromSlotItem>; public let equip: array<KromSlotItem>; public let missing: array<KromSlotItem>; }`
  - `public static func KromPlanLoadout(equipped: array<KromSlotItem>, target: array<KromSlotItem>, owned: array<KromOwnedItem>) -> ref<KromPlan>`
- Rules:
  - An `equipped` entry not in `target` (same area, slot and TweakDBID) goes to `unequip`.
  - Each `target` entry not already equipped is resolved against `owned`: first the exact `ItemID`, else the same `ItemID.GetTDBID` with the highest `quality`. Each owned item is used at most once.
  - Unresolved target entries go to `missing`.

- [ ] **Step 1: Write failing tests** in `KromSelfTest_Planner()`. Build ItemIDs with `ItemID.FromTDBID(t"Items.<record>")` using real cyberware records.
  - `Planner_EquippedMatchIsNoop`: equipped == target gives three empty arrays.
  - `Planner_UnequipsComeFirst`: switching the OS item gives unequip size 1 and equip size 1.
  - `Planner_PrefersExactItemThenSameRecord`: when the exact ItemID is owned it is picked; when only a different ItemID of the same TDBID is owned, the higher-quality one is picked.
  - `Planner_NoDoubleUseOfOneItem`: two target slots need the same TDBID but only one is owned, so equip size 1 and missing size 1.
  - `Planner_MissingWhenNotOwned`: an item that is not owned at all goes to missing.
- [ ] **Step 2: Compile.** It must fail because `KromPlanLoadout` is undefined.
- [ ] **Step 3: Implement `Planner.reds`** per the rules above.
- [ ] **Step 4: Compile, deploy, load a save.** The log shows all 5 planner `PASS` lines plus the 4 storage ones.
- [ ] **Step 5: Commit.** `git commit -am "feat: loadout planner"`

### Task 4: Reading the game state and applying a plan

**Files:**
- Create: `src/KromSetleri/Ripperdoc.reds`

**Interfaces:**
- Consumes: `KromSetleriSystem`, `KromPlanLoadout`, `KromPlan` (Tasks 2–3).
- Produces (`@addMethod(RipperDocGameController)`):
  - `KromIsRealRipperdoc() -> Bool` returns `Equals(this.m_screen, CyberwareScreenType.Ripperdoc)`.
  - `KromCurrentCyberware() -> array<KromSlotItem>`. Iterates `EquipmentSystem.GetData(this.m_player).GetAllCyberwareEquipmentAreas()` and `GetNumberOfSlots(area)`, using `GetItemInEquipSlot(area, slot)` and skipping invalid IDs.
  - `KromOwnedCyberware() -> array<KromOwnedItem>`. Player inventory items whose `RPGManager.GetItemRecord(id).EquipArea().Type()` is a cyberware area; quality from `RPGManager.GetItemDataQuality`.
  - `KromApplySet(index: Int32) -> ref<KromPlan>`. Calls `UnequipCyberware(data, null, true)` for each unequip, then `CheckIfCanEquip` and `EquipCyberware` for each equip. Item data comes from `GameInstance.GetTransactionSystem(game).GetItemData(this.m_player, id)`. An equip that is rejected moves to `plan.missing`. Ends with one UI refresh through the same path vanilla uses after equipping (`this.InitializeEquipmentMinigrids()` or the equivalent found while implementing; note which in the commit).
  - `KromSaveCurrent(index: Int32, name: String) -> Bool`

- [ ] **Step 1: Compile `Ripperdoc.reds`** with these methods and no UI. Expected `errors: 0`.
- [ ] **Step 2: Temporary in-game harness.** Add a `@wrapMethod(RipperDocGameController) OnInitialize()`, guarded by `KromDebug_SelfTest`. When the screen is a real ripperdoc it logs `KromCurrentCyberware()` as `area/slot/TDBID` lines and the owned count. merci opens a ripperdoc; the log lines must match the installed cyberware.
- [ ] **Step 3: Commit.** `git commit -am "feat: read and apply cyberware sets via ripperdoc logic"`

### Task 5: LOADOUTS button and menu

**Files:**
- Create: `src/KromSetleri/Popup.reds` (`public class KromSetleriPopup extends InMenuPopup`)
- Create: `src/KromSetleri/Text.reds` (Turkish strings as static funcs: `KromText.Title() -> String` and so on)
- Modify: `src/KromSetleri/Ripperdoc.reds` (button injection)

**Interfaces:**
- Consumes: `KromApplySet`, `KromSaveCurrent`, `KromSetleriSystem.GetSets/RenameSet/DeleteSet/MaxSets`.
- Produces (UI per spec draft D):
  - **Button:** a `SimpleButton` labelled `LOADOUTS`, added in a wrapped `RipperDocGameController.OnInitialize` only when `KromIsRealRipperdoc()`. Anchored top-right in the ripperdoc root widget next to the capacity readout. Clicking it shows `KromSetleriPopup`.
  - **Left column:** the set list, plus a final row "+ Şu anki kromları yeni set yap" (hidden when `MaxSets()` is reached).
  - **Right column:** the selected set's items as `<area label> · <item display name>`. Items not owned are coloured with `ThemeColors.Red()`-equivalent and suffixed "· envanterde yok".
  - **Footer actions:** Yükle (F), Üstüne kaydet (R), Adlandır (T, opens `HubTextInput`), Sil (DEL), Kapat (ESC).
  - **After Yükle:** a notification. If `missing` is empty it reads "<set adı> takıldı". Otherwise "<set adı> takıldı · N implant takılamadı: <names>".
  - **New set default name:** `"Set " + ToString(count + 1)`.

- [ ] **Step 1: Compile `Text.reds` and `Popup.reds`.** Expected `errors: 0`.
- [ ] **Step 2: Inject the button and compile.** Expected `errors: 0`.
- [ ] **Step 3: Deploy. merci runs the in-game checklist below; record pass/fail per item in the commit message.**
  1. The button appears at a ripperdoc, and does not appear at Hub → Cyberware or the Glamdoc.
  2. Save the current chrome as a new set, change one implant, load the set; the original is back and the summary says it was installed.
  3. Load a set whose total exceeds current capacity; the rest installs and the summary names the rejected ones.
  4. Sell an implant that belongs to a set, then open the menu; it shows red "envanterde yok". Loading reports it as missing.
  5. Rename and delete work. The 11th set is refused (the "+" row is hidden).
  6. Save, quit, relaunch, load; the sets are still there.
  7. Remove `r6/scripts/KromSetleri`, launch and load that save; the save loads without errors. Then redeploy.
- [ ] **Step 4: Commit.** `git commit -am "feat: LOADOUTS button and menu"`

### Task 6: Cleanup and handoff

**Files:**
- Modify: `src/KromSetleri/SelfTest.reds`. Set `KromDebug_SelfTest = false`; keep the tests for future runs.
- Modify: `Ripperdoc.reds`. Remove the temporary logging harness from Task 4.
- Create: `krom-setleri/README.md`. Covers what it does, install path, how to uninstall, and known limits.
- Modify: `C:\Users\merci\.claude\projects\C--Users-merci\memory\cyberpunk-2-5-mod-port.md`. Add a short pointer to the mod.

- [ ] **Step 1: Compile, deploy, launch to the main menu.** No `KromSetleri` log noise and `errors: 0`.
- [ ] **Step 2: Commit.** `git commit -am "chore: disable self-tests, add README"`
