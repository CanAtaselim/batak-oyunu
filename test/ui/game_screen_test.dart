import 'package:batak/engine/models/game_state.dart';
import 'package:batak/game/game_controller.dart';
import 'package:batak/game/settings.dart';
import 'package:batak/main.dart';
import 'package:batak/ui/screens/game_screen.dart';
import 'package:batak/ui/strings.dart';
import 'package:batak/ui/widgets/bid_panel.dart';
import 'package:batak/ui/widgets/hand_fan.dart';
import 'package:batak/ui/widgets/playing_card_view.dart';
import 'package:batak/ui/widgets/score_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ekranların gerçekten çizildiğini ve insan hamlesinin motora ulaştığını
/// doğrulayan duman testi.
void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  ProviderContainer container() => ProviderContainer(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
          delayProvider.overrideWithValue((_) async {}),
        ],
      );

  Future<ProviderContainer> pumpApp(WidgetTester tester) async {
    // Telefon boyutu, dikey.
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final c = container();
    addTearDown(c.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: c, child: const BatakApp()),
    );
    await tester.pump();
    return c;
  }

  /// Botların sırası geçsin diye olay kuyruğunu boşaltır ve çerçeve çizer.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  testWidgets('ana ekrandan masaya geçilir', (tester) async {
    await pumpApp(tester);
    expect(find.text(Str.appName), findsOneWidget);
    expect(find.text(Str.newGame), findsOneWidget);

    await tester.tap(find.text(Str.newGame));
    await tester.pump();
    await settle(tester);

    expect(find.byType(GameScreen), findsOneWidget);
    expect(find.text('${Str.trump} ♠'), findsOneWidget);
    expect(find.byType(HandFan), findsOneWidget);
  });

  testWidgets('insan tahminini panelden söyler', (tester) async {
    final c = await pumpApp(tester);
    await tester.tap(find.text(Str.newGame));
    await tester.pump();
    await settle(tester);

    expect(find.byType(BidPanel), findsOneWidget);
    // Tahmin verirken el görünür olmalı.
    expect(find.byType(HandFan), findsOneWidget);
    await tester.tap(find.widgetWithText(InkWell, '4'));
    await tester.pump();
    await tester.tap(find.text(Str.bidButton));
    await settle(tester);

    expect(c.read(gameControllerProvider)!.game.bids[GameState.humanSeat], 4);
    expect(find.byType(BidPanel), findsNothing);
  });

  testWidgets('yelpazede 13 kağıt var ve geçerli kağıda dokunmak onu atar',
      (tester) async {
    final c = await pumpApp(tester);
    final controller = c.read(gameControllerProvider.notifier);
    await tester.tap(find.text(Str.newGame));
    await tester.pump();
    await settle(tester);

    if (c.read(gameControllerProvider)!.humanCanBid) {
      await tester.tap(find.widgetWithText(InkWell, '3'));
      await tester.pump();
      await tester.tap(find.text(Str.bidButton));
      await settle(tester);
    }

    final fan = find.descendant(
      of: find.byType(HandFan),
      matching: find.byType(PlayingCardView),
    );
    expect(fan, findsNWidgets(13));

    final session = c.read(gameControllerProvider)!;
    expect(session.humanCanPlay, isTrue);

    // Yelpazede kartın görünen tek yeri sol şeridi; dokunma oraya gider.
    final hand = session.game.handOf(GameState.humanSeat);
    final legal = controller.humanLegalCards;
    final card = hand.lastWhere(legal.contains);
    final finder = find.byWidgetPredicate(
      (w) => w is PlayingCardView && w.card == card,
    );
    expect(finder, findsOneWidget);
    await tester.tapAt(tester.getTopLeft(finder) + const Offset(9, 40));
    await settle(tester);

    expect(
      c.read(gameControllerProvider)!.game.handOf(GameState.humanSeat),
      isNot(contains(card)),
    );
  });

  testWidgets('el bitince puan tablosu açılır', (tester) async {
    final c = await pumpApp(tester);
    final controller = c.read(gameControllerProvider.notifier);
    await tester.tap(find.text(Str.newGame));
    await tester.pump();
    await settle(tester);

    for (var guard = 0; guard < 300; guard++) {
      final session = c.read(gameControllerProvider)!;
      if (session.game.phase == Phase.roundOver) break;
      if (session.humanCanBid) {
        controller.placeBid(3);
      } else if (session.humanCanPlay) {
        controller.playCard(controller.humanLegalCards.first);
      }
      await tester.pump(const Duration(milliseconds: 16));
    }
    await settle(tester);

    expect(c.read(gameControllerProvider)!.game.phase, Phase.roundOver);
    expect(find.byType(ScoreSheet), findsOneWidget);
    expect(find.text(Str.nextRound), findsOneWidget);

    await tester.tap(find.text(Str.nextRound));
    await settle(tester);
    expect(c.read(gameControllerProvider)!.game.roundIndex, 1);
    expect(find.byType(ScoreSheet), findsNothing);
  });
}
