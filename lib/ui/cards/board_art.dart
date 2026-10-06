import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Masanın üslubu. Hepsi çizimdir: görsel dosya yok, her ekran oranına uyar.
///
/// Masanın işi kağıtları taşımaktır; bu yüzden hepsi sakin ve koyudur. Açık
/// renkli kağıtlar üstünde öne çıksın diye kontrast masadan değil kağıttan
/// gelir.
enum BoardStyle {
  /// Düz çuha: ortadan gelen ışık ve kenarlara doğru kararma.
  sade('sade', 'Sade çuha'),

  /// Çuhanın ortasında, kağıtların düştüğü yeri belli eden soluk bir halka.
  halka('halka', 'Halkalı çuha'),

  /// Masanın kenarına işlenmiş ince çift çizgi.
  kenar('kenar', 'Kenar işlemeli'),

  /// Çuhaya çok soluk basılmış küçük baklava deseni.
  doku('doku', 'Desenli çuha'),

  /// Destenin kendi çizilmiş masası. Yalnızca görsel destelerde vardır;
  /// çizilen destede sade çuhaya düşer.
  gorsel('gorsel', 'Destenin masası');

  const BoardStyle(this.code, this.label);

  final String code;
  final String label;

  static BoardStyle fromCode(String? code) =>
      BoardStyle.values.firstWhere((s) => s.code == code,
          orElse: () => BoardStyle.halka);
}

/// Bir masanın renkleri. Deste ile birlikte gelir.
final class BoardPalette {
  const BoardPalette({
    required this.light,
    required this.base,
    required this.dark,
    required this.accent,
  });

  /// Ortadaki ışığın rengi.
  final Color light;

  /// Çuhanın ana rengi.
  final Color base;

  /// Kenarlardaki koyu ton.
  final Color dark;

  /// İnce çizgilerin ve halkanın rengi (altın, bronz…).
  final Color accent;
}

/// Masayı çizer.
class BoardPainter extends CustomPainter {
  const BoardPainter({required this.style, required this.palette});

  final BoardStyle style;
  final BoardPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    _felt(canvas, size);
    switch (style) {
      // Görsel masası olmayan destede (ya da görsel kapalıyken) düz çuha.
      case BoardStyle.sade:
      case BoardStyle.gorsel:
        break;
      case BoardStyle.halka:
        _ring(canvas, size);
      case BoardStyle.kenar:
        _inlay(canvas, size);
      case BoardStyle.doku:
        _pattern(canvas, size);
    }
    _vignette(canvas, size);
  }

  /// Çuha: ortadan gelen ışık ve ince dokuma izi.
  void _felt(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.25),
          radius: 1.05,
          colors: [palette.light, palette.base, palette.dark],
          stops: const [0, 0.55, 1],
        ).createShader(rect),
    );

    // Dokuma izi: çok soluk çapraz çizgiler.
    final threads = Paint()
      ..color = Colors.white.withValues(alpha: 0.016)
      ..strokeWidth = 1;
    for (var x = -size.height; x < size.width; x += 7) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), threads);
    }
  }

  /// Kağıtların düştüğü yeri belli eden halka.
  void _ring(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.42);
    final radius = size.width * 0.36;

    canvas.drawCircle(
      center,
      radius,
      Paint()..color = Colors.black.withValues(alpha: 0.10),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1, size.width * 0.004)
        ..color = palette.accent.withValues(alpha: 0.30),
    );
    canvas.drawCircle(
      center,
      radius * 0.93,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.8, size.width * 0.002)
        ..color = palette.accent.withValues(alpha: 0.16),
    );
  }

  /// Masanın kenarına işlenmiş çift çizgi.
  void _inlay(Canvas canvas, Size size) {
    final outer = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(size.width * 0.045),
      Radius.circular(size.width * 0.06),
    );
    final inner = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(size.width * 0.062),
      Radius.circular(size.width * 0.045),
    );
    canvas.drawRRect(
      outer,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.2, size.width * 0.005)
        ..color = palette.accent.withValues(alpha: 0.34),
    );
    canvas.drawRRect(
      inner,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.8, size.width * 0.002)
        ..color = palette.accent.withValues(alpha: 0.18),
    );
  }

  /// Çuhaya basılmış küçük baklavalar.
  void _pattern(Canvas canvas, Size size) {
    final step = size.width * 0.115;
    final half = step * 0.17;
    final paint = Paint()..color = palette.accent.withValues(alpha: 0.055);
    for (var y = step / 2; y < size.height; y += step) {
      final offset = ((y / step).floor().isEven) ? 0.0 : step / 2;
      for (var x = offset + step / 2; x < size.width; x += step) {
        final diamond = Path()
          ..moveTo(x, y - half)
          ..lineTo(x + half, y)
          ..lineTo(x, y + half)
          ..lineTo(x - half, y)
          ..close();
        canvas.drawPath(diamond, paint);
      }
    }
  }

  /// Kenarlara doğru kararma: gözü masanın ortasında tutar.
  void _vignette(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.15),
          radius: 0.95,
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.38)],
          stops: const [0.6, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(BoardPainter old) =>
      old.style != style || old.palette != palette;
}
