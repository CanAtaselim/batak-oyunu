import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../engine/models/card.dart';
import '../../engine/models/game_config.dart';
import '../../game/deck_store.dart';
import '../../game/settings.dart';
import '../cards/board_art.dart';
import '../cards/deck_theme.dart';
import '../strings.dart';
import '../theme.dart';
import '../widgets/playing_card_view.dart';

/// Masa ayarları. Değişiklikler yeni oyunda geçerli olur; süren oyunun ayarları
/// kaydın içinde durur.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text(Str.settings),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        children: [
          _Group(
            title: Str.settingsDeck,
            subtitle: Str.settingsDeckDesc,
            child: _DeckPicker(
              selected: settings.deck,
              ownership: ref.watch(deckStoreProvider),
              turkishIndices: settings.turkishIndices,
              onSelect: notifier.setDeck,
            ),
          ),
          _Group(
            title: Str.settingsBoard,
            subtitle: Str.settingsBoardDesc,
            child: _BoardPicker(
              selected: settings.boardStyle,
              deck: settings.deck,
              onSelect: notifier.setBoardStyle,
            ),
          ),
          _Group(
            title: Str.settingsYan,
            subtitle: Str.settingsYanDesc,
            child: _Choices<int>(
              values: GameConfig.yanValues,
              selected: settings.yan,
              label: (v) => '$v',
              onSelect: notifier.setYan,
            ),
          ),
          _Group(
            title: Str.settingsRounds,
            child: _Choices<int>(
              values: GameConfig.roundCountValues,
              selected: settings.roundCount,
              label: (v) => '$v',
              onSelect: notifier.setRoundCount,
            ),
          ),
          _Group(
            title: Str.settingsBots,
            child: _Choices<BotLevel>(
              // Zor bot sonraki sürümde; şimdilik Kolay ve Orta.
              values: const [BotLevel.easy, BotLevel.medium],
              selected: settings.botLevel,
              label: (v) => switch (v) {
                BotLevel.easy => Str.botEasy,
                BotLevel.medium => Str.botMedium,
                BotLevel.hard => Str.botHard,
              },
              onSelect: notifier.setBotLevel,
            ),
          ),
          _Group(
            title: Str.settingsTempo,
            child: _Choices<Tempo>(
              values: Tempo.values,
              selected: settings.tempo,
              label: (v) => switch (v) {
                Tempo.slow => Str.tempoSlow,
                Tempo.normal => Str.tempoNormal,
                Tempo.fast => Str.tempoFast,
              },
              onSelect: notifier.setTempo,
            ),
          ),
          SwitchListTile(
            value: settings.turkishIndices,
            onChanged: notifier.setTurkishIndices,
            title: const Text(Str.settingsIndices),
            subtitle: const Text(Str.settingsIndicesDesc),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 18),
          const Text(
            Str.settingsNote,
            style: TextStyle(fontSize: 12.5, color: BatakColors.onFeltDim),
          ),
        ],
      ),
    );
  }
}

/// Deste seçici: her destenin yanında gerçek kağıtlarından üçü ve masası.
///
/// Kilitli desteler soluk görünür ve seçilemez; altlarında nasıl açılacağı
/// yazar. Şimdilik bütün desteler açık.
class _DeckPicker extends StatelessWidget {
  const _DeckPicker({
    required this.selected,
    required this.ownership,
    required this.turkishIndices,
    required this.onSelect,
  });

  final DeckTheme selected;
  final DeckOwnership ownership;
  final bool turkishIndices;
  final void Function(DeckTheme) onSelect;

  static final _preview = [
    PlayingCard.parse('SA'),
    PlayingCard.parse('HK'),
    PlayingCard.parse('D10'),
  ];

  /// Kilitli destenin altında yazan açılış koşulu.
  String? _lockLabel(DeckTheme deck) {
    if (ownership.isUnlocked(deck)) return null;
    return switch (deck.unlock) {
      FreeUnlock() => null,
      AdsUnlock() => Str.fmt(Str.deckAdsLeft, [ownership.adsRemaining(deck)]),
      CoinsUnlock(price: final price) => Str.fmt(Str.deckPrice, [price]),
    };
  }

  @override
  Widget build(BuildContext context) => Column(
        children: [
          for (final deck in DeckTheme.all)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _row(context, deck),
            ),
        ],
      );

  Widget _row(BuildContext context, DeckTheme deck) {
    final unlocked = ownership.isUnlocked(deck);
    final lock = _lockLabel(deck);
    final isSelected = deck.id == selected.id;

    return InkWell(
      onTap: unlocked ? () => onSelect(deck) : null,
      borderRadius: BorderRadius.circular(12),
      child: Opacity(
        opacity: unlocked ? 1 : 0.55,
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white.withValues(alpha: 0.04),
            border: Border.all(
              color: isSelected
                  ? BatakColors.brass
                  : Colors.white.withValues(alpha: 0.12),
              width: isSelected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 96,
                height: 52 * deck.aspect,
                child: Stack(
                  children: [
                    for (final (i, card) in _preview.indexed)
                      Positioned(
                        left: i * 20,
                        child: PlayingCardView(
                          card: card,
                          width: 52,
                          theme: deck,
                          trShortNames: turkishIndices,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deck.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? BatakColors.brass
                            : BatakColors.onFelt,
                      ),
                    ),
                    Text(
                      deck.description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: BatakColors.onFeltDim,
                      ),
                    ),
                    if (lock != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.lock_rounded,
                              size: 12,
                              color: BatakColors.brass,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              lock,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: BatakColors.brass,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle_rounded,
                  color: BatakColors.brass,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Masa seçici: her üslup kendi minyatürüyle, seçili destenin renklerinde.
class _BoardPicker extends StatelessWidget {
  const _BoardPicker({
    required this.selected,
    required this.deck,
    required this.onSelect,
  });

  final BoardStyle selected;
  final DeckTheme deck;
  final void Function(BoardStyle) onSelect;

  @override
  Widget build(BuildContext context) {
    // "Destenin masası" yalnızca görseli olan destelerde anlamlı.
    final styles = [
      for (final style in BoardStyle.values)
        if (style != BoardStyle.gorsel || !deck.drawn) style,
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final style in styles) _tile(style),
      ],
    );
  }

  Widget _tile(BoardStyle style) {
    final isSelected = style == selected;
    final useImage = style == BoardStyle.gorsel;
    return InkWell(
      onTap: () => onSelect(style),
      borderRadius: BorderRadius.circular(10),
      child: Column(
        children: [
          Container(
            width: 74,
            height: 104,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? BatakColors.brass
                    : Colors.white.withValues(alpha: 0.18),
                width: isSelected ? 2 : 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: useImage
                ? Image.asset(deck.boardAsset, fit: BoxFit.cover)
                : CustomPaint(
                    painter: BoardPainter(style: style, palette: deck.board),
                  ),
          ),
          const SizedBox(height: 5),
          SizedBox(
            width: 78,
            child: Text(
              style.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                color: isSelected ? BatakColors.brass : BatakColors.onFeltDim,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.child, this.subtitle});

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            if (subtitle != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: BatakColors.onFeltDim,
                  ),
                ),
              ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      );
}

class _Choices<T> extends StatelessWidget {
  const _Choices({
    required this.values,
    required this.selected,
    required this.label,
    required this.onSelect,
  });

  final List<T> values;
  final T selected;
  final String Function(T) label;
  final void Function(T) onSelect;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final value in values)
            ChoiceChip(
              label: Text(label(value)),
              selected: value == selected,
              onSelected: (_) => onSelect(value),
            ),
        ],
      );
}
