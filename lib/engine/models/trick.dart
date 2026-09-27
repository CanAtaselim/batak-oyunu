import 'card.dart';
import 'suit.dart';

/// Bir oyuncunun bir eldeki tek hamlesi.
final class Play {
  const Play(this.seat, this.card);

  final int seat;
  final PlayingCard card;

  @override
  bool operator ==(Object other) =>
      other is Play && other.seat == seat && other.card == card;

  @override
  int get hashCode => Object.hash(seat, card);

  @override
  String toString() => '$seat:${card.code}';
}

/// Dört kağıdın atıldığı bir tur. [plays] atılma sırasındadır.
final class Trick {
  Trick({required this.leader, List<Play> plays = const [], this.winner})
      : plays = List.unmodifiable(plays);

  /// Eli açan koltuk.
  final int leader;

  /// Atılma sırasıyla hamleler.
  final List<Play> plays;

  /// El tamamlanıp sonuçlanınca dolar, öncesinde null.
  final int? winner;

  static const int seatCount = 4;

  /// Açılan tür. Masa boşsa null.
  Suit? get led => plays.isEmpty ? null : plays.first.card.suit;

  List<PlayingCard> get cards => [for (final p in plays) p.card];

  bool get isEmpty => plays.isEmpty;

  bool get isComplete => plays.length == seatCount;

  /// Sırası gelen koltuk. El tamamlanmışsa null.
  int? get turn =>
      isComplete ? null : (leader + plays.length) % seatCount;

  PlayingCard? cardOf(int seat) {
    for (final p in plays) {
      if (p.seat == seat) return p.card;
    }
    return null;
  }

  Trick add(int seat, PlayingCard card) => Trick(
        leader: leader,
        plays: [...plays, Play(seat, card)],
      );

  Trick withWinner(int seat) =>
      Trick(leader: leader, plays: plays, winner: seat);

  @override
  String toString() => 'Trick(leader: $leader, ${plays.join(' ')}'
      '${winner == null ? '' : ' -> $winner'})';
}
