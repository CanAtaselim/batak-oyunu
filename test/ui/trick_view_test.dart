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
}
