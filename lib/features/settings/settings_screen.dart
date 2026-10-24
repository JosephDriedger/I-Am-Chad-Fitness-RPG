import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/ads.dart';
import '../../app/feedback.dart';
import '../../app/game_ui.dart';
import '../../app/providers.dart';
import '../../app/reminders.dart';
import '../../game/core.dart' show Haptic, Sfx;
import '../../domain/guide.dart';
import '../patron/patron_screen.dart';
import 'guide_screen.dart';
import 'reminders_panel.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(prefsProvider);
    final repo = ref.read(repositoryProvider);

    return GameScaffold(
      title: 'Settings',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
        children: [
          GamePanel(
            title: 'Help',
            child: GameButton(
              key: const Key('open_guide'),
              label: Guide.title,
              icon: Icons.menu_book_rounded,
              kind: GameButtonKind.secondary,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const GuideScreen()),
              ),
            ),
          ),
          const SizedBox(height: 16),
          GamePanel(
            title: 'Units',
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('km / kg')),
                ButtonSegment(value: false, label: Text('mi / lb')),
              ],
              selected: {prefs.useMetric},
              onSelectionChanged: (s) => repo.saveSettings(prefs.copyWith(useMetric: s.first)),
            ),
          ),
          const SizedBox(height: 16),
          GamePanel(
            title: 'Accessibility & Comfort',
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Reduce Motion', style: TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: const Text('Turns off non-essential animation.'),
                  value: prefs.reducedMotion,
                  onChanged: (v) => repo.saveSettings(prefs.copyWith(reducedMotion: v)),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Quieter Chad', style: TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: const Text('Fewer unprompted comments in the guild hall.'),
                  value: prefs.quietChad,
                  onChanged: (v) => repo.saveSettings(prefs.copyWith(quietChad: v)),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Sound Effects', style: TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: const Text('Short, quiet cues for hits, loot and level-ups.'),
                  value: prefs.soundOn,
                  onChanged: (v) {
                    repo.saveSettings(prefs.copyWith(soundOn: v));
                    // Let them hear what they just switched on.
                    if (v) _preview(ref).sfx(Sfx.saved);
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Music', style: TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: const Text(
                    'A calm tune in the guild hall and a livelier one in battle. Off unless you want it, and it plays quietly under any other audio.',
                  ),
                  value: prefs.musicOn,
                  onChanged: (v) => repo.saveSettings(prefs.copyWith(musicOn: v)),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Vibration', style: TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: const Text('Gentle pulses in battles, when you save a workout and as reps are counted.'),
                  value: prefs.hapticsOn,
                  onChanged: (v) {
                    repo.saveSettings(prefs.copyWith(hapticsOn: v));
                    // And feel it.
                    if (v) _preview(ref).haptic(Haptic.success);
                  },
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Text size follows your device settings.',
                      style: TextStyle(color: GameColors.inkSoft, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Only where the platform can send notifications; nothing is offered that cannot be done.
          if (ref.watch(reminderGatewayProvider).isSupported) ...[
            const RemindersPanel(),
            const SizedBox(height: 16),
          ],
          const SizedBox(height: 16),
          GamePanel(
            title: 'Your Data',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your workouts, progress and story choices are stored only on this device, and there is no account. '
                  'The only things that use the internet are the store, and the one ad at the start of a story chapter, '
                  'which Premium removes.',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 14),
                GameButton(
                  label: 'Copy My Data (JSON)',
                  icon: Icons.copy_all_rounded,
                  kind: GameButtonKind.secondary,
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
                const SizedBox(height: 10),
                GameButton(
                  label: 'Delete All My Data',
                  icon: Icons.delete_forever_rounded,
                  kind: GameButtonKind.danger,
                  onPressed: () => _confirmDelete(context, repo.deleteEverything),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GamePanel(
            title: 'Support the Game',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'The whole game is free, every story chapter included, and it always will be. The only ad is one at '
                  'the start of each chapter, and Premium removes it. There are also optional cosmetic extras and a '
                  'tip jar. Nothing there makes the game easier.',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 14),
                GameButton(
                  label: "Open the Patron's Hall",
                  icon: Icons.favorite_rounded,
                  kind: GameButtonKind.secondary,
                  onPressed: () => Navigator.of(context).push(gameRoute<void>(const PatronScreen())),
                ),
                const _AdPrivacyChoices(),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const GamePanel(
            title: 'About',
            child: Text(
              'I Am Chad: Fitness RPG is a prototype. "I Am Chad" is a working title.\n\n'
              'This is a game, not medical advice, and it cannot verify the '
              'workouts you log. Move at your own level, stop if anything '
              'hurts, and talk to a qualified professional if you are unsure '
              'whether an activity is right for you.\n\n'
              'Title font: Lilita One, licensed under the SIL Open Font License.',
              style: TextStyle(fontWeight: FontWeight.w600, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Future<void> Function() wipe) async {
    final ok = await showGameDialog<bool>(
      context: context,
      title: 'Delete Everything?',
      content: const Text(
        'This permanently removes your hero, workouts, rewards and equipment from this device. It cannot be undone.\n\n'
        'Anything you bought from the Patron\'s Hall belongs to your store account, so Restore Purchases brings it back.',
      ),
      actions: [
        Builder(
          builder: (ctx) => GameButton(label: 'Cancel', kind: GameButtonKind.positive, onPressed: () => Navigator.pop(ctx, false)),
        ),
        Builder(
          builder: (ctx) => GameButton(label: 'Delete Everything', kind: GameButtonKind.danger, small: true, onPressed: () => Navigator.pop(ctx, true)),
        ),
      ],
    );
    if (ok == true) {
      await wipe();
      if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    }
  }
}

/// Sound and vibration that play whatever the switches say, for the moment a
/// switch is turned on. Goes through the same players as the game itself.
GameFeedback _preview(WidgetRef ref) => GameFeedback(
      soundOn: true,
      hapticsOn: true,
      player: ref.read(sfxPlayerProvider),
      hapticPlayer: ref.read(hapticPlayerProvider),
    );

/// Lets the player revisit their ad-privacy choices, shown only where the law
/// makes that choice available.
class _AdPrivacyChoices extends ConsumerWidget {
  const _AdPrivacyChoices();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ads = ref.watch(adGatewayProvider);
    return FutureBuilder<bool>(
      future: ads.privacyOptionsRequired(),
      builder: (context, snapshot) {
        if (snapshot.data != true) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 10),
          child: GameButton(
            label: 'Ad Privacy Choices',
            icon: Icons.privacy_tip_rounded,
            kind: GameButtonKind.secondary,
            onPressed: ads.showPrivacyOptions,
          ),
        );
      },
    );
  }
}
