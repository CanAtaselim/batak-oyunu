import 'dart:math';

import '../models/action.dart';
import '../models/card.dart';
import '../models/game_config.dart';
import '../models/game_state.dart';
import '../models/player_view.dart';
import '../models/trick.dart';
import '../variants/koz_maca/koz_maca_rules.dart';
import 'variant_rules.dart';

/// Aksiyon uygulayan saf motor. Zamanlama, gecikme ve animasyon bilmez.
///
/// Determinizm: aynı `config`, `seed` ve aksiyon listesi her zaman aynı
/// [GameState]'i üretir. Motor `DateTime` ya da global `Random()` kullanmaz.
final class Engine {
  const Engine(this.rules);

  /// Varyanta göre doğru kural setini seçer.
  factory Engine.forConfig(GameConfig config) => Engine(switch (config.variant) {
        Variant.kozMaca => const KozMacaRules(),
      });

  final VariantRules rules;

  // ---------------------------------------------------------------- yeni oyun

  GameState newGame(GameConfig config, int seed) => _deal(
        config: config,
        seed: seed,
        roundIndex: 0,
        dealer: Random(seed).nextInt(GameState.seatCount),
        scores: const [0, 0, 0, 0],
      );

  /// Bir oyun elini dağıtır. `r` numaralı elin destesi `Random(seed + r)` ile
  /// karıştırılır.
  GameState _deal({
    required GameConfig config,
    required int seed,
    required int roundIndex,
    required int dealer,
    required List<int> scores,
    List<int>? lastRoundScores,
  }) {
    final deck = PlayingCard.shuffled(Random(seed + roundIndex));
    final hands = <List<PlayingCard>>[];
    for (var seat = 0; seat < GameState.seatCount; seat++) {
      final hand = deck.sublist(
        seat * GameState.tricksPerRound,
        (seat + 1) * GameState.tricksPerRound,
      )..sort();
      hands.add(hand);
    }
    return GameState(
      config: config,
      seed: seed,
      roundIndex: roundIndex,
      dealer: dealer,
      phase: Phase.bidding,
      hands: hands,
      bids: const [null, null, null, null],
      tricksTaken: const [0, 0, 0, 0],
      scores: scores,
      // İlk eli dağıtıcının sağındaki oyuncu açar (A5).
      trick: Trick(leader: GameState.next(dealer)),
      completedTricks: const [],
      spadesBroken: false,
      lastRoundScores: lastRoundScores,
    );
  }

  // ------------------------------------------------------------------ aksiyon

  /// Aksiyonu uygular. Geçersizse [IllegalActionException] fırlatır.
  GameState apply(GameState s, GameAction action) => switch (action) {
        Bid() => _applyBid(s, action),
        PlayCard() => _applyPlay(s, action),
        NextRound() => _applyNextRound(s),
      };

  GameState _applyBid(GameState s, Bid action) {
    if (s.phase != Phase.bidding) {
      throw IllegalActionException('Tahmin turu değil: ${s.phase}');
    }
    if (action.seat != s.turn) {
      throw IllegalActionException(
          'Sıra ${s.turn} koltuğunda, ${action.seat} tahmin edemez');
    }
    if (!rules.validBids().contains(action.value)) {
      throw IllegalActionException('Geçersiz tahmin: ${action.value}');
    }
    final bids = List<int?>.of(s.bids)..[action.seat] = action.value;
    final allBidsIn = bids.every((b) => b != null);
    return s.copyWith(
      bids: bids,
      phase: allBidsIn ? Phase.playing : Phase.bidding,
    );
  }

