import 'package:flutter/material.dart';

import '../strings.dart';
import '../theme.dart';
import 'playing_card_view.dart';

/// Bir botun masadaki künyesi: adı, tahmini, aldığı el ve elindeki kağıt sayısı.
class SeatBadge extends StatelessWidget {
  const SeatBadge({
    required this.seat,
    required this.cardsInHand,
    required this.bid,
    required this.taken,
    required this.isDealer,
    required this.isTurn,
    this.thinking = false,
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

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [_backStack(), const SizedBox(height: 6), _info(context)],
      );

  Widget _backStack() {
    const width = 26.0;
    final shown = cardsInHand.clamp(0, 8);
    return SizedBox(
      width: width + (shown <= 1 ? 0 : (shown - 1) * 7),
      height: width * PlayingCardView.aspect,
      child: Stack(
        children: [
          for (var i = 0; i < shown; i++)
            Positioned(left: i * 7, child: const CardBackView(width: width)),
        ],
      ),
    );
  }

  Widget _info(BuildContext context) {
    final bidText = bid == null ? Str.waitingBid : '$bid';
    return AnimatedContainer(
      duration: anim(context, 200),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0x8C081409),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isTurn
              ? BatakColors.brass.withValues(alpha: 0.85)
              : Colors.white.withValues(alpha: 0.14),
          width: isTurn ? 1.4 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            Str.seatNames[seat],
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: BatakColors.onFelt,
            ),
          ),
          if (isDealer) ...[
            const SizedBox(width: 5),
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: BatakColors.brass,
                shape: BoxShape.circle,
              ),
            ),
          ],
          const SizedBox(width: 7),
          // Tahmin söylendiği anda ve el alındıkça sayı yumuşak değişir.
          AnimatedSwitcher(
            duration: anim(context, 220),
            child: Text(
              '${Str.bidShort}$bidText · ${Str.takenShort}$taken',
              key: ValueKey('$bidText/$taken'),
              style: const TextStyle(
                fontSize: 11,
                color: BatakColors.onFeltDim,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
          if (thinking) ...[
            const SizedBox(width: 6),
            const SizedBox(
              width: 9,
              height: 9,
              child: CircularProgressIndicator(
                strokeWidth: 1.6,
                color: BatakColors.brass,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
