import 'dart:math';

import 'package:batak/engine/models/card.dart';
import 'package:batak/engine/models/suit.dart';
import 'package:batak/ui/widgets/hand_fan.dart';
import 'package:batak/ui/widgets/playing_card_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

/// Elin ekrandaki dizilişi: renkler dönüşümlü, yay biçiminde.
void main() {
  bool isRed(Suit suit) => suit == Suit.hearts || suit == Suit.diamonds;

  group('diziliş', () {
    test('dört tür de varken sıra ♠ ♥ ♣ ♦ olur', () {
      final ordered = handDisplayOrder(
        cards('D5 SA H7 C2 DK S3 HQ C9'),
      );
      final suitsInOrder = <Suit>[];
      for (final card in ordered) {
        if (suitsInOrder.isEmpty || suitsInOrder.last != card.suit) {
          suitsInOrder.add(card.suit);
        }
      }
      expect(suitsInOrder, [Suit.spades, Suit.hearts, Suit.clubs, Suit.diamonds]);
      for (var i = 1; i < suitsInOrder.length; i++) {
        expect(
          isRed(suitsInOrder[i]),
          isNot(isRed(suitsInOrder[i - 1])),
          reason: 'yan yana iki aynı renk: ${suitsInOrder[i - 1]} ${suitsInOrder[i]}',
        );
      }
    });

    test('rastgele dağıtılan her elde komşu türler farklı renkte', () {
      final random = Random(11);
      for (var i = 0; i < 300; i++) {
        final hand = PlayingCard.shuffled(random).take(13).toList();
        final order = handSuitOrder(hand);
        final blacks = order.where((s) => !isRed(s)).length;
        final reds = order.length - blacks;
        // İki renk arasındaki fark 1'den büyükse dönüşüm zorunlu olarak bozulur
        // (örneğin elde hiç kırmızı yoksa); o durumda bir şey iddia edilemez.
        if ((blacks - reds).abs() > 1) continue;
        for (var j = 1; j < order.length; j++) {
          expect(
            isRed(order[j]),
            isNot(isRed(order[j - 1])),
            reason: '${order[j - 1]} ile ${order[j]} aynı renkte: $order',
          );
        }
      }
    });

    test('eksik tür varken de en az sayıda aynı renk komşuluğu kalır', () {
      // Elde kırmızı yok: ♠ ile ♣ yan yana gelmek zorunda.
      expect(handSuitOrder(cards('SA S3 C2 C9')), [Suit.spades, Suit.clubs]);
      // Tek kırmızı var: araya girer, hiç aynı renk komşuluğu kalmaz.
      expect(
        handSuitOrder(cards('SA S3 C2 H7')),
        [Suit.spades, Suit.hearts, Suit.clubs],
      );
      // İki kırmızı, bir siyah: kırmızıyla başlanır.
      expect(
        handSuitOrder(cards('H7 D4 C2')),
        [Suit.hearts, Suit.clubs, Suit.diamonds],
      );
    });

    test('aynı türün içinde küçükten büyüğe', () {
      final ordered = handDisplayOrder(cards('SA S3 S10 S7'));
      expect(ordered.map((c) => c.rank), [3, 7, 10, 14]);
    });

    test('kağıt oynanınca kalanların sırası değişmez', () {
      final hand = cards('D5 SA H7 C2 DK S3 HQ C9');
      final before = handDisplayOrder(hand).map((c) => c.code).toList();
      final after = handDisplayOrder(
        hand.where((c) => c.code != 'H7').toList(),
      ).map((c) => c.code).toList();
      expect(after, before.where((code) => code != 'H7').toList());
    });
  });

  group('yay', () {
    Future<void> pumpFan(WidgetTester tester, List<PlayingCard> hand) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 393,
              child: HandFan(
                hand: hand,
                legalCards: const [],
                enabled: false,
                onTap: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 250));
    }

    testWidgets('13 kağıt çizilir ve hiçbiri ekrandan taşmaz', (tester) async {
      tester.view.physicalSize = const Size(1080, 2316);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.reset);

      final hand = handDisplayOrder(PlayingCard.shuffled(Random(3)).take(13));
      await pumpFan(tester, hand);
      expect(find.byType(PlayingCardView), findsNWidgets(13));

      for (final card in hand) {
        final rect = tester.getRect(
          find.byWidgetPredicate((w) => w is PlayingCardView && w.card == card),
        );
        expect(rect.left, greaterThanOrEqualTo(-1), reason: '$card soldan taştı');
        expect(rect.right, lessThanOrEqualTo(394), reason: '$card sağdan taştı');
      }
    });

    testWidgets('ortadaki kağıt kenardakilerden yukarıda durur', (tester) async {
      final hand = handDisplayOrder(PlayingCard.shuffled(Random(5)).take(13));
      await pumpFan(tester, hand);

      double topOf(PlayingCard card) => tester
          .getRect(
            find.byWidgetPredicate((w) => w is PlayingCardView && w.card == card),
          )
          .top;

      expect(topOf(hand[6]), lessThan(topOf(hand.first)));
      expect(topOf(hand[6]), lessThan(topOf(hand.last)));
    });
  });
}
