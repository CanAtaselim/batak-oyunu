import 'package:flutter/material.dart';

import '../strings.dart';
import '../theme.dart';

/// Tahmin paneli: 0–13 arası bir sayı seçilir ve söylenir.
///
/// Tahminler herkese açıktır, o yüzden panelde masadaki diğer tahminler de
/// görünür.
class BidPanel extends StatefulWidget {
  const BidPanel({required this.bids, required this.onBid, super.key});

  /// Koltuk başına söylenmiş tahminler; henüz söylenmemiş olan null.
  final List<int?> bids;
  final ValueChanged<int> onBid;

  @override
  State<BidPanel> createState() => _BidPanelState();
}

class _BidPanelState extends State<BidPanel> {
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final said = [
      for (var seat = 1; seat < widget.bids.length; seat++)
        if (widget.bids[seat] != null) '${Str.seatNames[seat]} ${widget.bids[seat]}',
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: const BoxDecoration(
        color: Color(0xF2102A21),
        border: Border(top: BorderSide(color: Color(0x33FFFFFF))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(Str.bidTitle, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            said.isEmpty ? Str.bidHint : '${Str.bidsTitle}: ${said.join(' · ')}',
            style: const TextStyle(fontSize: 13, color: BatakColors.onFeltDim),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (var value = 0; value <= 13; value++)
                _BidChip(
                  value: value,
                  selected: _selected == value,
                  onTap: () => setState(() => _selected = value),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  _selected == 0 ? Str.bidZeroNote : '',
                  style: const TextStyle(fontSize: 12.5, color: BatakColors.brass),
                ),
              ),
              const SizedBox(width: 12),
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
        ],
      ),
    );
  }
}

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
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? BatakColors.brass : const Color(0x1AFFFFFF),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? BatakColors.brass : const Color(0x33FFFFFF),
            ),
          ),
          child: Text(
            '$value',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: selected ? BatakColors.ink : BatakColors.onFelt,
            ),
          ),
        ),
      );
}
