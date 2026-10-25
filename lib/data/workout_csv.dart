/// The player's workouts as a spreadsheet file (CSV), to open in a spreadsheet
/// app, keep, or share with a coach. It is a plain look at the journal, one row a
/// workout, oldest first. It is not a backup: it leaves out everything but the
/// workouts, and cannot be restored from (Settings says so). Numbers are always in
/// kilometres, kilograms and minutes, with the unit in the heading, so a
/// spreadsheet never has to guess what a figure means.
library;

import 'package:intl/intl.dart';

import '../domain/workout.dart';

class WorkoutCsv {
  const WorkoutCsv._();

  static const columns = <String>[
    'Date',
    'Time',
    'Exercise',
    'Variant',
    'Sets',
    'Reps per set',
    'Duration (minutes)',
    'Distance (km)',
    'Load (kg)',
    'How it felt',
    'Notes',
    'Counted for rewards',
    'Counted by camera',
  ];

  /// The whole file. A byte-order mark leads it, so spreadsheet apps read the accents and
  /// symbols in a note as they were typed, and rows end in CRLF, as the format asks.
  static String encode(Iterable<WorkoutEntry> entries) {
    final sorted = entries.toList()..sort((a, b) => a.performedAt.compareTo(b.performedAt));
    final date = DateFormat('yyyy-MM-dd');
    final time = DateFormat('HH:mm');
    final out = StringBuffer('﻿')..write(_row(columns));
    for (final e in sorted) {
      final t = e.performedAt.toLocal();
      out.write(_row([
        date.format(t),
        time.format(t),
        e.activity?.name ?? 'Unknown activity',
        e.variant ?? '',
        _count(e.sets),
        _count(e.reps),
        _number((e.durationSeconds ?? 0) > 0 ? e.durationSeconds! / 60 : null, 2),
        _number((e.distanceMeters ?? 0) > 0 ? e.distanceMeters! / 1000 : null, 3),
        _number((e.loadKg ?? 0) > 0 ? e.loadKg : null, 2),
        e.feel ?? '',
        e.notes ?? '',
        e.countsForRewards ? 'Yes' : 'No',
        e.cameraCounted ? 'Yes' : 'No',
      ]));
    }
    return out.toString();
  }

  static String _row(List<String> cells) => '${cells.map(cell).join(',')}\r\n';

  static String _count(int? n) => n == null || n <= 0 ? '' : '$n';

  /// A number with no trailing zeros, always with a point, whatever the phone's language.
  static String _number(double? v, int places) {
    if (v == null) return '';
    final s = v.toStringAsFixed(places);
    return s.contains('.') ? s.replaceFirst(RegExp(r'\.?0+$'), '') : s;
  }

  /// One cell, quoted when it has to be. A text that a spreadsheet could read as a
  /// formula (it starts with = + - @ or a tab) gets a leading apostrophe, so a note can
  /// never run anything when the file is opened.
  static String cell(String raw) {
    var v = raw;
    if (v.isNotEmpty && '=+-@\t\r'.contains(v[0])) v = "'$v";
    if (v.contains(',') || v.contains('"') || v.contains('\n') || v.contains('\r')) {
      v = '"${v.replaceAll('"', '""')}"';
    }
    return v;
  }
}
