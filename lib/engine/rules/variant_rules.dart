import '../models/card.dart';
import '../models/suit.dart';
import '../models/trick.dart';

/// Varyanta özgü kurallar. Ortak akış (dağıt → tahmin → 13 el → puanla) bu
/// arayüzün arkasındaki farklarla çalışır. İlk uygulama Koz Maça'dır.
abstract interface class VariantRules {
  /// Kayıt formatındaki varyant kodu.
  String get code;

  /// Bu dağıtımın kozu. Koz Maça'da her zaman ♠.
  Suit get trump;

  /// Atılabilecek kağıtlar. Motorun, arayüzün ve botların tek kaynağı.
  List<PlayingCard> legalMoves(
    List<PlayingCard> hand,
    List<PlayingCard> table,
    bool spadesBroken,
  );

  /// Tamamlanmış eli kimin aldığı.
  int trickWinner(Trick trick);

  /// Söylenebilecek tahminler.
  List<int> validBids();

  /// Bir oyun elinin sonunda tek oyuncunun puanı.
  int scoreRound({required int bid, required int taken, required int yan});

  /// Bu kağıt atılınca koz kırılır mı.
  bool breaksTrump(PlayingCard card);
}
