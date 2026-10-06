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
    final boardPalette = settings.deck.board(Theme.of(context).brightness);

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
                    palette: boardPalette,
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
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: AnimatedBuilder(
                                animation: _deal,
                                builder: (context, _) => _Table(
                                  session: session,
                                  settings: settings,
                                  dealProgress: _deal.value,
                                ),
                              ),
                            ),
                            // Tahmin pop-up'ı masanın ortasında açılır.
                            // Yelpazenin üstünü kapatmaz: oyuncu tahmin
                            // verirken kendi elini görmek zorunda.
                            if (session.humanCanBid)
                              Positioned.fill(
                                child: _BidOverlay(
                                  bids: game.bids,
                                  onBid: controller.placeBid,
                                ),
                              ),
                          ],
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

/// Tahmin pop-up'ının altındaki örtü: masayı yumuşatır, dokunuşları yutar.
class _BidOverlay extends StatelessWidget {
  const _BidOverlay({required this.bids, required this.onBid});

  final List<int?> bids;
  final ValueChanged<int> onBid;

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {},
        child: DecoratedBox(
          // Masayı yumuşatan bant. Üstte ve altta söndüğü için üst barla ve
          // yelpazeyle arasında sert bir kesim görünmez.
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                context.pal.scrim.withValues(alpha: 0),
                context.pal.scrim,
                context.pal.scrim,
                context.pal.scrim.withValues(alpha: 0),
              ],
              stops: const [0, 0.16, 0.84, 1],
            ),
          ),
          child: Appear(
            ms: 240,
            offset: const Offset(0, 0.04),
            scaleFrom: 0.93,
            child: BidPanel(bids: bids, onBid: onBid),
          ),
        ),
      );
}

/// Koz, kaçıncı el, yan batar ve senin tahmin/alış durumun.
class _TopBar extends StatelessWidget {
  const _TopBar({required this.game, required this.onLeave});

  final GameState game;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 6, 6),
      child: Row(
        children: [
          // Dar ekranda çipler alt satıra kayar; taşma olmaz. Tahmin ve alınan
          // el burada değil, koltukların kendi künyesinde durur.
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 5,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _chip(context, '${Str.trump} ♠', accent: true),
                _chip(
                  context,
                  '${Str.roundLabel} ${game.roundIndex + 1}/'
                  '${game.config.roundCount} · ${Str.yanLabel} ${game.config.yan}',
                ),
              ],
            ),
          ),
          _LeaveButton(onLeave: onLeave),
        ],
      ),
    );
  }

  /// Masanın rengi ne olursa olsun okunan pil.
  Widget _chip(BuildContext context, String text, {bool accent = false}) {
    final pal = context.pal;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: accent ? pal.accent : pal.panel,
        borderRadius: BorderRadius.circular(999),
        boxShadow: BatakPalette.onBoardShadow,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: accent ? FontWeight.w800 : FontWeight.w700,
          color: accent ? pal.onAccent : pal.inkSoft,
        ),
      ),
    );
  }
}

/// Masadan çıkış: üst barın sağ ucundaki yuvarlak düğme.
class _LeaveButton extends StatelessWidget {
  const _LeaveButton({required this.onLeave});

  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) => Material(
        color: context.pal.panel,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: IconButton(
          onPressed: onLeave,
          icon: const Icon(Icons.close_rounded, size: 18),
          color: context.pal.inkSoft,
          tooltip: Str.abandonGame,
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
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
        // Tahmin pop-up'ı açıkken künyeler söner: pop-up kenardakilerin üstüne
        // bindiği için yarım görünürlerdi, bilgileri de zaten pop-up'ta.
        AnimatedOpacity(
          opacity: session.humanCanBid ? 0 : 1,
          duration: anim(context, 220),
          curve: Curves.easeOut,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(alignment: Alignment.topCenter, child: _badge(game, 2)),
              Align(
                alignment: const Alignment(-0.92, -0.1),
                child: _badge(game, 3),
              ),
              Align(
                alignment: const Alignment(0.92, -0.1),
                child: _badge(game, 1),
              ),
            ],
          ),
        ),
        TrickView(
          trick: session.visibleTrick,
          winner: session.resolvingTrick?.winner,
          collecting: session.collecting,
          cardWidth: 76,
          deck: settings.deck,
          turkishIndices: settings.turkishIndices,
        ),
        // İnsanın künyesi masanın alt ucunda, botlarınkiyle aynı dilde:
        // kaç el aldığını oyun sırasında görmek gerekir.
        Align(
          alignment: const Alignment(0, 1),
          child: AnimatedOpacity(
            opacity: session.humanCanBid ? 0 : 1,
            duration: anim(context, 220),
            curve: Curves.easeOut,
            child: _badge(game, GameState.humanSeat),
          ),
        ),
      ],
    );
  }

  Widget _badge(GameState game, int seat) => SeatBadge(
        seat: seat,
        showBacks: seat != GameState.humanSeat,
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
