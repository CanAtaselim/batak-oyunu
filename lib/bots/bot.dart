import '../engine/models/card.dart';
import '../engine/models/player_view.dart';

/// Bir botun bilgi sınırı `PlayerView`'dur; hile yoktur.
///
/// [chooseCard] dönüş değeri **daima** `view.legalCards` içinden olmalıdır.
abstract interface class Bot {
  /// Bu botun seviyesini gösteren kod; günlük ve simülasyon çıktısında kullanılır.
  String get name;

  int chooseBid(PlayerView view);

  PlayingCard chooseCard(PlayerView view);
}
