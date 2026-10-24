# Krom Setleri: tasarım

Tarih: 24 Ekim 2026 · Oyun: Cyberpunk 2077 2.5 (3.0.88.46235) · Kullanıcı: merci

## Amaç ve neden

merci tek bir kayıt dosyasında birden fazla build denemek istiyor (ör. netrunner, Sandevistan'lı yakın dövüş, tank). Perk ve nitelik setlerini Rewire (Nexus #35655) çözüyor. Kromlar için oyun içi menüsü olan bir mod bulunamadı; bu mod o boşluğu dolduruyor. merci CET menüsüyle uğraşmak istemiyor; her şey oyunun kendi arayüzünde olmalı.

Başarı: Ripperdoc'ta köşedeki LOADOUTS düğmesine basıp bir setten diğerine tek seçimle geçmek. Geçiş oyunun kurallarına uyar.

## Hedefler

- Ripperdoc ekranının köşesinde bir **LOADOUTS** düğmesi.
- Düğmeye basınca ripperdoc ekranının üstüne açılan bir menü:
  - solda kayıtlı setlerin listesi; en altta "şu anki kromları yeni set yap" satırı,
  - sağda seçili setin içindeki implantlar; envanterde bulunmayanlar kırmızı,
  - altta işlemler: Yükle, Üstüne kaydet, Adlandır, Sil, Kapat.
- **Yükle:**
  - Seçili setteki implantları envanterden takar ve sette olmayanları çıkarır.
  - Envanterde olmayan ya da takılamayan implantlar atlanır, gerisi takılır.
  - Sonunda kaç implantın takılamadığını ve hangileri olduğunu söyleyen bir bildirim çıkar.
- **Kaydet:** Şu an takılı olan implantların hepsini, yuvalarıyla birlikte sete yazar.
- Setler kayıt dosyasının içinde saklanır. Her kayıt kendi setlerini taşır.

## Hedef olmayanlar

- Perk ve nitelikler: Rewire'ın işi, karıştırılmayacak. Perk seti ile krom seti ayrı ayrı değişir (merci'nin kararı).
- Ripperdoc dışında set değiştirme: oyunun kuralına uygun olacak, sadece ripperdoc'ta (merci'nin kararı).
- Silah, kıyafet, quickhack setleri.
- Kayıtlar arası set paylaşımı.

## Kesinlikle olmaması gerekenler

- Hiçbir eşyayı yoktan var etmemeli, para vermemeli ya da almamalı. Sadece sahip olunan implantlar takılır. Vanilla'da sahip olunan implantı takmak ücretsiz olduğu için yükleme de ücretsiz.
- Oyunun kapasite ve perk şartlarını atlamamalı.
- Kayıt dosyasını bozmamalı. Mod kaldırılırsa kayıt sorunsuz açılmalı; sadece setler kaybolur.
- CET gerektirmemeli.

## Kısıtlar

- **Oyun sürümü:** 2.5. Bugünkü kurulumdaki çerçevelerle çalışmalı: redscript 0.5.32, Codeware (2.5 PR build), ArchiveXL, TweakXL, RED4ext 1.31.
- **Dil:** Redscript; arayüz için Codeware'in ink widget yardımcıları. Kendi DLL'i yok. 2.5'te native eklentiler riskli olduğu için bu tercih edildi (benim seçimim).
- **Takma mantığı:** Oyunun kendi takma mantığı kullanılmalı. 2.5'te `RipperDocGameController` üzerinde `EquipCyberware(itemData)`, `UnequipCyberware(itemData, opt itemToEquip, opt skipRefresh)` ve `CheckIfCanEquip(...)` var. Kapasite, perk şartları, ses ve kol modeli güncellemeleri bunlardan gelir.
- **Diğer modlar:** Mevcut modlarla çakışmamalı: LHUD, Dark Future, Mod Settings menü yaması, Equipment-EX. Ripperdoc ekranında `@replaceMethod` kullanılmayacak; yalnızca `@wrapMethod`, `@addMethod` ve `@addField`. Bu, bugünkü Mod Settings menü sorunundan çıkan ders.

## Kararlar (kimin olduğu yanında)

- LOADOUTS düğmesi + üstüne açılan menü yerleşimi: merci (taslak D).
- Perk/krom ayrı: merci.
- Sadece ripperdoc'ta: merci.
- Eksik implantı atla + bildirim; setler kayıtta saklanır; yükleme ücretsiz: Claude önerdi, merci onayladı.
- Arayüz metinleri Türkçe: Claude'un seçimi (oyun Türkçe oynanıyor).
- Set sayısı en fazla 10: Claude'un seçimi. Liste kaydırılabilir; 10 build denemek için yeterli.

## Kurucunun kararına kalanlar

- Düğmenin tam konumu ve görseli. Köşede, oyunun kendi düğme stilinde olmalı.
- Set adlandırma girişi: Codeware'in TextInput bileşeni ya da varsayılan isim ("Set 1"…) + yeniden adlandırma.
- **Yükleme sırası:**
  1. Önce sette olmayanları çıkar, sonra sette olanları tak; böylece kapasite boşalır.
  2. İşletim sistemi ve kollar gibi tekil yuvalar `UnequipCyberware(..., itemToEquip)` ile değiştirilebilir.
- **Kayıtta saklama biçimi:**
  - Seçenekler: `ScriptableSystem` üzerinde `persistent` alanlar ya da oyuncuya eklenen `persistent` alanlar.
  - Saklanacaklar: her set için ad ve (alan, yuva, ItemID) listesi.
  - Persistent alanların hangi tipleri desteklediği doğrulanmalı. ItemID dizisi desteklenmiyorsa TweakDBID + seed gibi ayrıştırılmış alanlar kullanılabilir.
- **Eşleştirme:** Aynı TweakDBID'li birden fazla kopya varsa önce aynı ItemID, yoksa aynı TweakDBID'li en yüksek kaliteli/seviyeli kopya.
- **Kontrolcü/klavye:** Menüde gezinme ve tuş atamaları oyunun ipucu çubuğu stiliyle uyumlu olmalı.

## Doğrulama

- Her değişiklikten sonra `cp2077-build/tools/offline-compile.sh` ile 2.5'e karşı 0 hata.
- **Oyun içi test, kayıt yedeği alındıktan sonra:**
  1. Set kaydet.
  2. Kromları değiştir.
  3. Seti yükle; kapasiteyi aşan bir seti yükle.
  4. Bir implantı sat ve o seti yükle.
  5. Kaydet, oyunu kapatıp aç, setlerin kalıcı olduğunu gör.
- Mod kaldırılıp kaydın açıldığı bir test.

## Kurulum yeri

- Kaynak: `C:\Users\merci\cp2077-build\krom-setleri\`.
- Oyuna kurulum: `r6\scripts\KromSetleri\`.
