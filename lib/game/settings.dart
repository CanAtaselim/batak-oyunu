import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../engine/models/game_config.dart';

/// Bot kağıt atışı ve el toplandıktan sonraki bekleme süreleri.
enum Tempo {
  slow('slow', 1200, 1500),
  normal('normal', 700, 1000),
  fast('fast', 300, 500);

  const Tempo(this.code, this.botMs, this.trickMs);

  final String code;
  final int botMs;
  final int trickMs;

  static Tempo fromCode(String? code) =>
      Tempo.values.firstWhere((t) => t.code == code, orElse: () => Tempo.normal);
}

/// Kalıcı ayarlar. Oyun ortasında değiştirilirse yeni oyunda geçerli olur.
final class Settings {
  const Settings({
    this.yan = 2,
    this.roundCount = 11,
    this.botLevel = BotLevel.medium,
    this.tempo = Tempo.normal,
    this.turkishIndices = false,
  });

  final int yan;
  final int roundCount;
  final BotLevel botLevel;
  final Tempo tempo;

  /// Kart indeksleri V/K/P/A mı, J/Q/K/A mı.
  final bool turkishIndices;

  GameConfig get config => GameConfig(
        yan: yan,
        roundCount: roundCount,
        botLevel: botLevel,
      );

  Settings copyWith({
    int? yan,
    int? roundCount,
    BotLevel? botLevel,
    Tempo? tempo,
    bool? turkishIndices,
  }) =>
      Settings(
        yan: yan ?? this.yan,
        roundCount: roundCount ?? this.roundCount,
        botLevel: botLevel ?? this.botLevel,
        tempo: tempo ?? this.tempo,
        turkishIndices: turkishIndices ?? this.turkishIndices,
      );
}

/// main() içinde gerçek örnekle override edilir.
final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPrefsProvider override edilmeli'),
);

final settingsProvider =
    NotifierProvider<SettingsNotifier, Settings>(SettingsNotifier.new);

class SettingsNotifier extends Notifier<Settings> {
  static const _kYan = 'yan';
  static const _kRounds = 'roundCount';
  static const _kBots = 'botLevel';
  static const _kTempo = 'tempo';
  static const _kTrIndices = 'turkishIndices';

  SharedPreferences get _prefs => ref.read(sharedPrefsProvider);

  @override
  Settings build() {
    final p = _prefs;
    return Settings(
      yan: p.getInt(_kYan) ?? 2,
      roundCount: p.getInt(_kRounds) ?? 11,
      botLevel: BotLevel.fromCode(p.getString(_kBots) ?? 'medium'),
      tempo: Tempo.fromCode(p.getString(_kTempo)),
      turkishIndices: p.getBool(_kTrIndices) ?? false,
    );
  }

  Future<void> setYan(int value) async {
    state = state.copyWith(yan: value);
    await _prefs.setInt(_kYan, value);
  }

  Future<void> setRoundCount(int value) async {
    state = state.copyWith(roundCount: value);
    await _prefs.setInt(_kRounds, value);
  }

  Future<void> setBotLevel(BotLevel value) async {
    state = state.copyWith(botLevel: value);
    await _prefs.setString(_kBots, value.code);
  }

  Future<void> setTempo(Tempo value) async {
    state = state.copyWith(tempo: value);
    await _prefs.setString(_kTempo, value.code);
  }

  Future<void> setTurkishIndices(bool value) async {
    state = state.copyWith(turkishIndices: value);
    await _prefs.setBool(_kTrIndices, value);
  }

}
