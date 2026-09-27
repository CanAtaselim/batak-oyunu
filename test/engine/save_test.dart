import 'package:batak/engine/models/action.dart';
import 'package:batak/engine/models/card.dart';
import 'package:batak/engine/models/game_config.dart';
import 'package:batak/engine/models/game_state.dart';
import 'package:batak/engine/save/save_game.dart';
import 'package:test/test.dart';

import '../helpers.dart';

void main() {
  const config = GameConfig(yan: 3, roundCount: 5);

  test('kağıt kodları kayıt formatına uyar', () {
    expect(c('SA').code, 'SA');
    expect(c('H10').code, 'H10');
    expect(c('D2').code, 'D2');
    expect(c('CK').code, 'CK');
    for (final card in PlayingCard.fullDeck()) {
      expect(PlayingCard.parse(card.code), card);
    }
  });

  test('aksiyonlar skill\'deki biçimde serileşir', () {
    expect(const Bid(1, 3).toJson(), ['B', 1, 3]);
    expect(PlayCard(1, c('H10')).toJson(), ['P', 1, 'H10']);
    expect(const NextRound().toJson(), ['N']);
  });

  test('kayıt gidip geri gelir', () {
    final save = SaveGame(
      config: config,
      seed: 123456,
      actions: [const Bid(1, 3), PlayCard(1, c('H10'))],
    );
    final decoded = SaveGame.decode(save.encode())!;
    expect(decoded.seed, 123456);
    expect(decoded.config, config);
    expect(decoded.actions, save.actions);
    expect(save.toJson()['v'], 1);
  });

  test('sürüm uyuşmazsa kayıt yok sayılır', () {
    final raw = SaveGame(config: config, seed: 1, actions: const []).encode();
    expect(SaveGame.decode(raw.replaceFirst('"v":1', '"v":2')), isNull);
  });

  test('bozuk JSON çökmez, null döner', () {
    expect(SaveGame.decode('{'), isNull);
    expect(SaveGame.decode('[]'), isNull);
    expect(SaveGame.decode('{"v":1}'), isNull);
    expect(SaveGame.decode('{"v":1,"config":{},"seed":1,"actions":[]}'), isNull);
  });

  test('kurallara aykırı aksiyon listesi oynatılamaz, null döner', () {
    // 0. koltuk tahmin sırası kendisinde değilken tahmin ediyor.
    final save = SaveGame(
      config: config,
      seed: 1,
      actions: const [Bid(0, 3), Bid(0, 3), Bid(0, 3), Bid(0, 3), Bid(0, 3)],
    );
    expect(save.replay(), isNull);
  });

  test('aksiyon eklemek yeni kayıt üretir, eskisini bozmaz', () {
    final save = SaveGame(config: config, seed: 1, actions: const []);
    final next = save.withAction(const Bid(2, 4));
    expect(save.actions, isEmpty);
    expect(next.actions.length, 1);
  });

  test('boş kayıt yeni oyunu kurar', () {
    final save = SaveGame(config: config, seed: 99, actions: const []);
    final state = save.replay()!;
    expect(state.phase, Phase.bidding);
    expect(state.roundIndex, 0);
  });
}
