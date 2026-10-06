---
name: batak-oyunu
description: Flutter/Dart ile Batak kart oyunu (Koz Maça, İhaleli, Eşli, Gömmeli) geliştirirken kural motoru, puanlama, bot ve test yazımı için kullan. Batak kurallarının tek doğru kaynağı budur.
---

# Batak Oyunu (Flutter)

Bu skill, mobil Batak oyununun **kurallarının tek doğru kaynağıdır**. Kural motoru, puanlama,
botlar ve testler yazılırken buradaki spesifikasyon esas alınır. İnternette gördüğün ya da
hatırladığın farklı ev kurallarını **kullanma**. Burada onaylanmış kurallar geçerlidir. Bir kural
belirsiz ya da eksikse tahmin etme, kullanıcıya sor ve bu dosyanın güncellenmesini öner.

## Varyantlar ve durum

| Varyant | Durum | Bölüm |
|---|---|---|
| Koz Maça (tekli) | ✅ Kurallar onaylandı (27.09.2026) | Bölüm A |
| İhaleli (tekli) | ⏳ Sırada | — |
| Eşli İhale | ⏳ | — |
| Gömmeli | ⏳ | — |

Bir varyant üzerinde çalışırken önce ortak bölümleri, sonra o varyantın bölümünü **baştan sona oku**.

## Mimari ilkeler

1. **Kural motoru saf Dart olur.** Flutter'a, UI'a ya da `BuildContext`'e bağımlı olmaz. `lib/engine/`
   altında durur ve `dart test` ile UI olmadan test edilir.
2. **Durum değişmezdir (immutable).** Her hamle yeni bir `GameState` üretir. Böylece botlar olası
   hamleleri denerken asıl durumu bozmaz, tekrar oynatma (replay) ve geri alma da kolaylaşır.
3. **Tek kapı `legalActions(state)`'tir.** Bu fonksiyon içeride varyantın `legalMoves` kuralını
   kullanır (Koz Maça için A4). UI hangi kartların tıklanabilir olduğunu, bot hangi kartlardan
   seçeceğini, `apply` da hangi hamlenin geçerli olduğunu **aynı kaynaktan** öğrenir. Kural mantığı
   başka bir yerde tekrar yazılmaz.
4. **Varyant farkları konfigürasyonla yönetilir.** Ortak akış (dağıt → tahmin/ihale → 13 el →
   puanla) tek yerde yazılır. Varyanta özgü kısımlar (kozun nasıl belirlendiği, tahmin kuralları,
   puanlama) bir `VariantRules` arayüzünün arkasında durur. Koz Maça bu arayüzün ilk uygulamasıdır.
5. **Rastgelelik dışarıdan verilir.** Karıştırma fonksiyonu bir `Random` parametresi alır. Testlerde
   sabit seed kullanılır, böylece eller tekrarlanabilir.
6. **Her kural bir teste karşılık gelir.** Test senaryoları birebir unit test olarak yazılır. Bir
   kural değişirse sıra şöyledir: önce bu skill, sonra testler, en son kod.

## Ortak terimler

| Terim | Anlamı | Kodda |
|---|---|---|
| Tür / renk | Maça ♠, Kupa ♥, Karo ♦, Sinek ♣ | `Suit.spades/hearts/diamonds/clubs` |
| Koz | Diğer türleri yenen tür | `trump` |
| El (tur) | 4 kağıdın atılıp birinin topladığı tur | `Trick` |
| Oyun eli | 13 elin tamamı, yani bir dağıtım | `Round` |
| Oyun | Birden fazla oyun eli; sonunda kazanan belli olur | `Game` |
| Tahmin | Oyuncunun o dağıtımda kaç el alacağı sözü | `bid` |
| Koz kırılması | O dağıtımda ilk kez maça atılması | `spadesBroken` |
| Yan batar | Tahmin kaç el aşılırsa batılacağı | `yan` |
| Batmak | Tahmini tutturamayıp eksi puan almak | — |

Kağıt sırası (küçükten büyüğe): 2, 3, 4, 5, 6, 7, 8, 9, 10, Vale (J), Kız (Q), Papaz (K), As (A).
Kodda `rank` değeri 2–14 arasında tutulur (J=11, Q=12, K=13, A=14).

## Masa düzeni ve yön

Türkiye usulünde oyun **saat yönünün tersine** (sağa doğru) oynanır. Koltuklar:

```
          2 (üst)
3 (sol)            1 (sağ)
          0 (insan, alt)
```

`next(seat) = (seat + 1) % 4` saat yönünün tersini verir: 0 → 1 → 2 → 3 → 0.

## Proje yapısı (Flutter)

Aşağıdaki kararlar 27.09.2026'da onaylandı.

| Konu | Karar |
|---|---|
| Durum yönetimi | `flutter_riverpod`, `Notifier` |
| Modeller | El yazımı immutable sınıflar ve Dart 3 `sealed` sınıflar. `freezed` ve `build_runner` **yok** |
| Kayıt | Yarım kalan oyun, seed ve aksiyon listesi olarak JSON halinde `shared_preferences`'a yazılır |
| Ayarlar | `shared_preferences` |
| Ekran | Sadece dikey (portrait) |
| Dil | Türkçe. Tüm metinler `lib/ui/strings.dart`'ta durur, widget içine metin gömülmez |

### Klasör düzeni

