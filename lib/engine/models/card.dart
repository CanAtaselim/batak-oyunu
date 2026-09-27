import 'dart:math';

import 'suit.dart';

/// Tek bir oyun kağıdı. Flutter'ın `Card` widget'ıyla karışmasın diye
/// sınıf adı `PlayingCard`.
///
/// [rank] 2–14 arasındadır: J=11, Q=12, K=13, A=14.
final class PlayingCard implements Comparable<PlayingCard> {
  const PlayingCard(this.suit, this.rank)
      : assert(rank >= 2 && rank <= 14, 'rank 2-14 arasında olmalı');

  final Suit suit;
  final int rank;

  static const int minRank = 2;
  static const int maxRank = 14;

  /// Kayıt formatındaki kod: `SA`, `H10`, `D2`.
  String get code => '${suit.code}$rankCode';

  /// Değerin harf/rakam gösterimi: `2`–`10`, `J`, `Q`, `K`, `A`.
  String get rankCode => switch (rank) {
        11 => 'J',
        12 => 'Q',
        13 => 'K',
        14 => 'A',
        _ => '$rank',
      };

  /// Türkçe değer gösterimi: `V` (Vale), `K` (Kız), `P` (Papaz), `A` (As).
  String get rankCodeTr => switch (rank) {
        11 => 'V',
        12 => 'K',
        13 => 'P',
        14 => 'A',
        _ => '$rank',
      };

  static PlayingCard parse(String code) {
    if (code.length < 2) throw ArgumentError('Geçersiz kağıt kodu: $code');
    final suit = Suit.fromCode(code.substring(0, 1));
    final rankPart = code.substring(1);
    final rank = switch (rankPart) {
      'J' => 11,
      'Q' => 12,
      'K' => 13,
      'A' => 14,
      _ => int.tryParse(rankPart) ?? -1,
    };
    if (rank < minRank || rank > maxRank) {
      throw ArgumentError('Geçersiz kağıt kodu: $code');
    }
    return PlayingCard(suit, rank);
  }

  /// 52 kağıdın tamamı, sabit sırada (♣2..♣A, ♦2.., ♥2.., ♠2..♠A).
  static List<PlayingCard> fullDeck() => [
        for (final suit in Suit.values)
          for (var rank = minRank; rank <= maxRank; rank++)
            PlayingCard(suit, rank),
      ];

  /// Rastgeleliği dışarıdan alır; testlerde sabit seed ile tekrarlanabilir.
  static List<PlayingCard> shuffled(Random random) =>
      fullDeck()..shuffle(random);

  /// Önce tür (♣ < ♦ < ♥ < ♠), sonra değer. Kural değil, deterministik sıra.
  @override
  int compareTo(PlayingCard other) => suit.index != other.suit.index
      ? suit.index - other.suit.index
      : rank - other.rank;

  @override
  bool operator ==(Object other) =>
      other is PlayingCard && other.suit == suit && other.rank == rank;

  @override
  int get hashCode => suit.index * 100 + rank;

  @override
  String toString() => '${suit.symbol}$rankCode';
}
