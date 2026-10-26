import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/data/workout_csv.dart';
import 'package:i_am_chad/domain/workout.dart';

List<List<String>> _rows(String csv) {
  // Enough of a reader for these tests: quoted cells may hold commas, quotes and new lines.
  final rows = <List<String>>[];
  var row = <String>[];
  final cell = StringBuffer();
  var quoted = false;
  final text = csv.startsWith('﻿') ? csv.substring(1) : csv;
  for (var i = 0; i < text.length; i++) {
    final ch = text[i];
    if (quoted) {
      if (ch == '"' && i + 1 < text.length && text[i + 1] == '"') {
        cell.write('"');
        i++;
      } else if (ch == '"') {
        quoted = false;
      } else {
        cell.write(ch);
      }
    } else if (ch == '"') {
      quoted = true;
    } else if (ch == ',') {
      row.add(cell.toString());
      cell.clear();
    } else if (ch == '\r') {
      // The row ends at the line feed that follows.
    } else if (ch == '\n') {
      row.add(cell.toString());
      cell.clear();
      rows.add(row);
      row = <String>[];
    } else {
      cell.write(ch);
    }
  }
  return rows;
}

void main() {
  final walk = WorkoutEntry(activityId: 'walking', performedAt: DateTime(2026, 10, 20, 7, 5), durationSeconds: 1830, distanceMeters: 2500);
  final lift = WorkoutEntry(
    activityId: 'dumbbell_press',
    performedAt: DateTime(2026, 10, 19, 18, 30),
    sets: 3,
    reps: 8,
    loadKg: 12.5,
    perceivedEffort: 4,
    notes: 'Left shoulder felt fine, "good" day',
  );

  test('it starts with the headings, one row a workout, oldest first', () {
    final rows = _rows(WorkoutCsv.encode([walk, lift]));
    expect(rows.first, WorkoutCsv.columns);
    expect(rows, hasLength(3));
    expect(rows[1][0], '2026-10-19', reason: 'oldest first, whatever order they came in');
    expect(rows[2][0], '2026-10-20');
    expect(rows.every((r) => r.length == WorkoutCsv.columns.length), isTrue);
  });

  test('every figure says its unit in the heading, and is a plain number', () {
    final rows = _rows(WorkoutCsv.encode([walk, lift]));
    final head = rows.first;
    final l = rows[1], w = rows[2];
    expect(head[head.indexOf('Load (kg)')], 'Load (kg)');
    expect(l[head.indexOf('Sets')], '3');
    expect(l[head.indexOf('Reps per set')], '8');
    expect(l[head.indexOf('Load (kg)')], '12.5');
    expect(l[head.indexOf('Duration (minutes)')], '');
    expect(w[head.indexOf('Duration (minutes)')], '30.5');
    expect(w[head.indexOf('Distance (km)')], '2.5');
    expect(w[head.indexOf('Time')], '07:05');
    expect(w[head.indexOf('Exercise')], 'Walking');
  });

  test('how it felt, the note, and whether it counted are there too', () {
    final rows = _rows(WorkoutCsv.encode([lift]));
    final head = rows.first, r = rows[1];
    expect(r[head.indexOf('How it felt')], 'Hard');
    expect(r[head.indexOf('Notes')], 'Left shoulder felt fine, "good" day', reason: 'commas and quotes survive');
    expect(r[head.indexOf('Counted for rewards')], 'Yes');
    final late = lift.copyWith(loggedAt: DateTime(2026, 10, 25));
    expect(_rows(WorkoutCsv.encode([late]))[1][head.indexOf('Counted for rewards')], 'No');
    expect(_rows(WorkoutCsv.encode([lift.copyWith(cameraCounted: true)]))[1][head.indexOf('Counted by camera')], 'Yes');
  });

  test('a note can never run as a formula when the file is opened', () {
    for (final risky in ['=1+1', '+SUM(A1)', '-2+3', '@cmd', '\tx']) {
      final text = WorkoutCsv.encode([lift.copyWith(notes: risky)]);
      final note = _rows(text)[1][WorkoutCsv.columns.indexOf('Notes')];
      expect(note, "'$risky", reason: risky);
    }
    expect(WorkoutCsv.cell('Plain note'), 'Plain note');
  });

  test('a note with a new line stays in one cell', () {
    final rows = _rows(WorkoutCsv.encode([lift.copyWith(notes: 'one\ntwo')]));
    expect(rows, hasLength(2));
    expect(rows[1][WorkoutCsv.columns.indexOf('Notes')], 'one\ntwo');
  });

  test('with no workouts it is just the headings, and an unknown exercise is named as such', () {
    expect(_rows(WorkoutCsv.encode(const [])), hasLength(1));
    final unknown = WorkoutEntry(activityId: 'moon_dance', performedAt: DateTime(2026, 10, 20), durationSeconds: 60);
    expect(_rows(WorkoutCsv.encode([unknown]))[1][2], 'Unknown activity');
  });

  test('it leads with a byte-order mark and ends rows with CRLF, as spreadsheets expect', () {
    final text = WorkoutCsv.encode([walk]);
    expect(text.startsWith('﻿'), isTrue);
    expect(text.split('\r\n'), hasLength(3), reason: 'two rows and the end');
  });

  test('it holds nothing about the player but the workouts', () {
    final text = WorkoutCsv.encode([walk, lift]).toLowerCase();
    for (final w in ['coins', 'level', 'hero', 'xp', 'energy', 'streak', 'story']) {
      expect(text.contains(w), isFalse, reason: w);
    }
  });
}
