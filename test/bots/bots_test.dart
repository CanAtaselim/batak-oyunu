import 'dart:math';

import 'package:batak/bots/easy_bot.dart';
import 'package:batak/bots/medium_bot.dart';
import 'package:test/test.dart';

import '../helpers.dart';

/// SKILL.md BT senaryoları.
void main() {
  // Seed sabit: Orta bot rastgelelik kullanmasa da kurucu istiyor.
  MediumBot medium() => MediumBot(Random(1));
  EasyBot easy() => EasyBot(Random(1));

  group('BT tahmin', () {
    const bt1 = 'SA SK SQ S7 S3 HA H5 DK D9 D4 C8 C6 C2';
    const bt2 = 'S8 S4 HQ HJ H5 H3 DQ D10 D6 D2 CJ C9 C4';
    const bt3 = 'S9 S5 S2 HQ H8 H7 H4 H3 DJ D6 D3 D2 C5';

    test('BT1 — Orta, koz onurları ve uzunluk: 6', () {
      expect(medium().chooseBid(botView(hand: bt1, bid: 0)), 6);
    });

    test('BT2 — Orta, sıfır koşulu sağlanıyor: 0', () {
      expect(medium().chooseBid(botView(hand: bt2, bid: 0)), 0);
    });

    test('BT3 — Orta, zayıf el ama sıfır değil: 1', () {
      expect(medium().chooseBid(botView(hand: bt3, bid: 0)), 1);
    });

    test('BT4 — Kolay, BT1 eli: 4', () {
      expect(easy().chooseBid(botView(hand: bt1, bid: 0)), 4);
    });

    test('Kolay bot sıfır tahmini söylemez', () {
      expect(easy().chooseBid(botView(hand: bt2, bid: 0)), 1);
    });

    test('tahminler her zaman 0–13 arasında', () {
      final rnd = Random(9);
      for (var i = 0; i < 300; i++) {
        final deck = shuffledDeckCodes(rnd);
        final hand = deck.take(13).join(' ');
        for (final bid in [
          medium().chooseBid(botView(hand: hand, bid: 0)),
          easy().chooseBid(botView(hand: hand, bid: 0)),
        ]) {
          expect(bid, inInclusiveRange(0, 13));
        }
      }
    });
  });

  group('BT oyun (Orta)', () {
    /// [bid]/[taken] modu kurar: AL için taken < bid, ALMA için taken >= bid.
    void check(
      String name, {
      required bool wantsTricks,
      required bool spadesBroken,
      String table = '',
      required String hand,
      required String expected,
    }) {
      test('$name — ${wantsTricks ? 'AL' : 'ALMA'}, masa: '
          '${table.isEmpty ? '—' : table}, el: $hand', () {
        final view = botView(
          hand: hand,
          table: table,
          bid: wantsTricks ? 5 : 2,
          taken: wantsTricks ? 0 : 2,
          spadesBroken: spadesBroken,
        );
        expect(view.wantsTricks, wantsTricks);
        final card = medium().chooseCard(view);
        expect(view.legalCards, contains(card),
            reason: 'bot legalCards dışından kağıt seçti');
        expect(card.code, c(expected).code);
      });
    }

    check('BT5', wantsTricks: true, spadesBroken: false,
        hand: 'HA C3 C7 S5', expected: 'HA');
    check('BT6', wantsTricks: false, spadesBroken: false,
        hand: 'HA C3 C7 S5', expected: 'C3');
    check('BT7', wantsTricks: true, spadesBroken: true, table: 'D5 DK S3',
        hand: 'S4 S10 SA C2', expected: 'S4');
    check('BT8', wantsTricks: false, spadesBroken: true, table: 'D5 DK S3',
        hand: 'S4 S10 SA C2', expected: 'SA');
    check('BT9', wantsTricks: false, spadesBroken: true, table: 'D8 S6',
        hand: 'S3 S4 CK', expected: 'S4');
    check('BT10', wantsTricks: false, spadesBroken: false, table: 'H5',
        hand: 'CA D2 D9', expected: 'CA');
    check('BT11', wantsTricks: true, spadesBroken: false, table: 'H5',
        hand: 'CA D2 D9', expected: 'D2');
    check('BT12', wantsTricks: true, spadesBroken: true, table: 'H5 HJ',
        hand: 'H2 H7 CK', expected: 'H2');
  });
}
