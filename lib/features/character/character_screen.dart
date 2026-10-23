import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/widgets.dart';
import '../../domain/items.dart';
import '../../domain/player_state.dart';

class CharacterScreen extends ConsumerWidget {
  const CharacterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(playerProvider);
    final owned = ref.watch(itemsProvider).value ?? const <OwnedItem>[];
    final t = Theme.of(context).textTheme;
    if (player == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final h = player.hero;
    final ownedIds = {for (final o in owned) o.itemId: o};

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: HeroAvatar(
            style: h.appearanceStyle,
            color: h.appearanceColor,
            skin: h.appearanceSkin,
            equipped: {for (final i in player.equipped) i.id},
            size: 96,
          ),
        ),
        const SizedBox(height: 8),
        Center(child: Text(h.name, style: t.headlineSmall)),
        Center(child: Text('Level ${player.level}', style: t.titleSmall)),
        Center(
          child: TextButton.icon(
            onPressed: () => _customise(context, ref, player),
            icon: const Icon(Icons.brush_outlined),
            label: const Text('Customise'),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Stats', style: t.titleMedium),
                const SizedBox(height: 8),
                _StatRow('Health', '${player.maxHp}'),
                _StatRow('Attack', '${player.attack}'),
                _StatRow('Defense', '${player.defense}'),
                const Divider(height: 24),
                _StatRow('Total XP', '${player.totalXp}'),
                _StatRow('  From Workouts', '${player.activityXp}'),
                _StatRow('  From Adventures', '${h.adventureXp}'),
                _StatRow('Coins', '${h.coins}'),
                _StatRow('Expeditions Won', '${h.victories}'),
                const SizedBox(height: 8),
                Text(
                  'Stat growth slows as you level, so there is no runaway '
                  'power. Tactics matter more than level.',
                  style: t.bodySmall,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Equipment', style: t.titleMedium),
        const SizedBox(height: 8),
        if (owned.isEmpty)
          const Card(
            child: ListTile(
              leading: Icon(Icons.inventory_2_outlined),
              title: Text('Nothing Yet'),
              subtitle: Text('Win an expedition to find your first piece.'),
            ),
          )
        else
          for (final slot in EquipmentSlot.values)
            for (final item in ItemCatalog.all.where((i) => i.slot == slot))
              if (ownedIds.containsKey(item.id))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Card(
                    child: SwitchListTile(
                      title: Text(item.name),
                      subtitle: Text(
                          '${slot.label} · ${item.bonusLabel}\n${item.description}'),
                      isThreeLine: true,
                      value: ownedIds[item.id]!.equipped,
                      onChanged: (v) => ref
                          .read(repositoryProvider)
                          .setEquipped(item.id, v),
                    ),
                  ),
                ),
        const SizedBox(height: 8),
        Text(
          '${owned.length} of ${ItemCatalog.all.length} pieces found',
          style: t.bodySmall,
        ),
      ],
    );
  }

  Future<void> _customise(
      BuildContext context, WidgetRef ref, PlayerStatus player) async {
    final name = TextEditingController(text: player.hero.name);
    var pickStyle = player.hero.appearanceStyle;
    var pickColor = player.hero.appearanceColor;
    var pickSkin = player.hero.appearanceSkin;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.fromLTRB(
              16, 0, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: HeroAvatar(style: pickStyle, color: pickColor, skin: pickSkin, size: 80)),
                const SizedBox(height: 12),
                TextField(
                  controller: name,
                  maxLength: 20,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 8),
                AppearancePicker(
                  style: pickStyle,
                  color: pickColor,
                  skin: pickSkin,
                  onChanged: ({int? style, int? color, int? skin}) => setState(() {
                    pickStyle = style ?? pickStyle;
                    pickColor = color ?? pickColor;
                    pickSkin = skin ?? pickSkin;
                  }),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () async {
                    final n = name.text.trim();
                    await ref.read(repositoryProvider).updateHeroDetails(
                          name: n.isEmpty ? null : n,
                          appearanceStyle: pickStyle,
                          appearanceColor: pickColor,
                          appearanceSkin: pickSkin,
                        );
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    name.dispose();
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(label),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
