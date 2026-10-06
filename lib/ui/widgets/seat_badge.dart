import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../engine/models/game_state.dart';

import '../strings.dart';
import '../theme.dart';
import '../cards/deck_theme.dart';
import 'playing_card_view.dart';

/// Bir koltuğun masadaki künyesi: adı, elindeki kağıtlar ve **kaç el aldığı**.
///
/// Alınan el sayısı oyunun en çok bakılan bilgisidir, o yüzden künyenin
/// merkezinde büyük durur: `aldığı / tahmini`. Tahmin söylenmemişse tahmin
/// yerine tire yazar. Oyuncu tahminini doldurduğunda sayı vurgu rengine döner.
///
/// Masanın rengi desteye ve temaya göre değişir; künye her zaman panel
/// renginde bir pildir, böylece okunurluk masadan bağımsızdır.
class SeatBadge extends StatelessWidget {
  const SeatBadge({
    required this.seat,
    required this.cardsInHand,
    required this.bid,
    required this.taken,
    required this.isDealer,
    required this.isTurn,
    this.thinking = false,
    this.dealProgress = 1,
    this.deck = klasikDeck,
    this.showBacks = true,
    super.key,
  });

  final int seat;
  final int cardsInHand;

  /// Henüz tahmin söylenmediyse null.
  final int? bid;
  final int taken;
  final bool isDealer;
  final bool isTurn;
  final bool thinking;

  /// Dağıtım ilerlemesi (0–1); deste dağıtıldıkça büyür.
  final double dealProgress;

  /// Seçili deste; kapalı kağıdın sırtı buradan gelir.
  final DeckTheme deck;

  /// Elindeki kağıtların sırtı gösterilsin mi. İnsanın eli zaten yelpazede
  /// açık durduğu için onun künyesinde gösterilmez.
  final bool showBacks;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showBacks) ...[_backStack(), const SizedBox(height: 6)],
          _info(context),
        ],
      );

  Widget _backStack() {
    const width = 26.0;
    final dealt = dealProgress >= 1
        ? cardsInHand
        : (GameState.tricksPerRound * dealProgress).floor();
    final shown = math.min(cardsInHand, dealt).clamp(0, 8);
    return SizedBox(
      width: width + (shown <= 1 ? 0 : (shown - 1) * 7),
      height: width * deck.aspect,
      child: Stack(
        children: [
          for (var i = 0; i < shown; i++)
            Positioned(
              left: i * 7,
              child: CardBackView(width: width, theme: deck),
            ),
        ],
      ),
    );
  }

  Widget _info(BuildContext context) {
    final pal = context.pal;
    // Tahminini dolduran oyuncunun sayısı vurgulanır.
    final filled = bid != null && taken >= bid!;
    return AnimatedContainer(
      duration: anim(context, 200),
      padding: const EdgeInsets.fromLTRB(9, 5, 7, 5),
      decoration: BoxDecoration(
        color: isTurn ? pal.accent : pal.panel,
        borderRadius: BorderRadius.circular(999),
        boxShadow: BatakPalette.onBoardShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            Str.seatNames[seat],
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: isTurn ? pal.onAccent : pal.ink,
            ),
          ),
          if (isDealer) ...[
            const SizedBox(width: 5),
            Tooltip(
              message: Str.dealerBadge,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: pal.blush,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
          if (thinking) ...[
            const SizedBox(width: 6),
            SizedBox(
              width: 9,
              height: 9,
              child: CircularProgressIndicator(
                strokeWidth: 1.6,
                color: isTurn ? pal.onAccent : pal.accentDeep,
              ),
            ),
          ],
          const SizedBox(width: 7),
          _score(context, pal, filled: filled),
        ],
      ),
    );
  }

  /// `aldığı / tahmini` — oyun sırasında en çok bakılan sayı.
  Widget _score(BuildContext context, BatakPalette pal, {required bool filled}) {
    final onAccentBg = isTurn;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: onAccentBg
            ? pal.onAccent.withValues(alpha: 0.12)
            : pal.surfaceAlt,
        borderRadius: BorderRadius.circular(999),
      ),
      child: AnimatedSwitcher(
        duration: anim(context, 220),
        child: RichText(
          key: ValueKey('$taken/${bid ?? '-'}'),
          text: TextSpan(
            children: [
              TextSpan(
                text: '$taken',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                  color: filled
                      ? (onAccentBg ? pal.onAccent : pal.accentDeep)
                      : (onAccentBg ? pal.onAccent : pal.ink),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              TextSpan(
                text: '/${bid ?? Str.noBidShort}',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                  color: onAccentBg
                      ? pal.onAccent.withValues(alpha: 0.75)
                      : pal.inkDim,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
