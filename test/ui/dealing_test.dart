import 'dart:math';

import 'package:batak/engine/models/card.dart';
import 'package:batak/engine/models/game_state.dart';
import 'package:batak/game/game_controller.dart';
import 'package:batak/game/settings.dart';
import 'package:batak/ui/widgets/hand_fan.dart';
import 'package:batak/ui/widgets/playing_card_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Dağıtım animasyonu: kağıtlar tek tek gelir, o bitmeden kimse oynamaz.
void main() {
  group('yelpazede dağıtım', () {
    Future<void> pumpFan(WidgetTester tester, double progress) async {
      final hand = handDisplayOrder(PlayingCard.shuffled(Random(4)).take(13));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                const Expanded(child: SizedBox.expand()),
                HandFan(
                  hand: hand,
                  legalCards: const [],
                  enabled: false,
                  dealProgress: progress,
                  onTap: (_) {},
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 250));
    }

    /// Ekranda gerçekten görünen (saydamlığı sıfır olmayan) kağıt sayısı.
    int visibleCards(WidgetTester tester) => tester
        .widgetList<Opacity>(
          find.ancestor(
            of: find.byType(PlayingCardView),
            matching: find.byType(Opacity),
          ),
        )
        .where((o) => o.opacity > 0.01)
        .length;

    testWidgets('başlangıçta hiçbir kağıt görünmez', (tester) async {
      await pumpFan(tester, 0);
      expect(visibleCards(tester), 0);
    });

    testWidgets('dağıtım ilerledikçe kağıt sayısı artar', (tester) async {
      var previous = 0;
      for (final progress in [0.0, 0.25, 0.5, 0.75, 1.0]) {
        await pumpFan(tester, progress);
        final now = visibleCards(tester);
        expect(now, greaterThanOrEqualTo(previous), reason: 'ilerleme $progress');
        previous = now;
      }
      expect(previous, 13);
    });

    testWidgets('dağıtım bitince 13 kağıt da tam yerinde', (tester) async {
      await pumpFan(tester, 1);
      expect(visibleCards(tester), 13);
      final opacities = tester
          .widgetList<Opacity>(
            find.ancestor(
              of: find.byType(PlayingCardView),
              matching: find.byType(Opacity),
            ),
          )
          .map((o) => o.opacity);
      for (final o in opacities) {
        expect(o, 1, reason: 'kağıt yarı saydam kaldı');
      }
    });

    testWidgets('dağıtılan kağıt yukarıdan gelir', (tester) async {
      final hand = handDisplayOrder(PlayingCard.shuffled(Random(4)).take(13));
      double topOf(WidgetTester tester, PlayingCard card) => tester
          .getRect(
            find.byWidgetPredicate((w) => w is PlayingCardView && w.card == card),
          )
          .top;

      await pumpFan(tester, 1);
      final settled = topOf(tester, hand.first);
      // İlk kağıt yolun ortasındayken (kendi payının yarısı) yukarıda olmalı.
      await pumpFan(tester, 0.5 / 13);
      expect(topOf(tester, hand.first), lessThan(settled));
    });
  });

  group('motor dağıtım biterken bekler', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('yeni oyun dağıtım durumunda başlar ve sonra tahmine geçer', () async {
      final c = ProviderContainer(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
          delayProvider.overrideWithValue((_) async {}),
        ],
      );
      addTearDown(c.dispose);
      final controller = c.read(gameControllerProvider.notifier);
      controller.newGame(seed: 3);

      // Dağıtım bitene kadar ne insan ne bot oynar.
      final started = c.read(gameControllerProvider)!;
      expect(started.dealing, isTrue);
      expect(started.humanCanBid, isFalse);
      expect(started.game.bids.whereType<int>(), isEmpty);

      for (var i = 0; i < 100; i++) {
        await pumpEventQueue();
        if (!c.read(gameControllerProvider)!.dealing) break;
      }
      expect(c.read(gameControllerProvider)!.dealing, isFalse);
    });

    test('yeni oyun eli de dağıtım animasyonuyla başlar', () async {
      final c = ProviderContainer(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
          delayProvider.overrideWithValue((_) async {}),
        ],
      );
      addTearDown(c.dispose);
      final controller = c.read(gameControllerProvider.notifier);
      controller.newGame(seed: 2026);

      for (var guard = 0; guard < 500; guard++) {
        await pumpEventQueue();
        final session = c.read(gameControllerProvider)!;
        if (session.game.phase == Phase.roundOver) break;
        if (session.humanCanBid) {
          controller.placeBid(3);
        } else if (session.humanCanPlay) {
          controller.playCard(controller.humanLegalCards.first);
        }
      }
      expect(c.read(gameControllerProvider)!.game.phase, Phase.roundOver);

      controller.nextRound();
      final next = c.read(gameControllerProvider)!;
      expect(next.game.roundIndex, 1);
      expect(next.dealing, isTrue, reason: 'yeni el dağıtımsız başladı');
      expect(next.humanCanBid, isFalse);
    });
  });
}
