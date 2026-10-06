import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../ui/cards/deck_theme.dart';
import 'settings.dart';

/// Oyuncunun deste mülkiyeti: hangileri açık, reklam ilerlemesi ve jeton.
///
/// Değişmezdir; her işlem yeni bir kopya üretir.
final class DeckOwnership {
  DeckOwnership({
    Set<DeckId> unlocked = const {},
    Map<DeckId, int> adsWatched = const {},
    this.coins = 0,
  })  : unlocked = Set.unmodifiable(unlocked),
        adsWatched = Map.unmodifiable(adsWatched);

  /// Açılmış desteler. Bedava desteler burada tutulmaz; onlar zaten açıktır.
  final Set<DeckId> unlocked;

  /// Deste başına izlenmiş reklam sayısı.
  final Map<DeckId, int> adsWatched;

  final int coins;

  bool isUnlocked(DeckTheme theme) =>
      theme.unlock is FreeUnlock || unlocked.contains(theme.id);

  /// Reklamla açılan destede izlenmiş reklam sayısı.
  int adsFor(DeckId id) => adsWatched[id] ?? 0;

  /// Açılması için kaç reklam kaldığı. Reklamla açılmıyorsa ya da zaten
  /// açıksa 0.
  int adsRemaining(DeckTheme theme) {
    final rule = theme.unlock;
    if (rule is! AdsUnlock || isUnlocked(theme)) return 0;
    final left = rule.count - adsFor(theme.id);
    return left < 0 ? 0 : left;
  }

  /// Jetonla açılan destenin fiyatı karşılanıyor mu.
  bool canAfford(DeckTheme theme) {
    final rule = theme.unlock;
    return rule is CoinsUnlock && coins >= rule.price;
  }

  DeckOwnership copyWith({
    Set<DeckId>? unlocked,
    Map<DeckId, int>? adsWatched,
    int? coins,
  }) =>
      DeckOwnership(
        unlocked: unlocked ?? this.unlocked,
        adsWatched: adsWatched ?? this.adsWatched,
        coins: coins ?? this.coins,
      );
}

final deckStoreProvider =
    NotifierProvider<DeckStore, DeckOwnership>(DeckStore.new);

/// Deste açma altyapısı.
///
/// Reklam gösterimi ve ödeme burada **yok**: bu sınıf yalnızca sonucu işler
/// (`adWatched`, `buy`). Reklam SDK'sı ya da mağaza entegrasyonu eklendiğinde
/// onlar bu iki yöntemi çağırır; oyunun geri kalanı değişmez.
class DeckStore extends Notifier<DeckOwnership> {
  static const _kUnlocked = 'deckUnlocked';
  static const _kCoins = 'deckCoins';
  static const _adsPrefix = 'deckAds.';

  SharedPreferences get _prefs => ref.read(sharedPrefsProvider);

  @override
  DeckOwnership build() {
    final prefs = _prefs;
    final codes = prefs.getStringList(_kUnlocked) ?? const <String>[];
    final unlocked = {
      for (final id in DeckId.values)
        if (codes.contains(id.name)) id,
    };
    return DeckOwnership(
      unlocked: unlocked,
      adsWatched: {
        for (final id in DeckId.values)
          if ((prefs.getInt('$_adsPrefix${id.name}') ?? 0) > 0)
            id: prefs.getInt('$_adsPrefix${id.name}')!,
      },
      coins: prefs.getInt(_kCoins) ?? 0,
    );
  }

  /// Bir reklam izlendi. Hedefe ulaşıldıysa deste açılır ve true döner.
  ///
  /// Desteyi id yerine nesne olarak alır: kural destenin kendisinde durur,
  /// çağıran da onu zaten elinde tutar.
  Future<bool> adWatched(DeckTheme theme) async {
    final id = theme.id;
    final rule = theme.unlock;
    if (rule is! AdsUnlock || state.isUnlocked(theme)) return false;

    final watched = state.adsFor(id) + 1;
    final ads = {...state.adsWatched, id: watched};
    await _prefs.setInt('$_adsPrefix${id.name}', watched);

    if (watched >= rule.count) {
      state = state.copyWith(adsWatched: ads, unlocked: {...state.unlocked, id});
      await _persistUnlocked();
      return true;
    }
    state = state.copyWith(adsWatched: ads);
    return false;
  }

  /// Jetonla satın alma. Parası yetmiyorsa ya da kural jeton değilse false.
  Future<bool> buy(DeckTheme theme) async {
    final id = theme.id;
    final rule = theme.unlock;
    if (rule is! CoinsUnlock || state.isUnlocked(theme)) return false;
    if (state.coins < rule.price) return false;

    state = state.copyWith(
      coins: state.coins - rule.price,
      unlocked: {...state.unlocked, id},
    );
    await _prefs.setInt(_kCoins, state.coins);
    await _persistUnlocked();
    return true;
  }

  /// Jeton ekler (ödül, satın alma, günlük hediye…).
  Future<void> addCoins(int amount) async {
    state = state.copyWith(coins: state.coins + amount);
    await _prefs.setInt(_kCoins, state.coins);
  }

  Future<void> _persistUnlocked() async {
    await _prefs.setStringList(
      _kUnlocked,
      [for (final id in state.unlocked) id.name],
    );
  }
}
