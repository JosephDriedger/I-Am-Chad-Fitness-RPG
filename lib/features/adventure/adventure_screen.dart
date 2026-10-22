import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/widgets.dart';
import '../../domain/chad.dart';
import '../../domain/expedition.dart';
import 'expedition_screen.dart';

class AdventureScreen extends ConsumerWidget {
  const AdventureScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(playerProvider);
    final t = Theme.of(context).textTheme;
    if (player == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final canGo = player.energy >= Expedition.energyCost;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(child: Text('Adventure', style: t.headlineSmall)),
            StatChip(
              icon: Icons.bolt,
              text: '${player.energy} energy',
              tip: 'Adventure energy: ${player.energy}',
            ),
          ],
        ),
        const SizedBox(height: 12),
        ChadBubble(
          text: canGo
              ? ChadDialogue.line(ChadContext.adventureStart,
                  seed: player.hero.victories)
              : ChadDialogue.line(ChadContext.lowEnergy),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Expedition', style: t.titleLarge),
                const SizedBox(height: 4),
                Text(
                  'Three short battles with an event on the way. Earn XP, '
                  'coins and a piece of equipment.',
                  style: t.bodyMedium,
                ),
                const SizedBox(height: 12),
                Wrap(spacing: 8, children: [
                  StatChip(
                      icon: Icons.bolt,
                      text: 'Costs ${Expedition.energyCost} energy'),
                  const StatChip(icon: Icons.timer_outlined, text: 'About 3 min'),
                ]),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: canGo ? () => _start(context, ref, practice: false) : null,
                  icon: const Icon(Icons.explore),
                  label: Text(canGo ? 'Set out' : 'Need ${Expedition.energyCost} energy'),
                ),
                if (!canGo) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Energy comes from the workouts you log. A short walk or '
                    'some stretching is plenty.',
                    style: t.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Practice yard', style: t.titleLarge),
                const SizedBox(height: 4),
                Text(
                  'A relaxed duel that is always free. No XP, just a few coins. '
                  'Perfect for rest days.',
                  style: t.bodyMedium,
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _start(context, ref, practice: true),
                  icon: const Icon(Icons.sports_martial_arts),
                  label: const Text('Practice duel'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text('Expeditions won: ${player.hero.victories}', style: t.bodyMedium),
      ],
    );
  }

  Future<void> _start(BuildContext context, WidgetRef ref,
      {required bool practice}) async {
    final repo = ref.read(repositoryProvider);
    final seed = ref.read(clockProvider)().millisecondsSinceEpoch & 0x7FFFFFFF;
    if (!practice) await repo.spendEnergy(Expedition.energyCost);
    if (!context.mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ExpeditionScreen(seed: seed, practice: practice),
    ));
  }
}
