// Uygulama ikonunu üretir. Test değildir; Flutter'ın çizim motorunu kullanmak
// için test koşucusuyla çalıştırılır:
//
//   flutter test tool/generate_icons_test.dart
//
// Çıktı: android/app/src/main/res/mipmap-*/ic_launcher.png ve
// ic_launcher_foreground.png (uyarlanabilir ikonun ön katmanı).
//
// İkon elle hazırlanmış bir asset değil, çizimdir: renkler ve biçim oyunun
// kendi diliyle aynı kalsın ve gerektiğinde yeniden üretilebilsin diye.

import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

const _res = 'android/app/src/main/res';

/// Yoğunluk adı → tam ikon boyutu (px).
const _launcherSizes = {
  'mdpi': 48,
  'hdpi': 72,
  'xhdpi': 96,
  'xxhdpi': 144,
  'xxxhdpi': 192,
};

/// Uyarlanabilir ikonun ön katmanı 108 dp'dir; güvenli alan ortadaki 72 dp.
const _foregroundSizes = {
  'mdpi': 108,
  'hdpi': 162,
  'xhdpi': 216,
  'xxhdpi': 324,
  'xxxhdpi': 432,
};

void main() {
  testWidgets('ikonları üret', (tester) async {
    // Tuval 1024 px: test yüzeyi varsayılan 800×600'de kalırsa çizim kırpılır.
    tester.view.physicalSize = const Size(1024, 1024);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    for (final adaptive in [false, true]) {
      final key = GlobalKey();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: RepaintBoundary(
              key: key,
              child: SizedBox(
                width: 1024,
                height: 1024,
                child: CustomPaint(painter: BatakIconPainter(adaptive: adaptive)),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final sizes = adaptive ? _foregroundSizes : _launcherSizes;
      final name = adaptive ? 'ic_launcher_foreground' : 'ic_launcher';
      for (final entry in sizes.entries) {
        await tester.runAsync(() async {
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: entry.value / 1024);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          final dir = Directory('$_res/mipmap-${entry.key}')
            ..createSync(recursive: true);
          File('${dir.path}/$name.png')
              .writeAsBytesSync(data!.buffer.asUint8List());
          image.dispose();
        });
      }

      // Önizleme: gözle denetlemek için tam boy.
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 1);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        File('build/icon_preview_${adaptive ? 'foreground' : 'full'}.png')
            .writeAsBytesSync(data!.buffer.asUint8List());
        image.dispose();
      });
    }
  });
}

/// Batak ikonu: çuha zemin üstünde yelpaze yapmış iki kağıt, öndekinde koz maça.
class BatakIconPainter extends CustomPainter {
  const BatakIconPainter({required this.adaptive});

  /// Uyarlanabilir ikonun ön katmanı: zemin çizilmez ve çizim, maskelenince
  /// kırpılmasın diye güvenli alana sığdırılır.
  final bool adaptive;

  static const _feltLight = Color(0xFF276B51);
  static const _felt = Color(0xFF17402F);
  static const _feltDark = Color(0xFF0C2419);
  static const _brass = Color(0xFFD7A254);
  static const _cardFace = Color(0xFFFDFDFB);
  static const _ink = Color(0xFF14181B);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    if (!adaptive) _background(canvas, s);

    // Uyarlanabilir ikonda çizim, 108 dp'lik tuvalin ortadaki 72 dp'sine sığar.
    final artScale = adaptive ? 0.62 : 0.74;
    canvas.save();
    canvas.translate(s / 2, s / 2);
    canvas.scale(artScale);
    canvas.translate(-s / 2, -s / 2);
    _cards(canvas, s);
    canvas.restore();
  }

  void _background(Canvas canvas, double s) {
    final rect = Rect.fromLTWH(0, 0, s, s);
    final radius = Radius.circular(s * 0.22);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, radius),
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.1, -0.3),
          radius: 1.1,
          colors: [_feltLight, _felt, _feltDark],
          stops: [0, 0.55, 1],
        ).createShader(rect),
    );
    // İnce pirinç kenar.
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(s * 0.035), Radius.circular(s * 0.19)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.012
        ..color = _brass.withValues(alpha: 0.55),
    );
  }

  /// İki kağıt: arkadaki hafif sola, öndeki sağa yatık.
  void _cards(Canvas canvas, double s) {
    final cardW = s * 0.44;
    final cardH = cardW * 92 / 64;

    void card(double angle, Offset offset, {bool withSpade = false}) {
      canvas.save();
      canvas.translate(s / 2 + offset.dx, s / 2 + offset.dy);
      canvas.rotate(angle);
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: cardW,
        height: cardH,
      );
      final rrect = RRect.fromRectAndRadius(rect, Radius.circular(cardW * 0.11));
      canvas.drawRRect(
        rrect.shift(Offset(0, s * 0.012)),
        Paint()
          ..color = const Color(0x4D000000)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.018),
      );
      canvas.drawRRect(rrect, Paint()..color = _cardFace);
      canvas.drawRRect(
        rrect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.004
          ..color = const Color(0xFFD8DCD8),
      );
      if (withSpade) {
        final spadeH = cardH * 0.56;
        _spade(
          canvas,
          Rect.fromCenter(
            center: Offset(0, -cardH * 0.02),
            width: spadeH * 0.86,
            height: spadeH,
          ),
        );
      }
      canvas.restore();
    }

    card(-14 * math.pi / 180, Offset(-s * 0.10, s * 0.02));
    card(7 * math.pi / 180, Offset(s * 0.06, 0), withSpade: true);
  }

  /// Maça: iki yan lob, tepe ucu ve altındaki sap.
  void _spade(Canvas canvas, Rect r) {
    double x(double f) => r.left + r.width * f;
    double y(double f) => r.top + r.height * f;

    final spade = Path()
      ..moveTo(x(0.50), y(0.02))
      ..cubicTo(x(0.50), y(0.26), x(0.00), y(0.34), x(0.00), y(0.60))
      ..cubicTo(x(0.00), y(0.78), x(0.20), y(0.86), x(0.34), y(0.78))
      ..cubicTo(x(0.40), y(0.75), x(0.44), y(0.72), x(0.46), y(0.68))
      ..cubicTo(x(0.45), y(0.82), x(0.39), y(0.93), x(0.29), y(0.98))
      ..lineTo(x(0.71), y(0.98))
      ..cubicTo(x(0.61), y(0.93), x(0.55), y(0.82), x(0.54), y(0.68))
      ..cubicTo(x(0.56), y(0.72), x(0.60), y(0.75), x(0.66), y(0.78))
      ..cubicTo(x(0.80), y(0.86), x(1.00), y(0.78), x(1.00), y(0.60))
      ..cubicTo(x(1.00), y(0.34), x(0.50), y(0.26), x(0.50), y(0.02))
      ..close();
    canvas.drawPath(spade, Paint()..color = _ink);
  }

  @override
  bool shouldRepaint(BatakIconPainter old) => old.adaptive != adaptive;
}
