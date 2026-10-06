import 'package:batak/game/game_controller.dart';
import 'package:batak/game/settings.dart';
import 'package:batak/main.dart';
import 'package:batak/ui/strings.dart';
import 'package:batak/ui/widgets/bid_panel.dart';
import 'package:batak/ui/widgets/hand_fan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tahmin pop-up'ı: masanın ortasında açılır, yelpazeyi kapatmaz.
void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Future<ProviderContainer> pumpGame(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final c = ProviderContainer(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        delayProvider.overrideWithValue((_) async {}),
      ],
    );
    addTearDown(c.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: c, child: const BatakApp()),
    );
    await tester.pump();
    await tester.tap(find.text(Str.newGame));
    await tester.pump();
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    return c;
  }

  testWidgets('pop-up yatayda ortalanır', (tester) async {
    await pumpGame(tester);
    expect(find.byType(BidPanel), findsOneWidget);

    final panel = tester.getRect(find.byKey(BidPanel.cardKey));
    final screen = tester.getRect(find.byType(MaterialApp));
    expect(
      panel.center.dx,
      moreOrLessEquals(screen.center.dx, epsilon: 1),
      reason: 'pop-up ekranın ortasında değil',
    );
  });

  testWidgets('pop-up yelpazenin üstünü kapatmaz', (tester) async {
    await pumpGame(tester);

    final card = tester.getRect(find.byKey(BidPanel.cardKey));
    final fan = tester.getRect(find.byType(HandFan));

    expect(find.byType(HandFan), findsOneWidget);
    expect(
      card.bottom,
      lessThanOrEqualTo(fan.top),
      reason: 'pop-up yelpazenin üstüne biniyor',
    );
  });

  testWidgets('0–13 arası on dört sayı var ve biri seçilince söylenebilir',
      (tester) async {
    final c = await pumpGame(tester);

    for (var value = 0; value <= 13; value++) {
      expect(
        find.widgetWithText(InkWell, '$value'),
        findsOneWidget,
        reason: '$value yok',
      );
    }

    // Seçim yapılmadan söylenemez.
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, Str.bidButton),
    );
    expect(button.onPressed, isNull);

    await tester.tap(find.widgetWithText(InkWell, '5'));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text(Str.bidButton));
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    expect(c.read(gameControllerProvider)!.game.bids[0], 5);
    expect(find.byType(BidPanel), findsNothing);
  });

  testWidgets('0 seçilince sıfır uyarısı çıkar, 1 seçilince kaybolur',
      (tester) async {
    await pumpGame(tester);
    expect(find.text(Str.bidZeroNote), findsNothing);

    await tester.tap(find.widgetWithText(InkWell, '0'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(Str.bidZeroNote), findsOneWidget);

    await tester.tap(find.widgetWithText(InkWell, '1'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(Str.bidZeroNote), findsNothing);
  });
}
