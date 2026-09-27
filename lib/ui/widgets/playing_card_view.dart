import 'package:flutter/material.dart';

import '../../engine/models/card.dart';
import '../../engine/models/suit.dart';
import '../theme.dart';

/// Deste: **Sade Mobil**.
///
/// Bütün mürekkep sol üst köşede toplanır, çünkü yelpazede kartın görünen tek
/// parçası orasıdır. Pip yok; ortadaki soluk tür simgesi yalnızca masaya
/// atılan kağıtta işe yarar. Sağ alt köşe indeksi yok: kart hiçbir zaman ters
/// tutulmuyor.
///
/// Tüm ölçüler [width]'e oranlıdır, böylece aynı widget hem 52 px'lik masa
/// kağıdı hem 92 px'lik büyük kart olur.
class PlayingCardView extends StatelessWidget {
  const PlayingCardView({
    required this.card,
    required this.width,
    this.dimmed = false,
    this.trShortNames = false,
    super.key,
  });

  /// Kart oranı: 64 × 92.
  static const double aspect = 92 / 64;

  final PlayingCard card;
  final double width;

  /// Atılamayan kağıtlar soluk görünür.
  final bool dimmed;

  /// İndeks harfleri Türkçe: V (Vale), K (Kız), P (Papaz), A (As).
  final bool trShortNames;

  double get height => width * aspect;

  static Color colorOf(Suit suit) =>
      suit == Suit.hearts || suit == Suit.diamonds
          ? BatakColors.red
          : BatakColors.ink;

  @override
  Widget build(BuildContext context) {
    final color = colorOf(card.suit);
    final label = trShortNames ? card.rankCodeTr : card.rankCode;
    return Opacity(
      opacity: dimmed ? 0.55 : 1,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: BatakColors.cardFace,
          borderRadius: BorderRadius.circular(width * 0.13),
          border: Border.all(color: BatakColors.cardEdge, width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Soluk tür simgesi: masadaki kağıdı uzaktan tanımak için.
            Positioned(
              right: width * 0.06,
              bottom: -width * 0.06,
              child: Text(
                card.suit.symbol,
                style: TextStyle(
                  fontSize: width * 0.56,
                  height: 1,
                  color: color.withValues(alpha: 0.16),
                ),
              ),
            ),
            Positioned(
              left: width * 0.07,
              top: width * 0.02,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: width * 0.34,
                      height: 1,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -width * 0.015,
                      color: color,
                    ),
                  ),
                  Text(
                    card.suit.symbol,
                    style: TextStyle(
                      fontSize: width * 0.2,
                      height: 1.05,
                      color: color,
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
}

/// Kapalı kağıt: koyu yeşil yüz, pirinç ince çerçeve, ortada koz simgesi.
class CardBackView extends StatelessWidget {
  const CardBackView({required this.width, super.key});

  final double width;

  @override
  Widget build(BuildContext context) {
    final height = width * PlayingCardView.aspect;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(width * 0.13),
        border: Border.all(color: const Color(0xFF0D1C16)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [BatakColors.cardBack, BatakColors.cardBackDark],
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x33000000), blurRadius: 5, offset: Offset(0, 2)),
        ],
      ),
      child: Center(
        child: Container(
          margin: EdgeInsets.all(width * 0.07),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(width * 0.08),
            border: Border.all(
              color: BatakColors.brass.withValues(alpha: 0.55),
              width: width * 0.028,
            ),
          ),
          child: Center(
            child: Text(
              '♠',
              style: TextStyle(
                fontSize: width * 0.38,
                height: 1,
                color: BatakColors.brass.withValues(alpha: 0.8),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
