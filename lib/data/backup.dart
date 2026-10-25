/// A full backup of the player's game, and how it is read back. Everything the
/// game stores about the player goes in (the hero, workouts, rewards, gear,
/// expeditions, story progress and purchases' receipts); the device's own
/// preferences (units, sound, reminders) stay on the device, so a restore never
/// switches a reminder on or changes how the phone behaves.
///
/// A backup is plain JSON the player can keep anywhere. Reading one is strict:
/// a file that is not a backup, was made by a newer version of the game, or has
/// anything it should not have (an unknown table or column, a value that is not
/// plain data) is refused whole, before anything on the phone is touched.
library;

import 'dart:convert';

/// Why a backup was not accepted. None of these changes anything on the phone.
enum BackupProblem {
  /// Not something this game wrote.
  notABackup,

  /// Made by a newer version of the game; update first.
  newerVersion,

  /// Looks like a backup but cannot be trusted, so it is refused.
  damaged,
}

class BackupException implements Exception {
  const BackupException(this.problem);

  final BackupProblem problem;

  @override
  String toString() => 'BackupException(${problem.name})';
}

class Backup {
  const Backup({required this.schemaVersion, required this.createdAt, required this.tables});

  static const appName = 'I Am Chad: Fitness RPG';
  static const format = 1;

  /// The most rows accepted, far more than anyone logs.
  static const maxRows = 200000;

  /// Tables that are the device's own and are never backed up.
  static const deviceTables = {'app_settings'};

  /// The database version the rows were written under.
  final int schemaVersion;
  final DateTime createdAt;

  /// Rows by table name, each a map of column name to a plain value.
  final Map<String, List<Map<String, Object?>>> tables;

  int get rowCount => tables.values.fold(0, (a, b) => a + b.length);

  List<Map<String, Object?>> rows(String table) => tables[table] ?? const [];

  String encode() => jsonEncode({
        'app': appName,
        'backupVersion': format,
        'schemaVersion': schemaVersion,
        'createdAt': createdAt.toIso8601String(),
        'tables': tables,
      });

  /// Reads [text]. [knownColumns] maps each table that can be restored to its
  /// column names, and [currentSchema] is this game's database version.
  static Backup parse(
    String text, {
    required Map<String, Set<String>> knownColumns,
    required int currentSchema,
  }) {
    final Object? json;
    try {
      json = jsonDecode(text.trim());
    } on FormatException {
      throw const BackupException(BackupProblem.notABackup);
    }
    if (json is! Map || json['app'] != appName || json['tables'] is! Map) {
      throw const BackupException(BackupProblem.notABackup);
    }
    final version = json['backupVersion'];
    final schema = json['schemaVersion'];
    if (version is! int || schema is! int || schema < 1) throw const BackupException(BackupProblem.damaged);
    if (version > format || schema > currentSchema) throw const BackupException(BackupProblem.newerVersion);
    final created = DateTime.tryParse('${json['createdAt']}');
    if (created == null) throw const BackupException(BackupProblem.damaged);

    final tables = <String, List<Map<String, Object?>>>{};
    var rows = 0;
    for (final entry in (json['tables'] as Map).entries) {
      final name = entry.key;
      final columns = knownColumns[name];
      final list = entry.value;
      if (name is! String || columns == null || list is! List) throw const BackupException(BackupProblem.damaged);
      final out = <Map<String, Object?>>[];
      for (final raw in list) {
        if (raw is! Map || raw.isEmpty) throw const BackupException(BackupProblem.damaged);
        final row = <String, Object?>{};
        for (final cell in raw.entries) {
          final column = cell.key, value = cell.value;
          if (column is! String || !columns.contains(column)) throw const BackupException(BackupProblem.damaged);
          // Plain data only: numbers, text, true or false, or nothing.
          if (value != null && value is! num && value is! String && value is! bool) {
            throw const BackupException(BackupProblem.damaged);
          }
          row[column] = value;
        }
        out.add(row);
        if (++rows > maxRows) throw const BackupException(BackupProblem.damaged);
      }
      tables[name] = out;
    }
    return Backup(schemaVersion: schema, createdAt: created, tables: tables);
  }
}
