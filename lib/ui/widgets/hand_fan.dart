import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../engine/models/card.dart';
import '../../engine/models/suit.dart';
import '../theme.dart';
import 'playing_card_view.dart';

/// Eldeki kağıtların ekrandaki sırası: **renkler dönüşümlü** dizilir, yani iki
/// siyah ya da iki kırmızı tür yan yana gelmez. Aynı türün içinde küçükten
/// büyüğe.
///
/// Sıra kağıt kümesinin saf bir işlevidir: bir kağıt oynandığında kalanların
/// yeri değişmez, kartlar zıplamaz. Kural motorunu ilgilendirmez, yalnızca
/// görünümdür.
const List<Suit> blackSuits = [Suit.spades, Suit.clubs];
const List<Suit> redSuits = [Suit.hearts, Suit.diamonds];

/// Elde bulunan türleri renkleri dönüşümlü olacak şekilde sıraya dizer.
///
/// Bir renk diğerinden fazlaysa çok olan renkle başlanır; böylece aynı renk
/// ancak zorunlu kaldığında (örneğin elde hiç kırmızı yoksa) yan yana gelir.
List<Suit> handSuitOrder(Iterable<PlayingCard> hand) {
  final present = hand.map((c) => c.suit).toSet();
  final blacks = [for (final s in blackSuits) if (present.contains(s)) s];
  final reds = [for (final s in redSuits) if (present.contains(s)) s];
  final startBlack = blacks.length >= reds.length;
  final first = startBlack ? blacks : reds;
  final second = startBlack ? reds : blacks;

  final order = <Suit>[];
  for (var i = 0; i < first.length || i < second.length; i++) {
    if (i < first.length) order.add(first[i]);
    if (i < second.length) order.add(second[i]);
  }
  return order;
}

List<PlayingCard> handDisplayOrder(Iterable<PlayingCard> hand) {
  final order = handSuitOrder(hand);
  final cards = [...hand];
  cards.sort((a, b) {
    final suitDiff = order.indexOf(a.suit) - order.indexOf(b.suit);
    return suitDiff != 0 ? suitDiff : a.rank - b.rank;
  });
  return cards;
}

/// İnsan oyuncunun 13 kağıtlık yelpazesi.
///
/// Kağıtlar bir yay üzerine dizilir: ortadakiler yukarıda ve dik, kenardakiler
/// aşağıda ve eğik durur — elde tutulan deste gibi. Görünen tek parça sol üst
/// köşe olduğu için atılabilen kağıtlar yukarı kaldırılır, atılamayanlar soluk
/// bırakılır.
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

  /// Atılabilen kağıdın yukarı kalkma payı.
  static const double _lift = 14;

  /// Kenardaki kağıdın ortadakine göre ne kadar alçakta durduğu.
  static const double _arcDrop = 20;

  /// Yelpazenin uçtaki kağıdının eğimi.
  static const double _maxAngle = 11 * math.pi / 180;

  @override
  Widget build(BuildContext context) {
    if (hand.isEmpty) return const SizedBox(height: 108);
    final cards = handDisplayOrder(hand);
    return LayoutBuilder(
      builder: (context, constraints) {
        // Eğik duran uç kağıtlar köşeleriyle dışarı taşar; kenarda pay kalır.
        final available = constraints.maxWidth - 44;
        final cardWidth = math.min(_maxCardWidth, available * 0.19);
        final cardHeight = cardWidth * PlayingCardView.aspect;
        final step = cards.length == 1
            ? 0.0
            : math.min(
                cardWidth * 0.46,
                (available - cardWidth) / (cards.length - 1),
              );
        final fanWidth = cardWidth + step * (cards.length - 1);

        return SizedBox(
          height: cardHeight + _lift + _arcDrop + 12,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              SizedBox(
                width: fanWidth,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (var i = 0; i < cards.length; i++)
                      _fanCard(context, cards, i, cardWidth, step),
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
    List<PlayingCard> cards,
    int i,
    double cardWidth,
    double step,
  ) {
    final card = cards[i];
    final isLegal = enabled && legalCards.contains(card);

    // Yaydaki konum: ortada 0, uçlarda ±1.
    final mid = (cards.length - 1) / 2;
    final t = mid == 0 ? 0.0 : (i - mid) / mid;
    final angle = t * _maxAngle;
    final drop = t * t * _arcDrop;

    // Kağıt oynandıkça yelpaze yeniden yerleşir; kalan kartlar kayarak gider.
    return AnimatedPositioned(
      key: ValueKey(card.code),
      duration: anim(context, 180),
      curve: Curves.easeOutCubic,
      left: i * step,
      bottom: (isLegal ? _lift : 0) + (_arcDrop - drop),
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
