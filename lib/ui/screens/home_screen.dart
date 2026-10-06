import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../engine/models/card.dart';
import '../../engine/models/game_state.dart';
import '../../game/game_controller.dart';
import '../../game/settings.dart';
import '../strings.dart';
import '../theme.dart';
import '../cards/deck_theme.dart';
import '../widgets/playing_card_view.dart';
import 'game_screen.dart';
import 'settings_screen.dart';

/// Ana ekran: yeni oyun, kayıtlı oyuna devam, ayarlar.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameControllerProvider);
    final controller = ref.read(gameControllerProvider.notifier);
    final pal = context.pal;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          // Ortadan gelen ışık: üstte panel tonu, kenarlarda zemin.
          gradient: RadialGradient(
            center: const Alignment(0, -0.4),
            radius: 1.15,
            colors: [pal.panel, pal.surface, pal.surfaceAlt],
            stops: const [0, 0.5, 1],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 30),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Logo(deck: ref.watch(settingsProvider).deck, pal: pal),
                    const SizedBox(height: 28),
                    Text(
                      Str.appName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.2,
                        color: pal.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${Str.variantKozMaca} · ${Str.variantKozMacaDesc}',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13.5, color: pal.inkDim),
                    ),
                    const SizedBox(height: 34),
                    if (session != null) ...[
                      FilledButton(
                        onPressed: () => _open(context),
                        child: const Text(Str.continueGame),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        Str.fmt(Str.savedGameLine, [
                          session.game.roundIndex + 1,
                          '${session.game.scores[GameState.humanSeat]}',
                        ]),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12.5, color: pal.inkDim),
                      ),
                      const SizedBox(height: 18),
                      OutlinedButton(
                        onPressed: () {
                          controller.newGame();
                          _open(context);
                        },
                        child: const Text(Str.newGame),
                      ),
                    ] else
                      FilledButton(
                        onPressed: () {
                          controller.newGame();
                          _open(context);
                        },
                        child: const Text(Str.newGame),
                      ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const SettingsScreen(),
                        ),
                      ),
                      child: const Text(Str.settings),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _open(BuildContext context) => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const GameScreen()),
      );
}

/// Üç kağıtlık küçük bir yelpaze; destenin ne olduğunu ana ekranda gösterir.
class _Logo extends StatelessWidget {
  const _Logo({required this.deck, required this.pal});

  final DeckTheme deck;
  final BatakPalette pal;

  static const _cards = [
    ('SA', -0.22, -26.0, 0.0),
    ('HK', 0.0, 0.0, -8.0),
    ('D10', 0.22, 26.0, 0.0),
  ];

  @override
  Widget build(BuildContext context) => Container(
        height: 150,
        // Hale: kağıtlar zeminde kaybolmasın.
        decoration: BoxDecoration(
          gradient: RadialGradient(
            radius: 0.62,
            colors: [
              pal.accent.withValues(alpha: 0.55),
              pal.accent.withValues(alpha: 0),
            ],
            stops: const [0.25, 1],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            for (final (code, angle, dx, dy) in _cards)
              Transform.translate(
                offset: Offset(dx, dy),
                child: Transform.rotate(
                  angle: angle,
                  child: PlayingCardView(
                    card: PlayingCard.parse(code),
                    width: 62,
                    theme: deck,
                  ),
                ),
              ),
          ],
        ),
      );
}
