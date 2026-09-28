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

/// İnsan oyuncunun eli: **iki sıra yelpaze** halinde dizilir.
///
/// 13 kağıtta üstte 6, altta 7 kağıt durur; alt sıra üst sıranın alt kısmını
/// örter. Her sıra kendi içinde yay çizer: ortadaki kağıtlar yukarıda ve dik,
/// uçtakiler aşağıda ve eğik — elde tutulan deste gibi.
///
/// Atılabilen kağıtlar yukarı kaldırılır, atılamayanlar soluk bırakılır.
class HandFan extends StatelessWidget {
  const HandFan({
    required this.hand,
    required this.legalCards,
    required this.onTap,
    this.enabled = true,
    this.turkishIndices = false,
    this.dealProgress = 1,
    super.key,
  });

  final List<PlayingCard> hand;
  final List<PlayingCard> legalCards;
  final ValueChanged<PlayingCard> onTap;
  final bool enabled;
  final bool turkishIndices;

  /// Dağıtım animasyonunun ilerlemesi (0–1). Kağıtlar soldan sağa, sırayla
  /// masadan gelip yerine oturur. 1 ise animasyon yok, hepsi yerinde.
  final double dealProgress;

  static const double _maxCardWidth = 88;

  /// Atılabilen kağıdın yukarı kalkma payı.
  static const double _lift = 14;

  /// Bir sıradaki kağıtların ne kadarının görüneceği (kart eninin oranı).
  static const double _overlap = 0.62;

  /// Bir sıranın ucundaki kağıdın ortadakine göre alçalma payı.
  static const double _arcDrop = 14;

  /// Üst sıradaki kağıdın merkezi ile alt sıranın üst kenarı arasında kalması
  /// istenen boşluk. Merkez örtülürse o kağıda dokunulamaz.
  static const double _tapMargin = 10;

  /// Bir sıranın ucundaki kağıdın eğimi.
  static const double _maxAngle = 10 * math.pi / 180;

  /// Dağıtılan kağıdın masadan ele kadar kat ettiği yol.
  static const double _dealTravel = 120;

  @override
  Widget build(BuildContext context) {
    if (hand.isEmpty) return const SizedBox(height: 132);
    final cards = handDisplayOrder(hand);
    // Alt sıra kalabalık olan sıradır: 13 kağıtta üstte 6, altta 7.
    final bottomCount = (cards.length / 2).ceil();
    final topCount = cards.length - bottomCount;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Eğik duran uç kağıtlar köşeleriyle dışarı taşar; kenarda pay kalır.
        final available = constraints.maxWidth - 44;
        // Kart eni kalabalık sıraya göre seçilir ki o sıra ekrana sığsın.
        final widest = bottomCount < 1 ? 1 : bottomCount;
        final fitWidth = available / (1 + _overlap * (widest - 1));
        final cardWidth = math.min(_maxCardWidth, fitWidth);
        final cardHeight = cardWidth * PlayingCardView.aspect;
        final step = cardWidth * _overlap;
        // Üst sıra, alt sıranın en yüksek kağıdını yarı boyu kadar aşmalı:
        // yoksa üst kağıdın merkezi alta gömülür ve dokunuş oraya gitmez.
        final rowGap = cardHeight / 2 + _arcDrop + _tapMargin;

        // Genişlik açıkça veriliyor: Stack'in içinde yalnızca Positioned
        // çocuklar var ve konumlanmamış tek bir çocuk (boş sıra) genişliği
        // sıfıra düşürürse kağıtlar çizilir ama dokunuş ulaşmaz.
        return SizedBox(
          width: constraints.maxWidth,
          height: cardHeight + rowGap + _lift + _arcDrop + 8,
          child: Stack(
            alignment: Alignment.bottomCenter,
            clipBehavior: Clip.none,
            children: [
              // Üst sıra önce çizilir, alt sıra onun üstüne biner.
              if (topCount > 0)
                _row(
                  context,
                  cards.take(topCount).toList(),
                  offset: 0,
                  total: cards.length,
                  cardWidth: cardWidth,
                  step: step,
                  bottom: rowGap,
                ),
              _row(
                context,
                cards.skip(topCount).toList(),
                offset: topCount,
                total: cards.length,
                cardWidth: cardWidth,
                step: step,
                bottom: 0,
              ),
            ],
          ),
        );
      },
    );
  }

  /// Tek bir sıra; kendi içinde yay çizer. Boş sıra hiç eklenmez.
  Widget _row(
    BuildContext context,
    List<PlayingCard> cards, {
    required int offset,
    required int total,
    required double cardWidth,
    required double step,
    required double bottom,
  }) {
    assert(cards.isNotEmpty, 'boş sıra Stack genişliğini bozar');
    final width = cardWidth + step * (cards.length - 1);
    return Positioned(
      bottom: bottom,
      child: SizedBox(
        width: width,
        height: cardWidth * PlayingCardView.aspect + _lift + _arcDrop,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (var i = 0; i < cards.length; i++)
              _fanCard(
                context,
                cards[i],
                i,
                cards.length,
                cardWidth,
                step,
                _dealT(offset + i, total),
              ),
          ],
        ),
      ),
    );
  }

  /// [index] numaralı kağıdın kendi giriş animasyonundaki ilerlemesi.
  ///
  /// Her kağıt dağıtımın 1/[total]'i kadar sürede yerine oturur; sıradaki
  /// kağıt bir öncekinin hemen ardından gelir.
  double _dealT(int index, int total) {
    if (dealProgress >= 1) return 1;
    final t = dealProgress * total - index;
    return t.clamp(0.0, 1.0);
  }

  Widget _fanCard(
    BuildContext context,
    PlayingCard card,
    int i,
    int rowLength,
    double cardWidth,
    double step,
    double dealT,
  ) {
    final isLegal = enabled && legalCards.contains(card);

    // Sıradaki yay konumu: ortada 0, uçlarda ±1.
    final mid = (rowLength - 1) / 2;
    final t = mid == 0 ? 0.0 : (i - mid) / mid;
    final angle = t * _maxAngle;
    final drop = t * t * _arcDrop;

    // Dağıtım: kağıt masadan gelip yerine oturur.
    final eased = Curves.easeOutCubic.transform(dealT);

    // Kağıt oynandıkça sıralar yeniden dizilir; kalan kartlar kayarak gider.
    return AnimatedPositioned(
      key: ValueKey(card.code),
      duration: anim(context, 180),
      curve: Curves.easeOutCubic,
      left: i * step,
      bottom: (isLegal ? _lift : 0) + (_arcDrop - drop),
      child: Transform.translate(
        offset: Offset(0, -(1 - eased) * _dealTravel),
        child: Transform.scale(
          scale: 0.86 + 0.14 * eased,
          child: Opacity(
            opacity: eased,
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
          ),
        ),
      ),
    );
  }
}
