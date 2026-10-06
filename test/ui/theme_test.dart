import 'package:batak/game/settings.dart';
import 'package:batak/main.dart';
import 'package:batak/ui/cards/deck_theme.dart';
import 'package:batak/ui/strings.dart';
import 'package:batak/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Açık/koyu tema seçimi ve paletin widget ağacına ulaşması.
void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  ProviderContainer container() => ProviderContainer(
        overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
      );

  Future<ProviderContainer> pumpApp(
    WidgetTester tester, {
    Brightness platform = Brightness.light,
  }) async {
    final c = container();
    addTearDown(c.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MediaQuery(
          data: MediaQueryData(platformBrightness: platform),
          child: const BatakApp(),
        ),
      ),
    );
    await tester.pump();
    return c;
  }

  BatakPalette paletteOf(WidgetTester tester) {
    final context = tester.element(find.text(Str.appName));
    return context.pal;
  }

  test('varsayılan tema telefonun ayarını izler', () {
    const settings = Settings();
    expect(settings.theme, ThemeChoice.system);
    expect(settings.theme.mode, ThemeMode.system);
  });

  testWidgets('telefon koyudayken koyu palet gelir', (tester) async {
    await pumpApp(tester, platform: Brightness.dark);
    expect(paletteOf(tester).isDark, isTrue);
  });

  testWidgets('telefon açıktayken açık palet gelir', (tester) async {
    await pumpApp(tester);
    expect(paletteOf(tester).isDark, isFalse);
  });

  testWidgets('koyu seçilince telefon açık olsa da koyu kalır', (tester) async {
    final c = await pumpApp(tester);
    expect(paletteOf(tester).isDark, isFalse);

    await c.read(settingsProvider.notifier).setTheme(ThemeChoice.dark);
    // Tema geçişi animasyonlu; palet geçiş bitince yerine oturur.
    await tester.pumpAndSettle();

    expect(paletteOf(tester).isDark, isTrue);
    expect(prefs.getString('theme'), 'dark');
  });

  testWidgets('seçim yeniden açılışta hatırlanır', (tester) async {
    final c = await pumpApp(tester);
    await c.read(settingsProvider.notifier).setTheme(ThemeChoice.light);
    await tester.pump();

    // Yeni bir kapsayıcı: ayar diskten okunur.
    final fresh = container();
    addTearDown(fresh.dispose);
    expect(fresh.read(settingsProvider).theme, ThemeChoice.light);
  });

  test('her destenin masası temaya göre yön değiştirir', () {
    for (final deck in DeckTheme.all) {
      expect(deck.board(Brightness.light).isLight, isTrue);
      expect(deck.board(Brightness.dark).isLight, isFalse);
    }
  });
}
