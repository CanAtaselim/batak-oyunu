// Pastel arayüzü gözle görmek için ekran görüntüleri üretir. Test değildir:
//
//   flutter test tool/preview_ui_test.dart
//
// Çıktılar: build/ui_home.png, build/ui_bid.png, build/ui_settings.png
//
// Not: test ortamının öntanımlı yazı tipi Ahem'dir ve metinleri kutu olarak
// çizer. Önizleme okunabilir olsun diye sistemdeki Arial, Ahem adıyla
// yükleniyor; bu yalnızca bu araca özgü bir hiledir.

// Araç dosyası: test altyapısını test dizini dışında kullanıyor.
// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'dart:io';
import 'dart:ui' as ui;

import 'package:batak/game/game_controller.dart';
import 'package:batak/game/settings.dart';
import 'package:batak/main.dart';
import 'package:batak/ui/strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _fonts = {
  'Ahem': '/System/Library/Fonts/Supplemental/Arial.ttf',
};

Future<void> _loadFonts() async {
  for (final (family, path) in _fonts.entries.map((e) => (e.key, e.value))) {
    final file = File(path);
    if (!file.existsSync()) continue;
    final loader = FontLoader(family)
      ..addFont(Future.value(file.readAsBytesSync().buffer.asByteData()));
    await loader.load();
  }
}

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Future<GlobalKey> pump(WidgetTester tester, {bool dark = false}) async {
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        delayProvider.overrideWithValue((_) async {}),
      ],
    );
    addTearDown(container.dispose);

    final key = GlobalKey();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MediaQuery(
          data: MediaQueryData(
            platformBrightness: dark ? Brightness.dark : Brightness.light,
          ),
          child: RepaintBoundary(key: key, child: const BatakApp()),
        ),
      ),
    );
    await tester.pump();
    return key;
  }

  Future<void> shoot(WidgetTester tester, GlobalKey key, String name) async {
    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1.4);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      File('build/$name.png').writeAsBytesSync(data!.buffer.asUint8List());
      image.dispose();
    });
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  for (final dark in [false, true]) {
    final suffix = dark ? '_dark' : '_light';

    testWidgets('ana ekran$suffix', (tester) async {
      await _loadFonts();
      final key = await pump(tester, dark: dark);
      await settle(tester);
      await shoot(tester, key, 'ui_home$suffix');
    });

    testWidgets('tahmin pop-up$suffix', (tester) async {
      await _loadFonts();
      final key = await pump(tester, dark: dark);
      await tester.tap(find.text(Str.newGame));
      await tester.pump();
      await settle(tester);
      await tester.tap(find.widgetWithText(InkWell, '4'));
      await settle(tester);
      await shoot(tester, key, 'ui_bid$suffix');
    });

    testWidgets('masa$suffix', (tester) async {
      await _loadFonts();
      final key = await pump(tester, dark: dark);
      await tester.tap(find.text(Str.newGame));
      await tester.pump();
      await settle(tester);
      // Tahmini söyle ki masa oyun halinde görünsün.
      await tester.tap(find.widgetWithText(InkWell, '3'));
      await settle(tester);
      await tester.tap(find.text(Str.bidButton));
      for (var i = 0; i < 200; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      await shoot(tester, key, 'ui_table$suffix');
    });

    testWidgets('ayarlar$suffix', (tester) async {
      await _loadFonts();
      final key = await pump(tester, dark: dark);
      await tester.tap(find.text(Str.settings));
      await tester.pump();
      await settle(tester);
      await shoot(tester, key, 'ui_settings$suffix');
    });
  }
}
