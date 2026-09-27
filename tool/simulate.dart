// Bot ayarı ve fuzz testi için saf Dart komut satırı aracı.
//
//   dart run tool/simulate.dart --rounds 10000 --bots medium,medium,easy,easy --seed 1
//
// Her aksiyondan sonra değişmezleri denetler, sonunda bot başına rapor basar.
// Kabul ölçütü: Orta'nın ortalama oyun eli puanı Kolay'dan açıkça yüksek olmalı
// ve koltuk pozisyonu değiştirildiğinde sonuç tersine dönmemeli (--rotate).

import 'dart:io';
import 'dart:math';

import 'package:batak/bots/bot.dart';
import 'package:batak/bots/bot_factory.dart';
import 'package:batak/engine/models/action.dart';
import 'package:batak/engine/models/card.dart';
import 'package:batak/engine/models/game_config.dart';
import 'package:batak/engine/models/game_state.dart';
import 'package:batak/engine/rules/engine.dart';

void main(List<String> args) {
  final opts = _parseArgs(args);
  final rounds = int.parse(opts['rounds'] ?? '10000');
  final seed = int.parse(opts['seed'] ?? '1');
  final yan = int.parse(opts['yan'] ?? '2');
  final levels = (opts['bots'] ?? 'medium,medium,easy,easy')
      .split(',')
      .map((s) => BotLevel.fromCode(s.trim()))
      .toList();
  final rotate = opts.containsKey('rotate');
  if (levels.length != GameState.seatCount) {
    stderr.writeln('--bots tam 4 seviye istiyor, örnek: medium,medium,easy,easy');
    exit(2);
  }

  final config = GameConfig(yan: yan, roundCount: 1);
  final engine = Engine.forConfig(config);
  final stats = <String, _Stats>{};
  final bySeat = <int, _Stats>{for (var s = 0; s < 4; s++) s: _Stats()};
  var illegal = 0;
  var checks = 0;

  final started = DateTime.now();
  for (var round = 0; round < rounds; round++) {
    // Koltuk etkisini ayıklamak için dizilim her turda bir kaydırılır.
    final shift = rotate ? round % GameState.seatCount : 0;
    final seatLevels = [
      for (var s = 0; s < GameState.seatCount; s++)
        levels[(s + shift) % GameState.seatCount],
    ];
    final bots = <Bot>[
      for (var s = 0; s < GameState.seatCount; s++)
        createBot(seatLevels[s], Random(seed * 1000003 + round * 4 + s)),
    ];

    var state = engine.newGame(config, seed + round);
    while (state.phase != Phase.gameOver) {
      final seat = state.turn;
      final GameAction action;
      switch (state.phase) {
        case Phase.bidding:
          action = Bid(seat!, bots[seat].chooseBid(engine.viewFor(state, seat)));
        case Phase.playing:
          final view = engine.viewFor(state, seat!);
          final card = bots[seat].chooseCard(view);
          if (!view.legalCards.contains(card)) {
            stderr.writeln('HATA: ${bots[seat].name} legalCards dışına çıktı');
            illegal++;
          }
          action = PlayCard(seat, card);
        case Phase.roundOver:
          action = const NextRound();
        case Phase.gameOver:
          continue;
      }
      try {
        state = engine.apply(state, action);
      } on IllegalActionException catch (e) {
        stderr.writeln('HATA: $e');
        illegal++;
        break;
      }
      checks++;
      final problem = _checkInvariants(state);
      if (problem != null) {
        stderr.writeln('DEĞİŞMEZ İHLALİ: $problem');
        illegal++;
        break;
      }
    }

    if (state.phase != Phase.gameOver) continue;
    for (var s = 0; s < GameState.seatCount; s++) {
      final name = seatLevels[s].code;
      final entry = stats.putIfAbsent(name, _Stats.new);
      entry.add(
        bid: state.bids[s]!,
        taken: state.tricksTaken[s],
        score: state.lastRoundScores![s],
        yan: yan,
      );
      bySeat[s]!.add(
        bid: state.bids[s]!,
        taken: state.tricksTaken[s],
        score: state.lastRoundScores![s],
        yan: yan,
      );
    }
  }

  final elapsed = DateTime.now().difference(started);
  stdout.writeln('Batak simülasyonu — $rounds oyun eli, seed $seed, yan $yan');
  stdout.writeln('Dizilim: ${levels.map((l) => l.code).join(', ')}'
      '${rotate ? ' (koltuklar her turda kaydırıldı)' : ''}');
  stdout.writeln('Süre: ${elapsed.inMilliseconds} ms, $checks aksiyon denetlendi'
      '${illegal == 0 ? '' : ', $illegal HATA'}');
  stdout.writeln('');
  _printTable('Bot', stats);
  if (!rotate) {
    stdout.writeln('');
    _printTable('Koltuk',
        {for (final e in bySeat.entries) 'koltuk ${e.key}': e.value});
  }

  if (illegal > 0) exit(1);
}

