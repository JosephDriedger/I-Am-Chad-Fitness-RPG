import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/game_ui.dart';
import '../../domain/month_view.dart';
import '../../domain/workout.dart';

/// A month at a glance: a gold dot behind each day someone moved. A day without
/// movement is just a day, with nothing on it. Only for looking back on.
class MonthPanel extends StatefulWidget {
  const MonthPanel({super.key, required this.entries, required this.now});

  final List<WorkoutEntry> entries;
  final DateTime now;

  @override
  State<MonthPanel> createState() => _MonthPanelState();
}

class _MonthPanelState extends State<MonthPanel> {
  late int _year = widget.now.year;
  late int _month = widget.now.month;

  /// Collapsed to a line to begin with, so the workouts below stay close to the top of the Journal.
  bool _open = false;

  void _step(int by) => setState(() {
        final d = DateTime(_year, _month + by);
        _year = d.year;
        _month = d.month;
      });

  @override
  Widget build(BuildContext context) {
    final view = MonthView.of(widget.entries, year: _year, month: _month);
    final first = MonthView.firstMonth(widget.entries);
    final thisMonth = (widget.now.year, widget.now.month);
    final atNewest = (_year, _month) == thisMonth;
    final atOldest = first == null || (_year, _month).compareTo(first) <= 0;
    final name = DateFormat('MMMM y').format(DateTime(_year, _month));
    final monthWord = DateFormat('MMMM').format(DateTime(_year, _month));
    final today = startOfDay(widget.now);
    final n = view.activeDays;

    return GamePanel(
      title: 'Your Month',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_open) ...[
          Row(
            children: [
              IconButton(
                key: const Key('month_earlier'),
                tooltip: 'Earlier Month',
                onPressed: atOldest ? null : () => _step(-1),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(child: Text(name, textAlign: TextAlign.center, style: gameTitle(19))),
              IconButton(
                key: const Key('month_later'),
                tooltip: 'Later Month',
                onPressed: atNewest ? null : () => _step(1),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          Semantics(
            label: '$name: you moved on $n ${n == 1 ? 'day' : 'days'}',
            child: ExcludeSemantics(
              child: Column(
                key: const Key('month_grid'),
                children: [
                  Row(
                    children: [
                      for (final d in const ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
                        Expanded(
                          child: Center(child: Text(d, style: const TextStyle(fontWeight: FontWeight.w900, color: GameColors.inkSoft))),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  for (final week in view.weeks)
                    Row(
                      children: [
                        for (final day in week)
                          Expanded(
                            child: day.inMonth
                                ? _Cell(key: Key('day_${dayKey(day.date)}'), day: day, isToday: day.date == today)
                                : const SizedBox(height: 38),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          ],
          const SizedBox(height: 8),
          Text(
            n == 0
                ? 'A quiet month. Rest counts too.'
                : '$n ${n == 1 ? 'day' : 'days'} you moved in $monthWord. Rest days are part of the plan.',
            key: const Key('month_summary'),
            style: const TextStyle(color: GameColors.inkSoft, fontWeight: FontWeight.w700, fontSize: 12.5),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const Key('month_toggle'),
              onPressed: () => setState(() => _open = !_open),
              icon: Icon(_open ? Icons.expand_less_rounded : Icons.calendar_month_rounded),
              label: Text(_open ? 'Hide Calendar' : 'Show Calendar'),
            ),
          ),
        ],
      ),
    );
  }
}

extension on (int, int) {
  int compareTo((int, int) other) => $1 != other.$1 ? $1.compareTo(other.$1) : $2.compareTo(other.$2);
}

class _Cell extends StatelessWidget {
  const _Cell({super.key, required this.day, required this.isToday});

  final MonthDay day;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: Center(
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: day.active ? GameColors.gold : null,
            border: isToday ? Border.all(color: GameColors.wood, width: 2) : null,
          ),
          child: Text(
            '${day.date.day}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: day.active ? FontWeight.w900 : FontWeight.w600,
              color: day.active ? GameColors.ink : GameColors.inkSoft,
            ),
          ),
        ),
      ),
    );
  }
}
