# Batak görselleri

Üç deste (osmanli, sehir, ejder) ve her birine uyan oyun masası.

## Flutter'a ekleme

1. `assets/` klasörünü projenin köküne kopyala.
2. `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/boards/
    - assets/decks/osmanli/
    - assets/decks/sehir/
    - assets/decks/ejder/
```

3. Dosya adları skill'deki kağıt kodlarıyla aynı: tür harfi (S=maça, H=kupa, D=karo, C=sinek) + değer (2-10, J, Q, K, A). Arka yüz `back.webp`.

```dart
enum DeckTheme { osmanli, sehir, ejder }

String cardAsset(DeckTheme deck, Card c) =>
    'assets/decks/${deck.name}/${c.code}.webp';     // örn. assets/decks/osmanli/SA.webp
String backAsset(DeckTheme deck) => 'assets/decks/${deck.name}/back.webp';
String boardAsset(DeckTheme deck) => 'assets/boards/${deck.name}.webp';

// Masa: Image.asset(boardAsset(deck), fit: BoxFit.cover)
```

## Ölçüler

- Kartlar: 500×700 px (oran 5:7), köşeleri şeffaf. Elde üst üste binince sol üstteki büyük değer ve tür görünür kalır.
- Masalar: 1080×1920 px (9:16), `BoxFit.cover` ile her ekrana yayılır.
- Masa bölgeleri (1080×1920 koordinatlarında):
  - Koltuk 2 (üst): (540, 330)
  - Koltuk 3 (sol): (120, 860)
  - Koltuk 1 (sağ): (960, 860)
  - Yere atılan kağıtlar: merkez (540, 860), yarıçap yaklaşık 250
  - İnsan oyuncunun eli: y ≈ 1400 ve altı
  - Üstteki 0-170 aralığı skor çubuğu için boş bırakıldı.

## Kaynak ve yeniden üretme

`kaynak/svg/` içinde her görselin vektör aslı var. `kaynak/uretici/` Python betikleri görselleri üretir:

```
pip install fonttools brotli playwright pillow
python3 build.py            # desteleri SVG + PNG olarak üretir (out/)
python3 boards.py           # masaları SVG olarak üretir
```

Renkleri, figürleri ya da yeni bir desteyi bu dosyalardan değiştirebilirsin. Yeni deste eklemek için `Deck` sınıfını genişleten bir dosya yazıp `build.py` içindeki `DECKS` listesine eklemen yeterli.

Fontlar (Playfair Display, Bangers, Cinzel) SIL Open Font License ile dağıtılıyor, kart köşelerindeki harfler bu fontlardan vektöre çevrildi.

Şehir Muhafızları ve Ejder Diyarı'ndaki bütün karakterler bu oyun için çizildi, herhangi bir markaya ait değil.