/// Simülasyon sırasında denetlenen değişmezler (invariants_test.dart ile aynı).
String? _checkInvariants(GameState s) {
  final all = <PlayingCard>[
    for (final hand in s.hands) ...hand,
    ...s.trick.cards,
    for (final t in s.completedTricks) ...t.cards,
  ];
  if (all.length != 52) return 'kağıt sayısı ${all.length}';
  if (all.toSet().length != 52) return 'kağıt tekrarı';
  if (s.phase == Phase.roundOver || s.phase == Phase.gameOver) {
    final total = s.tricksTaken.reduce((a, b) => a + b);
    if (total != GameState.tricksPerRound) return 'el toplamı $total';
  }
  return null;
}

void _printTable(String header, Map<String, _Stats> rows) {
  final head = [
    header.padRight(8),
    'ort.puan'.padLeft(9),
    'tuttur%'.padLeft(8),
    'eksik%'.padLeft(7),
    'yanbat%'.padLeft(8),
    'sıfır'.padLeft(6),
    'sıfır%'.padLeft(7),
    'ort.tahmin'.padLeft(11),
  ].join(' ');
  stdout.writeln(head);
  stdout.writeln('-' * head.length);
  for (final entry in rows.entries) {
    final st = entry.value;
    if (st.rounds == 0) continue;
    stdout.writeln([
      entry.key.padRight(8),
      st.avgScore.toStringAsFixed(2).padLeft(9),
      st.pct(st.exact).padLeft(8),
      st.pct(st.under).padLeft(7),
      st.pct(st.yanBust).padLeft(8),
      '${st.zeroBids}'.padLeft(6),
      (st.zeroBids == 0
              ? '—'
              : '${(100 * st.zeroMade / st.zeroBids).toStringAsFixed(1)}%')
          .padLeft(7),
      st.avgBid.toStringAsFixed(2).padLeft(11),
    ].join(' '));
  }
}

final class _Stats {
  int rounds = 0;
  int totalScore = 0;
  int totalBid = 0;
  int exact = 0;
  int under = 0;
  int yanBust = 0;
  int overSafe = 0;
  int zeroBids = 0;
  int zeroMade = 0;

  void add({
    required int bid,
    required int taken,
    required int score,
    required int yan,
  }) {
    rounds++;
    totalScore += score;
    totalBid += bid;
    if (bid == 0) {
      zeroBids++;
      if (taken == 0) zeroMade++;
      return;
    }
    if (taken < bid) {
      under++;
    } else if (taken == bid) {
      exact++;
    } else if (taken - bid >= yan) {
      yanBust++;
    } else {
      overSafe++;
    }
  }

  double get avgScore => rounds == 0 ? 0 : totalScore / rounds;
  double get avgBid => rounds == 0 ? 0 : totalBid / rounds;
  String pct(int n) =>
      rounds == 0 ? '—' : '${(100 * n / rounds).toStringAsFixed(1)}%';
}

Map<String, String> _parseArgs(List<String> args) {
  final out = <String, String>{};
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (!arg.startsWith('--')) continue;
    final key = arg.substring(2);
    if (i + 1 < args.length && !args[i + 1].startsWith('--')) {
      out[key] = args[++i];
    } else {
      out[key] = 'true';
    }
  }
  return out;
}
