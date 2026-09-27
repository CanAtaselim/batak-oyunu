/// Oyun varyantları. Şimdilik yalnızca Koz Maça uygulanmış durumda.
enum Variant {
  kozMaca('kozMaca');

  const Variant(this.code);

  final String code;

  static Variant fromCode(String code) =>
      Variant.values.firstWhere((v) => v.code == code,
          orElse: () => throw ArgumentError('Bilinmeyen varyant: $code'));
}

enum BotLevel {
  easy('easy'),
  medium('medium'),
  hard('hard');

  const BotLevel(this.code);

  final String code;

  static BotLevel fromCode(String code) =>
      BotLevel.values.firstWhere((b) => b.code == code,
          orElse: () => throw ArgumentError('Bilinmeyen bot seviyesi: $code'));
}

/// Masa ayarları. Oyun boyunca değişmez.
final class GameConfig {
  const GameConfig({
    this.variant = Variant.kozMaca,
    this.yan = 2,
    this.roundCount = 11,
    this.botLevel = BotLevel.medium,
  })  : assert(yan >= 1 && yan <= 3, 'yan 1, 2 ya da 3 olmalı'),
        assert(roundCount > 0, 'roundCount pozitif olmalı');

  /// Yan batar: tahminden kaç fazla el alınca batılır.
  final int yan;

  /// Oyunun kaç oyun eli süreceği.
  final int roundCount;

  final Variant variant;
  final BotLevel botLevel;

  static const List<int> yanValues = [1, 2, 3];
  static const List<int> roundCountValues = [5, 7, 11, 15, 21];

  GameConfig copyWith({
    Variant? variant,
    int? yan,
    int? roundCount,
    BotLevel? botLevel,
  }) =>
      GameConfig(
        variant: variant ?? this.variant,
        yan: yan ?? this.yan,
        roundCount: roundCount ?? this.roundCount,
        botLevel: botLevel ?? this.botLevel,
      );

  Map<String, Object> toJson() => {
        'variant': variant.code,
        'yan': yan,
        'roundCount': roundCount,
        'botLevel': botLevel.code,
      };

  static GameConfig fromJson(Map<String, Object?> json) => GameConfig(
        variant: Variant.fromCode(json['variant'] as String),
        yan: json['yan'] as int,
        roundCount: json['roundCount'] as int,
        botLevel: BotLevel.fromCode(json['botLevel'] as String),
      );

  @override
  bool operator ==(Object other) =>
      other is GameConfig &&
      other.variant == variant &&
      other.yan == yan &&
      other.roundCount == roundCount &&
      other.botLevel == botLevel;

  @override
  int get hashCode => Object.hash(variant, yan, roundCount, botLevel);
}
