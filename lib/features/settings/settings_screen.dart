import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(prefsProvider);
    final repo = ref.read(repositoryProvider);
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Units', style: t.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('km / kg')),
                ButtonSegment(value: false, label: Text('mi / lb')),
              ],
              selected: {prefs.useMetric},
              onSelectionChanged: (s) =>
                  repo.saveSettings(prefs.copyWith(useMetric: s.first)),
            ),
            const SizedBox(height: 16),
            Text('Accessibility & comfort', style: t.titleMedium),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Reduce motion'),
              subtitle: const Text('Turns off non-essential animation.'),
              value: prefs.reducedMotion,
              onChanged: (v) => repo.saveSettings(prefs.copyWith(reducedMotion: v)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Quieter Chad'),
              subtitle:
                  const Text('Fewer unprompted comments on the Guild screen.'),
              value: prefs.quietChad,
              onChanged: (v) => repo.saveSettings(prefs.copyWith(quietChad: v)),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text(
                'Text size follows your device settings.',
              ),
            ),
            const Divider(height: 32),
            Text('Your data', style: t.titleMedium),
            const SizedBox(height: 4),
            const Text(
              'Everything is stored only on this device. There is no account '
              'and nothing is uploaded.',
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.copy_all_outlined),
              label: const Text('Copy my data (JSON)'),
              onPressed: () async {
                final json = await repo.exportJson();
                await Clipboard.setData(ClipboardData(text: json));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Copied. Paste it anywhere to keep a backup.'),
                  ));
                }
              },
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: Icon(Icons.delete_forever_outlined,
                  color: Theme.of(context).colorScheme.error),
              label: Text('Delete all my data',
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
              onPressed: () => _confirmDelete(context, repo.deleteEverything),
            ),
            const Divider(height: 32),
            Text('About', style: t.titleMedium),
            const SizedBox(height: 4),
            const Text(
              'I Am Chad: Fitness RPG is a prototype. "I Am Chad" is a working '
              'title.\n\n'
              'This is a game, not medical advice, and it cannot verify the '
              'workouts you log. Move at your own level, stop if anything '
              'hurts, and talk to a qualified professional if you are unsure '
              'whether an activity is right for you.',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, Future<void> Function() wipe) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete everything?'),
        content: const Text(
            'This permanently removes your hero, workouts, rewards and '
            'equipment from this device. It cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete everything')),
        ],
      ),
    );
    if (ok == true) {
      await wipe();
      if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    }
  }
}
