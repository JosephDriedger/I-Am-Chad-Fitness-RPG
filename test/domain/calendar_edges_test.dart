import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/domain/hero.dart';
import 'package:i_am_chad/domain/quests.dart';
import 'package:i_am_chad/domain/workout.dart';

WorkoutEntry _on(DateTime d) => WorkoutEntry(activityId: 'walking', performedAt: d, durationSeconds: 600);

void main() {
  group('the week is built from calendar dates', () {
    test('every day of a year sits in a Monday-to-Sunday week of exactly seven dates', () {
      for (var i = 0; i < 366; i++) {
        final day = DateTime(2026, 1, 1 + i, 13);
        final (monday, nextMonday) = QuestBoard.weekBounds(day);
        expect(monday.weekday, DateTime.monday, reason: '$day');
        expect(monday.hour, 0, reason: '$day');
        expect(nextMonday.weekday, DateTime.monday, reason: '$day');
        expect(nextMonday.hour, 0, reason: '$day');
        expect(DateTime(monday.year, monday.month, monday.day + 7), nextMonday, reason: '$day');
        expect(day.isBefore(nextMonday) && !day.isBefore(monday), isTrue, reason: '$day');
      }
    });

    test('late Sunday belongs to this week and early Monday to the next', () {
      final sunday = DateTime(2026, 10, 25, 12);
      final lateSunday = _on(DateTime(2026, 10, 25, 23, 30));
      final earlyMonday = _on(DateTime(2026, 10, 26, 0, 30));
      final goal = QuestBoard.weeklyGoal(
        level: ExperienceLevel.starting,
        now: sunday,
        entries: [lateSunday, earlyMonday],
      );
      expect(goal.daysActive, 1);
      expect(QuestBoard.activeWeekdays(now: sunday, entries: [lateSunday, earlyMonday]), {DateTime.sunday});
    });

    test('the same holds across the weeks where clocks change', () {
      // Dates around the usual spring and autumn changes in the US and Europe.
      for (final sunday in [DateTime(2026, 3, 8, 12), DateTime(2026, 3, 29, 12), DateTime(2026, 10, 25, 12), DateTime(2026, 11, 1, 12)]) {
        final lateSunday = _on(DateTime(sunday.year, sunday.month, sunday.day, 23, 30));
        final earlyMonday = _on(DateTime(sunday.year, sunday.month, sunday.day + 1, 0, 30));
        final goal = QuestBoard.weeklyGoal(
          level: ExperienceLevel.starting,
          now: sunday,
          entries: [lateSunday, earlyMonday],
        );
        expect(goal.daysActive, 1, reason: '$sunday');
      }
    });
  });

  test('suggestions change every calendar day for a whole year', () {
    List<String> ids(DateTime d) => [
          for (final q in QuestBoard.dailySuggestions(
            level: ExperienceLevel.returning,
            day: d,
            preferred: const {},
            hasDumbbells: true,
            count: 99,
          ))
            q.id
        ];
    for (var i = 0; i < 365; i++) {
      final today = DateTime(2026, 1, 1 + i, 9);
      final tomorrow = DateTime(2026, 1, 2 + i, 9);
      expect(ids(today), isNot(ids(tomorrow)), reason: '$today');
      expect(ids(today), ids(DateTime(2026, 1, 1 + i, 21)), reason: '$today');
    }
  });
}