  GameState _applyPlay(GameState s, PlayCard action) {
    if (s.phase != Phase.playing) {
      throw IllegalActionException('Kağıt atma turu değil: ${s.phase}');
    }
    if (action.seat != s.turn) {
      throw IllegalActionException(
          'Sıra ${s.turn} koltuğunda, ${action.seat} atamaz');
    }
    final hand = s.handOf(action.seat);
    if (!hand.contains(action.card)) {
      throw IllegalActionException(
          '${action.card.code} ${action.seat} koltuğunun elinde yok');
    }
    final legal = rules.legalMoves(hand, s.trick.cards, s.spadesBroken);
    if (!legal.contains(action.card)) {
      throw IllegalActionException('${action.card.code} kurallara aykırı');
    }

    final hands = [
      for (var seat = 0; seat < GameState.seatCount; seat++)
        seat == action.seat
            ? [for (final c in s.hands[seat]) if (c != action.card) c]
            : s.hands[seat],
    ];
    final trick = s.trick.add(action.seat, action.card);
    final spadesBroken = s.spadesBroken || rules.breaksTrump(action.card);

    if (!trick.isComplete) {
      return s.copyWith(hands: hands, trick: trick, spadesBroken: spadesBroken);
    }

    // 4. kağıt atıldı: el hemen sonuçlanır, motor animasyon beklemez.
    final winner = rules.trickWinner(trick);
    final finished = trick.withWinner(winner);
    final tricksTaken = List<int>.of(s.tricksTaken)..[winner] += 1;
    final completed = [...s.completedTricks, finished];

    final afterTrick = s.copyWith(
      hands: hands,
      tricksTaken: tricksTaken,
      completedTricks: completed,
      spadesBroken: spadesBroken,
      lastTrick: finished,
      // Eli alan oyuncu bir sonraki eli açar.
      trick: Trick(leader: winner),
    );

    if (completed.length < GameState.tricksPerRound) return afterTrick;
    return _scoreRound(afterTrick);
  }

  /// 13. el bitti: puanları ekle, durumu `roundOver` ya da `gameOver` yap.
  GameState _scoreRound(GameState s) {
    final roundScores = [
      for (var seat = 0; seat < GameState.seatCount; seat++)
        rules.scoreRound(
          bid: s.bids[seat]!,
          taken: s.tricksTaken[seat],
          yan: s.config.yan,
        ),
    ];
    final scores = [
      for (var seat = 0; seat < GameState.seatCount; seat++)
        s.scores[seat] + roundScores[seat],
    ];
    final isLastRound = s.roundIndex >= s.config.roundCount - 1;
    return s.copyWith(
      scores: scores,
      lastRoundScores: roundScores,
      phase: isLastRound ? Phase.gameOver : Phase.roundOver,
    );
  }

  GameState _applyNextRound(GameState s) {
    if (s.phase != Phase.roundOver) {
      throw IllegalActionException(
          'Yeni dağıtım için oyun elinin bitmesi gerekir: ${s.phase}');
    }
    return _deal(
      config: s.config,
      seed: s.seed,
      roundIndex: s.roundIndex + 1,
      dealer: GameState.next(s.dealer),
      scores: s.scores,
      lastRoundScores: s.lastRoundScores,
    );
  }

  // ------------------------------------------------------------------- sorgu

  /// Sıradaki oyuncunun yapabileceği aksiyonlar. Arayüz, botlar ve [apply]
  /// aynı kaynaktan beslenir.
  List<GameAction> legalActions(GameState s) {
    final seat = s.turn;
    return switch (s.phase) {
      Phase.bidding => [for (final b in rules.validBids()) Bid(seat!, b)],
      Phase.playing => [
          for (final c in legalCardsFor(s, seat!)) PlayCard(seat, c),
        ],
      Phase.roundOver => const [NextRound()],
      Phase.gameOver => const [],
    };
  }

  /// [seat] koltuğunun şu an atabileceği kağıtlar. Sırası değilse boş liste.
  List<PlayingCard> legalCardsFor(GameState s, int seat) {
    if (s.phase != Phase.playing || s.turn != seat) return const [];
    return rules.legalMoves(s.handOf(seat), s.trick.cards, s.spadesBroken);
  }

  /// Bir oyuncunun görebildiği durum.
  PlayerView viewFor(GameState s, int seat) => PlayerView(
        seat: seat,
        hand: s.handOf(seat),
        legalCards: legalCardsFor(s, seat),
        currentTrick: s.trick,
        completedTricks: s.completedTricks,
        bids: s.bids,
        tricksTaken: s.tricksTaken,
        dealer: s.dealer,
        trump: rules.trump,
        spadesBroken: s.spadesBroken,
        scores: s.scores,
        roundIndex: s.roundIndex,
        config: s.config,
      );
}
