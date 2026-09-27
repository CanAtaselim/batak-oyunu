import '../engine/models/card.dart';
import '../engine/models/player_view.dart';
import '../engine/models/suit.dart';
import '../engine/rules/variant_rules.dart';

/// Botların ortak yardımcıları. Kural mantığı burada tekrar yazılmaz; eli kimin
/// aldığı sorusu her zaman [VariantRules.trickWinner]'a sorulur.
extension BotCardList on List<PlayingCard> {
  /// Değere göre en küçük kağıt. Eşitlikte tür sırası ♣ < ♦ < ♥ < ♠.
  PlayingCard get lowest => reduce((a, b) => compareByRank(a, b) <= 0 ? a : b);

  /// Değere göre en büyük kağıt. Eşitlikte tür sırası ♣ < ♦ < ♥ < ♠.
  PlayingCard get highest => reduce((a, b) => compareByRank(a, b) >= 0 ? a : b);
}

/// Önce değer, sonra tür (♣ < ♦ < ♥ < ♠). Botların seçimi deterministik kalsın.
int compareByRank(PlayingCard a, PlayingCard b) =>
    a.rank != b.rank ? a.rank - b.rank : a.suit.index - b.suit.index;

/// Masadaki kağıtlar arasında şu an eli alan kağıt. Masa boşsa null.
PlayingCard? currentWinnerCard(PlayerView view, VariantRules rules) {
  if (view.currentTrick.isEmpty) return null;
  final seat = rules.trickWinner(view.currentTrick);
  return view.currentTrick.cardOf(seat);
}

/// [card] masaya eklendiğinde eli o mu alır?
bool wouldWin(PlayerView view, VariantRules rules, PlayingCard card) {
  final trick = view.currentTrick.add(view.seat, card);
  return rules.trickWinner(trick) == view.seat;
}

/// Geçerli kağıtları "şu an eli alanlar" ve "almayanlar" diye ikiye böler.
({List<PlayingCard> winners, List<PlayingCard> losers}) splitByOutcome(
  PlayerView view,
  VariantRules rules,
) {
  final winners = <PlayingCard>[];
  final losers = <PlayingCard>[];
  for (final card in view.legalCards) {
    (wouldWin(view, rules, card) ? winners : losers).add(card);
  }
  return (winners: winners, losers: losers);
}

/// Bir türdeki kağıtlar.
List<PlayingCard> ofSuit(Iterable<PlayingCard> cards, Suit suit) =>
    [for (final c in cards) if (c.suit == suit) c];

/// Koz olmayan kağıtlar.
List<PlayingCard> nonTrump(Iterable<PlayingCard> cards, Suit trump) =>
    [for (final c in cards) if (c.suit != trump) c];

/// Bir eldeki tür başına kağıt sayısı.
Map<Suit, int> suitCounts(Iterable<PlayingCard> hand) {
  final counts = {for (final s in Suit.values) s: 0};
  for (final card in hand) {
    counts[card.suit] = counts[card.suit]! + 1;
  }
  return counts;
}
