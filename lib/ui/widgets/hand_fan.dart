import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../engine/models/card.dart';
import '../theme.dart';
import 'playing_card_view.dart';

/// İnsan oyuncunun 13 kağıtlık yelpazesi.
///
/// Kartların çoğu üst üste durur; görünen tek parça sol üst köşedir. Bu yüzden
/// atılabilen kağıtlar yukarı kaldırılır, atılamayanlar soluk bırakılır — hangi
/// kağıdın tıklanabilir olduğu tek bakışta anlaşılsın.
class HandFan extends StatelessWidget {
  const HandFan({
    required this.hand,
    required this.legalCards,
    required this.onTap,
    this.enabled = true,
    this.turkishIndices = false,
    super.key,
  });

  final List<PlayingCard> hand;
  final List<PlayingCard> legalCards;
  final ValueChanged<PlayingCard> onTap;
  final bool enabled;
  final bool turkishIndices;

  static const double _maxCardWidth = 66;
  static const double _lift = 14;

  @override
  Widget build(BuildContext context) {
    if (hand.isEmpty) return const SizedBox(height: 108);
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth - 12;
        final cardWidth = math.min(_maxCardWidth, available * 0.19);
        final cardHeight = cardWidth * PlayingCardView.aspect;
        final step = hand.length == 1
            ? 0.0
            : math.min(
                cardWidth * 0.46,
                (available - cardWidth) / (hand.length - 1),
              );
        final fanWidth = cardWidth + step * (hand.length - 1);
        final mid = (hand.length - 1) / 2;

        return SizedBox(
          height: cardHeight + _lift + 10,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              SizedBox(
                width: fanWidth,
                height: cardHeight + _lift + 10,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (var i = 0; i < hand.length; i++)
                      _fanCard(context, i, cardWidth, step, mid),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _fanCard(
    BuildContext context,
    int i,
    double cardWidth,
    double step,
    double mid,
  ) {
    final card = hand[i];
    final isLegal = enabled && legalCards.contains(card);
    final angle = (i - mid) * 0.9 * math.pi / 180;
    // Kağıt oynandıkça yelpaze yeniden yerleşir; kalan kartlar kayarak gider.
    return AnimatedPositioned(
      key: ValueKey(card.code),
      duration: anim(context, 180),
      curve: Curves.easeOutCubic,
      left: i * step,
      bottom: isLegal ? _lift : 0,
      child: Transform.rotate(
        angle: angle,
        alignment: Alignment.bottomCenter,
        child: GestureDetector(
          onTap: isLegal ? () => onTap(card) : null,
          behavior: HitTestBehavior.opaque,
          child: PlayingCardView(
            card: card,
            width: cardWidth,
            dimmed: enabled && !isLegal,
            trShortNames: turkishIndices,
          ),
        ),
      ),
    );
  }
}
