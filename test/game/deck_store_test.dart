import 'package:batak/engine/models/card.dart';
import 'package:batak/game/deck_store.dart';
import 'package:batak/game/settings.dart';
import 'package:batak/ui/cards/board_art.dart';
import 'package:batak/ui/cards/deck_theme.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Deste açma altyapısı: reklam sayacı, jetonla satın alma ve kalıcılık.
///
/// Şimdilik bütün desteler bedava; buradaki kilitli desteler kuralın kendisini
/// sınamak için uydurulmuştur.
/// Testlerdeki uydurma desteler için; rengin bir önemi yok.
const _testBoard = BoardPalette(
  light: Color(0xFF000000),
  base: Color(0xFF000000),
  dark: Color(0xFF000000),
  accent: Color(0xFF000000),
);

void main() {
  late SharedPreferences prefs;

  ProviderContainer makeContainer() => ProviderContainer(
        overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
      );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  group('deste tanımları', () {
    test('her destenin görsel yolu kağıt koduyla üretilir', () {
      final deck = DeckTheme.byId(DeckId.osmanli);
      expect(deck.cardAsset(PlayingCard.parse('SA')),
          'assets/decks/osmanli/SA.webp');
      expect(deck.cardAsset(PlayingCard.parse('H10')),
          'assets/decks/osmanli/H10.webp');
      expect(deck.backAsset, 'assets/decks/osmanli/back.webp');
      expect(deck.boardAsset, 'assets/boards/osmanli.webp');
    });

    test('çizilen deste görsel kullanmaz, oranı farklıdır', () {
      expect(klasikDeck.drawn, isTrue);
      expect(klasikDeck.aspect, 92 / 64);
      for (final deck in DeckTheme.all.where((d) => !d.drawn)) {
        expect(deck.aspect, 7 / 5, reason: deck.name);
      }
    });

    test('bilinmeyen kod klasiğe düşer', () {
      expect(DeckTheme.fromCode(null).id, DeckId.klasik);
      expect(DeckTheme.fromCode('yok-boyle-deste').id, DeckId.klasik);
      expect(DeckTheme.fromCode('ejder').id, DeckId.ejder);
    });

    test('şu an bütün desteler açık', () {
      final c = makeContainer();
      addTearDown(c.dispose);
      final ownership = c.read(deckStoreProvider);
      for (final deck in DeckTheme.all) {
        expect(ownership.isUnlocked(deck), isTrue, reason: deck.name);
      }
    });
  });

  group('reklamla açma', () {
    test('sayaç dolunca deste açılır', () async {
      final c = makeContainer();
      addTearDown(c.dispose);
      final store = c.read(deckStoreProvider.notifier);

      // Üç reklamlık uydurma kural.
      const deck = DeckTheme(
        id: DeckId.ejder,
        name: 'Ejder',
        description: '',
        unlock: AdsUnlock(3),
        boardLight: _testBoard,
      boardDark: _testBoard,
      );
      expect(c.read(deckStoreProvider).isUnlocked(deck), isFalse);
      expect(c.read(deckStoreProvider).adsRemaining(deck), 3);

      expect(await store.adWatched(deck), isFalse);
      expect(await store.adWatched(deck), isFalse);
      expect(c.read(deckStoreProvider).adsFor(DeckId.ejder), 2);
      expect(c.read(deckStoreProvider).adsRemaining(deck), 1);

      expect(await store.adWatched(deck), isTrue, reason: 'açılmadı');
      expect(c.read(deckStoreProvider).isUnlocked(deck), isTrue);
      expect(c.read(deckStoreProvider).adsRemaining(deck), 0);
    });

    test('açıldıktan sonra fazladan reklam sayılmaz', () async {
      final c = makeContainer();
      addTearDown(c.dispose);
      final store = c.read(deckStoreProvider.notifier);
      const deck = DeckTheme(
        id: DeckId.ejder,
        name: 'Ejder',
        description: '',
        unlock: AdsUnlock(3),
        boardLight: _testBoard,
      boardDark: _testBoard,
      );
      for (var i = 0; i < 3; i++) {
        await store.adWatched(deck);
      }
      final before = c.read(deckStoreProvider).adsFor(DeckId.ejder);
      expect(await store.adWatched(deck), isFalse);
      expect(c.read(deckStoreProvider).adsFor(DeckId.ejder), before);
    });
  });

  group('jetonla açma', () {
    const deck = DeckTheme(
      id: DeckId.sehir,
      name: 'Şehir',
      description: '',
      unlock: CoinsUnlock(500),
      boardLight: _testBoard,
      boardDark: _testBoard,
    );

    test('parası yetmezse açılmaz ve jeton eksilmez', () async {
      final c = makeContainer();
      addTearDown(c.dispose);
      final store = c.read(deckStoreProvider.notifier);
      await store.addCoins(499);

      expect(c.read(deckStoreProvider).canAfford(deck), isFalse);
      expect(await store.buy(deck), isFalse);
      expect(c.read(deckStoreProvider).coins, 499);
      expect(c.read(deckStoreProvider).isUnlocked(deck), isFalse);
    });

    test('parası yetince açılır ve fiyat kadar düşer', () async {
      final c = makeContainer();
      addTearDown(c.dispose);
      final store = c.read(deckStoreProvider.notifier);
      await store.addCoins(700);

      expect(c.read(deckStoreProvider).canAfford(deck), isTrue);
      expect(await store.buy(deck), isTrue);
      expect(c.read(deckStoreProvider).coins, 200);
      expect(c.read(deckStoreProvider).isUnlocked(deck), isTrue);

      // İkinci kez satın alınamaz.
      expect(await store.buy(deck), isFalse);
      expect(c.read(deckStoreProvider).coins, 200);
    });
  });

  test('açılan desteler ve jeton uygulamayı kapatınca kaybolmaz', () async {
    const paid = DeckTheme(
      id: DeckId.sehir,
      name: 'Şehir',
      description: '',
      unlock: CoinsUnlock(500),
      boardLight: _testBoard,
      boardDark: _testBoard,
    );
    const adDeck = DeckTheme(
      id: DeckId.ejder,
      name: 'Ejder',
      description: '',
      unlock: AdsUnlock(3),
      boardLight: _testBoard,
      boardDark: _testBoard,
    );
    final first = makeContainer();
    final store = first.read(deckStoreProvider.notifier);
    await store.addCoins(700);
    await store.buy(paid);
    await store.adWatched(adDeck);
    first.dispose();

    final second = makeContainer();
    addTearDown(second.dispose);
    final ownership = second.read(deckStoreProvider);
    expect(ownership.coins, 200);
    expect(ownership.unlocked, contains(DeckId.sehir));
    expect(ownership.adsFor(DeckId.ejder), 1);
  });

  test('seçili deste ayarlarda kalıcıdır', () async {
    final first = makeContainer();
    await first.read(settingsProvider.notifier).setDeck(
          DeckTheme.byId(DeckId.sehir),
        );
    first.dispose();

    final second = makeContainer();
    addTearDown(second.dispose);
    expect(second.read(settingsProvider).deck.id, DeckId.sehir);
  });
}
