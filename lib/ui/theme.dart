import 'package:flutter/material.dart';

/// Kağıdın kendi renkleri. Kart fiziksel bir nesnedir: tema açık da olsa koyu
/// da olsa kağıt aynı basılmıştır, bu yüzden bu tonlar temaya bağlı değildir.
abstract final class BatakColors {
  static const cardFace = Color(0xFFFFFFFF);
  static const cardEdge = Color(0xFFE0DCD4);
  static const cardBack = Color(0xFF1C4235);
  static const cardBackDark = Color(0xFF12291F);
  static const cardInk = Color(0xFF14181B);
  static const red = Color(0xFFD22B32);
  static const brass = Color(0xFFD7A254);
}

/// Arayüzün renkleri. Açık ve koyu iki sürümü vardır; widget'lar
/// `context.pal` ile okur, sabit renk yazmaz.
///
/// Masa üstündeki künye ve çipler de buradan beslenir: masanın rengi desteye
/// göre değişir, arayüz ona değil temaya bağlıdır. Böylece hangi deste seçili
/// olursa olsun okunurluk aynı kalır.
@immutable
final class BatakPalette extends ThemeExtension<BatakPalette> {
  const BatakPalette({
    required this.brightness,
    required this.surface,
    required this.surfaceAlt,
    required this.panel,
    required this.line,
    required this.accent,
    required this.accentDeep,
    required this.onAccent,
    required this.blush,
    required this.butter,
    required this.ink,
    required this.inkSoft,
    required this.inkDim,
    required this.good,
    required this.bad,
    required this.scrim,
    required this.shadow,
  });

  final Brightness brightness;

  /// Ekran zemini.
  final Color surface;

  /// İkinci yüzey: seçilmemiş çip, sayı kutusu.
  final Color surfaceAlt;

  /// Pop-up ve panel zemini; masa üstündeki pillerin de zemini.
  final Color panel;

  final Color line;

  /// Ana vurgu dolgusu (seçili çip, dolu düğme).
  final Color accent;

  /// Vurgunun okunur koyu/açık tonu: seçili etiket, ikon.
  final Color accentDeep;

  /// [accent] üstüne yazılan metin.
  final Color onAccent;

  final Color blush;
  final Color butter;

  final Color ink;
  final Color inkSoft;
  final Color inkDim;

  final Color good;
  final Color bad;

  /// Pop-up altındaki örtü.
  final Color scrim;

  /// Yükseltilmiş yüzeylerin gölge rengi.
  final Color shadow;

  bool get isDark => brightness == Brightness.dark;

  /// Açık tema: doygun pastel. Kağıt beyazı masadan ve panelden ayrılsın diye
  /// zeminler kırık beyazdır, saf beyaz değildir.
  static const light = BatakPalette(
    brightness: Brightness.light,
    surface: Color(0xFFF2EBE0),
    surfaceAlt: Color(0xFFE6DCCD),
    panel: Color(0xFFFCF9F4),
    line: Color(0xFFD5C9B6),
    accent: Color(0xFF8FB9A2),
    accentDeep: Color(0xFF3F7159),
    onAccent: Color(0xFF14241C),
    blush: Color(0xFFE9A9AF),
    butter: Color(0xFFF2D28A),
    ink: Color(0xFF26302B),
    inkSoft: Color(0xFF4C5852),
    inkDim: Color(0xFF808C85),
    good: Color(0xFF3F7159),
    bad: Color(0xFFB85C4C),
    scrim: Color(0x591A2822),
    shadow: Color(0x1A121A16),
  );

  /// Koyu tema: aynı pastel aile, karartılmış. Vurgu yeşili açık kalır ki
  /// koyu zeminde okunsun.
  static const dark = BatakPalette(
    brightness: Brightness.dark,
    surface: Color(0xFF181D1A),
    surfaceAlt: Color(0xFF323B35),
    panel: Color(0xFF222A26),
    line: Color(0xFF3A443E),
    accent: Color(0xFF6E9D83),
    accentDeep: Color(0xFFA9CFB8),
    onAccent: Color(0xFF0E1813),
    blush: Color(0xFFC98D93),
    butter: Color(0xFFD9BC77),
    ink: Color(0xFFE8EFE9),
    inkSoft: Color(0xFFB9C4BD),
    inkDim: Color(0xFF87958D),
    good: Color(0xFF7FC19C),
    bad: Color(0xFFE09080),
    scrim: Color(0x8C0A110D),
    shadow: Color(0x4D000000),
  );

