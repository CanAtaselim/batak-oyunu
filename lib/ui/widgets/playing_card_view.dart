import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../engine/models/card.dart';
import '../../engine/models/suit.dart';
import '../cards/deck_theme.dart';
import '../theme.dart';

/// Deste: **Sade Mobil**.
///
/// İndeks **iki köşede** durur: sol üstte ve sağ altta (180° dönük). Yelpazede
/// kartın görünen tek parçası sol üst köşedir; masaya atılan kağıt başka bir
/// kağıdın altında kalırsa da diğer köşesinden okunur.
///
/// Pip yok; ortadaki büyük tür simgesi kağıdı uzaktan tanıtır.
///
/// Tüm ölçüler [width]'e oranlıdır, böylece aynı widget hem 52 px'lik masa
/// kağıdı hem 92 px'lik büyük kart olur.
class PlayingCardView extends StatelessWidget {
  const PlayingCardView({
    required this.card,
    required this.width,
    this.theme = klasikDeck,
    this.dimmed = false,
    this.trShortNames = false,
    super.key,
  });

  /// Çizilen destenin kart oranı: 64 × 92. Görsel desteler 5:7'dir; ölçü
  /// [DeckTheme.aspect]'ten alınır.
  static const double aspect = 92 / 64;

  /// Karartma tülünün anahtarı; testler bununla arıyor.
  static const String dimKey = 'kartKarartma';

  final PlayingCard card;
  final double width;

  /// Deste ve masa teması. Görsel destelerde kağıt dosyadan çizilir.
  final DeckTheme theme;

  /// Atılamayan kağıtlar kararır. Saydamlık kullanılmaz: saydam kart alttaki
  /// kağıdı göstererek yelpazeyi iç içe geçmiş gibi gösteriyordu.
  final bool dimmed;

  /// İndeks harfleri Türkçe: V (Vale), K (Kız), P (Papaz), A (As).
  final bool trShortNames;

  double get height => width * theme.aspect;

  static Color colorOf(Suit suit) =>
      suit == Suit.hearts || suit == Suit.diamonds
          ? BatakColors.red
          : BatakColors.cardInk;

  @override
  Widget build(BuildContext context) {
    if (!theme.drawn) return _assetCard(theme.cardAsset(card));
    final color = colorOf(card.suit);
    final label = trShortNames ? card.rankCodeTr : card.rankCode;
    return Container(
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
          // Ortadaki tür simgesi: masadaki kağıdı uzaktan tanıtır. Tam
          // renkte durur, iki köşedeki indekslere yer bırakır.
          Center(
            child: Text(
              card.suit.symbol,
              style: TextStyle(
                fontSize: width * 0.5,
                height: 1,
                color: color,
              ),
            ),
          ),
          Positioned(
            left: width * 0.07,
            top: width * 0.02,
            child: _corner(color, label),
          ),
          Positioned(
            right: width * 0.07,
            bottom: width * 0.02,
            child: Transform.rotate(
              angle: math.pi,
              child: _corner(color, label),
            ),
          ),
          // Atılamayan kağıdın üstüne serilen koyu tül. Kartın kendisi opak
          // kalır; saydamlık kullanılsaydı alttaki kağıt içinden görünürdü.
          if (dimmed)
            const Positioned.fill(
              key: ValueKey(dimKey),
              child: ColoredBox(color: Color(0x52000A06)),
            ),
        ],
      ),
    );
  }

  /// Görsel desteden gelen kağıt. Dosyanın köşeleri zaten şeffaf ve yuvarlak
  /// olduğu için arkasına zemin çizilmez.
  Widget _assetCard(String asset) {
    final radius = BorderRadius.circular(width * 0.07);
    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: const [
            BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            children: [
              Image.asset(asset, width: width, height: height, fit: BoxFit.fill),
              if (dimmed)
                const Positioned.fill(
                  key: ValueKey(dimKey),
                  child: ColoredBox(color: Color(0x52000A06)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Köşe indeksi: değer ve altında tür simgesi.
  Widget _corner(Color color, String label) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
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
            style: TextStyle(fontSize: width * 0.2, height: 1.05, color: color),
          ),
        ],
      );
}

/// Kapalı kağıt: koyu yeşil yüz, pirinç ince çerçeve, ortada koz simgesi.
class CardBackView extends StatelessWidget {
  const CardBackView({
    required this.width,
    this.theme = klasikDeck,
    super.key,
  });

  final double width;
  final DeckTheme theme;

  @override
  Widget build(BuildContext context) {
    final height = width * theme.aspect;
    if (!theme.drawn) {
      final radius = BorderRadius.circular(width * 0.07);
      return SizedBox(
        width: width,
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: const [
              BoxShadow(color: Color(0x33000000), blurRadius: 5, offset: Offset(0, 2)),
            ],
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: Image.asset(
              theme.backAsset,
              width: width,
              height: height,
              fit: BoxFit.fill,
            ),
          ),
        ),
      );
    }
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
