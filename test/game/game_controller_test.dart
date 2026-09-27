import 'package:batak/engine/models/card.dart';
import 'package:batak/engine/models/game_config.dart';
import 'package:batak/engine/models/game_state.dart';
import 'package:batak/game/game_controller.dart';
import 'package:batak/game/settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// GameController sözleşmesi: insan aksiyonunun doğrulanması, bot akışı,
/// kayıt ve yaşam döngüsü.
void main() {
  late SharedPreferences prefs;

  /// Gecikmesiz kap: bot temposu beklemeden akar.
  ProviderContainer makeContainer() => ProviderContainer(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
          delayProvider.overrideWithValue((_) async {}),
        ],
      );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  /// Sıra insana gelene ya da oyun eli bitene kadar botları oynatır.
  Future<void> settle(ProviderContainer c) async {
    for (var i = 0; i < 200; i++) {
      await pumpEventQueue();
      final session = c.read(gameControllerProvider);
      if (session == null) return;
      if (session.humanCanBid || session.humanCanPlay) return;
      if (session.game.phase != Phase.playing &&
          session.game.phase != Phase.bidding) {
        return;
      }
    }
  }

  test('yeni oyun tahmin turunda başlar ve kaydedilir', () async {
    final c = makeContainer();
    addTearDown(c.dispose);
    c.read(gameControllerProvider.notifier).newGame(seed: 42);
    await settle(c);

    final session = c.read(gameControllerProvider)!;
    expect(session.game.phase, Phase.bidding);
    expect(session.game.handOf(0).length, 13);
    expect(prefs.getString('savedGame'), isNotNull);
  });

  test('insan sırası gelmeden tahmin edemez, geldiğinde edebilir', () async {
    final c = makeContainer();
    addTearDown(c.dispose);
    final controller = c.read(gameControllerProvider.notifier);
    controller.newGame(seed: 42);
    await settle(c);

    // Botlar kendi tahminlerini söyledi, sıra insanda.
    expect(c.read(gameControllerProvider)!.humanCanBid, isTrue);
    controller.placeBid(4);
    await settle(c);
    expect(c.read(gameControllerProvider)!.game.bids[0], 4);

    // İkinci kez tahmin: yok sayılmalı.
    controller.placeBid(9);
    await settle(c);
    expect(c.read(gameControllerProvider)!.game.bids[0], 4);
  });

  test('kurallara aykırı kağıt yok sayılır, çift dokunma bir kez işler',
      () async {
    final c = makeContainer();
    addTearDown(c.dispose);
    final controller = c.read(gameControllerProvider.notifier);
    controller.newGame(seed: 7);
    await settle(c);
    if (c.read(gameControllerProvider)!.humanCanBid) {
      controller.placeBid(3);
      await settle(c);
    }
    expect(c.read(gameControllerProvider)!.humanCanPlay, isTrue);

    final session = c.read(gameControllerProvider)!;
    final illegal = session.game
        .handOf(0)
        .firstWhere((card) => !controller.humanLegalCards.contains(card));
    controller.playCard(illegal);
    await pumpEventQueue();
    expect(c.read(gameControllerProvider)!.game.handOf(0), contains(illegal));

    final legal = controller.humanLegalCards.first;
    controller.playCard(legal);
    controller.playCard(legal); // çift dokunma
    await settle(c);
    final hand = c.read(gameControllerProvider)!.game.handOf(0);
    expect(hand, isNot(contains(legal)));
    expect(hand.length, 12);
  });

  test('bir oyun eli baştan sona oynanır ve puan tablosuna varılır', () async {
    final c = makeContainer();
    addTearDown(c.dispose);
    final controller = c.read(gameControllerProvider.notifier);
    controller.newGame(seed: 2026);

    for (var guard = 0; guard < 400; guard++) {
      await settle(c);
      final session = c.read(gameControllerProvider)!;
      if (session.game.phase == Phase.roundOver ||
          session.game.phase == Phase.gameOver) {
        break;
      }
      if (session.humanCanBid) {
        controller.placeBid(3);
      } else if (session.humanCanPlay) {
        controller.playCard(controller.humanLegalCards.first);
      }
    }

    final game = c.read(gameControllerProvider)!.game;
    expect(game.phase, Phase.roundOver);
    expect(game.tricksTaken.reduce((a, b) => a + b), 13);
    expect(game.lastRoundScores, isNotNull);

    // Puan tablosu kapanınca yeni dağıtım.
    controller.nextRound();
    await settle(c);
    expect(c.read(gameControllerProvider)!.game.roundIndex, 1);
    expect(c.read(gameControllerProvider)!.game.phase, Phase.bidding);
  });

  test('pause bekleyen botları durdurur, resume devam ettirir', () async {
    final c = ProviderContainer(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        // Gerçek gecikme: pause'un araya girebildiğini görmek için.
        delayProvider.overrideWithValue(
          (_) => Future<void>.delayed(const Duration(milliseconds: 40)),
        ),
      ],
    );
    addTearDown(c.dispose);
    final controller = c.read(gameControllerProvider.notifier);
    controller.newGame(seed: 5);
    controller.pause();
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final bidsWhilePaused =
        c.read(gameControllerProvider)!.game.bids.whereType<int>().length;

    controller.resume();
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final bidsAfterResume =
        c.read(gameControllerProvider)!.game.bids.whereType<int>().length;
    expect(bidsAfterResume, greaterThan(bidsWhilePaused));
  });

  test('tamamlanan el masada bekler, toplanır, sonra temizlenir', () async {
    // Gerçek (kısa) gecikme: sunum aşamaları gözlenebilsin.
    final c = ProviderContainer(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        delayProvider.overrideWithValue(
          (d) => Future<void>.delayed(Duration(milliseconds: d.inMilliseconds ~/ 20)),
        ),
      ],
    );
    addTearDown(c.dispose);
    final controller = c.read(gameControllerProvider.notifier);
    controller.newGame(seed: 11);

    var sawResolving = false;
    var sawCollecting = false;
    for (var i = 0; i < 400; i++) {
      final session = c.read(gameControllerProvider)!;
      if (session.resolvingTrick != null) sawResolving = true;
      if (session.collecting) sawCollecting = true;
      if (session.humanCanBid) {
        controller.placeBid(3);
      } else if (session.humanCanPlay) {
        controller.playCard(controller.humanLegalCards.first);
      }
      if (session.game.completedTricks.length >= 2 &&
          sawResolving &&
          sawCollecting) {
        break;
      }
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }

    expect(sawResolving, isTrue, reason: 'el masada hiç gösterilmedi');
    expect(sawCollecting, isTrue, reason: 'toplama animasyonu tetiklenmedi');

    // Toplama bitince masa boşalır ve sıra kazananda olur.
    for (var i = 0; i < 100; i++) {
      final session = c.read(gameControllerProvider)!;
      if (session.resolvingTrick == null && !session.collecting) {
        expect(session.visibleTrick, session.game.trick);
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    fail('el toplanmadı');
  });

  test('kayıtlı oyun yeniden açılışta aynı duruma dönüşür', () async {
    final first = makeContainer();
    final controller = first.read(gameControllerProvider.notifier);
    controller.newGame(seed: 99);
    await settle(first);
    if (first.read(gameControllerProvider)!.humanCanBid) {
      controller.placeBid(2);
      await settle(first);
    }
    if (first.read(gameControllerProvider)!.humanCanPlay) {
      controller.playCard(controller.humanLegalCards.first);
      await settle(first);
    }
    final before = first.read(gameControllerProvider)!.game;
    first.dispose();

    final second = makeContainer();
    addTearDown(second.dispose);
    final restored = second.read(gameControllerProvider);
    expect(restored, isNotNull);
    expect(restored!.game, before);
  });

  test('bozuk kayıt silinir ve uygulama çökmez', () async {
    SharedPreferences.setMockInitialValues({'savedGame': '{"v":1,'});
    prefs = await SharedPreferences.getInstance();
    final c = makeContainer();
    addTearDown(c.dispose);
    expect(c.read(gameControllerProvider), isNull);
    expect(prefs.getString('savedGame'), isNull);
  });

  test('oyunu bırakmak kaydı siler', () async {
    final c = makeContainer();
    addTearDown(c.dispose);
    final controller = c.read(gameControllerProvider.notifier);
    controller.newGame(seed: 1);
    expect(prefs.getString('savedGame'), isNotNull);
    controller.abandon();
    expect(c.read(gameControllerProvider), isNull);
    expect(prefs.getString('savedGame'), isNull);
  });

  test('ayarlar oyun kurulumuna yansır', () async {
    final c = makeContainer();
    addTearDown(c.dispose);
    await c.read(settingsProvider.notifier).setYan(3);
    await c.read(settingsProvider.notifier).setRoundCount(5);
    await c.read(settingsProvider.notifier).setBotLevel(BotLevel.easy);
    c.read(gameControllerProvider.notifier).newGame(seed: 3);
    final config = c.read(gameControllerProvider)!.game.config;
    expect(config.yan, 3);
    expect(config.roundCount, 5);
    expect(config.botLevel, BotLevel.easy);
  });

  test('kart kodları kayıtta dolaşınca bozulmaz', () async {
    final c = makeContainer();
    addTearDown(c.dispose);
    c.read(gameControllerProvider.notifier).newGame(seed: 4);
    await settle(c);
    final raw = prefs.getString('savedGame')!;
    expect(raw, contains('"v":1'));
    expect(PlayingCard.parse('H10').code, 'H10');
    expect(c.read(gameControllerProvider)!.game.seed, 4);
  });
}
