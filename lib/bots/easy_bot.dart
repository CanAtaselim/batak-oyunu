import 'dart:math';

import '../engine/models/card.dart';
import '../engine/models/player_view.dart';
import '../engine/models/suit.dart';
import 'bot.dart';

/// Kolay bot: tahmini kaba bir sayımla verir, kağıdı rastgele atar.
///
/// Rastgelelik kurucudan gelir; testlerde seed'lidir.
final class EasyBot implements Bot {
  EasyBot(this.random);

  final Random random;

  @override
  String get name => 'easy';

  /// `(As sayısı) + max(0, maça sayısı − 3)`, 1–13 arasına sıkıştırılır.
  /// Kolay bot sıfır tahmini söylemez.
  @override
  int chooseBid(PlayerView view) {
    final aces = view.hand.where((c) => c.rank == 14).length;
    final spades = view.hand.where((c) => c.suit == Suit.spades).length;
    final int bid = aces + (spades > 3 ? spades - 3 : 0);
    return bid < 1 ? 1 : (bid > 13 ? 13 : bid);
  }

  @override
  PlayingCard chooseCard(PlayerView view) =>
      view.legalCards[random.nextInt(view.legalCards.length)];
}
