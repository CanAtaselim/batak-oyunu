import 'dart:ui' show Brightness;

import 'package:flutter/painting.dart';

import '../../engine/models/card.dart';
import 'board_art.dart';

/// Bir kart temasının nasıl açıldığı.
///
/// Şimdilik bütün temalar [FreeUnlock]; altyapı ileride reklamla ya da parayla
/// açılacak desteler için hazır. Bir desteyi kilitlemek için [DeckTheme.all]
/// içindeki `unlock` değerini değiştirmek yeterlidir.
sealed class UnlockRule {
  const UnlockRule();
}

/// Herkese açık deste.
final class FreeUnlock extends UnlockRule {
  const FreeUnlock();
}

/// [count] reklam izlenince açılır.
final class AdsUnlock extends UnlockRule {
  const AdsUnlock(this.count);

  final int count;
}

/// [price] jeton karşılığı açılır.
final class CoinsUnlock extends UnlockRule {
  const CoinsUnlock(this.price);

  final int price;
}

enum DeckId { klasik, osmanli, sehir, ejder }

/// Varsayılan tema; widget'ların öntanımlı değeri.
const DeckTheme klasikDeck = DeckTheme(
  id: DeckId.klasik,
  name: 'Klasik',
  description: 'Sade kağıtlar, adaçayı masa',
  unlock: FreeUnlock(),
  drawn: true,
  boardLight: BoardPalette(
    light: Color(0xFFA9C9B5),
    base: Color(0xFF8DB49E),
    dark: Color(0xFF6E9A84),
    accent: Color(0xFF3F7159),
  ),
  boardDark: BoardPalette(
    light: Color(0xFF2C4537),
    base: Color(0xFF1E3227),
    dark: Color(0xFF101E17),
    accent: Color(0xFF8FB9A2),
  ),
);

/// Kart destesi ve ona eşlik eden masa.
///
/// Desteler görsel dosyalardan gelir (`assets/decks/<id>/<kağıt kodu>.webp`);
/// yalnızca `klasik` uygulamanın içinde çizilir. Kağıt kodları motorunkiyle
/// aynıdır (SA, H10, DK…), bu yüzden dosya adı doğrudan koddan üretilir.
final class DeckTheme {
  const DeckTheme({
    required this.id,
    required this.name,
    required this.description,
    required this.unlock,
    required this.boardLight,
    required this.boardDark,
    this.drawn = false,
  });

  final DeckId id;
  final String name;
  final String description;
  final UnlockRule unlock;

  /// Görsel dosya yerine uygulamanın içinde çizilen deste.
  final bool drawn;

  /// Bu destenin masası, açık temada. Pastel ama kağıt beyazından belirgin
  /// biçimde koyu: kontrast masadan değil kağıttan gelir.
  final BoardPalette boardLight;

  /// Aynı masanın koyu temadaki hali.
  final BoardPalette boardDark;

  /// Temanın parlaklığına uyan masa paleti.
  BoardPalette board(Brightness brightness) =>
      brightness == Brightness.dark ? boardDark : boardLight;

  /// Kart oranı (boy / en). Çizilen deste 64×92, görseller 500×700.
  double get aspect => drawn ? 92 / 64 : 7 / 5;

  String cardAsset(PlayingCard card) => 'assets/decks/${id.name}/${card.code}.webp';

  String get backAsset => 'assets/decks/${id.name}/back.webp';

  /// Bu destenin masası. Çizilen destede masa da çizimdir.
  String get boardAsset => 'assets/boards/${id.name}.webp';

  /// Sırasıyla: çizilen klasik deste, sonra görsel desteler.
  ///
  /// Yeni deste eklemek: görselleri `assets/decks/<id>/` altına koy, [DeckId]
  /// içine adını yaz ve buraya bir satır ekle. Başka hiçbir yere dokunmak
  /// gerekmez.
  static const List<DeckTheme> all = [
    klasikDeck,
    DeckTheme(
      id: DeckId.osmanli,
      name: 'Osmanlı',
      description: 'Lale ve hat motifleri',
      // İleride örneğin: AdsUnlock(5)
      unlock: FreeUnlock(),
      boardLight: BoardPalette(
        light: Color(0xFFAEC3D6),
        base: Color(0xFF90AAC2),
        dark: Color(0xFF7090AB),
        accent: Color(0xFF8A6A1E),
      ),
      boardDark: BoardPalette(
        light: Color(0xFF24405C),
        base: Color(0xFF152A3D),
        dark: Color(0xFF0A1622),
        accent: Color(0xFFC9A227),
      ),
    ),
    DeckTheme(
      id: DeckId.sehir,
      name: 'Şehir Muhafızları',
      description: 'Çizgi roman kahramanları',
      // İleride örneğin: CoinsUnlock(500)
      unlock: FreeUnlock(),
      boardLight: BoardPalette(
        light: Color(0xFFB9C3D2),
        base: Color(0xFF9CA8BC),
        dark: Color(0xFF7C8AA1),
        accent: Color(0xFF3F5E7D),
      ),
      boardDark: BoardPalette(
        light: Color(0xFF2B3C57),
        base: Color(0xFF1A2436),
        dark: Color(0xFF0B1220),
        accent: Color(0xFF7FA8C9),
      ),
    ),
    DeckTheme(
      id: DeckId.ejder,
      name: 'Ejder Diyarı',
      description: 'Ejderler ve şövalyeler',
      unlock: FreeUnlock(),
      boardLight: BoardPalette(
        light: Color(0xFFAFC4AE),
        base: Color(0xFF93AC93),
        dark: Color(0xFF748D76),
        accent: Color(0xFF7A5F24),
      ),
      boardDark: BoardPalette(
        light: Color(0xFF2D4032),
        base: Color(0xFF1A2A20),
        dark: Color(0xFF0B1710),
        accent: Color(0xFFC09A4E),
      ),
    ),
  ];

  static DeckTheme byId(DeckId id) =>
      all.firstWhere((theme) => theme.id == id);

  static DeckTheme fromCode(String? code) => all.firstWhere(
        (theme) => theme.id.name == code,
        orElse: () => all.first,
      );

  @override
  String toString() => 'DeckTheme(${id.name})';
}
