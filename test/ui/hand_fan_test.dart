import 'dart:math';
import 'dart:math' as math;

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

  group('iki sıra yelpaze', () {
    Future<void> pumpFan(WidgetTester tester, List<PlayingCard> hand) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            // Uygulamadaki yerleşim: Column, gevşek genişlik. Sabit genişlikli
            // bir kutu Stack'in genişlik hatasını gizler.
            body: Column(
              children: [
                const Expanded(child: SizedBox.expand()),
                HandFan(
                  hand: hand,
                  legalCards: const [],
                  enabled: false,
                  onTap: (_) {},
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 250));
    }

    Finder cardFinder(PlayingCard card) =>
        find.byWidgetPredicate((w) => w is PlayingCardView && w.card == card);

    /// Kartın merkezinin dikey konumu. Dönme merkezi neredeyse hiç
    /// oynatmadığı için sıraları ayırmakta ve yayı ölçmekte güvenilirdir.
    double centerY(WidgetTester tester, PlayingCard card) =>
        tester.getCenter(cardFinder(card)).dy;

    /// Kartın eğimi (radyan). Sola eğik negatif, sağa eğik pozitif.
    double angleOf(WidgetTester tester, PlayingCard card) {
      final transform = tester.widget<Transform>(
        find
            .ancestor(of: cardFinder(card), matching: find.byType(Transform))
            .first,
      );
      final m = transform.transform.storage;
      return math.atan2(m[1], m[0]);
    }

    /// Dönmüş kartın gerçek sınırları: dört köşe de dönüştürülüp kutulanır.
    ({double left, double right}) boundsOf(
      WidgetTester tester,
      PlayingCard card,
    ) {
      final finder = cardFinder(card);
      final xs = [
        tester.getTopLeft(finder).dx,
        tester.getTopRight(finder).dx,
        tester.getBottomLeft(finder).dx,
        tester.getBottomRight(finder).dx,
      ];
      return (left: xs.reduce(math.min), right: xs.reduce(math.max));
    }

    /// Kağıtları dikey konumlarına göre iki sıraya ayırır. Sıra içindeki yay
    /// oynaması, sıralar arasındaki boşluktan küçüktür; kümeler karışmaz.
    (List<PlayingCard>, List<PlayingCard>) rows(
      WidgetTester tester,
      List<PlayingCard> hand,
    ) {
      final centers = {for (final c in hand) c: centerY(tester, c)};
      final lowest = centers.values.reduce(math.max);
      final highest = centers.values.reduce(math.min);
      final split = (lowest + highest) / 2;
      return (
        [for (final c in hand) if (centers[c]! < split) c],
        [for (final c in hand) if (centers[c]! >= split) c],
      );
    }

    testWidgets('13 kağıt üstte 6, altta 7 olarak dizilir', (tester) async {
      final hand = handDisplayOrder(PlayingCard.shuffled(Random(3)).take(13));
      await pumpFan(tester, hand);
      expect(find.byType(PlayingCardView), findsNWidgets(13));

      final (top, bottom) = rows(tester, hand);
      expect(top.length, 6);
      expect(bottom.length, 7);
    });

    testWidgets('dizilişin ilk yarısı üst sırada, ikinci yarısı altta',
        (tester) async {
      final hand = handDisplayOrder(PlayingCard.shuffled(Random(8)).take(13));
      await pumpFan(tester, hand);
      final (top, bottom) = rows(tester, hand);
      expect(top, hand.take(6).toList());
      expect(bottom, hand.skip(6).toList());

      // İki sıra dikeyde hiç karışmaz.
      final lowestTopRow =
          top.map((c) => centerY(tester, c)).reduce(math.max);
      final highestBottomRow =
          bottom.map((c) => centerY(tester, c)).reduce(math.min);
      expect(lowestTopRow, lessThan(highestBottomRow));
    });

    testWidgets('her sıra kendi içinde yay çizer', (tester) async {
      final hand = handDisplayOrder(PlayingCard.shuffled(Random(5)).take(13));
      await pumpFan(tester, hand);
      final (top, bottom) = rows(tester, hand);

      for (final row in [top, bottom]) {
        final first = row.first;
        final last = row.last;
        final middle = row[row.length ~/ 2];

        // Uçlar dışa eğik, orta neredeyse dik.
        expect(angleOf(tester, first), lessThan(0));
        expect(angleOf(tester, last), greaterThan(0));
        expect(
          angleOf(tester, middle).abs(),
          lessThan(angleOf(tester, first).abs()),
        );
        expect(
          angleOf(tester, middle).abs(),
          lessThan(angleOf(tester, last).abs()),
        );

        // Ortadaki kağıt uçtakilerden yukarıda durur.
        expect(centerY(tester, middle), lessThan(centerY(tester, first)));
        expect(centerY(tester, middle), lessThan(centerY(tester, last)));
      }
    });

    testWidgets('sıralar üst üste biner ama üst sıranın köşesi görünür',
        (tester) async {
      final hand = handDisplayOrder(PlayingCard.shuffled(Random(5)).take(13));
      await pumpFan(tester, hand);
      final (top, bottom) = rows(tester, hand);

      // Sıraların ortasındaki kağıtlar dik durur; ölçüm onlardan alınır.
      final topMid = tester.getRect(cardFinder(top[top.length ~/ 2]));
      final bottomMid = tester.getRect(cardFinder(bottom[bottom.length ~/ 2]));

      expect(bottomMid.top, lessThan(topMid.bottom), reason: 'sıralar binmiyor');
      // Üst sıranın yarısına yakını açıkta kalmalı: indeks köşesi görünsün.
      expect(bottomMid.top - topMid.top, greaterThan(topMid.height * 0.45));
    });

    testWidgets('hiçbir kağıt ekrandan taşmaz', (tester) async {
      tester.view.physicalSize = const Size(1080, 2316);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.reset);

      final hand = handDisplayOrder(PlayingCard.shuffled(Random(3)).take(13));
      await pumpFan(tester, hand);
      for (final card in hand) {
        final bounds = boundsOf(tester, card);
        expect(bounds.left, greaterThanOrEqualTo(-1), reason: '$card soldan taştı');
        expect(bounds.right, lessThanOrEqualTo(394), reason: '$card sağdan taştı');
      }
    });

    testWidgets('kağıt eksildikçe sıralar dengeli kalır', (tester) async {
      final full = handDisplayOrder(PlayingCard.shuffled(Random(9)).take(13));
      for (final (count, expectedTop, expectedBottom) in const [
        (12, 6, 6),
        (9, 4, 5),
        (5, 2, 3),
        (2, 1, 1),
      ]) {
        final hand = full.take(count).toList();
        await pumpFan(tester, hand);
        expect(find.byType(PlayingCardView), findsNWidgets(count));
        final (top, bottom) = rows(tester, hand);
        expect(top.length, expectedTop, reason: '$count kağıtta üst sıra');
        expect(bottom.length, expectedBottom, reason: '$count kağıtta alt sıra');
      }
    });

    testWidgets('her el büyüklüğünde her kağıda dokunulabilir', (tester) async {
      tester.view.physicalSize = const Size(1080, 2316);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.reset);

      // Üst sıradaki kağıdın merkezi alt sıranın altında kalırsa dokunuş
      // yanlış karta gider ve oyuncu o kağıdı atamaz. Her el büyüklüğü için
      // tek tek denenir.
      final deck = PlayingCard.fullDeck();
      for (var n = 1; n <= 13; n++) {
        final hand = handDisplayOrder(deck.take(n));
        final tapped = <PlayingCard>[];
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  const Expanded(child: SizedBox.expand()),
                  HandFan(hand: hand, legalCards: hand, onTap: tapped.add),
                ],
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        for (final card in hand) {
          await tester.tap(cardFinder(card), warnIfMissed: false);
          await tester.pump();
        }
        expect(
          tapped,
          hand,
          reason: '$n kağıtta dokunuş yanlış karta gitti ya da hiç gitmedi',
        );
      }
    });

    testWidgets('atılamayan kağıda dokunmak hiçbir şey yapmaz',
        (tester) async {
      final hand = handDisplayOrder(PlayingCard.fullDeck().take(13));
      final legal = [hand[2], hand[9]];
      final tapped = <PlayingCard>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                const Expanded(child: SizedBox.expand()),
                HandFan(hand: hand, legalCards: legal, onTap: tapped.add),
              ],
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      for (final card in hand) {
        await tester.tap(cardFinder(card), warnIfMissed: false);
        await tester.pump();
      }
      expect(tapped, legal);
    });
  });
}
