import 'card.dart';

/// Motorun kabul ettiği aksiyonlar. Başka bir yoldan durum değiştirilemez.
sealed class GameAction {
  const GameAction();

  /// Kayıt formatındaki JSON gösterimi.
  List<Object> toJson();
}

/// Tahmin söylemek.
final class Bid extends GameAction {
  const Bid(this.seat, this.value);

  final int seat;
  final int value;

  @override
  List<Object> toJson() => ['B', seat, value];

  @override
  bool operator ==(Object other) =>
      other is Bid && other.seat == seat && other.value == value;

  @override
  int get hashCode => Object.hash('B', seat, value);

  @override
  String toString() => 'Bid($seat, $value)';
}

/// Kağıt atmak.
final class PlayCard extends GameAction {
  const PlayCard(this.seat, this.card);

  final int seat;
  final PlayingCard card;

  @override
  List<Object> toJson() => ['P', seat, card.code];

  @override
  bool operator ==(Object other) =>
      other is PlayCard && other.seat == seat && other.card == card;

  @override
  int get hashCode => Object.hash('P', seat, card);

  @override
  String toString() => 'PlayCard($seat, ${card.code})';
}

/// Puan tablosu gösterildikten sonra yeni dağıtım.
final class NextRound extends GameAction {
  const NextRound();

  @override
  List<Object> toJson() => ['N'];

  @override
  bool operator ==(Object other) => other is NextRound;

  @override
  int get hashCode => 'N'.hashCode;

  @override
  String toString() => 'NextRound()';
}

/// Kurallara aykırı bir aksiyon [Engine.apply]'a verildiğinde fırlatılır.
final class IllegalActionException implements Exception {
  const IllegalActionException(this.message);

  final String message;

  @override
  String toString() => 'IllegalActionException: $message';
}
