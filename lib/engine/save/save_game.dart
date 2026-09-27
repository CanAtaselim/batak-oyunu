import 'dart:convert';

import '../models/action.dart';
import '../models/card.dart';
import '../models/game_config.dart';
import '../models/game_state.dart';
import '../rules/engine.dart';

/// Yarım kalan oyunun kaydı: ayarlar, seed ve aksiyon listesi.
///
/// Durum kaydedilmez; açılışta aksiyonlar baştan oynatılarak kurulur. Böylece
/// kayıt küçük kalır ve motorun determinizmi tek doğruluk ölçütü olur.
final class SaveGame {
  SaveGame({
    required this.config,
    required this.seed,
    required List<GameAction> actions,
  }) : actions = List.unmodifiable(actions);

  /// Kayıt formatı sürümü. Uyuşmazsa kayıt atılır.
  static const int version = 1;

  final GameConfig config;
  final int seed;
  final List<GameAction> actions;

  SaveGame withAction(GameAction action) =>
      SaveGame(config: config, seed: seed, actions: [...actions, action]);

  Map<String, Object> toJson() => {
        'v': version,
        'config': config.toJson(),
        'seed': seed,
        'actions': [for (final a in actions) a.toJson()],
      };

  String encode() => jsonEncode(toJson());

  /// Kaydı okur. Sürüm uyuşmazsa ya da JSON bozuksa null döner — çağıran
  /// kaydı siler ve oyun sıfırdan başlar, uygulama çökmez.
  static SaveGame? decode(String raw) {
    try {
      final json = jsonDecode(raw);
      if (json is! Map<String, Object?>) return null;
      if (json['v'] != version) return null;
      return SaveGame(
        config: GameConfig.fromJson(json['config'] as Map<String, Object?>),
        seed: json['seed'] as int,
        actions: [
          for (final a in json['actions'] as List) _actionFromJson(a as List),
        ],
      );
    } on Object {
      return null;
    }
  }

  static GameAction _actionFromJson(List<Object?> a) => switch (a[0]) {
        'B' => Bid(a[1] as int, a[2] as int),
        'P' => PlayCard(a[1] as int, PlayingCard.parse(a[2] as String)),
        'N' => const NextRound(),
        _ => throw ArgumentError('Bilinmeyen aksiyon: $a'),
      };

  /// Aksiyonları baştan oynatarak durumu kurar.
  ///
  /// Oynatma sırasında [IllegalActionException] alınırsa null döner; kayıt
  /// bozuk demektir ve silinmelidir.
  GameState? replay() {
    final engine = Engine.forConfig(config);
    try {
      var state = engine.newGame(config, seed);
      for (final action in actions) {
        state = engine.apply(state, action);
      }
      return state;
    } on IllegalActionException {
      return null;
    }
  }
}
