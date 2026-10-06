/// Uygulamadaki tüm metinler burada durur; widget içine metin gömülmez.
abstract final class Str {
  static const appName = 'Batak';

  // Ana ekran
  static const newGame = 'Yeni oyun';
  static const continueGame = 'Devam et';
  static const settings = 'Ayarlar';
  static const variantKozMaca = 'Koz Maça';
  static const variantKozMacaDesc = 'Tekli, koz her zaman maça';
  static const savedGameLine = 'Kayıtlı oyun: %d. el, senin puanın %s';

  // Masa
  static const you = 'Sen';
  static const bot1 = 'Bot 1';
  static const bot2 = 'Bot 2';
  static const bot3 = 'Bot 3';
  static const trump = 'Koz';
  static const roundLabel = 'El';
  static const yanLabel = 'Yan';
  static const bidShort = 'T';
  static const takenShort = 'A';
  static const bidTakenLine = '%d / %d';
  static const waitingBid = '…';

  /// Künyede tahmin yerine: henüz söylenmedi.
  static const noBidShort = '–';
  static const dealerBadge = 'Dağıtan';

  // Tahmin
  static const bidTitle = 'Kaç el alacaksın?';
  static const bidHint = 'Koz maça. Tahmini tutturamazsan batarsın.';
  static const bidZeroNote = '0 dersen hiç el almamalısın: +50 ya da −50.';
  static const bidButton = 'Söyle';
  static const bidsTitle = 'Tahminler';

  // El sonu / oyun sonu
  static const roundOverTitle = '%d. el bitti';
  static const gameOverTitle = 'Oyun bitti';
  static const nextRound = 'Sonraki el';
  static const backToHome = 'Ana ekran';
  static const colPlayer = 'Oyuncu';
  static const colBid = 'Tahmin';
  static const colTaken = 'Aldı';
  static const colRound = 'El puanı';
  static const colTotal = 'Toplam';
  static const winnerLine = 'Kazanan: %s';
  static const winnerTieLine = 'Berabere birinci: %s';

  // Ayarlar
  static const settingsYan = 'Yan batar';
  static const settingsYanDesc = 'Tahminden kaç fazla el alınca batılır';
  static const settingsRounds = 'Oyun eli sayısı';
  static const settingsBots = 'Bot seviyesi';
  static const settingsTempo = 'Oyun hızı';
  static const botEasy = 'Kolay';
  static const botMedium = 'Orta';
  static const botHard = 'Zor';
  static const tempoSlow = 'Yavaş';
  static const tempoNormal = 'Normal';
  static const tempoFast = 'Hızlı';
  static const settingsTheme = 'Görünüm';
  static const settingsThemeDesc = 'Açık, koyu ya da telefonun ayarı';
  static const themeSystem = 'Telefon';
  static const themeLight = 'Açık';
  static const themeDark = 'Koyu';
  static const settingsDeck = 'Deste ve masa';
  static const settingsDeckDesc = 'Oyun sürerken de değiştirebilirsin';
  static const deckLocked = 'Kilitli';
  static const deckAdsLeft = '%d reklam kaldı';
  static const deckPrice = '%d jeton';
  static const settingsBoard = 'Masa';
  static const settingsBoardDesc = 'Renkleri seçili desteden gelir';
  static const settingsIndices = 'Türkçe kart harfleri';
  static const settingsIndicesDesc = 'J · Q · K · A yerine V · K · P · A';
  static const settingsNote = 'Ayarlar yeni oyunda geçerli olur.';
  static const abandonGame = 'Oyunu bırak';
  static const abandonConfirm = 'Kayıtlı oyun silinecek. Emin misin?';
  static const cancel = 'Vazgeç';
  static const confirm = 'Sil';

  static const seatNames = [you, bot1, bot2, bot3];

  /// `%d` ve `%s` yer tutucularını sırayla doldurur.
  static String fmt(String template, List<Object> args) {
    var out = template;
    for (final arg in args) {
      out = out.replaceFirst(RegExp(r'%[ds]'), '$arg');
    }
    return out;
  }
}
