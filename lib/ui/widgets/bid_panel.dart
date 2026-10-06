import 'package:flutter/material.dart';

import '../strings.dart';
import '../theme.dart';

/// Tahmin pop-up'ı: masanın ortasında açılır, 0–13 arası bir sayı seçilir ve
/// söylenir.
///
/// Masanın üstünde yüzer ama yelpazeyi kapatmaz: oyuncu tahmin verirken kendi
/// elini görmek zorundadır. Tahminler herkese açık olduğu için masadaki diğer
/// tahminler de panelde görünür.
class BidPanel extends StatefulWidget {
  const BidPanel({required this.bids, required this.onBid, super.key});

  /// Koltuk başına söylenmiş tahminler; henüz söylenmemiş olan null.
  final List<int?> bids;
  final ValueChanged<int> onBid;

  /// Pop-up kartının kendisi. Panelin dış sınırı ekranı kapladığı için
  /// testler kartı bu anahtarla ölçer.
  static const cardKey = Key('bidCard');

  @override
  State<BidPanel> createState() => _BidPanelState();
}

class _BidPanelState extends State<BidPanel> {
  int? _selected;

  /// Her satırda yedi sayı: 0–6 ve 7–13.
  static const _perRow = 7;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: DecoratedBox(
            key: BidPanel.cardKey,
            decoration: BoxDecoration(
              color: pal.panel,
              borderRadius: BorderRadius.circular(26),
              boxShadow: pal.pop,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _header(context),
                  const SizedBox(height: 16),
                  _numbers(),
                  const SizedBox(height: 12),
                  _note(),
                  _bidsStrip(),
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: _selected == null
                        ? null
                        : () {
                            final value = _selected!;
                            setState(() => _selected = null);
                            widget.onBid(value);
                          },
                    child: const Text(Str.bidButton),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) => Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.pal.accent,
              shape: BoxShape.circle,
            ),
            child: Text(
              '♠',
              style: TextStyle(
                fontSize: 19,
                height: 1,
                color: context.pal.onAccent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Str.bidTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 19,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  Str.bidHint,
                  style: TextStyle(fontSize: 12.5, color: context.pal.inkDim),
                ),
              ],
            ),
          ),
        ],
      );

  Widget _numbers() => Column(
        children: [
          for (var row = 0; row * _perRow <= 13; row++)
            Padding(
              padding: EdgeInsets.only(top: row == 0 ? 0 : 8),
              child: Row(
                children: [
                  for (var i = 0; i < _perRow; i++)
                    if (row * _perRow + i <= 13)
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(left: i == 0 ? 0 : 7),
                          child: _BidChip(
                            value: row * _perRow + i,
                            selected: _selected == row * _perRow + i,
                            onTap: () => setState(
                              () => _selected = row * _perRow + i,
                            ),
                          ),
                        ),
                      )
                    else
                      // Son satırda boş kalan yer: çipler aynı genişlikte kalsın.
                      const Expanded(child: SizedBox.shrink()),
                ],
              ),
            ),
        ],
      );

  /// 0 demek ayrı bir bahis; seçilince hatırlatılır.
  Widget _note() => AnimatedSize(
        duration: anim(context, 180),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: _selected == 0
            ? Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: context.pal.butter.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  Str.bidZeroNote,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                    color: context.pal.ink,
                  ),
                ),
              )
            : const SizedBox(width: double.infinity),
      );

  /// Masadaki diğer tahminler.
  Widget _bidsStrip() {
    final said = [
      for (var seat = 1; seat < widget.bids.length; seat++)
        if (widget.bids[seat] != null)
          (Str.seatNames[seat], widget.bids[seat]!),
    ];
    if (said.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Text(
            Str.bidsTitle,
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 0.4,
              fontWeight: FontWeight.w700,
              color: context.pal.inkDim,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final (name, bid) in said)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: context.pal.surfaceAlt,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      '$name $bid',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: context.pal.inkSoft,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tek bir sayı. Seçilince pastel yeşile döner ve hafifçe büyür.
class _BidChip extends StatelessWidget {
  const _BidChip({
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final int value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    return AnimatedScale(
        scale: selected ? 1.08 : 1,
        duration: anim(context, 140),
        curve: Curves.easeOutBack,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(13),
          child: AnimatedContainer(
            duration: anim(context, 140),
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? pal.accent : pal.surfaceAlt,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: selected ? pal.accentDeep : pal.line,
                width: selected ? 1.6 : 1,
              ),
            ),
            child: Text(
              '$value',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: selected ? pal.onAccent : pal.inkSoft,
              ),
            ),
          ),
        ),
      );
  }
}
