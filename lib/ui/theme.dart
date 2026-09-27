import 'package:flutter/material.dart';

/// Masanın ve kartların renkleri. Kart yüzü fiziksel bir nesne gibi davranır:
/// tema ne olursa olsun beyaz kalır.
abstract final class BatakColors {
  static const felt = Color(0xFF183A2E);
  static const feltDark = Color(0xFF0E241C);
  static const feltLight = Color(0xFF23503F);
  static const brass = Color(0xFFD7A254);
  static const ink = Color(0xFF14181B);
  static const cardFace = Color(0xFFFFFFFF);
  static const cardEdge = Color(0xFFD8DCD8);
  static const cardBack = Color(0xFF1C4235);
  static const cardBackDark = Color(0xFF12291F);
  static const red = Color(0xFFD22B32);
  static const onFelt = Color(0xFFEAF2EC);
  static const onFeltDim = Color(0xFFA9BDB1);
  static const good = Color(0xFF4FA47C);
  static const bad = Color(0xFFE0705A);
}

/// Animasyon süresi. Sistemde animasyonlar kapatılmışsa sıfır döner, böylece
/// erişilebilirlik ayarına uyulur.
Duration anim(BuildContext context, int ms) =>
    MediaQuery.maybeDisableAnimationsOf(context) ?? false
        ? Duration.zero
        : Duration(milliseconds: ms);

ThemeData buildTheme() {
  const scheme = ColorScheme.dark(
    primary: BatakColors.brass,
    onPrimary: BatakColors.ink,
    secondary: BatakColors.feltLight,
    surface: Color(0xFF16241E),
    onSurface: BatakColors.onFelt,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: BatakColors.felt,
    fontFamily: null,
    textTheme: const TextTheme(
      titleLarge: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.3),
      titleMedium: TextStyle(fontWeight: FontWeight.w600),
      bodyMedium: TextStyle(height: 1.4),
      labelSmall: TextStyle(letterSpacing: 0.6, fontWeight: FontWeight.w600),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
      ),
    ),
  );
}
