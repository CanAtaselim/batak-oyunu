import 'package:flutter/material.dart';

import '../../engine/models/game_state.dart';
import '../strings.dart';
import '../theme.dart';
import 'appear.dart';

/// Oyun eli ya da oyun bitince gösterilen puan tablosu.
class ScoreSheet extends StatelessWidget {
  const ScoreSheet({
    required this.game,
    required this.onNextRound,
    required this.onHome,
    super.key,
  });

  final GameState game;
  final VoidCallback onNextRound;
  final VoidCallback onHome;

  bool get _gameOver => game.phase == Phase.gameOver;

  @override
  Widget build(BuildContext context) {
    final roundScores = game.lastRoundScores ?? const [0, 0, 0, 0];
    final winners = game.winners;
    return ColoredBox(
      color: const Color(0xCC061410),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Appear(
            child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            decoration: BoxDecoration(
              color: const Color(0xFF16241E),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0x33FFFFFF)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _gameOver
                      ? Str.gameOverTitle
                      : Str.fmt(Str.roundOverTitle, [game.roundIndex + 1]),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 14),
                _table(roundScores),
                if (_gameOver) ...[
                  const SizedBox(height: 14),
                  Text(
                    Str.fmt(
                      winners.length > 1 ? Str.winnerTieLine : Str.winnerLine,
                      [winners.map((s) => Str.seatNames[s]).join(', ')],
                    ),
                    style: const TextStyle(
                      color: BatakColors.brass,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                if (_gameOver)
                  FilledButton(onPressed: onHome, child: const Text(Str.backToHome))
                else
                  FilledButton(
                    onPressed: onNextRound,
                    child: const Text(Str.nextRound),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _table(List<int> roundScores) {
    const headerStyle = TextStyle(
      fontSize: 11,
      letterSpacing: 0.4,
      color: BatakColors.onFeltDim,
      fontWeight: FontWeight.w600,
    );
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2.1),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1),
        3: FlexColumnWidth(1.3),
        4: FlexColumnWidth(1.3),
      },
      children: [
        const TableRow(
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(Str.colPlayer, style: headerStyle),
            ),
            Text(Str.colBid, style: headerStyle, textAlign: TextAlign.center),
            Text(Str.colTaken, style: headerStyle, textAlign: TextAlign.center),
            Text(Str.colRound, style: headerStyle, textAlign: TextAlign.right),
            Text(Str.colTotal, style: headerStyle, textAlign: TextAlign.right),
          ],
        ),
        for (var seat = 0; seat < GameState.seatCount; seat++)
          TableRow(
            decoration: seat == GameState.humanSeat
                ? const BoxDecoration(color: Color(0x14D7A254))
                : null,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
                child: Text(
                  Str.seatNames[seat],
                  style: TextStyle(
                    fontWeight: seat == GameState.humanSeat
                        ? FontWeight.w700
                        : FontWeight.w400,
                  ),
                ),
              ),
              _cell('${game.bids[seat] ?? '—'}', align: TextAlign.center),
              _cell('${game.tricksTaken[seat]}', align: TextAlign.center),
              _cell(
                _signed(roundScores[seat]),
                align: TextAlign.right,
                color: roundScores[seat] < 0 ? BatakColors.bad : BatakColors.good,
              ),
              _cell(
                '${game.scores[seat]}',
                align: TextAlign.right,
                weight: FontWeight.w700,
              ),
            ],
          ),
      ],
    );
  }

  static String _signed(int value) => value > 0 ? '+$value' : '$value';

  static Widget _cell(
    String text, {
    TextAlign align = TextAlign.left,
    Color? color,
    FontWeight? weight,
  }) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Text(
          text,
          textAlign: align,
          style: TextStyle(
            color: color,
            fontWeight: weight,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      );
}
