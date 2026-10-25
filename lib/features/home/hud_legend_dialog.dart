import 'package:flutter/material.dart';

import '../../app/game_ui.dart';
import '../../domain/hud_legend.dart';

const _icons = {
  HudIcon.level: (Icons.star_rounded, Color(0xFFF2C94C)),
  HudIcon.energy: (Icons.bolt, Color(0xFF3FB8AA)),
  HudIcon.coins: (Icons.monetization_on, Color(0xFFD9A520)),
  HudIcon.week: (Icons.calendar_today, Color(0xFFE08A3C)),
  HudIcon.streak: (Icons.local_fire_department_rounded, Color(0xFFE0562F)),
};

/// Explains the numbers at the top of the hall in plain words.
Future<void> showHudLegend(BuildContext context) => showGameDialog<void>(
      context: context,
      title: HudLegend.title,
      content: Column(
        key: const Key('hud_legend'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final e in HudLegend.entries())
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(_icons[e.icon]!.$1, color: _icons[e.icon]!.$2),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.title, style: gameTitle(17)),
                        Text(e.text, style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          Text(HudLegend.footnote, style: const TextStyle(color: GameColors.inkSoft, fontWeight: FontWeight.w700)),
        ],
      ),
      actions: [
        Builder(
          builder: (ctx) => GameButton(
            key: const Key('hud_legend_close'),
            label: 'Got It',
            kind: GameButtonKind.positive,
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ),
      ],
    );
