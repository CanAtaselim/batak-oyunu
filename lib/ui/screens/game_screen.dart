import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../engine/models/game_state.dart';
import '../../game/game_controller.dart';
import '../../game/settings.dart';
import '../cards/board_art.dart';
import '../strings.dart';
import '../theme.dart';
import '../widgets/appear.dart';
import '../widgets/bid_panel.dart';
import '../widgets/hand_fan.dart';
import '../widgets/score_sheet.dart';
import '../widgets/seat_badge.dart';
import '../widgets/trick_view.dart';

/// Oyun masası. Dikey ekran; alt koltuk insan.
class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen>
    with SingleTickerProviderStateMixin {
  late final AppLifecycleListener _lifecycle;

  /// Dağıtım animasyonunun saati. 0'dan 1'e giderken kağıtlar tek tek yerine
  /// oturur; motor bu sırada beklemededir (GameSession.dealing).
  late final AnimationController _deal;

  @override
  void initState() {
    super.initState();
    _deal = AnimationController(vsync: this, value: 1);
    // Arka plana alınınca bekleyen bot zamanlayıcıları iptal edilir.
    _lifecycle = AppLifecycleListener(
      onHide: () => ref.read(gameControllerProvider.notifier).pause(),
      onPause: () => ref.read(gameControllerProvider.notifier).pause(),
      onShow: () => ref.read(gameControllerProvider.notifier).resume(),
      onRestart: () => ref.read(gameControllerProvider.notifier).resume(),
    );
    // Kayıtlı oyun ekrana geldiyse botlar kaldığı yerden devam eder.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gameControllerProvider.notifier).resumeSaved();
      if (ref.read(gameControllerProvider)?.dealing ?? false) _startDeal();
    });
  }

  void _startDeal() {
    _deal
      ..duration = anim(context, ref.read(settingsProvider).tempo.dealMs)
      ..forward(from: 0);
  }

  @override
  void dispose() {
    _deal.dispose();
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(gameControllerProvider);
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(gameControllerProvider.notifier);

    // Yeni dağıtım başladığında saati sıfırdan çalıştır.
    ref.listen<GameSession?>(gameControllerProvider, (previous, next) {
      final started = next != null &&
          next.dealing &&
          (previous == null ||
              !previous.dealing ||
              previous.game.roundIndex != next.game.roundIndex);
      if (started) _startDeal();
    });

    if (session == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) Navigator.of(context).maybePop();
      });
      return const Scaffold(body: SizedBox.shrink());
    }

    final game = session.game;
    final showScores =
        game.phase == Phase.roundOver || game.phase == Phase.gameOver;

    // Masa: seçilen üslup çizilir. "Destenin masası" seçiliyse ve o destenin
    // bir görseli varsa onun yerine görsel serilir.
    final useImage =
        settings.boardStyle == BoardStyle.gorsel && !settings.deck.drawn;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          image: useImage
              ? DecorationImage(
                  image: AssetImage(settings.deck.boardAsset),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: Stack(
          children: [
            if (!useImage)
              Positioned.fill(
                child: CustomPaint(
                  painter: BoardPainter(
                    style: settings.boardStyle,
                    palette: settings.deck.board,
                  ),
                ),
              ),
            SafeArea(
              child: Stack(
                children: [
                  Column(
                    children: [
                      _TopBar(
                        game: game,
                        onLeave: () => _confirmLeave(context),
                      ),
                      Expanded(
                        child: AnimatedBuilder(
                          animation: _deal,
                          builder: (context, _) => _Table(
                            session: session,
                            settings: settings,
                            dealProgress: _deal.value,
                          ),
                        ),
                      ),
                      // Tahmin panelini yelpazenin üstüne koyuyoruz: oyuncu
                      // tahmin verirken kendi elini görmek zorunda.
                      if (session.humanCanBid)
                        Appear(
                          offset: const Offset(0, 0.25),
                          child: BidPanel(
                            bids: game.bids,
                            onBid: controller.placeBid,
                          ),
                        ),
                      AnimatedBuilder(
                        animation: _deal,
                        builder: (context, _) => _MyHand(
                          session: session,
                          settings: settings,
                          dealProgress: _deal.value,
                        ),
                      ),
                    ],
                  ),
                  if (showScores && session.resolvingTrick == null)
                    Positioned.fill(
                      child: ScoreSheet(
                        game: game,
                        onNextRound: controller.nextRound,
                        onHome: () {
                          controller.abandon();
                          Navigator.of(context).maybePop();
                        },
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLeave(BuildContext context) async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(Str.abandonGame),
        content: const Text(Str.abandonConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(Str.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(Str.confirm),
          ),
        ],
      ),
    );
    if (leave == true && context.mounted) {
      ref.read(gameControllerProvider.notifier).abandon();
      if (context.mounted) Navigator.of(context).maybePop();
    }
  }
}

/// Koz, kaçıncı el, yan batar ve senin tahmin/alış durumun.
class _TopBar extends StatelessWidget {
  const _TopBar({required this.game, required this.onLeave});

  final GameState game;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    final myBid = game.bids[GameState.humanSeat];
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 4),
      child: Row(
        children: [
          // Dar ekranda çipler alt satıra kayar; taşma olmaz.
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _chip('${Str.trump} ♠', accent: true),
                _chip('${Str.roundLabel} ${game.roundIndex + 1}/'
                    '${game.config.roundCount} · ${Str.yanLabel} ${game.config.yan}'),
                _chip('${Str.bidShort}${myBid ?? Str.waitingBid} · '
                    '${Str.takenShort}${game.tricksTaken[GameState.humanSeat]}'),
              ],
            ),
          ),
          IconButton(
            onPressed: onLeave,
            icon: const Icon(Icons.close_rounded, size: 20),
            color: BatakColors.onFeltDim,
            tooltip: Str.abandonGame,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, {bool accent = false}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0x80081409),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: accent
                ? BatakColors.brass.withValues(alpha: 0.45)
                : Colors.white.withValues(alpha: 0.16),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: accent ? BatakColors.brass : BatakColors.onFelt,
          ),
        ),
      );
}

