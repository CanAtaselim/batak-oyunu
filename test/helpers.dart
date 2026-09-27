import 'dart:math';

import 'package:batak/engine/models/action.dart';
import 'package:batak/engine/models/card.dart';
import 'package:batak/engine/models/game_config.dart';
import 'package:batak/engine/models/game_state.dart';
import 'package:batak/engine/models/trick.dart';
import 'package:batak/engine/models/player_view.dart';
import 'package:batak/engine/rules/engine.dart';
import 'package:batak/engine/variants/koz_maca/koz_maca_rules.dart';

/// `'SA'` → ♠A.
PlayingCard c(String code) => PlayingCard.parse(code);

/// `'SA S5 H3'` → [♠A, ♠5, ♥3]. Boş metin boş liste verir.
List<PlayingCard> cards(String codes) => codes.trim().isEmpty
    ? const []
    : [for (final code in codes.trim().split(RegExp(r'\s+'))) c(code)];

/// Kağıt listelerini sıraya bakmadan karşılaştırmak için kanonik metin.
String canon(Iterable<PlayingCard> list) =>
    ([...list]..sort()).map((x) => x.code).join(' ');

/// 0. koltuktan başlayarak sırayla atılmış tamamlanmış bir el kurar.
Trick trickOf(String codes, {int leader = 0}) {
  var t = Trick(leader: leader);
  var seat = leader;
  for (final card in cards(codes)) {
    t = t.add(seat, card);
    seat = (seat + 1) % Trick.seatCount;
  }
  return t;
}

/// Oyun elinin ortasındaki bir durumu elle kurar. Yalnızca testler için;
/// motorun kendi dağıtımını atlar, o yüzden 52 kağıt değişmezi çağıranın
/// sorumluluğundadır.
GameState stateFor({
  required List<String> hands,
  int dealer = 3,
  List<int?> bids = const [3, 3, 3, 3],
  List<int> tricksTaken = const [0, 0, 0, 0],
  String table = '',
  int? leader,
  bool spadesBroken = false,
  Phase phase = Phase.playing,
  GameConfig config = const GameConfig(),
  int seed = 1,
  int roundIndex = 0,
}) {
  final lead = leader ?? GameState.next(dealer);
  var trick = Trick(leader: lead);
  var seat = lead;
  for (final card in cards(table)) {
    trick = trick.add(seat, card);
    seat = GameState.next(seat);
  }
  return GameState(
    config: config,
    seed: seed,
    roundIndex: roundIndex,
    dealer: dealer,
    phase: phase,
    hands: [for (final h in hands) cards(h)],
    bids: bids,
    tricksTaken: tricksTaken,
    scores: const [0, 0, 0, 0],
    trick: trick,
    completedTricks: const [],
    spadesBroken: spadesBroken,
  );
}

/// Geçerli aksiyonlardan rastgele seçerek oyunu ilerletir.
///
/// [until] koşulu sağlanınca ya da geçerli aksiyon kalmayınca durur. Her adımda
/// [onStep] çağrılır; değişmez testleri buraya bağlanır.
GameState autoPlay(
  Engine engine,
  GameState start, {
  required bool Function(GameState) until,
  Random? random,
  void Function(GameState state, List<GameAction> legal, GameAction chosen)?
      onStep,
}) {
  final rnd = random ?? Random(7);
  var state = start;
  var guard = 0;
  while (!until(state)) {
    final legal = engine.legalActions(state);
    if (legal.isEmpty) break;
    final chosen = legal[rnd.nextInt(legal.length)];
    onStep?.call(state, legal, chosen);
    state = engine.apply(state, chosen);
    if (++guard > 5000) {
      throw StateError('autoPlay ilerlemiyor, sonsuz döngü koruması');
    }
  }
  return state;
}

/// Bot testleri için doğrudan bir `PlayerView` kurar.
///
/// [table] masadaki kağıtlardır; botun eldeki sırası oradan çıkar (3 kağıt
/// varsa bot 4. oyuncudur). [bid] ve [taken] botun modunu belirler.
PlayerView botView({
  required String hand,
  String table = '',
  required int bid,
  int taken = 0,
  bool spadesBroken = false,
  int seat = 0,
  GameConfig config = const GameConfig(),
}) {
  const rules = KozMacaRules();
  final handCards = cards(hand);
  final tableCards = cards(table);
  final leader =
      (seat - tableCards.length + Trick.seatCount * 2) % Trick.seatCount;
  var trick = Trick(leader: leader);
  var s = leader;
  for (final card in tableCards) {
    trick = trick.add(s, card);
    s = GameState.next(s);
  }
  final bids = <int?>[null, null, null, null];
  final taken4 = [0, 0, 0, 0];
  bids[seat] = bid;
  taken4[seat] = taken;
  return PlayerView(
    seat: seat,
    hand: handCards,
    legalCards: rules.legalMoves(handCards, tableCards, spadesBroken),
    currentTrick: trick,
    completedTricks: const [],
    bids: bids,
    tricksTaken: taken4,
    dealer: (leader - 1 + Trick.seatCount) % Trick.seatCount,
    trump: rules.trump,
    spadesBroken: spadesBroken,
    scores: const [0, 0, 0, 0],
    roundIndex: 0,
    config: config,
  );
}

/// Karıştırılmış destenin kağıt kodları; bot testlerinde rastgele el üretir.
List<String> shuffledDeckCodes(Random random) =>
    [for (final card in PlayingCard.shuffled(random)) card.code];
