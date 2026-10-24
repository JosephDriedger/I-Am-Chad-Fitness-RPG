import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/game_ui.dart';
import '../../app/providers.dart';
import '../../domain/cosmetics.dart';
import 'patron_screen.dart';

/// Capes and hair dyes, in the Customise sheet. Free and earned looks are
/// listed first-class; looks from the optional Patron Pack are shown the same
/// way, locked, and tapping one only explains it. Nothing here changes any
/// stat.
class Wardrobe extends ConsumerWidget {
  const Wardrobe({super.key, required this.cape, required this.dye, required this.onChanged});

  final String cape;
  final String dye;
  final void Function({String? cape, String? dye}) onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctx = ref.watch(cosmeticContextProvider) ?? const CosmeticContext();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Cape', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final c in Cosmetics.capes)
              _LookChip(
                label: c.name,
                color: c.color == null ? null : Color(c.color!),
                selected: cape == c.id,
                unlock: c.unlock,
                unlocked: c.unlock.isMet(ctx),
                onSelected: () => onChanged(cape: c.id),
              ),
          ],
        ),
        const SizedBox(height: 10),
        const Text('Hair Dye', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            _LookChip(
              label: 'Natural',
              selected: dye == Cosmetics.naturalDyeId,
              unlock: Unlock.free,
              unlocked: true,
              onSelected: () => onChanged(dye: Cosmetics.naturalDyeId),
            ),
            for (final d in Cosmetics.dyes)
              _LookChip(
                label: d.name,
                color: Color(d.color),
                selected: dye == d.id,
                unlock: d.unlock,
                unlocked: d.unlock.isMet(ctx),
                onSelected: () => onChanged(dye: d.id),
              ),
          ],
        ),
      ],
    );
  }
}

class _LookChip extends StatelessWidget {
  const _LookChip({
    required this.label,
    required this.selected,
    required this.unlock,
    required this.unlocked,
    required this.onSelected,
    this.color,
  });

  final String label;
  final Color? color;
  final bool selected;
  final Unlock unlock;
  final bool unlocked;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: unlocked ? label : '$label, locked. ${unlock.hint}',
      child: ExcludeSemantics(
        child: ChoiceChip(
          avatar: unlocked
              ? (color == null ? null : CircleAvatar(backgroundColor: color))
              : const Icon(Icons.lock_rounded, size: 16),
          label: Text(label),
          selected: selected && unlocked,
          onSelected: (_) => unlocked ? onSelected() : _explain(context),
        ),
      ),
    );
  }

  void _explain(BuildContext context) {
    final patron = unlock.isPatron;
    showGameDialog<void>(
      context: context,
      title: label,
      content: Text(
        patron
            ? 'This look is part of the optional Patron Pack. It is looks only and changes nothing about how '
                'the game plays. The whole game is free without it.'
            : '${unlock.hint}. It is yours as you play, with no hurry.',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      actions: [
        if (patron)
          Builder(
            builder: (ctx) => GameButton(
              label: "See the Patron's Hall",
              icon: Icons.favorite_rounded,
              kind: GameButtonKind.secondary,
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).push(gameRoute<void>(const PatronScreen()));
              },
            ),
          ),
        Builder(
          builder: (ctx) => GameButton(
            label: patron ? 'Not Now' : 'Got It',
            kind: GameButtonKind.positive,
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ),
      ],
    );
  }
}