/// Üç bot ve ortadaki el.
class _Table extends StatelessWidget {
  const _Table({
    required this.session,
    required this.settings,
    this.dealProgress = 1,
  });

  final GameSession session;
  final Settings settings;
  final double dealProgress;

  @override
  Widget build(BuildContext context) {
    final game = session.game;
    return Stack(
      alignment: Alignment.center,
      children: [
        Align(alignment: Alignment.topCenter, child: _badge(game, 2)),
        Align(alignment: const Alignment(-0.92, -0.1), child: _badge(game, 3)),
        Align(alignment: const Alignment(0.92, -0.1), child: _badge(game, 1)),
        TrickView(
          trick: session.visibleTrick,
          winner: session.resolvingTrick?.winner,
          collecting: session.collecting,
          deck: settings.deck,
          turkishIndices: settings.turkishIndices,
        ),
      ],
    );
  }

  Widget _badge(GameState game, int seat) => SeatBadge(
        seat: seat,
        cardsInHand: game.handOf(seat).length,
        bid: game.bids[seat],
        taken: game.tricksTaken[seat],
        isDealer: game.dealer == seat,
        isTurn: game.turn == seat &&
            session.resolvingTrick == null &&
            !session.dealing,
        thinking: session.botThinking && game.turn == seat,
        dealProgress: dealProgress,
        deck: settings.deck,
      );
}

/// İnsanın yelpazesi.
class _MyHand extends ConsumerWidget {
  const _MyHand({
    required this.session,
    required this.settings,
    this.dealProgress = 1,
  });

  final GameSession session;
  final Settings settings;
  final double dealProgress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(gameControllerProvider.notifier);
    return Padding(
      // Yelpaze telefonun hareket çubuğuna yapışmasın.
      padding: const EdgeInsets.only(bottom: 14),
      child: HandFan(
        hand: session.game.handOf(GameState.humanSeat),
        legalCards: controller.humanLegalCards,
        enabled: session.humanCanPlay,
        turkishIndices: settings.turkishIndices,
        deck: settings.deck,
        dealProgress: dealProgress,
        onTap: controller.playCard,
      ),
    );
  }
}
