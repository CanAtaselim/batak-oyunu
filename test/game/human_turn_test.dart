import 'package:batak/engine/models/game_state.dart';
import 'package:batak/game/game_controller.dart';
import 'package:batak/game/settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Motor insan sırasında durmalı: hiçbir bot onun yerine tahmin etmez ya da
/// kağıt atmaz. Gerçek (kısaltılmış) gecikmelerle sınanır.
void main() {
  test('insan hiç dokunmazsa oyun onun sırasında durur', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        delayProvider.overrideWithValue(
          (d) => Future<void>.delayed(
            Duration(milliseconds: d.inMilliseconds ~/ 10),
          ),
        ),
      ],
    );
    addTearDown(c.dispose);

    c.read(gameControllerProvider.notifier).newGame(seed: 42);

    // Bütün botlar tahminini söyleyip duracak kadar zaman tanı.
    await Future<void>.delayed(const Duration(seconds: 2));

    final session = c.read(gameControllerProvider)!;
    expect(
      session.game.bids[GameState.humanSeat],
      isNull,
      reason: 'insan tahmin etmeden tahmini yazılmış',
    );
    expect(session.humanCanBid, isTrue);
    expect(session.game.phase, Phase.bidding);
    expect(
      session.game.handOf(GameState.humanSeat).length,
      13,
      reason: 'insanın elinden kağıt eksilmiş',
    );
  });
}
