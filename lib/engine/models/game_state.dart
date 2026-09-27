import 'card.dart';
import 'game_config.dart';
import 'trick.dart';

enum Phase { bidding, playing, roundOver, gameOver }

/// Oyunun tüm bilgisi. Değişmezdir: her aksiyon yeni bir [GameState] üretir.
///
/// Botlar bu sınıfa erişemez, yalnızca `PlayerView` görür.
final class GameState {
  GameState({
    required this.config,
    required this.seed,
    required this.roundIndex,
    required this.dealer,
    required this.phase,
    required List<List<PlayingCard>> hands,
    required List<int?> bids,
    required List<int> tricksTaken,
    required List<int> scores,
    required this.trick,
    required List<Trick> completedTricks,
    required this.spadesBroken,
    this.lastTrick,
    List<int>? lastRoundScores,
  })  : hands = List.unmodifiable([
          for (final h in hands) List<PlayingCard>.unmodifiable(h),
        ]),
        bids = List.unmodifiable(bids),
        tricksTaken = List.unmodifiable(tricksTaken),
        scores = List.unmodifiable(scores),
        completedTricks = List.unmodifiable(completedTricks),
        lastRoundScores =
            lastRoundScores == null ? null : List.unmodifiable(lastRoundScores);

  static const int seatCount = 4;

  /// İnsan oyuncunun koltuğu. Masa düzeninde alttaki koltuk.
  static const int humanSeat = 0;

  /// Bir oyun elindeki el (tur) sayısı.
  static const int tricksPerRound = 13;

  final GameConfig config;
  final int seed;

  /// Kaçıncı oyun eli, 0'dan başlar.
  final int roundIndex;

  /// Bu oyun elinin dağıtıcısı.
  final int dealer;

  final Phase phase;

  /// Koltuk başına eldeki kağıtlar.
  final List<List<PlayingCard>> hands;

  /// Koltuk başına tahmin; henüz söylenmemişse null.
  final List<int?> bids;

  /// Koltuk başına bu oyun elinde alınan el sayısı.
  final List<int> tricksTaken;

  /// Koltuk başına oyun toplamı.
  final List<int> scores;

  /// Şu anda oynanan el. Masa boşken `plays` boştur.
  final Trick trick;

  /// Bu oyun elinde tamamlanmış eller, sırasıyla.
  final List<Trick> completedTricks;

  /// Bu oyun elinde maça atıldı mı.
  final bool spadesBroken;

  /// En son tamamlanan el. Arayüz toplama animasyonu için kullanır.
  final Trick? lastTrick;

  /// En son puanlanan oyun elinin koltuk başına puanı. İlk elden önce null.
  final List<int>? lastRoundScores;

  /// Saat yönünün tersi: 0 → 1 → 2 → 3 → 0.
  static int next(int seat) => (seat + 1) % seatCount;

  /// Sırası gelen koltuk. `roundOver` ve `gameOver` durumlarında null.
  int? get turn => switch (phase) {
        Phase.bidding => (dealer + 1 + bids.whereType<int>().length) % seatCount,
        Phase.playing => trick.turn,
        Phase.roundOver || Phase.gameOver => null,
      };

  List<PlayingCard> handOf(int seat) => hands[seat];

  int? bidOf(int seat) => bids[seat];

  /// Bu oyun elinde şimdiye kadar oynanmış el sayısı.
  int get trickIndex => completedTricks.length;

  /// Oyun bittiğinde en yüksek puanlı koltuklar. Eşitlikte hepsi birinci.
  List<int> get winners {
    final best = scores.reduce((a, b) => a > b ? a : b);
    return [
      for (var s = 0; s < seatCount; s++)
        if (scores[s] == best) s,
    ];
  }

  GameState copyWith({
    GameConfig? config,
    int? seed,
    int? roundIndex,
    int? dealer,
    Phase? phase,
    List<List<PlayingCard>>? hands,
    List<int?>? bids,
    List<int>? tricksTaken,
    List<int>? scores,
    Trick? trick,
    List<Trick>? completedTricks,
    bool? spadesBroken,
    Trick? lastTrick,
    List<int>? lastRoundScores,
  }) =>
      GameState(
        config: config ?? this.config,
        seed: seed ?? this.seed,
        roundIndex: roundIndex ?? this.roundIndex,
        dealer: dealer ?? this.dealer,
        phase: phase ?? this.phase,
        hands: hands ?? this.hands,
        bids: bids ?? this.bids,
        tricksTaken: tricksTaken ?? this.tricksTaken,
        scores: scores ?? this.scores,
        trick: trick ?? this.trick,
        completedTricks: completedTricks ?? this.completedTricks,
        spadesBroken: spadesBroken ?? this.spadesBroken,
        lastTrick: lastTrick ?? this.lastTrick,
        lastRoundScores: lastRoundScores ?? this.lastRoundScores,
      );

  @override
  bool operator ==(Object other) =>
      other is GameState &&
      other.config == config &&
      other.seed == seed &&
      other.roundIndex == roundIndex &&
      other.dealer == dealer &&
      other.phase == phase &&
      other.spadesBroken == spadesBroken &&
      _sameNested(other.hands, hands) &&
      _sameList(other.bids, bids) &&
      _sameList(other.tricksTaken, tricksTaken) &&
      _sameList(other.scores, scores) &&
      _sameTrick(other.trick, trick) &&
      _sameTricks(other.completedTricks, completedTricks) &&
      _sameTrick(other.lastTrick, lastTrick) &&
      _sameList(other.lastRoundScores, lastRoundScores);

  @override
  int get hashCode => Object.hash(
        config,
        seed,
        roundIndex,
        dealer,
        phase,
        spadesBroken,
        Object.hashAll([for (final h in hands) Object.hashAll(h)]),
        Object.hashAll(bids),
        Object.hashAll(tricksTaken),
        Object.hashAll(scores),
        trick.toString(),
        Object.hashAll([for (final t in completedTricks) t.toString()]),
        lastTrick?.toString(),
      );

  static bool _sameList<T>(List<T>? a, List<T>? b) {
    if (a == null || b == null) return a == b;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static bool _sameNested(
      List<List<PlayingCard>> a, List<List<PlayingCard>> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!_sameList(a[i], b[i])) return false;
    }
    return true;
  }

  static bool _sameTrick(Trick? a, Trick? b) {
    if (a == null || b == null) return a == b;
    return a.leader == b.leader &&
        a.winner == b.winner &&
        _sameList(a.plays, b.plays);
  }

  static bool _sameTricks(List<Trick> a, List<Trick> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!_sameTrick(a[i], b[i])) return false;
    }
    return true;
  }

  @override
  String toString() => 'GameState(round $roundIndex, $phase, dealer $dealer, '
      'turn $turn, bids $bids, taken $tricksTaken, scores $scores)';
}
