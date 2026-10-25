# ChromeProfiler (Krom Setleri)

A redscript mod for Cyberpunk 2077 2.5 that saves your installed cyberware as named sets at a ripperdoc and puts a set back on with one click.

[Türkçe açıklama aşağıda.](#türkçe)

## What it does

- Adds a **LOADOUTS** button to the bottom right of the ripperdoc's cyberware screen. It appears only at a real ripperdoc, not under Hub → Cyberware or at the Glamdoc.
- From the menu you can:
  - save your current cyberware as a new set (up to 10 sets),
  - load a set,
  - overwrite, rename or delete a set.
- Loading only installs cyberware that is already in your inventory. It never creates items and never costs or pays money.
- Pieces are installed through the game's own ripperdoc logic, so capacity and perk requirements still apply.
- Anything that could not be installed (not in inventory, or not enough capacity) is listed in the status line at the bottom of the menu.
- Sets are stored in the save file; each save keeps its own sets.
- Text is in Turkish when the game's on-screen language is Turkish, and in English otherwise.

## Requirements

- Cyberpunk 2077 2.5
- [redscript](https://github.com/jac3km4/redscript) 0.5.x
- [Codeware](https://github.com/psiberx/cp2077-codeware) (a 2.5-compatible build)

## Install / uninstall

- Install: copy the `src/KromSetleri` folder to `<game>/r6/scripts/KromSetleri`. `deploy.sh` does this from this repo; run it with the game closed.
- Uninstall: delete `<game>/r6/scripts/KromSetleri`. Saves still load; only the sets are lost.

## Known limits

- The menu is mouse-only; no keyboard shortcuts or controller support.
- Perk and attribute sets are out of scope (use Rewire for those).

## Development notes

- **Tests:** set `KromDebug_SelfTest()` in `src/KromSetleri/SelfTest.reds` to `true` and the storage, planner and text tests run in the main menu. Results go to `bin/x64/plugins/cyber_engine_tweaks/gamelog.log` as `[KromSetleri] PASS/FAIL` lines.
- **Redscript 0.5 pitfall:** never use an array returned by a call directly, e.g. `ArraySize(x.GetSets())` or `x.GetSets()[0]`. Store it in a local first; otherwise freed memory is read and the game crashes.
- **`ItemID.FromTDBID`** generates a new random seed on every call.
- **Design and plan (Turkish):** `docs/`

---

## Türkçe

Cyberpunk 2077 (2.5) için ripperdoc'ta krom (siberyazılım) setlerini kaydedip tek tıkla geri takmayı sağlayan redscript modu.

### Ne yapar

- Ripperdoc'un Siber Donanım ekranında sağ altta bir **LOADOUTS** düğmesi açar. Sadece gerçek bir ripperdoc'ta görünür; Hub → Siber Donanım ve Glamdoc'ta görünmez.
- Menüde:
  - şu anki kromları yeni set olarak kaydetme (en fazla 10 set),
  - bir seti yükleme,
  - üstüne kaydetme, adlandırma ve silme.
- Yüklerken sadece envanterindeki implantları takar. Hiçbir eşyayı yoktan var etmez, para almaz ya da vermez.
- Takma işlemi oyunun kendi ripperdoc mantığıyla yapılır; kapasite ve perk şartları geçerlidir.
- Takılamayan implantlar (envanterde yok ya da kapasite yetmiyor) menünün altındaki durum satırında listelenir.
- Setler kayıt dosyasının içinde saklanır. Her kayıt kendi setlerini taşır.
- Oyunun ekran dili Türkçeyse metinler Türkçe, değilse İngilizce görünür.

### Gereksinimler

Cyberpunk 2077 2.5, redscript 0.5.x ve Codeware (2.5 uyumlu derleme).

### Kurulum ve kaldırma

- Kurulum: `src/KromSetleri` klasörünü oyunun `r6/scripts/KromSetleri` klasörüne kopyala. Bu repodan `deploy.sh` aynısını yapar; oyun kapalıyken çalıştır.
- Kaldırma: `r6/scripts/KromSetleri/` klasörünü sil. Kayıtlar açılmaya devam eder; sadece setler kaybolur.

### Bilinen sınırlar

- Menü fareyle kullanılır; klavye kısayolu ve kumanda desteği yok.
- Perk ve nitelik setleri bu modun işi değil; onlar için Rewire kullanılıyor.
