# Krom Setleri

Cyberpunk 2077 (2.5) için ripperdoc'ta krom (siberyazılım) setlerini kaydedip tek tıkla geri takmayı sağlayan redscript modu.

## Ne yapar

- Ripperdoc'un Siber Donanım ekranında sağ altta bir **LOADOUTS** düğmesi açar. Sadece gerçek bir ripperdoc'ta görünür; Hub → Siber Donanım ve Glamdoc'ta görünmez.
- Menüde:
  - şu anki kromları yeni set olarak kaydetme (en fazla 10 set),
  - bir seti yükleme,
  - üstüne kaydetme, adlandırma ve silme.
- Yüklerken sadece envanterindeki implantları takar. Hiçbir eşyayı yoktan var etmez, para almaz ya da vermez.
- Takma işlemi oyunun kendi ripperdoc mantığıyla yapılır; kapasite ve perk şartları geçerlidir.
- Takılamayan implantlar (envanterde yok ya da kapasite yetmiyor) menünün altındaki durum satırında listelenir.
- Setler kayıt dosyasının içinde saklanır. Her kayıt kendi setlerini taşır.

## Gereksinimler

redscript 0.5.32 ve Codeware (2.5 uyumlu derleme).

## Kurulum ve kaldırma

- Kurulum: `deploy.sh`. `src/KromSetleri/*.reds` dosyalarını oyunun `r6/scripts/KromSetleri/` klasörüne kopyalar. Oyun kapalıyken çalıştır.
- Kaldırma: `r6/scripts/KromSetleri/` klasörünü sil. Kayıtlar açılmaya devam eder; sadece setler kaybolur.

## Bilinen sınırlar

- Menü fareyle kullanılır; klavye kısayolu ve kumanda desteği yok.
- Perk ve nitelik setleri bu modun işi değil; onlar için Rewire kullanılıyor.

## Geliştirme notları

- **Testler:** `src/KromSetleri/SelfTest.reds` içindeki `KromDebug_SelfTest()` `true` yapılırsa depolama ve planlayıcı testleri ana menüde çalışır. Sonuçlar `bin/x64/plugins/cyber_engine_tweaks/gamelog.log` dosyasına `[KromSetleri] PASS/FAIL` satırları olarak düşer.
- **Çevrimdışı derleme:** `EXTRA=<src/KromSetleri> bash ../tools/offline-compile.sh ArchiveXL Codeware TweakXL mod_settings`
- **Redscript 0.5 tuzağı:** Bir fonksiyonun döndürdüğü diziyi doğrudan kullanma, örneğin `ArraySize(x.GetSets())` ya da `x.GetSets()[0]`. Önce yerel bir değişkene ata; aksi halde silinmiş bellek okunur ve oyun çöker.
- **`ItemID.FromTDBID`:** Her çağrıda yeni bir rastgele tohum üretir.
- **Tasarım ve plan:** `docs/`
