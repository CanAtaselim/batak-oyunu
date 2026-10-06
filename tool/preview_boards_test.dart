// Masa alternatiflerini gözle karşılaştırmak için tek karelik çıktı üretir.
// Test değildir:
//
//   flutter test tool/preview_boards_test.dart
//
// Çıktı: build/board_preview.png

import 'dart:io';
import 'dart:ui' as ui;

import 'package:batak/engine/models/card.dart';
import 'package:batak/ui/cards/board_art.dart';
import 'package:batak/ui/cards/deck_theme.dart';
import 'package:batak/ui/widgets/playing_card_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Osmanlı destesinin masası: krem kağıtlar koyu lacivert çuhada öne çıksın.
const _osmanliBoard = BoardPalette(
  light: Color(0xFF24405C),
  base: Color(0xFF152A3D),
  dark: Color(0xFF0A1622),
  accent: Color(0xFFC9A227),
);

void main() {
  testWidgets('masa alternatifleri', (tester) async {
    tester.view.physicalSize = const Size(1600, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final deck = DeckTheme.byId(DeckId.osmanli);
    final key = GlobalKey();

    await tester.runAsync(() async {
      for (final code in ['SA', 'HK', 'D10', 'C7', 'S3']) {
        await precacheImage(
          AssetImage(deck.cardAsset(PlayingCard.parse(code))),
          _FakeContext(),
        );
      }
    });

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: RepaintBoundary(
          key: key,
          child: ColoredBox(
            color: const Color(0xFF202020),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final style in BoardStyle.values)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: _BoardSample(style: style, deck: deck),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      File('build/board_preview.png')
          .writeAsBytesSync(data!.buffer.asUint8List());
      image.dispose();
    });
  });
}

/// Tek bir masa örneği: üstünde atılmış üç kağıt, altta elden iki kağıt.
class _BoardSample extends StatelessWidget {
  const _BoardSample({required this.style, required this.deck});

  final BoardStyle style;
  final DeckTheme deck;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 340,
        height: 700,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: BoardPainter(style: style, palette: _osmanliBoard),
              ),
            ),
            // Masaya atılmış el.
            Positioned(
              top: 210,
              left: 60,
              child: Row(
                children: [
                  for (final code in ['SA', 'HK', 'D10'])
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: PlayingCardView(
                        card: PlayingCard.parse(code),
                        width: 68,
                        theme: deck,
                      ),
                    ),
                ],
              ),
            ),
            // Eldeki kağıtlar.
            Positioned(
              bottom: 24,
              left: 40,
              child: Row(
                children: [
                  for (final code in ['C7', 'S3'])
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: PlayingCardView(
                        card: PlayingCard.parse(code),
                        width: 86,
                        theme: deck,
                      ),
                    ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 4,
              child: Text(
                style.label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ],
        ),
      );
}

/// precacheImage yalnızca BuildContext istediği için; içeriğini kullanmıyor.
class _FakeContext extends StatelessWidget implements BuildContext {
  const _FakeContext();

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
