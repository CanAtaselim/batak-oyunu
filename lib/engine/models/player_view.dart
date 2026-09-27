import 'card.dart';
import 'game_config.dart';
import 'suit.dart';
import 'trick.dart';

/// Bir oyuncunun görebildiği her şey — ve yalnızca o kadarı.
///
/// Botlar kararlarını bu sınıftan verir. Başka oyuncuların eli burada yoktur ve
/// olamaz; bot `GameState`'e hiçbir yoldan erişemez.
final class PlayerView {
  PlayerView({
    required this.seat,
    required List<PlayingCard> hand,
    required List<PlayingCard> legalCards,
    required this.currentTrick,
    required List<Trick> completedTricks,
    required List<int?> bids,
    required List<int> tricksTaken,
    required this.dealer,
    required this.trump,
    required this.spadesBroken,
    required List<int> scores,
    required this.roundIndex,
    required this.config,
  })  : hand = List.unmodifiable(hand),
        legalCards = List.unmodifiable(legalCards),
        completedTricks = List.unmodifiable(completedTricks),
        bids = List.unmodifiable(bids),
        tricksTaken = List.unmodifiable(tricksTaken),
        scores = List.unmodifiable(scores);

  /// Bu görünümün sahibi.
  final int seat;

  final List<PlayingCard> hand;

  /// Şu an atılabilecek kağıtlar. Bot dönüş değerini buradan seçmek zorundadır.
  final List<PlayingCard> legalCards;

  /// Masadaki el: kim neyi attı.
  final Trick currentTrick;

  /// Bu oyun elinde oynanmış tüm eller, sırasıyla.
  final List<Trick> completedTricks;

  /// Koltuk başına tahmin; henüz söylenmemiş olan null.
  final List<int?> bids;

  final List<int> tricksTaken;
  final int dealer;
  final Suit trump;
  final bool spadesBroken;
  final List<int> scores;
  final int roundIndex;
  final GameConfig config;

  /// Bu oyuncunun tahmini; henüz söylememişse null.
  int? get myBid => bids[seat];

  /// Bu oyuncunun aldığı el sayısı.
  int get myTricks => tricksTaken[seat];

  /// Masadaki kağıtlar, atılma sırasıyla.
  List<PlayingCard> get table => currentTrick.cards;

  /// Açılan tür; masa boşsa null.
  Suit? get led => currentTrick.led;

  /// Bu oyuncu eli açıyor mu.
  bool get isLeading => currentTrick.isEmpty;

  /// Bu elde atılacak son kağıt bu mu (4. sıradaysa).
  bool get isLastToPlay => currentTrick.plays.length == Trick.seatCount - 1;

  /// El almaya mı çalışıyor, almamaya mı? Botların ortak "mod" kuralı.
  ///
  /// `taken >= bid` ise ya da `bid == 0` ise ALMA, aksi halde AL.
  bool get wantsTricks {
    final bid = myBid;
    if (bid == null || bid == 0) return false;
    return myTricks < bid;
  }

  /// Bu oyun elinde şimdiye kadar oynanmış tüm kağıtlar.
  List<PlayingCard> get playedCards => [
        for (final t in completedTricks) ...t.cards,
        ...currentTrick.cards,
      ];
}
