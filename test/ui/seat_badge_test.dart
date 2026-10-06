import 'package:batak/ui/strings.dart';
import 'package:batak/ui/theme.dart';
import 'package:batak/ui/widgets/seat_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Künye oyunun en çok bakılan sayısını taşır: kaç el alındı.
void main() {
  Future<void> pumpBadge(
    WidgetTester tester, {
    required int seat,
    required int taken,
    int? bid,
    bool showBacks = true,
    bool isTurn = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.light),
        home: Scaffold(
          body: Center(
            child: SeatBadge(
              seat: seat,
              cardsInHand: 13,
              bid: bid,
              taken: taken,
              isDealer: false,
              isTurn: isTurn,
              showBacks: showBacks,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  /// Künyedeki sayıyı RichText'in düz metni olarak okur.
  String scoreText(WidgetTester tester) {
    final rich = tester.widget<RichText>(
      find.descendant(
        of: find.byType(SeatBadge),
        matching: find.byType(RichText),
      ).last,
    );
    return rich.text.toPlainText();
  }

  testWidgets('aldığı el ve tahmini birlikte yazar', (tester) async {
    await pumpBadge(tester, seat: 1, taken: 2, bid: 4);
    expect(find.text(Str.bot1), findsOneWidget);
    expect(scoreText(tester), '2/4');
  });

  testWidgets('tahmin söylenmediyse yerine tire kor', (tester) async {
    await pumpBadge(tester, seat: 2, taken: 0);
    expect(scoreText(tester), '0/${Str.noBidShort}');
  });

  /// Künyedeki büyük sayının (aldığı el) rengi.
  Color? takenColor(WidgetTester tester) {
    final rich = tester.widget<RichText>(
      find.descendant(
        of: find.byType(SeatBadge),
        matching: find.byType(RichText),
      ).last,
    );
    final span = rich.text as TextSpan;
    return (span.children!.first as TextSpan).style?.color;
  }

  testWidgets('tahmin dolunca sayı vurgu rengine döner', (tester) async {
    await pumpBadge(tester, seat: 1, taken: 1, bid: 3);
    final before = takenColor(tester);

    await pumpBadge(tester, seat: 1, taken: 3, bid: 3);
    final after = takenColor(tester);

    expect(after, BatakPalette.light.accentDeep);
    expect(before, isNot(after));
  });

  testWidgets('insanın künyesinde kapalı kağıt yığını olmaz', (tester) async {
    await pumpBadge(tester, seat: 0, taken: 1, bid: 2, showBacks: false);
    expect(find.text(Str.you), findsOneWidget);
    expect(scoreText(tester), '1/2');
    // Kart sırtı çizilmediği için künye tek satırdır.
    final size = tester.getSize(find.byType(SeatBadge));
    expect(size.height, lessThan(40));
  });

  testWidgets('botun künyesinde kapalı kağıt yığını vardır', (tester) async {
    await pumpBadge(tester, seat: 1, taken: 1, bid: 2);
    final size = tester.getSize(find.byType(SeatBadge));
    expect(size.height, greaterThan(40));
  });
}
