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
    test('her destenin açık ve koyu masası var, kenardan ortaya aydınlanır', () {
      for (final deck in DeckTheme.all) {
        for (final brightness in Brightness.values) {
          final board = deck.board(brightness);
          final where = '${deck.name}/${brightness.name}';
          expect(
            board.dark.computeLuminance(),
            lessThan(board.base.computeLuminance()),
            reason: '$where: kenar ortadan açık',
          );
          expect(
            board.base.computeLuminance(),
            lessThan(board.light.computeLuminance()),
            reason: '$where: orta ışıktan açık',
          );
        }

        // Açık tema masası pastel ama kağıt beyazından belirgin biçimde
        // koyu; yoksa kağıtlar masaya karışır.
        final light = deck.board(Brightness.light);
        expect(light.isLight, isTrue, reason: '${deck.name}: açık masa koyu');
        expect(
          light.base.computeLuminance(),
          inInclusiveRange(0.2, 0.55),
          reason: '${deck.name}: açık masa ya fazla soluk ya fazla koyu',
        );

        // Koyu tema masası gerçekten koyu.
        final dark = deck.board(Brightness.dark);
        expect(dark.isLight, isFalse, reason: '${deck.name}: koyu masa açık');
        expect(
          dark.light.computeLuminance(),
          lessThan(0.25),
          reason: '${deck.name}: koyu masa fazla açık',
        );
      }
    });

    testWidgets('her üslup her boyutta hatasız çizilir', (tester) async {
      for (final style in BoardStyle.values) {
        for (final size in [const Size(74, 104), const Size(1080, 2316)]) {
          for (final brightness in Brightness.values) {
            final recorder = PictureRecorder();
            BoardPainter(style: style, palette: klasikDeck.board(brightness))
                .paint(Canvas(recorder), size);
            recorder.endRecording();
          }
        }
      }
    });
  });
}
