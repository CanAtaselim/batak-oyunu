/// Kağıt türleri. Sıralama bilinçli: ♣ < ♦ < ♥ < ♠.
///
/// Bu sıra kuralların bir parçası değil; eşit değerli kağıtlar arasında
/// deterministik bir kıyas yapabilmek için var (botların seçimi tekrarlanabilir
/// olsun diye). Koz Maça'da koz her zaman [Suit.spades].
enum Suit {
  clubs('C', '♣'),
  diamonds('D', '♦'),
  hearts('H', '♥'),
  spades('S', '♠');

  const Suit(this.code, this.symbol);

  /// Kayıt formatındaki tür harfi: S, H, D, C.
  final String code;

  /// Arayüzde gösterilen simge.
  final String symbol;

  static Suit fromCode(String code) => switch (code) {
        'S' => Suit.spades,
        'H' => Suit.hearts,
        'D' => Suit.diamonds,
        'C' => Suit.clubs,
        _ => throw ArgumentError('Bilinmeyen tür harfi: $code'),
      };
}
