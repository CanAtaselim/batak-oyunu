import 'package:flutter/material.dart';

import '../../engine/models/trick.dart';
import '../theme.dart';
import 'playing_card_view.dart';

/// Masanın ortası: her koltuğun attığı kağıt kendi yönünde durur.
///
/// Koltuk 0 alt, 1 sağ, 2 üst, 3 sol. Kağıt atılırken sahibinin yönünden
/// kayarak gelir; el toplanırken dördü birlikte kazananın yönüne süzülür.
///
/// Kağıtlar **atılma sırasına göre** üst üste biner: eli açanın kağıdı en
/// altta, en son atılan kağıt en üstte durur. Gerçek masada olduğu gibi.
class TrickView extends StatelessWidget {
  const TrickView({
    required this.trick,
    this.winner,
    this.collecting = false,
    this.cardWidth = 54,
    this.turkishIndices = false,
    super.key,
  });

  final Trick trick;

  /// El sonuçlandıysa kazanan koltuk; sürerken null.
  final int? winner;

  /// El toplanıyor: kağıtlar kazananın yönüne gidip kayboluyor.
  final bool collecting;

  final double cardWidth;
  final bool turkishIndices;

  static const _slots = <int, Alignment>{
    0: Alignment(0, 0.72),
    1: Alignment(0.72, 0),
    2: Alignment(0, -0.72),
    3: Alignment(-0.72, 0),
  };

  static const _angles = <int, double>{0: 0.03, 1: 0.09, 2: -0.04, 3: -0.09};

  /// Koltuğun masaya göre yönü; hem giriş hem toplama animasyonu bunu kullanır.
  /// Kağıdın sahibinin önünden masaya kat ettiği yol. İnsanın eli masadan
  /// daha uzakta olduğu için onunki daha uzun.
  static const _travel = <int, double>{0: 190, 1: 130, 2: 130, 3: 130};

  static const _dirs = <int, Offset>{
    0: Offset(0, 1),
    1: Offset(1, 0),
    2: Offset(0, -1),
    3: Offset(-1, 0),
  };

  @override
  Widget build(BuildContext context) {
    final height = cardWidth * PlayingCardView.aspect;
    final collectDir = collecting && winner != null ? _dirs[winner]! : null;
    return SizedBox(
      width: cardWidth * 3.1,
      height: height * 2.3,
      child: Stack(
        // Kağıt masanın dışından gelir; yol boyunca kırpılmamalı.
        clipBehavior: Clip.none,
        children: [
          // Atılma sırası çizim sırasıdır: son atılan kağıt en üstte kalır.
          for (final play in trick.plays)
            Align(
              alignment: _slots[play.seat]!,
              child: _TrickCard(
                key: ValueKey(play.card.code),
                from: _dirs[play.seat]!,
                travel: _travel[play.seat]!,
                angle: _angles[play.seat]!,
                isWinner: winner == play.seat,
                collectTo: collectDir,
                child: PlayingCardView(
                  card: play.card,
                  width: cardWidth,
                  trShortNames: turkishIndices,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Masaya atılan tek kağıt: geldiği yönden kayar, kazandıysa parlar, el
/// toplanırken kazananın yönüne süzülür.
class _TrickCard extends StatefulWidget {
  const _TrickCard({
    required this.from,
    required this.travel,
    required this.angle,
    required this.isWinner,
    required this.collectTo,
    required this.child,
    super.key,
  });

  final Offset from;

  /// Kağıdın sahibinin önünden masaya kat ettiği yol.
  final double travel;

  final double angle;
  final bool isWinner;
  final Offset? collectTo;
  final Widget child;

  @override
  State<_TrickCard> createState() => _TrickCardState();
}

class _TrickCardState extends State<_TrickCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enter;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    // Süre build'de MediaQuery'den okunamaz; ilk çerçevede ayarlanır.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _enter.duration = anim(context, 300);
      _enter.forward();
    });
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final collecting = widget.collectTo != null;
    return AnimatedBuilder(
      animation: _enter,
      builder: (context, child) {
        final t = Curves.easeOutCubic.transform(_enter.value);
        return Transform.translate(
          // Kağıt sahibinin önünden masaya doğru gelir.
          offset: widget.from * (1 - t) * widget.travel,
          child: Transform.scale(
            scale: 0.88 + 0.12 * t,
            child: Opacity(opacity: (0.2 + 1.6 * t).clamp(0.0, 1.0), child: child),
          ),
        );
      },
      child: AnimatedSlide(
        offset: collecting ? widget.collectTo! * 1.9 : Offset.zero,
        duration: anim(context, 260),
        curve: Curves.easeInCubic,
        child: AnimatedOpacity(
          opacity: collecting ? 0 : 1,
          duration: anim(context, 260),
          child: Transform.rotate(
            angle: widget.angle,
            child: AnimatedScale(
              duration: anim(context, 160),
              scale: widget.isWinner && !collecting ? 1.06 : 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: widget.isWinner && !collecting
                      ? const [
                          BoxShadow(
                            color: Color(0x99D7A254),
                            blurRadius: 14,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
