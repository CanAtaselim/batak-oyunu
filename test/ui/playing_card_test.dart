import 'package:batak/engine/models/card.dart';
import 'package:batak/ui/widgets/playing_card_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Kart iki köşesinden de okunabilmeli: masaya atılan kağıt başka bir kağıdın
/// altında kalsa bile bir köşesi görünür.
void main() {
  Future<void> pumpCard(
    WidgetTester tester,
    PlayingCard card, {
    bool turkishIndices = false,
  }) =>
      tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: PlayingCardView(
                card: card,
                width: 90,
                trShortNames: turkishIndices,
              ),
            ),
          ),
        ),
      );

  testWidgets('indeks iki köşede birden çizilir', (tester) async {
    await pumpCard(tester, PlayingCard.parse('H10'));
    expect(find.text('10'), findsNWidgets(2));
    // Tür simgesi: iki köşe + ortadaki soluk simge.
    expect(find.text('♥'), findsNWidgets(3));
  });

  testWidgets('ikinci köşe 180 derece dönüktür', (tester) async {
    await pumpCard(tester, PlayingCard.parse('SA'));
    final corners = tester.widgetList<Transform>(
      find.ancestor(
        of: find.text('A').last,
        matching: find.byType(Transform),
      ),
    );
    expect(corners, isNotEmpty, reason: 'ikinci köşe döndürülmemiş');
  });

  testWidgets('iki köşe de aynı değeri gösterir, Türkçe harflerde de',
      (tester) async {
    for (final (code, expected) in const [
      ('SK', 'P'),
      ('HQ', 'K'),
      ('DJ', 'V'),
      ('CA', 'A'),
      ('S7', '7'),
    ]) {
      await pumpCard(tester, PlayingCard.parse(code), turkishIndices: true);
      expect(find.text(expected), findsNWidgets(2), reason: code);
    }
  });

  testWidgets('köşeler kartın içinde kalır, taşma olmaz', (tester) async {
    await pumpCard(tester, PlayingCard.parse('D10'));
    final card = tester.getRect(find.byType(PlayingCardView));
    for (final corner in tester.widgetList<Text>(find.text('10'))) {
      final rect = tester.getRect(find.byWidget(corner));
      expect(card.contains(rect.topLeft), isTrue);
      expect(card.contains(rect.bottomRight), isTrue);
    }
  });
}