```
lib/
  engine/                  ← saf Dart; package:flutter import'u YASAK
    models/                (card.dart, suit.dart, trick.dart, game_state.dart, player_view.dart, action.dart)
    rules/                 (variant_rules.dart, engine.dart)
    variants/koz_maca/     (koz_maca_rules.dart: legalMoves, trickWinner, scoreRound)
    save/                  (JSON serileştirme)
  bots/                    (bot.dart, easy_bot.dart, medium_bot.dart, hard_bot.dart, knowledge.dart)
  game/                    (game_controller.dart: Riverpod Notifier, tempo, kayıt)
  ui/                      (screens/, widgets/, strings.dart)
test/
  engine/                  (skill'deki A10 senaryoları)
  bots/                    (skill'deki BT senaryoları)
  invariants_test.dart     (seed'li rastgele oyunlarla değişmezler)
tool/
  simulate.dart            (bot ayarı için komut satırı simülasyonu)
```

### Motor API'si

Motor, aksiyon uygulayan saf bir fonksiyondur. Zamanlama, gecikme ve animasyon bilgisi içermez.

```dart
sealed class Action {}
final class Bid extends Action { final int seat; final int value; }
final class PlayCard extends Action { final int seat; final Card card; }
final class NextRound extends Action {}   // puan tablosu gösterildikten sonra yeni dağıtım

enum Phase { bidding, playing, roundOver, gameOver }

GameState newGame(GameConfig config, int seed);
GameState apply(GameState s, Action a);   // geçersizse IllegalActionException fırlatır
List<Action> legalActions(GameState s);   // sıradaki oyuncu için
PlayerView viewFor(GameState s, int seat);
```

Kurallar:
- **Determinizm:** Aynı `config`, `seed` ve aksiyon listesi her zaman aynı `GameState`'i üretir.
  Motor `DateTime`, global `Random()` ya da başka bir dış durum kullanmaz.
