import 'package:flutter/material.dart';

import '../theme.dart';

/// Çocuğunu belirirken yumuşatır: hafif yukarı kayma ve sönümlenme.
///
/// Sayfa açılışında görünmeyen içerik bırakmaz; animasyon kapalıysa doğrudan
/// son halinde çizilir.
class Appear extends StatefulWidget {
  const Appear({
    required this.child,
    this.ms = 220,
    this.offset = const Offset(0, 0.06),
    this.scaleFrom = 1.0,
    super.key,
  });

  final Widget child;
  final int ms;

  /// Başlangıç kayması, çocuğun boyutuna oranlı.
  final Offset offset;

  /// Başlangıç ölçeği. 1'den küçük verilince içerik büyüyerek belirir; pop-up
  /// açılışında masanın üstüne çıktığı izlenimini verir.
  final double scaleFrom;

  @override
  State<Appear> createState() => _AppearState();
}

class _AppearState extends State<Appear> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    duration: Duration(milliseconds: widget.ms),
    vsync: this,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _controller.duration = anim(context, widget.ms);
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    return AnimatedBuilder(
      animation: curve,
      builder: (context, child) => Opacity(
        opacity: curve.value,
        child: Transform.scale(
          scale: widget.scaleFrom + (1 - widget.scaleFrom) * curve.value,
          child: FractionalTranslation(
            translation: widget.offset * (1 - curve.value),
            child: child,
          ),
        ),
      ),
      child: widget.child,
    );
  }
}
