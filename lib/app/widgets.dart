import 'package:flutter/material.dart';

import '../domain/hero.dart';
import '../domain/quests.dart';
import '../game/art/painters.dart' show paintHeroPortrait;
import '../game/look.dart';

/// Round portrait of the adventurer, drawn with the same art as the game.
class HeroAvatar extends StatelessWidget {
  const HeroAvatar({
    super.key,
    required this.style,
    required this.color,
    this.skin = 0,
    this.size = 64,
    this.equipped = const {},
  });

  final int style;
  final int color;
  final int skin;
  final double size;
  final Set<String> equipped;

  @override
  Widget build(BuildContext context) {
    final look = HeroLook(style: style, color: color, skin: skin, equipped: equipped);
    return Semantics(
      label: 'Your adventurer',
      image: true,
      child: ExcludeSemantics(
        child: SizedBox.square(
          dimension: size,
          child: CustomPaint(painter: _PortraitPainter(look)),
        ),
      ),
    );
  }
}

class _PortraitPainter extends CustomPainter {
  _PortraitPainter(this.look);

  final HeroLook look;

  @override
  void paint(Canvas canvas, Size size) =>
      paintHeroPortrait(canvas, size.width, look, 0);

  @override
  bool shouldRepaint(_PortraitPainter old) =>
      old.look.style != look.style ||
      old.look.color != look.color ||
      old.look.skin != look.skin;
}

/// Hair/outfit style, outfit colour and skin tone choices with live previews.
class AppearancePicker extends StatelessWidget {
  const AppearancePicker({
    super.key,
    required this.style,
    required this.color,
    required this.skin,
    required this.onChanged,
  });

  final int style;
  final int color;
  final int skin;
  final void Function({int? style, int? color, int? skin}) onChanged;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Style', style: t.titleSmall),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (var i = 0; i < HeroLook.styleNames.length; i++)
            ChoiceChip(
              avatar: HeroAvatar(style: i, color: color, skin: skin, size: 28),
              label: Text(HeroLook.styleNames[i]),
              selected: style == i,
              onSelected: (_) => onChanged(style: i),
            ),
        ]),
        const SizedBox(height: 12),
        Text('Outfit Colour', style: t.titleSmall),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (var i = 0; i < HeroLook.colors.length; i++)
            ChoiceChip(
              avatar: CircleAvatar(backgroundColor: HeroLook.colors[i]),
              label: Text(HeroLook.colorNames[i]),
              selected: color == i,
              onSelected: (_) => onChanged(color: i),
            ),
        ]),
        const SizedBox(height: 12),
        Text('Skin Tone', style: t.titleSmall),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (var i = 0; i < HeroLook.skins.length; i++)
            ChoiceChip(
              avatar: CircleAvatar(backgroundColor: HeroLook.skins[i]),
              label: Text(HeroLook.skinNames[i]),
              selected: skin == i,
              onSelected: (_) => onChanged(skin: i),
            ),
        ]),
      ],
    );
  }
}

/// Chad's speech bubble.
class ChadBubble extends StatelessWidget {
  const ChadBubble({super.key, required this.text, this.onDismiss});

  final String text;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Chad says: $text',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: scheme.tertiaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: scheme.tertiary,
                child: Text('C',
                    style: TextStyle(
                        color: scheme.onTertiary,
                        fontWeight: FontWeight.w800,
                        fontSize: 20)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Chad',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: scheme.onTertiaryContainer,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(text,
                        style: TextStyle(color: scheme.onTertiaryContainer)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Labelled progress bar. Always shows numbers, never colour alone.
class StatBar extends StatelessWidget {
  const StatBar({
    super.key,
    required this.label,
    required this.value,
    required this.max,
    this.color,
    this.icon,
  });

  final String label;
  final int value;
  final int max;
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final frac = max <= 0 ? 0.0 : (value / max).clamp(0.0, 1.0);
    return Semantics(
      label: '$label $value of $max',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16),
                  const SizedBox(width: 4),
                ],
                Text(label, style: Theme.of(context).textTheme.labelMedium),
                const Spacer(),
                Text('$value / $max',
                    style: Theme.of(context).textTheme.labelMedium),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: frac,
                minHeight: 10,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small icon + text pill (energy, coins, level...).
class StatChip extends StatelessWidget {
  const StatChip({super.key, required this.icon, required this.text, this.tip});

  final IconData icon;
  final String text;
  final String? tip;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: tip ?? text,
      child: ExcludeSemantics(
        child: Chip(
          avatar: Icon(icon, size: 18),
          label: Text(text),
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}

/// A suggested quest with a completion state and a start button.
class QuestTile extends StatelessWidget {
  const QuestTile({
    super.key,
    required this.quest,
    required this.done,
    required this.onStart,
  });

  final QuestSuggestion quest;
  final bool done;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        leading: Icon(
          done ? Icons.check_circle : Icons.flag_outlined,
          color: done ? scheme.primary : null,
        ),
        title: Text(quest.title),
        subtitle: Text(done ? 'Done today. Nice work!' : quest.description),
        trailing: done
            ? null
            : TextButton(onPressed: onStart, child: const Text('Start')),
        onTap: onStart,
      ),
    );
  }
}

String experienceBlurb(ExperienceLevel l) => '${l.label}: ${l.blurb}';

/// Standard footer reminding players this is a game, not medical advice.
class SafetyNote extends StatelessWidget {
  const SafetyNote({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        'Move at your own level and stop if anything hurts. I Am Chad is a '
        'game, not medical advice.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
