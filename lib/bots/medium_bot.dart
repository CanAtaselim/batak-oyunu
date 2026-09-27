import 'dart:math';

import '../engine/models/card.dart';
import '../engine/models/player_view.dart';
import '../engine/models/suit.dart';
import '../engine/rules/variant_rules.dart';
import '../engine/variants/koz_maca/koz_maca_rules.dart';
import 'bot.dart';
import 'bot_helpers.dart';

/// Orta bot: elini puanlayarak tahmin eder, oynarken "AL / ALMA" modu güder.
///
/// Mod kuralı: `taken >= bid` ya da `bid == 0` ise ALMA, aksi halde AL
/// (`PlayerView.wantsTricks`).
final class MediumBot implements Bot {
  MediumBot(this.random, {this.rules = const KozMacaRules()});

  final Random random;
  final VariantRules rules;

  @override
  String get name => 'medium';

  // ------------------------------------------------------------------ tahmin

  @override
  int chooseBid(PlayerView view) {
    if (_isZeroHand(view)) return 0;
    final int floored = _bidScore(view).floor();
    return floored < 1 ? 1 : (floored > 13 ? 13 : floored);
  }

  /// `floor` bilinçli bir temkin payıdır: yan batar yüzünden fazla almak,
  /// eksik almaktan daha tehlikelidir.
  double _bidScore(PlayerView view) {
    final hand = view.hand;
    final trump = view.trump;
    final counts = suitCounts(hand);
    final trumpCards = ofSuit(hand, trump);
    var score = 0.0;

    // Koz: A, K, Q her biri +1.
    var trumpHonors = 0;
    for (final rank in const [14, 13, 12]) {
      if (trumpCards.any((c) => c.rank == rank)) {
        score += 1;
        trumpHonors++;
      }
    }
    // Koz uzunluğu: 3'ten fazla her koz +1.
    final trumpCount = counts[trump]!;
    if (trumpCount > 3) score += trumpCount - 3;

    // Diğer türler: A +1, (K ve o türde en az 2 kağıt) +0.5.
    for (final suit in Suit.values) {
      if (suit == trump) continue;
      final cards = ofSuit(hand, suit);
      if (cards.any((c) => c.rank == 14)) score += 1;
      if (cards.any((c) => c.rank == 13) && cards.length >= 2) score += 0.5;
    }

    // Kesme potansiyeli, kozun kaç el tutabileceğiyle sınırlı.
    var ruffBonus = 0.0;
    for (final suit in Suit.values) {
      if (suit == trump) continue;
      final n = counts[suit]!;
      if (n == 0) {
        ruffBonus += 1;
      } else if (n == 1) {
        ruffBonus += 0.5;
      }
    }
    final trumpTricks = trumpCount < 3 ? trumpCount : 3;
    final ruffCap =
        trumpTricks - trumpHonors < 0 ? 0.0 : (trumpTricks - trumpHonors).toDouble();
    score += ruffBonus < ruffCap ? ruffBonus : ruffCap;

    return score;
  }

  /// Sıfır koşulu: hiçbir türde A ya da K yok, en fazla 2 maça var ve hepsi ≤ 9,
  /// diğer üç türün her birinde ≤ 6 olan en az bir kağıt var.
  bool _isZeroHand(PlayerView view) {
    final hand = view.hand;
    final trump = view.trump;
    if (hand.any((c) => c.rank >= 13)) return false;

    final trumpCards = ofSuit(hand, trump);
    if (trumpCards.length > 2) return false;
    if (trumpCards.any((c) => c.rank > 9)) return false;

    for (final suit in Suit.values) {
      if (suit == trump) continue;
      final cards = ofSuit(hand, suit);
      if (!cards.any((c) => c.rank <= 6)) return false;
    }
    return true;
  }

  // ------------------------------------------------------------------- oyun

  @override
  PlayingCard chooseCard(PlayerView view) {
    final legal = view.legalCards;
    if (legal.length == 1) return legal.first;
    return view.isLeading ? _lead(view) : _follow(view);
  }

  /// El açarken (masa boş).
  PlayingCard _lead(PlayerView view) {
    final legal = view.legalCards;
    final others = nonTrump(legal, view.trump);

    // Geçerli kağıtların hepsi koz ise.
    if (others.isEmpty) {
      return view.wantsTricks ? legal.highest : legal.lowest;
    }

    // ALMA: koz olmayanların en küçüğü.
    if (!view.wantsTricks) return others.lowest;

    // AL: koz olmayan bir As varsa onu at.
    final aces = others.where((c) => c.rank == 14).toList();
    if (aces.isNotEmpty) return aces.lowest;

    // Yoksa koz olmayan en uzun türün en küçüğü; eşitlikte küçük kağıdı daha
    // küçük olan tür.
    List<PlayingCard>? bestSuit;
    for (final suit in Suit.values) {
      if (suit == view.trump) continue;
      final cards = ofSuit(others, suit);
      if (cards.isEmpty) continue;
      if (bestSuit == null ||
          cards.length > bestSuit.length ||
          (cards.length == bestSuit.length &&
              compareByRank(cards.lowest, bestSuit.lowest) < 0)) {
        bestSuit = cards;
      }
    }
    return bestSuit!.lowest;
  }

  /// Takip ederken (masa dolu).
  PlayingCard _follow(PlayerView view) {
    final legal = view.legalCards;
    final split = splitByOutcome(view, rules);

    if (view.wantsTricks) {
      // El zaten başkasında kalacak: en küçüğünü ver.
      if (split.winners.isEmpty) return legal.lowest;
      // Son oyuncuysan fazlasını harcamana gerek yok.
      if (view.isLastToPlay) return split.winners.lowest;
      // Kozla kesiyorsan en küçük yeterli; aynı türle büyütüyorsan en büyüğü.
      final cutting = view.led != view.trump &&
          split.winners.every((c) => c.suit == view.trump);
      return cutting ? split.winners.lowest : split.winners.highest;
    }

    // ALMA: güvenliyken büyük kağıttan kurtul.
    if (split.losers.isNotEmpty) return split.losers.highest;
    // Almak zorundaysan en azından büyük kağıdı elden çıkar.
    return legal.highest;
  }
}
