import 'package:batak/engine/variants/koz_maca/koz_maca_rules.dart';
import 'package:test/test.dart';

import '../helpers.dart';

/// SKILL.md A10.1, A10.2 ve A10.4 senaryoları.
void main() {
  const rules = KozMacaRules();

  group('A10.1 legalMoves', () {
    /// [hand], [table] ve [spadesBroken] verildiğinde beklenen kağıtlar.
    void check(
      String name, {
      required bool spadesBroken,
      required String table,
      required String hand,
      required String expected,
    }) {
      test('$name — el: $hand, masa: ${table.isEmpty ? '—' : table}', () {
        final actual = rules.legalMoves(
          cards(hand),
          cards(table),
          spadesBroken,
        );
        expect(canon(actual), canon(cards(expected)));
      });
    }

    // Koz kırılmadan maça açılmaz, ama elde başka kağıt yoksa açılır.
    check('L1', spadesBroken: false, table: '', hand: 'SA S5 H3', expected: 'H3');
    check('L2', spadesBroken: false, table: '', hand: 'SA S5', expected: 'SA S5');
    check('L3', spadesBroken: true, table: '', hand: 'SA H3', expected: 'SA H3');

    // Renge uyarken büyütme zorunluluğu.
    check('L4', spadesBroken: false, table: 'C6', hand: 'C3 C7 C8 HK', expected: 'C7 C8');
    check('L5', spadesBroken: false, table: 'C6 C8', hand: 'C2 C4 SK', expected: 'C2 C4');
    check('L6', spadesBroken: true, table: 'H7 S4 H9', hand: 'H6 H10 S5', expected: 'H10');

    // Renk yokken koz zorunlu, yerdeki kozu geçebiliyorsan geçmek zorunlu.
    check('L7', spadesBroken: true, table: 'D8 S4 D10', hand: 'S2 S6 CK', expected: 'S6');
    check('L8', spadesBroken: true, table: 'D8 S9', hand: 'S2 S6 CK', expected: 'S2 S6');
    check('L9', spadesBroken: false, table: 'D8', hand: 'CK H2', expected: 'CK H2');

    // Koz açıldığında kural 1 maça için çalışır.
    check('L10', spadesBroken: true, table: 'S5', hand: 'S3 SJ HA', expected: 'SJ');
    check('L11', spadesBroken: true, table: 'SQ', hand: 'S3 SJ HA', expected: 'S3 SJ');

    // Elde tek koz varsa koz atmak zorunlu; koz kırılmamış olması engel değil.
    check('L12', spadesBroken: false, table: 'D8', hand: 'S2 CK', expected: 'S2');
  });

  group('A10.2 eli kim alır', () {
    void check(String name, String codes, int expected) {
      test('$name — $codes', () {
        expect(rules.trickWinner(trickOf(codes)), expected);
      });
    }

    check('W1', 'H7 S4 HA S9', 3);
    check('W2', 'C6 C8 HA C2', 1);
    check('W3', 'S2 HA DA CA', 0);
    check('W4', 'D5 DK S3 DA', 2);
  });

  group('A10.4 puanlama', () {
    void check(String name, {required int yan, required int bid, required int taken, required int expected}) {
      test('$name — Y=$yan b=$bid t=$taken', () {
        expect(rules.scoreRound(bid: bid, taken: taken, yan: yan), expected);
      });
    }

    check('P1', yan: 2, bid: 0, taken: 0, expected: 50);
    check('P2', yan: 2, bid: 0, taken: 1, expected: -50);
    check('P3', yan: 2, bid: 5, taken: 5, expected: 50);
    check('P4', yan: 2, bid: 7, taken: 6, expected: -70);
    check('P5', yan: 2, bid: 9, taken: 7, expected: -90);
    check('P6', yan: 2, bid: 7, taken: 8, expected: 71);
    check('P7', yan: 2, bid: 7, taken: 9, expected: -90);
    check('P8', yan: 2, bid: 13, taken: 13, expected: 130);
    check('P9', yan: 2, bid: 1, taken: 0, expected: -10);
    check('P10', yan: 1, bid: 7, taken: 8, expected: -80);
    check('P11', yan: 3, bid: 7, taken: 8, expected: 72);
    check('P12', yan: 3, bid: 7, taken: 9, expected: 72);
    check('P13', yan: 3, bid: 7, taken: 10, expected: -100);
  });
}