- **Dağıtım:** `r` numaralı oyun elinin (0'dan başlar) destesi `Random(seed + r)` ile karıştırılır.
  İlk dağıtıcı `Random(seed).nextInt(4)` ile seçilir.
- **El bitişi:** 4. kağıt atılınca el hemen sonuçlanır ve `GameState.lastTrick`'e yazılır. Masadaki
  4 kağıdı gösterme ve toplama animasyonu UI'ın işidir, motor beklemez.
- **Oyun eli bitişi:** 13. el bitince puanlar eklenir ve durum `roundOver` olur. `NextRound`
  aksiyonu yeni dağıtımı yapar. Son oyun elinden sonra durum `gameOver` olur.

### Kayıt formatı

```json
{ "v": 1, "config": { "variant": "kozMaca", "yan": 2, "roundCount": 11, "botLevel": "medium" },
  "seed": 123456, "actions": [["B",1,3], ["P",1,"H10"], ["N"]] }
```

- Kağıt kodu tür harfi ve değerden oluşur: `S`=♠, `H`=♥, `D`=♦, `C`=♣; değerler `2`–`10`, `J`, `Q`,
  `K`, `A`. Örnek: `SA`, `H10`.
- Her aksiyondan sonra kayıt güncellenir. Açılışta kayıt varsa aksiyonlar baştan oynatılarak durum
  kurulur.
- `v` uyuşmazsa ya da oynatma sırasında `IllegalActionException` alınırsa kayıt silinir ve oyun
  sıfırdan başlar. Uygulama bu durumda çökmez.

### GameController (Riverpod)

- Motor ile UI arasındaki tek köprüdür. `GameState`'i tutar, aksiyonu `apply` eder ve kaydeder.
- İnsan (koltuk 0) aksiyonu sadece sıra ondayken ve aksiyon `legalActions` içindeyse kabul edilir.
  Çift dokunma gibi durumlar böyle engellenir.
- Sıra bir bottaysa bot kararını alır, tempo gecikmesini bekler, sonra `apply` eder.
- Zor botun hesabı `Isolate.run` ile arka planda yapılır, UI donmaz. Hesap tempo süresinden kısa
  sürerse kalan süre beklenir.
- Uygulama arka plana alındığında bekleyen bot zamanlayıcıları iptal edilir, geri dönülünce devam edilir.

### Tempo

| Ayar | Bot kağıt atışı | El toplandıktan sonra bekleme |
|---|---|---|
| Yavaş | 1200 ms | 1500 ms |
| Normal (varsayılan) | 700 ms | 1000 ms |
| Hızlı | 300 ms | 500 ms |

## Botlar

Aşağıdaki kararlar 27.09.2026'da onaylandı. İlk sürüm **Kolay** ve **Orta** botlarla çıkar, **Zor**
sonra eklenir. Algoritmalar koz türünü `trump` olarak kullanır. Koz Maça'da `trump = ♠`.

### Arayüz ve bilgi sınırı (hile yok)

```dart
abstract interface class Bot {
  int chooseBid(PlayerView v);
  Card chooseCard(PlayerView v);   // dönüş değeri daima v.legalCards içinden
}
```

`PlayerView` sadece şunları içerir: `seat`, `hand`, `legalCards`, `currentTrick` (kim neyi attı),
`completedTricks` (bu oyun elinde oynanmış tüm eller, sırasıyla ve kimin attığıyla), `bids`
(henüz söylenmemiş olan `null`), `tricksTaken`, `dealer`, `trump`, `spadesBroken`, `scores`,
`roundIndex`, `config`.

**Başka oyuncuların eli `PlayerView`'da yoktur ve olamaz.** Bot `GameState`'e hiçbir yoldan erişemez.
Botlar rastgeleliği kurucuda aldıkları `Random`'dan alır. Testlerde bu `Random` seed'lidir.

### Ortak yardımcılar

- **Şu anki kazanan:** Masadaki kağıtlar arasında A5'e göre eli alan kağıt.
- **Kazanır mı:** Bir kağıt masaya eklendiğinde, o an için eli alan kağıt o mu olur?
- **Mod:** `taken >= bid` ise ya da `bid == 0` ise **ALMA** (el almamaya çalış), aksi halde **AL**.

### Kolay bot

- **Tahmin:** `(As sayısı) + max(0, maça sayısı − 3)`, sonuç 1–13 aralığına sıkıştırılır.
  Kolay bot sıfır tahmini söylemez.
- **Oyun:** `legalCards` içinden rastgele bir kağıt atar.

### Orta bot: tahmin

```
puan = 0
Maça:  A, K, Q her biri +1        (maçaOnur = bunların sayısı)
       maça sayısı 3'ü aşıyorsa, 3'ten fazla her maça için +1
Diğer türler:
       A varsa +1
       K varsa ve o türde en az 2 kağıt varsa +0.5
Kesme: kesmeBonus = her diğer tür için: 0 kağıt → +1, 1 kağıt → +0.5
       kesmeTavanı = max(0, min(maça sayısı, 3) − maçaOnur)
       puan += min(kesmeBonus, kesmeTavanı)

Sıfır koşulu: hiçbir türde A ya da K yok, en fazla 2 maça var ve hepsi ≤ 9,
              diğer üç türün her birinde ≤ 6 olan en az bir kağıt var
Tahmin = sıfır koşulu sağlanıyorsa 0, aksi halde max(1, floor(puan)); üst sınır 13
```

`floor` bilinçli bir temkin payıdır. Yan batar yüzünden fazla almak, eksik almaktan daha tehlikelidir.

### Orta bot: oyun

**El açarken (masa boş):**
- Geçerli kağıtların hepsi koz ise: AL modunda en büyüğü, ALMA modunda en küçüğü atar.
- **AL:** Koz olmayan bir As varsa onu atar. Yoksa koz olmayan en uzun türün en küçüğünü atar
  (eşitlikte küçük kağıdı daha küçük olan tür seçilir).
- **ALMA:** Koz olmayan kağıtlar içinden en küçüğünü atar.

**Takip ederken (masa dolu):**
- Geçerli kağıtlar kazananlar ve kaybedenler olarak ikiye ayrılır.
- **AL:**
  - Kazanan kağıt yoksa geçerli kağıtların en küçüğünü atar ("el zaten başkasında").
  - Sırada son oyuncuysa (4. kağıt) kazananların en küçüğünü atar.
  - Değilse: koz ile kesiyorsa (açılan tür koz değil ama attığı koz) kazanan kozların en küçüğünü
    atar. Aynı türle büyütüyorsa kazananların en büyüğünü atar.
- **ALMA:**
  - Kaybeden kağıt varsa kaybedenlerin **en büyüğünü** atar (güvenliyken büyük kağıttan kurtulur).
  - Hepsi kazanıyorsa en büyüğünü atar (almak zorundaysa en azından büyük kağıdı elden çıkarır).
- **Başka tür atarken** (ne açılan tür ne koz var): AL modunda en küçüğünü, ALMA modunda en büyüğünü atar.

Eşitlik durumunda (aynı değer, farklı tür) sıra ♣ < ♦ < ♥ < ♠ olur, deterministik kalsın.

### Zor bot (sonraki sürüm)

**Bilgi takibi (`knowledge.dart`).** Bot oynanan her kağıttan şu kısıtları çıkarır:
1. **Oynanan kağıtlar** artık kimsenin elinde değildir.
2. **Renk yokluğu:** X oyuncusu açılan tür S'ye uymadıysa, X'te S kalmamıştır.
3. **Koz yokluğu:** X ne açılan türü ne koz attıysa, X'te koz da kalmamıştır (koz zorunluluğu, A4.2).
4. **Üst sınır (büyütme kuralı):** X açılan türden masadaki en büyükten küçük bir kağıt attıysa,
   X'te o türden o anki en büyükten büyük kağıt yoktur. Kozla keserken masadaki kozdan küçük koz
   attıysa, X'te o kozdan büyük koz yoktur.
5. **Kozla açma:** Koz kırılmamışken X koz dışı bir kağıtla açtıysa bundan bilgi çıkmaz. Ama X
   koz kırılmamışken kozla açtıysa, X'in elinde sadece koz vardır.

Kural 4, Batak'a özgü ve çok değerli bir bilgidir. Spades/Hearts botlarında bulunmaz.

**Karar (determinizasyon ve Monte Carlo):**
1. Bilinmeyen kağıtları diğer 3 oyuncuya, el sayıları tutacak ve yukarıdaki kısıtlara uyacak
   şekilde rastgele dağıtan `N` örnek üretilir (varsayılan `N = 100`). Dağıtım yöntemi: kağıtlar en
   az yere gidebilenden başlayarak sıralanır, her kağıt yeri olan uygun oyunculardan birine rastgele
   verilir. Çıkmaza girilirse baştan başlanır (en çok 50 deneme). Olmazsa üst sınır kısıtları
   gevşetilir, renk yokluğu kısıtları korunur.
2. Her geçerli kağıt için her örnekte o kağıt atılır, oyun elinin geri kalanı **dört koltuk için de
   Orta politikayla** oynatılır ve botun kendi `scoreRound` puanı (A6) hesaplanır.
3. Ortalama puanı en yüksek kağıt seçilir. Eşitlikte küçük kağıt seçilir.
4. Denk kağıtlar (aynı türde, aradaki değerlerin hepsi oynanmış ya da botun elinde olan kağıtlar)
   tek aday sayılır.

**Tahmin:** Orta tahmini `e` bulunur. `b ∈ [max(0, e−2), min(13, e+2)]` adaylarının her biri için
50 rastgele dağıtımda botun tahmini `b` alınarak oyun elinin tamamı Orta politikayla oynatılır.
Ortalama `scoreRound` puanı en yüksek `b` seçilir.

**Performans:** Hesap `Isolate.run` içinde yapılır. Orta seviye bir telefonda karar başına en fazla
1 sn sürmelidir. Aşarsa `N` düşürülür.

### Bot test senaryoları (BT)

Mod sütunu botun o anki modunu gösterir. Test kurulumunda `bid` ve `taken` buna göre verilir.

**Tahmin:**

| # | Bot | El | Beklenen |
|---|---|---|---|
| BT1 | Orta | ♠A ♠K ♠Q ♠7 ♠3 · ♥A ♥5 · ♦K ♦9 ♦4 · ♣8 ♣6 ♣2 | 6 |
| BT2 | Orta | ♠8 ♠4 · ♥Q ♥J ♥5 ♥3 · ♦Q ♦10 ♦6 ♦2 · ♣J ♣9 ♣4 | 0 |
| BT3 | Orta | ♠9 ♠5 ♠2 · ♥Q ♥8 ♥7 ♥4 ♥3 · ♦J ♦6 ♦3 ♦2 · ♣5 | 1 |
| BT4 | Kolay | BT1 eli | 4 |

**Oyun (Orta):**

| # | Mod | spadesBroken | Masa | El | Beklenen |
|---|---|---|---|---|---|
| BT5 | AL | false | — | ♥A ♣3 ♣7 ♠5 | ♥A |
| BT6 | ALMA | false | — | ♥A ♣3 ♣7 ♠5 | ♣3 |
| BT7 | AL | true | ♦5 ♦K ♠3 (4. sıradasın) | ♠4 ♠10 ♠A ♣2 | ♠4 |
| BT8 | ALMA | true | ♦5 ♦K ♠3 (4. sıradasın) | ♠4 ♠10 ♠A ♣2 | ♠A |
| BT9 | ALMA | true | ♦8 ♠6 | ♠3 ♠4 ♣K | ♠4 |
| BT10 | ALMA | false | ♥5 | ♣A ♦2 ♦9 | ♣A |
| BT11 | AL | false | ♥5 | ♣A ♦2 ♦9 | ♦2 |
| BT12 | AL | true | ♥5 ♥J | ♥2 ♥7 ♣K | ♥2 |

### Simülasyon ve ayar (`tool/simulate.dart`)

- Saf Dart komut satırı aracıdır: `dart run tool/simulate.dart --rounds 10000 --bots medium,medium,easy,easy --seed 1`
- Her bot için şunları raporlar: ortalama oyun eli puanı, tutturma %, eksik alma %, yandan batma %,
  sıfır tahmini sayısı ve başarı %.
- Her aksiyondan sonra değişmezleri kontrol eder (bkz. aşağısı). Aynı araç bir fuzz testi işlevi de görür.
- Tahmin sezgisindeki sayılar (0.5 değerleri, kesme tavanı, sıfır koşulu) bu raporlara bakılarak
  ayarlanır. Değişiklik yapılırsa önce bu skill güncellenir.
- Kabul ölçütü: 10.000 elde **Orta'nın ortalama puanı Kolay'dan açıkça yüksek** olmalı. Koltuk
  pozisyonu değiştirildiğinde sonuç tersine dönmemeli.

### Değişmezler (`invariants_test.dart`)

1.000 seed'li rastgele oyun (botlar Kolay) oynatılır. Her adımda şu koşullar sağlanmalıdır:
- I1. Botun seçtiği aksiyon her zaman `legalActions` içindedir ve `apply` hata fırlatmaz.
- I2. Eldeki, masadaki ve oynanmış kağıtların birleşimi tam olarak 52 farklı kağıttır.
- I3. Her oyun elinin sonunda `tricksTaken` toplamı 13'tür.
- I4. Aynı seed ve aynı aksiyon listesi, JSON'a yazılıp geri okunduktan sonra aynı `GameState`'i verir.

---

# Bölüm A — Koz Maça

Kaynak olarak cikcik.com'daki Batak kuralları esas alındı. Kaynaktan bilinçli olarak ayrılan
noktalar A9'da listeleniyor.

## A1. Genel

- 4 oyuncu, **tekli** (herkes kendi adına), 52 kağıt, joker yok.
- Her oyuncuya 13 kağıt dağıtılır.
- **Koz her zaman maçadır (♠)** ve dağıtımdan dağıtıma değişmez.
- İhale yarışı yoktur. Herkes kendi tahminini söyler.

## A2. Oyun akışı

```
Oyun başı:  ilk dağıtıcı rastgele seçilir, tüm puanlar 0
Her oyun eli:
  1. Karıştır ve dağıt (her oyuncuya 13)
  2. Tahmin turu (A3)
  3. 13 el oyna (A4, A5)
  4. Puanla (A6), toplam puanlara ekle
  5. dealer = next(dealer)
Oyun sonu: ayarlanan oyun eli sayısı tamamlanınca (A7)
```

## A3. Tahmin

- Dağıtıcının sağındaki oyuncu (`next(dealer)`) başlar. Saat yönünün tersine herkes **bir kez**
  tahmin söyler, dağıtıcı en son söyler.
- Geçerli tahmin **0–13** arası bir tam sayıdır. 0, "el almam" demektir.
- Başka bir kısıt yoktur. Tahminlerin toplamı 13'e eşit olabilir, altında ya da üstünde kalabilir.
- Tahminler **herkese açıktır**. UI'da gösterilir, botlar da bu bilgiyi kullanabilir.

## A4. Kağıt atma kuralları (`legalMoves`)

Tanımlar:
- `hand`: oyuncunun elindeki kağıtlar
- `table`: o elde (turda) şimdiye kadar atılmış kağıtlar, atılma sırasıyla
- `led`: table'daki ilk kağıdın türü
- `spadesBroken`: bu oyun elinde herhangi bir turda maça atılıp atılmadığı (açarak ya da keserek)

### A4.1 El açma (table boş)

- `spadesBroken == false` ve elinde maça dışında kağıt varsa → **maça hariç** her kağıt.
- `spadesBroken == false` ve elinde **sadece maça** varsa → her kağıt (maça açılır, koz kırılır).
- `spadesBroken == true` → her kağıt.

Not: Her oyun elinin başında `spadesBroken = false` olduğu için, ilk turda maça açma yasağı bu
kuralın doğal bir sonucudur. Bunun için ayrı bir kural yazma.

### A4.2 Takip etme (table dolu)

Sırayla bakılır, ilk uyan kural geçerlidir:

1. **Elinde `led` türünden kağıt varsa** o türden atmak zorundasın:
   - **El kozla kesilmişse** (table'da maça var ve `led` maça değil) → `led` türünden
     **herhangi biri**. Yükseltme zorunluluğu yoktur: el artık kozdadır, o türden hiçbir kağıt
     eli alamaz, dolayısıyla büyütmenin bir anlamı kalmaz.
   - **Kesilmemişse:** `led` türünden, table'daki o türün en büyüğünden **daha büyük** kağıtların
     varsa → sadece onlar. Yoksa → `led` türünden herhangi biri.

   > 28.09.2026'da düzeltildi. Önceden "el kozla kesilmiş olsa bile yükseltme zorunludur"
   > yazıyordu; bu yanlıştı ve oyuncuyu kesilmiş elde boşuna büyük kağıt harcamaya zorluyordu.
2. **`led` türünden kağıdın yoksa ama maçan varsa** maça atmak zorundasın:
   - Table'da maça varsa ve ondan **büyük** maçan varsa → sadece o büyük maçalar (üstten kesmek zorunlu).
   - Aksi halde → herhangi bir maça.
3. **Ne `led` türünden ne de maçadan kağıdın varsa** → her kağıt.

`led == ♠` olduğunda kural 1 maça için çalışır, kural 2 hiç devreye girmez. Maça açılmış bir elde
"kesilme" diye bir şey olmadığı için **yükseltme zorunluluğu sürer**: elinde masadaki en büyük
maçayı geçen bir maça varsa onu atmak zorundasın.

Kural 2'deki üstten kesme zorunluluğu bu değişiklikten etkilenmez: renk yokken koz atıyorsan ve
masadaki kozu geçebiliyorsan yine geçmek zorundasın (A9.2).

### A4.3 Referans uygulama

```dart
import 'dart:math';

List<Card> legalMoves(List<Card> hand, List<Card> table, bool spadesBroken) {
  if (table.isEmpty) {
    final nonSpades = hand.where((c) => c.suit != Suit.spades).toList();
    if (!spadesBroken && nonSpades.isNotEmpty) return nonSpades;
    return List.of(hand);
  }

  final led = table.first.suit;
  final sameSuit = hand.where((c) => c.suit == led).toList();
  if (sameSuit.isNotEmpty) {
    // El kozla kesildiyse yükseltme zorunluluğu kalkar.
    final trumped =
        led != Suit.spades && table.any((c) => c.suit == Suit.spades);
    if (trumped) return sameSuit;

    final topLed = table.where((c) => c.suit == led).map((c) => c.rank).reduce(max);
    final higher = sameSuit.where((c) => c.rank > topLed).toList();
    return higher.isNotEmpty ? higher : sameSuit;
  }

  final spades = hand.where((c) => c.suit == Suit.spades).toList();
  if (spades.isNotEmpty) {
    final tableSpades = table.where((c) => c.suit == Suit.spades);
    if (tableSpades.isNotEmpty) {
      final topSpade = tableSpades.map((c) => c.rank).reduce(max);
      final higher = spades.where((c) => c.rank > topSpade).toList();
      if (higher.isNotEmpty) return higher;
    }
    return spades;
  }

  return List.of(hand);
}
```

## A5. Eli kim alır

- Table'da maça varsa **en büyük maçayı** atan alır.
- Maça yoksa `led` türünün **en büyüğünü** atan alır. Başka türden atılan kağıtların hiçbir değeri yoktur.
- Eli alan oyuncu bir sonraki eli açar.
- Oyun elinin ilk elini **dağıtıcının sağındaki** oyuncu (`next(dealer)`) açar.
- Herhangi bir elde maça atıldığında `spadesBroken = true` olur ve oyun elinin sonuna kadar öyle kalır.

## A6. Puanlama

Parametreler: `b` = tahmin, `t` = alınan el sayısı, `Y` = yan batar değeri (masa ayarı: 1, 2 ya da 3;
**varsayılan 2**).

| Durum | Puan |
|---|---|
| `b == 0` ve `t == 0` | **+50** |
| `b == 0` ve `t > 0` | **−50** |
| `t < b` (eksik aldı) | **−10·b** |
| `t == b` (tutturdu) | **+10·b** |
| `t > b` ve `t − b >= Y` (yandan battı) | **−10·t** |
| `t > b` ve `t − b < Y` (fazla aldı, batmadı) | **+10·b + (Y − 1)** |

```dart
int scoreRound({required int bid, required int taken, required int yan}) {
  if (bid == 0) return taken == 0 ? 50 : -50;
  if (taken < bid) return -10 * bid;
  if (taken == bid) return 10 * bid;
  if (taken - bid >= yan) return -10 * taken;
  return 10 * bid + (yan - 1);
}
```

Notlar:
- `Y = 1` iken tahminden fazla almak her zaman batırır.
- Fazla alıp batmayan oyuncunun bonusu, kaç fazla aldığına değil `Y`'ye bağlıdır. Kaynakta böyle
  olduğu için bilerek bu şekilde bırakıldı (örneğin Y=3 iken 7 deyip 8 ya da 9 alan +72 alır).

## A7. Oyun sonu

- Masa ayarı olarak oyun eli sayısı **5, 7, 11, 15 ya da 21** seçilebilir. **Varsayılan 11'dir.**
- Son oyun eli puanlanınca toplam puanı en yüksek olan oyuncu kazanır.
- Eşitlik olursa eşit puanlı oyuncuların hepsi birinci ilan edilir.

## A8. Masa ayarları özeti

| Ayar | Değerler | Varsayılan |
|---|---|---|
| `yan` | 1, 2, 3 | 2 |
| `roundCount` | 5, 7, 11, 15, 21 | 11 |

## A9. Kaynaktan bilinçli sapmalar

1. **Maça açma:** Kaynakta yasak sadece ilk tur için geçerli. Bizde koz kırılana kadar geçerli.
2. **Üstten kesme zorunluluğu:** Kaynakta renk yokken yerde koz varsa herhangi bir koz atılabiliyor.
   Bizde yerdeki kozu geçebiliyorsan geçmek zorundasın.

## A10. Test senaryoları

Kağıt gösterimi: `♠A`, `♥10`, `♣7`. Bu senaryolar birebir unit test olarak yazılmalıdır.

### A10.1 legalMoves

| # | spadesBroken | Table | El | Beklenen geçerli kağıtlar |
|---|---|---|---|---|
| L1 | false | — | ♠A ♠5 ♥3 | ♥3 |
| L2 | false | — | ♠A ♠5 | ♠A ♠5 |
| L3 | true | — | ♠A ♥3 | ♠A ♥3 |
| L4 | false | ♣6 | ♣3 ♣7 ♣8 ♥K | ♣7 ♣8 |
| L5 | false | ♣6 ♣8 | ♣2 ♣4 ♠K | ♣2 ♣4 |
| L6 | true | ♥7 ♠4 ♥9 | ♥6 ♥10 ♠5 | ♥6 ♥10 |
| L7 | true | ♦8 ♠4 ♦10 | ♠2 ♠6 ♣K | ♠6 |
| L8 | true | ♦8 ♠9 | ♠2 ♠6 ♣K | ♠2 ♠6 |
| L9 | false | ♦8 | ♣K ♥2 | ♣K ♥2 |
| L10 | true | ♠5 | ♠3 ♠J ♥A | ♠J |
| L11 | true | ♠Q | ♠3 ♠J ♥A | ♠3 ♠J |
| L12 | false | ♦8 | ♠2 ♣K | ♠2 |
| L13 | true | ♦8 ♠2 | ♦3 ♦A ♣K | ♦3 ♦A |
| L14 | false | ♦8 ♦10 | ♦3 ♦A ♣K | ♦A |
| L15 | true | ♠5 ♠9 | ♠3 ♠J ♥A | ♠J |

L6 ve L13 kesilmiş eli gösterir: renge uymak zorunlu, yükseltmek değil. L14 kesilmemiş elde
yükseltmenin sürdüğünü, L15 ise maça açıldığında (kesilme olamayacağı için) yine sürdüğünü
gösterir.

### A10.2 Eli kim alır

| # | Atılma sırası (koltuk 0→1→2→3) | Kazanan |
|---|---|---|
| W1 | ♥7 ♠4 ♥A ♠9 | koltuk 3 (♠9) |
| W2 | ♣6 ♣8 ♥A ♣2 | koltuk 1 (♣8) |
| W3 | ♠2 ♥A ♦A ♣A | koltuk 0 (♠2) |
| W4 | ♦5 ♦K ♠3 ♦A | koltuk 2 (♠3) |

### A10.3 spadesBroken

| # | Senaryo | Beklenen |
|---|---|---|
| S1 | Yeni oyun elinin başı | false |
| S2 | L12'deki hamlede ♠2 atıldı | true |
| S3 | Elinde sadece maça olan oyuncu maça ile el açtı | true |
| S4 | Yeni oyun eli dağıtıldı (önceki elde true idi) | false |

### A10.4 Puanlama

| # | Y | b | t | Puan |
|---|---|---|---|---|
| P1 | 2 | 0 | 0 | +50 |
| P2 | 2 | 0 | 1 | −50 |
| P3 | 2 | 5 | 5 | +50 |
| P4 | 2 | 7 | 6 | −70 |
| P5 | 2 | 9 | 7 | −90 |
| P6 | 2 | 7 | 8 | +71 |
| P7 | 2 | 7 | 9 | −90 |
| P8 | 2 | 13 | 13 | +130 |
| P9 | 2 | 1 | 0 | −10 |
| P10 | 1 | 7 | 8 | −80 |
| P11 | 3 | 7 | 8 | +72 |
| P12 | 3 | 7 | 9 | +72 |
| P13 | 3 | 7 | 10 | −100 |

### A10.5 Akış

| # | Senaryo | Beklenen |
|---|---|---|
| F1 | dealer = 2 | Tahmin sırası 3, 0, 1, 2; ilk eli 3 açar |
| F2 | Oyun eli bitti, dealer = 3 | Yeni dealer = 0 |
| F3 | Dağıtımdan sonra | Her oyuncuda 13 kağıt var, 52 kağıdın hepsi farklı |
| F4 | 13 elden sonra | Alınan ellerin toplamı = 13 |



---

# Bölüm D — Desteler ve masalar

28.09.2026'da onaylandı. Bu bölüm yalnızca görünümü anlatır; kural motoru
destelerden habersizdir ve onlara hiçbir yerde bağlı değildir.

## D1. Deste nedir

Bir **deste** (`DeckTheme`), 52 kağıdın görüntüsü ve ona eşlik eden masadır.
İkisi birlikte seçilir: deste değişince masa da değişir.

| Kod | Ad | Kaynak |
|---|---|---|
| `klasik` | Klasik | Uygulamanın içinde çizilir, görsel dosya kullanmaz |
| `osmanli` | Osmanlı | `assets/decks/osmanli/` + `assets/boards/osmanli.webp` |
| `sehir` | Şehir Muhafızları | `assets/decks/sehir/` |
| `ejder` | Ejder Diyarı | `assets/decks/ejder/` |

Dosya adları **kağıt koduyla birebir aynıdır** (A bölümündeki kayıt formatı):
`SA.webp`, `H10.webp`, `DK.webp`… Arka yüz `back.webp`. Bu yüzden yol koddan
doğrudan üretilir, eşleme tablosu tutulmaz:

```dart
String cardAsset(PlayingCard card) => 'assets/decks/${id.name}/${card.code}.webp';
```

Ölçüler: çizilen deste 64×92, görsel desteler 500×700 (5:7). Kart oranı
`DeckTheme.aspect`'ten okunur; yerleşim hesapları (yelpaze, masa, künye) bu
değeri kullanır, sabit bir orana güvenmez.

Görseller `assets/` altında durur; vektör asılları ve üretici betikler
`tool/gorseller/` içindedir ve uygulamaya paketlenmez.

## D2. Yeni deste ekleme

1. Görselleri `assets/decks/<id>/` altına koy (52 kağıt + `back.webp`),
   masayı `assets/boards/<id>.webp` yap.
2. `pubspec.yaml`'a `assets/decks/<id>/` satırını ekle.
3. `DeckId`'ye adını, `DeckTheme.all`'a bir satır ekle.

Başka hiçbir yere dokunmak gerekmez. `deck_assets_test.dart` yeni destenin
bütün dosyalarını otomatik olarak denetler; eksik kağıt testte düşer.

## D3. Deste açma altyapısı

Her destenin bir **açılma kuralı** (`UnlockRule`) vardır:

| Kural | Anlamı |
|---|---|
| `FreeUnlock()` | Herkese açık |
| `AdsUnlock(n)` | `n` reklam izlenince açılır |
| `CoinsUnlock(n)` | `n` jeton karşılığı açılır |

**Şu an bütün desteler `FreeUnlock`.** Bir desteyi kilitlemek için
`DeckTheme.all` içindeki tek satırı değiştirmek yeterlidir; arayüz kilidi,
ilerlemeyi ve fiyatı kendiliğinden gösterir.

Mülkiyet `DeckStore`'da durur ve `shared_preferences`'a yazılır: açılmış
desteler, deste başına izlenen reklam sayısı ve jeton bakiyesi.

```dart
Future<bool> adWatched(DeckTheme deck);  // sayaç dolduysa true
Future<bool> buy(DeckTheme deck);        // parası yettiyse true
Future<void> addCoins(int amount);
```

**Reklam SDK'sı ve ödeme bu sınıfın dışındadır.** `DeckStore` yalnızca sonucu
işler: reklam izlendiğinde `adWatched`, satın alma başarılı olduğunda `buy`
çağrılır. Entegrasyon eklendiğinde oyunun geri kalanı değişmez.

Yöntemler desteyi **id yerine nesne olarak** alır; kural destenin kendisinde
durur, böylece kayıt tablosuna bağımlı kalmadan sınanabilir.

---

# Bölüm E — Arayüz ve renk dili

06.10.2026'da kuruldu, aynı gün açık/koyu tema ile genişletildi. Kural motoru
arayüzden habersizdir; bu bölüm yalnızca görünümü ve ekran davranışını bağlar.

## E1. İki ayrı dünya

Renkler iki gruba ayrılır ve **karıştırılmaz**:

| Dünya | Nerede | Kural |
|---|---|---|
| **Arayüz** | ana ekran, ayarlar, pop-up, çip, künye | Temaya bağlı: açık ve koyu iki palet. Masanın rengine bağlı **değil**. |
| **Kağıt** | kart yüzü, kart sırtı | `BatakColors` içindeki sabitler. Kart fiziksel bir nesnedir; tema değişse de aynı basılmıştır. |

Sebep: masa hem desteyle hem temayla değişir. Masa üstündeki metin masanın
rengine bağlanırsa her deste × tema kombinasyonu için ayrı okunurluk sorunu
çıkar. Bu yüzden **masa üstündeki her şey panel renginde bir pildir**: künye,
üst bar çipi, çıkış düğmesi. Gölgeleri `BatakPalette.onBoardShadow` ile gelir
ve masadan bağımsızdır.

## E2. Palet

`BatakPalette`, `ThemeExtension<BatakPalette>` olarak temaya takılır ve
widget'lar `context.pal` ile okur. **Widget içine ham renk yazılmaz.**

İki sabit sürümü vardır: `BatakPalette.light` ve `BatakPalette.dark`.

| Alan | İş |
|---|---|
| `surface` / `surfaceAlt` | ekran zemini / ikinci yüzey (seçilmemiş çip, sayı kutusu) |
| `panel` | pop-up, panel ve masa üstü pillerin zemini |
| `line` | ince ayrım çizgisi |
| `accent` / `accentDeep` / `onAccent` | vurgu dolgusu / okunur vurgu tonu / vurgu üstü metin |
| `blush` `butter` | ikincil pastel vurgular (dağıtan noktası, sıfır uyarısı) |
| `ink` `inkSoft` `inkDim` | metin, koyudan soluğa |
| `good` `bad` | puan işareti |
| `scrim` | pop-up altındaki örtü |
| `soft` `pop` | panel ve pop-up gölgesi (paletin gölge renginden türer) |

`BatakColors` yalnızca kağıdı taşır: `cardFace`, `cardEdge`, `cardInk`,
`cardBack`, `cardBackDark`, `red`, `brass`.

`buildTheme(Brightness)` bu paletten bir `ThemeData` kurar ve paleti
`extensions` ile içine koyar. Düğme, çip, switch, dialog, liste hepsi
oradan beslenir.

## E3. Tema seçimi

`ThemeChoice { system, light, dark }` ayarlarda durur (`theme` anahtarı) ve
varsayılanı `system`'dir: telefonun kendi ayarını izler. `MaterialApp`
`theme` + `darkTheme` + `themeMode` üçlüsüyle kurulur.

Tema geçişi `AnimatedTheme` üzerinden animasyonludur; `BatakPalette.lerp`
yarıda eski paleti döndürür, bu yüzden paleti ölçen testler `pumpAndSettle`
ile geçişin bitmesini bekler.

Testler: `test/ui/theme_test.dart`.

## E4. Masa paleti

Her destenin **iki** masası vardır: `boardLight` ve `boardDark`;
`deck.board(brightness)` temaya uyanı verir. `BoardPalette.isLight`, `base`
parlaklığı 0.3'ü geçtiğinde doğrudur ve `BoardPainter` buna göre yön
değiştirir: koyu masada dokuma izi beyaz ve kenar kararması güçlü, açık
masada iz siyah, kararma hafif, işlemeler daha koyu çizilir.

Sınırlar testle korunur (`test/ui/deck_assets_test.dart`):

- her palette `dark < base < light`;
- açık masa `isLight` olmalı ve `base` parlaklığı **0.20–0.55** arasında
  kalmalı — daha soluğunda beyaz kağıt masaya karışır;
- koyu masada `light` parlaklığı 0.25'in altında kalmalı.

## E5. Masa yerleşimi

- **Üst bar** yalnızca koz ve el/yan bilgisini taşır. Tahmin ve alınan el
  oradan kaldırıldı; o bilgi koltuğun kendi künyesinde durur.
- **Künye** (`SeatBadge`) adı, dağıtan noktasını, düşünme göstergesini ve
  ortada **`aldığı / tahmini`** sayısını gösterir. Tahmin söylenmemişse
  tahmin yerine tire yazar; oyuncu tahminini doldurunca (`taken >= bid`)
  sayı `accentDeep` rengine döner. Sırası gelen koltuğun künyesi `accent`
  dolgusuna geçer.
- **İnsanın künyesi de masadadır** (alt uçta, `showBacks: false`): kaç el
  aldığını oyun sırasında görmek gerekir. Eli zaten yelpazede açık olduğu
  için kapalı kağıt yığını çizilmez.
- **Ortadaki el** 76 px kart genişliğiyle çizilir; daha küçüğünde telefonda
  okunmuyordu.

Testler: `test/ui/seat_badge_test.dart`.

## E6. Tahmin pop-up'ı

Tahmin **masanın ortasında açılan bir pop-up**tur, ekrana yapışık bir panel
değil.

- `BidPanel` masanın kapladığı alanın içine yerleşir (`_BidOverlay`), üst bara
  ve yelpazeye dokunmaz. **Yelpaze her zaman görünür kalır**: oyuncu tahmin
  verirken kendi elini görmek zorundadır — bu bir tasarım kuralıdır, test
  edilir.
- Altındaki örtü dikey gradyandır; üstte ve altta söner, böylece üst barla ve
  yelpazeyle arasında sert kesim olmaz. Örtü dokunuşları yutar.
- Pop-up açıkken **masadaki künyeler söner**: pop-up kenardakilerin üstüne
  bindiği için yarım görünüyorlardı, bilgileri de zaten pop-up'ın içinde.
- Sayılar 0–13, iki satırda yedişer. Seçili sayı `accent` dolguya döner ve
  1.08 ölçeğe büyür.
- 0 seçilince sıfır bahsinin uyarısı `butter` şeridinde belirir
  (`AnimatedSize`), başka sayıya geçilince kaybolur.
- Masadaki diğer tahminler altta `surfaceAlt` pillerde listelenir; tahminler
  herkese açıktır (A3).
- Seçim yapılmadan **Söyle** basılamaz. Düğme yazısı sabittir (`Str.bidButton`).
- Pop-up kartının anahtarı `BidPanel.cardKey`; ölçüm yapan testler panelin dış
  sınırını değil bu kartı ölçer.

Testler: `test/ui/bid_popup_test.dart`.

## E7. Önizleme aracı

`flutter test tool/preview_ui_test.dart` her ekranı **iki temada** üretir:
`build/ui_{home,bid,table,settings}_{light,dark}.png`. Test değildir, gözle
bakmak içindir. Test ortamının yazı tipi metinleri kutu çizer; yerleşim ve
renk doğrulanabilir, yazı okunmaz.

---

## Yol haritası (bu skill'e eklenecek bölümler)

- İhaleli (tekli), Eşli İhale, Gömmeli varyantları
- Zor bot (bilgi takibi + Monte Carlo)
- Reklam ve ödeme entegrasyonu (altyapısı Bölüm D'de hazır)
- UI tasarımı: kalan ekranların pastel diline taşınması (Bölüm E'de başladı)
