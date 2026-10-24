import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/game_ui.dart';
import '../../app/providers.dart';
import '../../app/reminders.dart';
import '../../domain/reminders.dart';

/// Gentle, opt-in reminders. Shown in Settings only where the platform can send
/// notifications. Off until the player turns it on, and asking for permission
/// happens only at that moment.
class RemindersPanel extends ConsumerStatefulWidget {
  const RemindersPanel({super.key});

  @override
  ConsumerState<RemindersPanel> createState() => _RemindersPanelState();
}

class _RemindersPanelState extends ConsumerState<RemindersPanel> {
  String? _note;

  static const _dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  static const _dayShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  static String _hourLabel(int h) => '${h % 12 == 0 ? 12 : h % 12} ${h < 12 ? 'AM' : 'PM'}';

  Future<void> _save(ReminderPrefs next) {
    final prefs = ref.read(prefsProvider);
    return ref.read(repositoryProvider).saveSettings(prefs.copyWith(reminders: next));
  }

  Future<void> _toggle(bool on) async {
    final current = ref.read(prefsProvider).reminders;
    if (!on) {
      setState(() => _note = null);
      await _save(current.copyWith(enabled: false));
      return;
    }
    // Ask only now, when the player has just said they want them.
    final granted = await ref.read(reminderGatewayProvider).requestPermission();
    if (!mounted) return;
    if (!granted) {
      setState(() => _note = 'That is fine. Reminders stay off. You can allow them in your phone\'s settings whenever you like.');
      return;
    }
    setState(() => _note = null);
    await _save(current.copyWith(enabled: true));
  }

  @override
  Widget build(BuildContext context) {
    final r = ref.watch(prefsProvider).reminders;
    return GamePanel(
      title: 'Gentle Reminders',
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            key: const Key('reminders_switch'),
            contentPadding: EdgeInsets.zero,
            title: const Text('Remind Me', style: TextStyle(fontWeight: FontWeight.w800)),
            subtitle: const Text('A small, kind nudge on the days you choose. Off unless you turn it on.'),
            value: r.enabled,
            onChanged: _toggle,
          ),
          if (_note != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(_note!, key: const Key('reminders_note'), style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          if (r.enabled) ...[
            const Divider(height: 8),
            const SizedBox(height: 6),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              children: [
                const Text('Around', style: TextStyle(fontWeight: FontWeight.w800)),
                DropdownButton<int>(
                  key: const Key('reminders_hour'),
                  value: r.hour,
                  onChanged: (h) => h == null ? null : _save(r.copyWith(hour: h)),
                  items: [
                    for (var h = ReminderPrefs.earliestHour; h <= ReminderPrefs.latestHour; h++)
                      DropdownMenuItem(value: h, child: Text(_hourLabel(h))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (var d = 1; d <= 7; d++)
                  Semantics(
                    label: '${_dayNames[d - 1]}. ${r.days.contains(d) ? 'On' : 'Off'}.',
                    child: ExcludeSemantics(
                      child: FilterChip(
                        key: Key('reminders_day_$d'),
                        label: Text(_dayShort[d - 1]),
                        selected: r.days.contains(d),
                        onSelected: (on) {
                          final days = {...r.days};
                          on ? days.add(d) : days.remove(d);
                          // At least one day stays picked; to stop them, turn the switch off.
                          if (days.isNotEmpty) _save(r.copyWith(days: days));
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Text(
              'At most one a day, never on a day you have already moved, and never once your week is done. '
              'They never mention what you missed, and they stop by themselves if you stop opening the game.',
              style: TextStyle(color: GameColors.inkSoft, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
