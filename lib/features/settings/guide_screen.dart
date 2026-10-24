import 'package:flutter/material.dart';

import '../../app/game_ui.dart';
import '../../app/widgets.dart';
import '../../domain/guide.dart';

/// Every term the game uses, in plain words. Reached from Settings; nothing here
/// is a test and nothing is saved.
class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      title: Guide.title,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
        children: [
          const ChadBubble(text: Guide.intro),
          for (final section in Guide.sections) ...[
            const SizedBox(height: 16),
            GamePanel(
              title: section.title,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < section.entries.length; i++) ...[
                    if (i > 0) const SizedBox(height: 12),
                    Semantics(
                      container: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(section.entries[i].term, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                          const SizedBox(height: 2),
                          Text(section.entries[i].text),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