  /// Panel gölgesi: pastel yüzeyler kalın çerçeveyle değil gölgeyle ayrılır.
  List<BoxShadow> get soft => [
        BoxShadow(color: shadow, blurRadius: 18, offset: const Offset(0, 8)),
      ];

  /// Pop-up gölgesi: masanın üstünde yüzdüğü belli olsun.
  List<BoxShadow> get pop => [
        BoxShadow(color: shadow, blurRadius: 34, offset: const Offset(0, 16)),
        BoxShadow(color: shadow, blurRadius: 6, offset: const Offset(0, 2)),
      ];

  /// Masa üstündeki pillerin gölgesi; masanın rengi ne olursa olsun aynı.
  static const onBoardShadow = [
    BoxShadow(color: Color(0x33000000), blurRadius: 8, offset: Offset(0, 2)),
  ];

  @override
  BatakPalette copyWith() => this;

  @override
  BatakPalette lerp(ThemeExtension<BatakPalette>? other, double t) =>
      t < 0.5 ? this : (other as BatakPalette? ?? this);
}

/// `context.pal` ile paletin okunması.
extension BatakPaletteX on BuildContext {
  BatakPalette get pal =>
      Theme.of(this).extension<BatakPalette>() ?? BatakPalette.light;
}

/// Animasyon süresi. Sistemde animasyonlar kapatılmışsa sıfır döner, böylece
/// erişilebilirlik ayarına uyulur.
Duration anim(BuildContext context, int ms) =>
    MediaQuery.maybeDisableAnimationsOf(context) ?? false
        ? Duration.zero
        : Duration(milliseconds: ms);

ThemeData buildTheme(Brightness brightness) {
  final pal =
      brightness == Brightness.dark ? BatakPalette.dark : BatakPalette.light;

  final scheme = ColorScheme(
    brightness: brightness,
    primary: pal.accentDeep,
    onPrimary: brightness == Brightness.dark ? pal.onAccent : Colors.white,
    primaryContainer: pal.accent,
    onPrimaryContainer: pal.onAccent,
    secondary: pal.accent,
    onSecondary: pal.onAccent,
    surface: pal.panel,
    onSurface: pal.ink,
    surfaceContainerHighest: pal.surfaceAlt,
    outline: pal.line,
    error: pal.bad,
    onError: Colors.white,
  );

  const radius = 16.0;

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: pal.surface,
    extensions: [pal],
    splashFactory: InkSparkle.splashFactory,
    textTheme: TextTheme(
      titleLarge: TextStyle(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
        color: pal.ink,
      ),
      titleMedium: TextStyle(fontWeight: FontWeight.w700, color: pal.ink),
      bodyMedium: TextStyle(height: 1.4, color: pal.inkSoft),
      labelSmall: TextStyle(
        letterSpacing: 0.6,
        fontWeight: FontWeight.w600,
        color: pal.inkDim,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      foregroundColor: pal.ink,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
        color: pal.ink,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: pal.accent,
        foregroundColor: pal.onAccent,
        disabledBackgroundColor: pal.surfaceAlt,
        disabledForegroundColor: pal.inkDim,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: pal.ink,
        side: BorderSide(color: pal.line, width: 1.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: pal.accentDeep,
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: pal.surfaceAlt,
      selectedColor: pal.accent,
      side: BorderSide(color: pal.line),
      labelStyle: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 13.5,
        color: pal.ink,
      ),
      secondaryLabelStyle: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 13.5,
        color: pal.onAccent,
      ),
      shape: const StadiumBorder(),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: pal.panel,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: pal.ink,
      ),
      contentTextStyle: TextStyle(
        fontSize: 14.5,
        height: 1.4,
        color: pal.inkSoft,
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? pal.accentDeep
            : pal.panel,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? pal.accent
            : pal.surfaceAlt,
      ),
      trackOutlineColor: WidgetStatePropertyAll(pal.line),
    ),
    listTileTheme: ListTileThemeData(
      titleTextStyle: TextStyle(
        fontSize: 15.5,
        fontWeight: FontWeight.w700,
        color: pal.ink,
      ),
      subtitleTextStyle: TextStyle(fontSize: 12.5, color: pal.inkDim),
    ),
  );
}
