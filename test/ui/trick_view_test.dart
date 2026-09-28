import 'package:batak/engine/models/trick.dart';
import 'package:batak/ui/widgets/playing_card_view.dart';
import 'package:batak/ui/widgets/trick_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

/// Masadaki kağıtlar atılma sırasına göre üst üste biner: eli açanın kağıdı en
/// altta, en son atılan en üstte. Koltuk numarasının sıralamaya etkisi yoktur.
void main() {
  /// Widget ağacındaki çizim sırası: son eleman en üstte durur.
  List<String> paintOrder(WidgetTester tester) => tester
      .widgetList<PlayingCardView>(find.byType(PlayingCardView))
      .map((w) => w.card.code)
      .toList();

  Future<void> pumpTrick(WidgetTester tester, Trick trick) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: Center(child: TrickView(trick: trick)))),
    );
    await tester.pump(const Duration(milliseconds: 250));
  }

  testWidgets('eli 2. koltuk açtıysa sıra 2, 3, 0, 1 olur', (tester) async {
    await pumpTrick(tester, trickOf('D5 DK S3 DA', leader: 2));
    expect(paintOrder(tester), ['D5', 'DK', 'S3', 'DA']);
  });

  testWidgets('en son atan insan olsa bile kağıdı en üstte kalır',
      (tester) async {
    // 1. koltuk açtı, sıra 1 → 2 → 3 → 0; insanın kağıdı sonuncu.
    await pumpTrick(tester, trickOf('H7 H9 HK HA', leader: 1));
    expect(paintOrder(tester).last, 'HA', reason: 'insanın kağıdı altta kaldı');
  });

  testWidgets('el açanın kağıdı hep en altta kalır', (tester) async {
    for (final leader in [0, 1, 2, 3]) {
      await pumpTrick(tester, trickOf('C2 C5 C9 CK', leader: leader));
      expect(paintOrder(tester).first, 'C2', reason: 'leader $leader');
    }
  });

  testWidgets('yarım el: yalnızca atılmış kağıtlar çizilir', (tester) async {
    await pumpTrick(tester, trickOf('S4 S8', leader: 3));
    expect(paintOrder(tester), ['S4', 'S8']);
  });

  testWidgets('atılan kağıt sahibinin önünden masaya gelir', (tester) async {
    // Kağıt önce sahibinin yönünde uzakta durur, sonra yerine oturur.
    final trick = trickOf('D5', leader: 0);
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: Center(child: TrickView(trick: trick)))),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    final start = paintCenter(tester, 'D5');

    await tester.pump(const Duration(milliseconds: 400));
    final settled = paintCenter(tester, 'D5');

    // 0. koltuk alttadır: kağıt aşağıdan yukarı doğru yol alır.
    expect(start.dy, greaterThan(settled.dy + 40),
        reason: 'kağıt masaya yol almadan belirdi');
  });

  testWidgets('her koltuğun kağıdı kendi yönünden gelir', (tester) async {
    for (final (leader, dx, dy) in const [
      (1, 1.0, 0.0),
      (2, 0.0, -1.0),
      (3, -1.0, 0.0),
    ]) {
      // Ağacı yık: aynı anahtarlı kağıt yeniden kullanılırsa animasyon
      // baştan başlamaz ve ölçüm anlamsız olur.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(child: TrickView(trick: trickOf('SA', leader: leader))),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      final start = paintCenter(tester, 'SA');
      await tester.pump(const Duration(milliseconds: 400));
      final settled = paintCenter(tester, 'SA');

      if (dx != 0) {
        expect((start.dx - settled.dx).sign, dx, reason: 'koltuk $leader');
      }
      if (dy != 0) {
        expect((start.dy - settled.dy).sign, dy, reason: 'koltuk $leader');
      }
    }
  });
}

/// Bir kağıdın o anki ekran merkezi.
Offset paintCenter(WidgetTester tester, String code) => tester.getCenter(
      find.byWidgetPredicate(
        (w) => w is PlayingCardView && w.card.code == code,
      ),
    );
