import 'dart:math';

import 'package:batak/bots/easy_bot.dart';
import 'package:batak/engine/models/action.dart';
import 'package:batak/engine/models/card.dart';
import 'package:batak/engine/models/game_config.dart';
import 'package:batak/engine/models/game_state.dart';
import 'package:batak/engine/rules/engine.dart';
import 'package:batak/engine/save/save_game.dart';
import 'package:test/test.dart';

/// SKILL.md değişmezleri (I1–I4). Seed'li rastgele oyunlar, botlar Kolay.
void main() {
  final engine = Engine.forConfig(const GameConfig());

  /// I2 — eldeki, masadaki ve oynanmış kağıtların birleşimi tam 52 farklı kağıt.
  void checkFullDeck(GameState s) {
    final all = <PlayingCard>[
      for (final hand in s.hands) ...hand,
      ...s.trick.cards,
      for (final t in s.completedTricks) ...t.cards,
    ];
    expect(all.length, 52, reason: 'kağıt sayısı 52 değil: $s');
    expect(all.toSet().length, 52, reason: 'kağıt tekrarı var: $s');
  }

  /// Tek bir oyunu baştan sona oynatır ve her adımda değişmezleri denetler.
  ({GameState state, List<GameAction> actions}) playGame(
    int seed,
    GameConfig config,
  ) {
    final bots = [for (var i = 0; i < 4; i++) EasyBot(Random(seed * 4 + i))];
    final actions = <GameAction>[];
    var state = engine.newGame(config, seed);
    checkFullDeck(state);

    var guard = 0;
    while (state.phase != Phase.gameOver) {
      final legal = engine.legalActions(state);
      expect(legal, isNotEmpty, reason: 'geçerli aksiyon yok: $state');

      final GameAction action;
      switch (state.phase) {
        case Phase.bidding:
          final seat = state.turn!;
          final bid = bots[seat].chooseBid(engine.viewFor(state, seat));
          action = Bid(seat, bid);
        case Phase.playing:
          final seat = state.turn!;
          final view = engine.viewFor(state, seat);
          final card = bots[seat].chooseCard(view);
          // I1 — botun seçtiği kağıt her zaman legalCards içinde.
          expect(view.legalCards, contains(card));
          action = PlayCard(seat, card);
        case Phase.roundOver:
          action = const NextRound();
        case Phase.gameOver:
          return (state: state, actions: actions);
      }

      // I1 — aksiyon legalActions içinde ve apply hata fırlatmıyor.
      expect(legal, contains(action), reason: '$action geçerli değil: $state');
      actions.add(action);
      state = engine.apply(state, action);
      checkFullDeck(state);

      // I3 — her oyun elinin sonunda tricksTaken toplamı 13.
      if (state.phase == Phase.roundOver || state.phase == Phase.gameOver) {
        expect(state.tricksTaken.reduce((a, b) => a + b), 13,
            reason: 'oyun eli sonunda 13 el olmalı: $state');
        expect(state.completedTricks.length, 13);
      }

      if (++guard > 20000) fail('oyun ilerlemiyor: $state');
    }
    return (state: state, actions: actions);
  }

  test('I1–I3 — 1000 seed\'li oyunda değişmezler korunur', () {
    // Oyun eli sayısı 3: 1000 oyun makul sürede bitsin. Tam uzunluktaki oyun
    // aşağıda ayrıca sınanıyor.
    const config = GameConfig(roundCount: 3, botLevel: BotLevel.easy);
    for (var seed = 0; seed < 1000; seed++) {
      final result = playGame(seed, config);
      expect(result.state.phase, Phase.gameOver);
      expect(result.state.winners, isNotEmpty);
    }
  }, timeout: const Timeout(Duration(minutes: 5)));

  test('I1–I3 — tam uzunlukta (11 oyun eli) oyunlar', () {
    const config = GameConfig(botLevel: BotLevel.easy);
    for (var seed = 5000; seed < 5020; seed++) {
      final result = playGame(seed, config);
      expect(result.state.phase, Phase.gameOver);
      expect(result.actions.whereType<NextRound>().length, 10);
    }
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('I4 — kayıt JSON\'a yazılıp geri okunduğunda aynı durumu verir', () {
    const config = GameConfig(roundCount: 3, botLevel: BotLevel.easy);
    for (var seed = 100; seed < 130; seed++) {
      final result = playGame(seed, config);
      final save = SaveGame(config: config, seed: seed, actions: result.actions);
      final decoded = SaveGame.decode(save.encode());
      expect(decoded, isNotNull, reason: 'kayıt okunamadı');
      final replayed = decoded!.replay();
      expect(replayed, isNotNull, reason: 'kayıt oynatılamadı');
      expect(replayed, result.state);
      expect(replayed!.scores, result.state.scores);
    }
  }, timeout: const Timeout(Duration(minutes: 2)));
}
