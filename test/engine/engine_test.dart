import 'dart:math';

import 'package:batak/engine/models/action.dart';
import 'package:batak/engine/models/game_config.dart';
import 'package:batak/engine/models/game_state.dart';
import 'package:batak/engine/rules/engine.dart';
import 'package:batak/engine/variants/koz_maca/koz_maca_rules.dart';
import 'package:test/test.dart';

import '../helpers.dart';

/// SKILL.md A10.3 ve A10.5 senaryoları, artı motor sözleşmesi.
void main() {
  final engine = Engine(const KozMacaRules());
  const config = GameConfig();

  /// `Random(seed).nextInt(4)` verilen dağıtıcıyı seçen ilk seed.
  int seedForDealer(int dealer) => Iterable<int>.generate(5000)
      .firstWhere((s) => Random(s).nextInt(GameState.seatCount) == dealer);

  /// Tahmin turunu sırayla tamamlar.
  GameState bidAll(GameState s, {int value = 3}) {
    var state = s;
    while (state.phase == Phase.bidding) {
      state = engine.apply(state, Bid(state.turn!, value));
    }
    return state;
  }

  group('A10.3 spadesBroken', () {
    test('S1 — yeni oyun elinin başında false', () {
      expect(engine.newGame(config, 42).spadesBroken, isFalse);
    });

    test('S2 — L12 hamlesinde ♠2 atılınca true', () {
      // 1. koltuk ♦8 ile açtı; 2. koltuğun elinde ♦ yok, tek kozu ♠2.
      final s = stateFor(
        hands: ['SA SK', 'H2 H3', 'S2 CK', 'D2 D3'],
        dealer: 0,
        table: 'D8',
      );
      expect(s.turn, 2);
      expect(engine.legalCardsFor(s, 2).map((c) => c.code), ['S2']);
      final after = engine.apply(s, PlayCard(2, c('S2')));
      expect(after.spadesBroken, isTrue);
    });

    test('S3 — elinde sadece maça olan oyuncu maça ile açtı, true', () {
      final s = stateFor(
        hands: ['H2 H3', 'S5 S9', 'D2 D3', 'C2 C3'],
        dealer: 0,
      );
      expect(s.turn, 1);
      expect(canon(engine.legalCardsFor(s, 1)), canon(cards('S5 S9')));
      expect(engine.apply(s, PlayCard(1, c('S9'))).spadesBroken, isTrue);
    });

    test('S4 — yeni oyun eli dağıtılınca yine false', () {
      var s = bidAll(engine.newGame(config, 42));
      s = autoPlay(engine, s, until: (x) => x.phase != Phase.playing);
      expect(s.phase, Phase.roundOver);
      expect(s.spadesBroken, isTrue, reason: '13 elde maça mutlaka atılır');
      expect(engine.apply(s, const NextRound()).spadesBroken, isFalse);
    });
  });

  group('A10.5 akış', () {
    test('F1 — dealer 2 iken tahmin sırası 3, 0, 1, 2 ve ilk eli 3 açar', () {
      final s = engine.newGame(config, seedForDealer(2));
      expect(s.dealer, 2);
      var state = s;
      for (final expectedSeat in [3, 0, 1, 2]) {
        expect(state.turn, expectedSeat);
        state = engine.apply(state, Bid(expectedSeat, 3));
      }
      expect(state.phase, Phase.playing);
      expect(state.trick.leader, 3);
      expect(state.turn, 3);
    });

    test('F1b — sırası gelmeyen oyuncu tahmin edemez', () {
      final s = engine.newGame(config, seedForDealer(2));
      expect(() => engine.apply(s, const Bid(0, 3)),
          throwsA(isA<IllegalActionException>()));
    });

    test('F2 — oyun eli bitti, dealer 3 iken yeni dealer 0', () {
      var s = bidAll(engine.newGame(config, seedForDealer(3)));
      expect(s.dealer, 3);
      s = autoPlay(engine, s, until: (x) => x.phase == Phase.roundOver);
      final next = engine.apply(s, const NextRound());
      expect(next.dealer, 0);
      expect(next.roundIndex, 1);
      expect(next.phase, Phase.bidding);
    });

    test('F3 — dağıtımdan sonra her elde 13 kağıt, 52 kağıt da farklı', () {
      for (final seed in [1, 7, 99, 12345]) {
        final s = engine.newGame(config, seed);
        for (var seat = 0; seat < GameState.seatCount; seat++) {
          expect(s.handOf(seat).length, 13);
        }
        final all = s.hands.expand((h) => h).toSet();
        expect(all.length, 52);
      }
    });

    test('F4 — 13 elden sonra alınan ellerin toplamı 13', () {
      var s = bidAll(engine.newGame(config, 2026));
      s = autoPlay(engine, s, until: (x) => x.phase == Phase.roundOver);
      expect(s.completedTricks.length, 13);
      expect(s.tricksTaken.reduce((a, b) => a + b), 13);
      expect(s.hands.every((h) => h.isEmpty), isTrue);
    });
  });

  group('motor sözleşmesi', () {
    test('aynı seed ve aksiyon listesi aynı duruma götürür', () {
      final a = engine.newGame(config, 555);
      final b = engine.newGame(config, 555);
      expect(a, b);
      final actions = <GameAction>[];
      var state = a;
      final rnd = Random(3);
      while (state.phase != Phase.roundOver) {
        final legal = engine.legalActions(state);
        final action = legal[rnd.nextInt(legal.length)];
        actions.add(action);
        state = engine.apply(state, action);
      }
      var replayed = b;
      for (final action in actions) {
        replayed = engine.apply(replayed, action);
      }
      expect(replayed, state);
    });

    test('tahmin turunda 0–13 arası her tahmin geçerli', () {
      final s = engine.newGame(config, 8);
      final actions = engine.legalActions(s);
      expect(actions.length, 14);
      expect(actions.whereType<Bid>().map((b) => b.value).toList(),
          List.generate(14, (i) => i));
    });

    test('elinde olmayan kağıt atılamaz', () {
      final s = stateFor(hands: ['H2', 'H3', 'H4', 'H5'], dealer: 0);
      expect(() => engine.apply(s, PlayCard(1, c('SA'))),
          throwsA(isA<IllegalActionException>()));
    });

    test('kurallara aykırı kağıt atılamaz', () {
      // Koz kırılmamış, elinde koz dışı kağıt var: maça açamaz.
      final s = stateFor(hands: ['H2', 'SA H3', 'H4', 'H5'], dealer: 0);
      expect(() => engine.apply(s, PlayCard(1, c('SA'))),
          throwsA(isA<IllegalActionException>()));
    });

    test('oyun eli bitmeden yeni dağıtım istenemez', () {
      final s = engine.newGame(config, 11);
      expect(() => engine.apply(s, const NextRound()),
          throwsA(isA<IllegalActionException>()));
    });

    test('son oyun eli puanlanınca durum gameOver olur', () {
      const short = GameConfig(roundCount: 2);
      var s = engine.newGame(short, 31);
      for (var round = 0; round < 2; round++) {
        s = bidAll(s);
        s = autoPlay(engine, s,
            until: (x) => x.phase == Phase.roundOver || x.phase == Phase.gameOver);
        if (round == 0) {
          expect(s.phase, Phase.roundOver);
          s = engine.apply(s, const NextRound());
        }
      }
      expect(s.phase, Phase.gameOver);
      expect(engine.legalActions(s), isEmpty);
      expect(s.winners, isNotEmpty);
    });

    test('puan toplamı oyun eli puanlarının toplamıdır', () {
      var s = bidAll(engine.newGame(config, 77), value: 3);
      s = autoPlay(engine, s, until: (x) => x.phase == Phase.roundOver);
      const rules = KozMacaRules();
      for (var seat = 0; seat < GameState.seatCount; seat++) {
        expect(
          s.scores[seat],
          rules.scoreRound(bid: 3, taken: s.tricksTaken[seat], yan: config.yan),
        );
      }
    });

    test('durum değişmez: apply eski durumu bozmaz', () {
      final s = bidAll(engine.newGame(config, 4));
      final handBefore = [...s.handOf(s.turn!)];
      final card = engine.legalCardsFor(s, s.turn!).first;
      engine.apply(s, PlayCard(s.turn!, card));
      expect(s.handOf(s.turn!), handBefore);
      expect(s.trick.plays, isEmpty);
    });

    test('PlayerView başka oyuncuların elini sızdırmaz', () {
      final s = bidAll(engine.newGame(config, 5));
      final view = engine.viewFor(s, 0);
      expect(view.hand, s.handOf(0));
      expect(view.seat, 0);
      expect(view.trump.symbol, '♠');
      // legalCards yalnızca sırası gelen oyuncu için dolu.
      final other = engine.viewFor(s, (s.turn! + 1) % 4);
      expect(other.legalCards, isEmpty);
    });
  });
}
