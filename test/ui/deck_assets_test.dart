import 'package:batak/engine/models/card.dart';
import 'package:batak/ui/cards/board_art.dart';
import 'package:batak/ui/cards/deck_theme.dart';
import 'package:batak/ui/widgets/playing_card_view.dart';
import 'package:flutter/material.dart';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Görsel destelerin bütün dosyaları gerçekten paketin içinde mi?
///
/// Yolu yanlış ya da eksik bir kağıt oyun sırasında ekranda patlar; burada
/// yakalanır.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final assetDecks = DeckTheme.all.where((deck) => !deck.drawn);

  test('her destede 52 kağıt, arka yüz ve masa var', () async {
    expect(assetDecks, isNotEmpty);
    for (final deck in assetDecks) {
      for (final card in PlayingCard.fullDeck()) {
        final path = deck.cardAsset(card);
        expect(
          () async => rootBundle.load(path),
          returnsNormally,
          reason: '$path yüklenemedi',
        );
        final data = await rootBundle.load(path);
        expect(data.lengthInBytes, greaterThan(200), reason: '$path boş');
      }
      final back = await rootBundle.load(deck.backAsset);
      expect(back.lengthInBytes, greaterThan(200), reason: deck.backAsset);
      final board = await rootBundle.load(deck.boardAsset);
      expect(board.lengthInBytes, greaterThan(200), reason: deck.boardAsset);
    }
  });

  test('çizilen deste hiç görsel istemez', () {
    expect(klasikDeck.drawn, isTrue);
  });

  testWidgets('görsel destede kağıt dosyadan çizilir', (tester) async {
    final deck = DeckTheme.byId(DeckId.sehir);
    final card = PlayingCard.parse('SK');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: PlayingCardView(card: card, width: 90, theme: deck),
          ),
        ),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));
    expect(image.image, isA<AssetImage>());
    expect(
      (image.image as AssetImage).assetName,
      'assets/decks/sehir/SK.webp',
    );
    // Görsel deste 5:7; yükseklik orana göre hesaplanır.
    final rect = tester.getRect(find.byType(PlayingCardView));
    expect(rect.height / rect.width, closeTo(7 / 5, 0.001));
  });

  testWidgets('çizilen destede hiç Image yoktur', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: PlayingCardView(
              card: PlayingCard.parse('SK'),
              width: 90,
              theme: klasikDeck,
            ),
          ),
        ),
      ),
    );
    expect(find.byType(Image), findsNothing);
    final rect = tester.getRect(find.byType(PlayingCardView));
    expect(rect.height / rect.width, closeTo(92 / 64, 0.001));
  });

  group('masa', () {
    test('her destenin bir masa paleti var ve koyudan açığa sıralı', () {
      for (final deck in DeckTheme.all) {
        final board = deck.board;
        // Kağıtlar açık renk; masa koyu olmalı ki kontrast kağıttan gelsin.
        expect(
          board.dark.computeLuminance(),
          lessThan(board.base.computeLuminance()),
          reason: '${deck.name}: kenar ortadan açık',
        );
        expect(
          board.base.computeLuminance(),
          lessThan(board.light.computeLuminance()),
          reason: '${deck.name}: orta ışıktan açık',
        );
        expect(
          board.light.computeLuminance(),
          lessThan(0.25),
          reason: '${deck.name}: masa fazla açık, kağıtlar kaybolur',
        );
      }
    });

    testWidgets('her üslup her boyutta hatasız çizilir', (tester) async {
      for (final style in BoardStyle.values) {
        for (final size in [const Size(74, 104), const Size(1080, 2316)]) {
          final recorder = PictureRecorder();
          BoardPainter(style: style, palette: klasikDeck.board)
              .paint(Canvas(recorder), size);
          recorder.endRecording();
        }
      }
    });
  });
}
