import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../bots/bot.dart';
import '../bots/bot_factory.dart';
import '../engine/models/action.dart';
import '../engine/models/card.dart';
import '../engine/models/game_config.dart';
import '../engine/models/game_state.dart';
import '../engine/models/trick.dart';
import '../engine/rules/engine.dart';
import '../engine/save/save_game.dart';
import 'settings.dart';

/// Ekranda gösterilen oyun. Motor durumuna ek olarak yalnızca sunum bilgisi
/// taşır: toplanmayı bekleyen el ve botun düşünüyor olması.
final class GameSession {
  const GameSession({
    required this.game,
    this.resolvingTrick,
    this.botThinking = false,
    this.collecting = false,
  });

  final GameState game;

  /// 4. kağıt atıldı, el sonuçlandı ama masada gösterilmeye devam ediyor.
  /// Motor beklemez; bu bekleme tamamen sunumdur.
  final Trick? resolvingTrick;

  final bool botThinking;

  /// El toplanıyor: kağıtlar kazananın önüne süzülüyor. Yalnızca sunum.
  final bool collecting;

  /// Masada gösterilecek el: toplanmayı bekleyen varsa o, yoksa güncel el.
  Trick get visibleTrick => resolvingTrick ?? game.trick;

  /// İnsan şu an kağıt atabilir mi?
  bool get humanCanPlay =>
      resolvingTrick == null &&
      game.phase == Phase.playing &&
      game.turn == GameState.humanSeat;

  /// İnsan şu an tahmin söyleyebilir mi?
  bool get humanCanBid =>
      game.phase == Phase.bidding && game.turn == GameState.humanSeat;

  GameSession copyWith({
    GameState? game,
    Trick? resolvingTrick,
    bool clearResolving = false,
    bool? botThinking,
    bool? collecting,
  }) =>
      GameSession(
        game: game ?? this.game,
        resolvingTrick:
            clearResolving ? null : (resolvingTrick ?? this.resolvingTrick),
        botThinking: botThinking ?? this.botThinking,
        collecting: clearResolving ? false : (collecting ?? this.collecting),
      );
}

/// Tempo gecikmesi. Testlerde beklemesiz bir işlevle override edilir.
typedef DelayFn = Future<void> Function(Duration);

final delayProvider = Provider<DelayFn>(
  (ref) => (duration) => Future<void>.delayed(duration),
);

final gameControllerProvider =
    NotifierProvider<GameController, GameSession?>(GameController.new);

/// Motor ile arayüz arasındaki tek köprü.
///
/// - Aksiyonu `apply` eder ve her aksiyondan sonra kaydeder.
/// - İnsan aksiyonu yalnızca sırası ondayken ve `legalActions` içindeyse kabul
///   edilir; çift dokunma böyle engellenir.
/// - Sıra bottayken kararı alır, tempo gecikmesini bekler, sonra uygular.
/// - Uygulama arka plana alınınca bekleyen bot zamanlayıcıları iptal edilir.
class GameController extends Notifier<GameSession?> {
  static const _saveKey = 'savedGame';

  late Engine _engine;
  late List<Bot> _bots;
  SaveGame? _save;

  /// Bekleyen gecikmeleri iptal etmek için: her duraklatma bu sayacı artırır.
  int _runId = 0;
  bool _paused = false;
  bool _pumping = false;
  bool _disposed = false;

  @override
  GameSession? build() {
    ref.onDispose(() {
      _disposed = true;
      _runId++;
    });
    return _restore();
  }

  Tempo get _tempo => ref.read(settingsProvider).tempo;

  /// El toplama animasyonuna ayrılan süre; bekleme süresinin içinden alınır.
  int get _collectMs {
    final trickMs = _tempo.trickMs;
    return trickMs ~/ 2 < 300 ? trickMs ~/ 2 : 300;
  }

  /// İnsanın şu an atabileceği kağıtlar. Arayüz hangi kartın tıklanabilir
  /// olduğunu buradan öğrenir — motorla aynı kaynaktan.
  List<PlayingCard> get humanLegalCards {
    final session = state;
    if (session == null || !session.humanCanPlay) return const [];
    return _engine.legalCardsFor(session.game, GameState.humanSeat);
  }

  // ------------------------------------------------------------------ kurulum

  /// Kayıtlı oyunu okur. Kayıt bozuksa siler ve null döner (uygulama çökmez).
  GameSession? _restore() {
    final prefs = ref.read(sharedPrefsProvider);
    final raw = prefs.getString(_saveKey);
    if (raw == null) return null;
    final save = SaveGame.decode(raw);
    final state = save?.replay();
    if (save == null || state == null) {
      prefs.remove(_saveKey);
      return null;
    }
    _save = save;
    _engine = Engine.forConfig(save.config);
    _bots = _makeBots(save.config, save.seed);
    return GameSession(game: state);
  }

  List<Bot> _makeBots(GameConfig config, int seed) => [
        for (var seat = 0; seat < GameState.seatCount; seat++)
          createBot(config.botLevel, Random(seed + seat * 7919)),
      ];

