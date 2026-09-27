import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../engine/models/game_config.dart';
import '../../game/settings.dart';
import '../strings.dart';
import '../theme.dart';

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
