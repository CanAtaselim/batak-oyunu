import 'dart:math';

import '../../models/card.dart';
import '../../models/suit.dart';
import '../../models/trick.dart';
import '../../rules/variant_rules.dart';

/// Koz Maça (tekli) kuralları — SKILL.md Bölüm A.
///
/// Koz her zaman ♠'dır ve dağıtımdan dağıtıma değişmez. İhale yarışı yoktur,
/// herkes kendi tahminini söyler.
final class KozMacaRules implements VariantRules {
  const KozMacaRules();

  @override
  String get code => 'kozMaca';

  @override
  Suit get trump => Suit.spades;

  @override
  bool breaksTrump(PlayingCard card) => card.suit == Suit.spades;

  @override
  List<int> validBids() => [for (var b = 0; b <= 13; b++) b];

  /// A4 — kağıt atma kuralları.
  @override
  List<PlayingCard> legalMoves(
    List<PlayingCard> hand,
    List<PlayingCard> table,
    bool spadesBroken,
  ) {
    // A4.1 — el açma.
    if (table.isEmpty) {
      final nonSpades = hand.where((c) => c.suit != Suit.spades).toList();
      if (!spadesBroken && nonSpades.isNotEmpty) return nonSpades;
      return List.of(hand);
    }

    // A4.2 — takip etme.
    final led = table.first.suit;
    final sameSuit = hand.where((c) => c.suit == led).toList();
    if (sameSuit.isNotEmpty) {
      // El kozla kesildiyse yükseltme zorunluluğu kalkar: el artık kozdadır,
      // açılan türden hiçbir kağıt eli alamaz.
      final trumped =
          led != Suit.spades && table.any((c) => c.suit == Suit.spades);
      if (trumped) return sameSuit;

      final topLed =
          table.where((c) => c.suit == led).map((c) => c.rank).reduce(max);
      final higher = sameSuit.where((c) => c.rank > topLed).toList();
      return higher.isNotEmpty ? higher : sameSuit;
    }

    final spades = hand.where((c) => c.suit == Suit.spades).toList();
    if (spades.isNotEmpty) {
      final tableSpades = table.where((c) => c.suit == Suit.spades);
      if (tableSpades.isNotEmpty) {
        final topSpade = tableSpades.map((c) => c.rank).reduce(max);
        final higher = spades.where((c) => c.rank > topSpade).toList();
        if (higher.isNotEmpty) return higher;
      }
      return spades;
    }

    return List.of(hand);
  }

  /// A5 — eli kim alır.
  @override
  int trickWinner(Trick trick) {
    if (trick.plays.isEmpty) {
      throw StateError('Boş el kazanılamaz');
    }
    final led = trick.plays.first.card.suit;
    Play? best;
    for (final play in trick.plays) {
      if (best == null) {
        best = play;
        continue;
      }
      if (_beats(play.card, best.card, led)) best = play;
    }
    return best!.seat;
  }

  /// [candidate] masadaki [current] kağıdı geçiyor mu?
  bool _beats(PlayingCard candidate, PlayingCard current, Suit led) {
    final candidateTrump = candidate.suit == Suit.spades;
    final currentTrump = current.suit == Suit.spades;
    if (candidateTrump != currentTrump) return candidateTrump;
    if (candidateTrump) return candidate.rank > current.rank;
    // Koz yok: yalnızca açılan tür değer taşır.
    if (candidate.suit != led) return false;
    if (current.suit != led) return true;
    return candidate.rank > current.rank;
  }

  /// A6 — puanlama.
  @override
  int scoreRound({required int bid, required int taken, required int yan}) {
    if (bid == 0) return taken == 0 ? 50 : -50;
    if (taken < bid) return -10 * bid;
    if (taken == bid) return 10 * bid;
    if (taken - bid >= yan) return -10 * taken;
    return 10 * bid + (yan - 1);
  }
}