  /// Yeni oyun kurar. Seed motorun dışından gelir; motor rastgelelik üretmez.
  void newGame({int? seed}) {
    final config = ref.read(settingsProvider).config;
    final gameSeed = seed ?? Random().nextInt(1 << 31);
    _engine = Engine.forConfig(config);
    _bots = _makeBots(config, gameSeed);
    _save = SaveGame(config: config, seed: gameSeed, actions: const []);
    _runId++;
    _paused = false;
    state = GameSession(game: _engine.newGame(config, gameSeed));
    _persist();
    _pump();
  }

  /// Kayıtlı oyunu ekrana getirir ve botlar sıradaysa devam ettirir.
  void resumeSaved() {
    if (state == null) return;
    _paused = false;
    _pump();
  }

  bool get hasSavedGame =>
      ref.read(sharedPrefsProvider).getString(_saveKey) != null;

  void abandon() {
    _runId++;
    _paused = true;
    _save = null;
    state = null;
    ref.read(sharedPrefsProvider).remove(_saveKey);
  }

  // ----------------------------------------------------------- insan aksiyonu

  /// İnsanın tahmini. Sırası değilse ya da geçersizse sessizce yok sayılır.
  void placeBid(int value) {
    final session = state;
    if (session == null || !session.humanCanBid) return;
    _submit(Bid(GameState.humanSeat, value));
  }

  /// İnsanın attığı kağıt. Kurallara aykırıysa ya da sırası değilse yok sayılır.
  void playCard(PlayingCard card) {
    final session = state;
    if (session == null || !session.humanCanPlay) return;
    _submit(PlayCard(GameState.humanSeat, card));
  }

  /// Puan tablosundan sonra yeni dağıtım.
  void nextRound() {
    final session = state;
    if (session == null || session.game.phase != Phase.roundOver) return;
    _submit(const NextRound());
  }

  /// İnsan aksiyonunu doğrular, uygular ve akışı sürdürür.
  void _submit(GameAction action) {
    if (!_engine.legalActions(state!.game).contains(action)) return;
    _apply(action);
    _pump();
  }

  // ------------------------------------------------------------- oyun akışı

  /// Botların sırasını ve el toplama beklemelerini yürütür.
  Future<void> _pump() async {
    if (_pumping) return;
    _pumping = true;
    final runId = _runId;
    try {
      while (true) {
        if (_disposed || _paused || runId != _runId) return;
        final session = state;
        if (session == null) return;

        // Tamamlanmış el masada duruyor: bekle, kazananın önüne topla, temizle.
        if (session.resolvingTrick != null) {
          final collectMs = _collectMs;
          if (!await _wait(_tempo.trickMs - collectMs, runId)) return;
          state = state!.copyWith(collecting: true);
          if (!await _wait(collectMs, runId)) return;
          state = state!.copyWith(clearResolving: true);
          continue;
        }

        final game = session.game;
        if (game.phase == Phase.roundOver || game.phase == Phase.gameOver) {
          return;
        }
        final seat = game.turn!;
        if (seat == GameState.humanSeat) return;

        state = session.copyWith(botThinking: true);
        final action = _botAction(game, seat);
        if (!await _wait(_tempo.botMs, runId)) return;
        _apply(action);
      }
    } finally {
      _pumping = false;
    }
  }

  GameAction _botAction(GameState game, int seat) {
    final view = _engine.viewFor(game, seat);
    final bot = _bots[seat];
    return switch (game.phase) {
      Phase.bidding => Bid(seat, bot.chooseBid(view)),
      Phase.playing => PlayCard(seat, bot.chooseCard(view)),
      _ => throw StateError('bot aksiyonu istenemez: ${game.phase}'),
    };
  }

  /// Gecikme. İptal edilmişse false döner.
  Future<bool> _wait(int ms, int runId) async {
    await ref.read(delayProvider)(Duration(milliseconds: ms));
    return !_disposed && !_paused && runId == _runId;
  }

  void _apply(GameAction action) {
    final before = state!.game;
    final after = _engine.apply(before, action);
    final trickJustFinished =
        after.completedTricks.length > before.completedTricks.length;
    state = GameSession(
      game: after,
      resolvingTrick: trickJustFinished ? after.lastTrick : null,
      botThinking: false,
    );
    _save = _save?.withAction(action);
    _persist();
  }

  void _persist() {
    final save = _save;
    if (save == null) return;
    // Oyun bittiyse kaydı tutmanın anlamı yok.
    if (state?.game.phase == Phase.gameOver) {
      ref.read(sharedPrefsProvider).remove(_saveKey);
      return;
    }
    ref.read(sharedPrefsProvider).setString(_saveKey, save.encode());
  }

  // --------------------------------------------------------- yaşam döngüsü

  /// Uygulama arka plana alındı: bekleyen bot zamanlayıcıları iptal edilir.
  void pause() {
    _paused = true;
    _runId++;
    final session = state;
    if (session != null && session.botThinking) {
      state = session.copyWith(botThinking: false);
    }
  }

  /// Öne dönüldü: kaldığı yerden devam eder.
  void resume() {
    if (_paused) {
      _paused = false;
      _pump();
    }
  }
}
