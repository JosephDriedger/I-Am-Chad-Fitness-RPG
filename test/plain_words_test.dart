import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Words a player should never have to meet. Anything the screens say stays in
/// plain language; the technical names belong in code and docs only.
const _technical = ['JSON', 'SQL', 'SQLite', 'database', 'API', 'payload', 'schema', 'checksum', 'SHA', 'manifest'];

/// The technical words in [text], if any.
List<String> _hits(String text) => [
      for (final w in _technical)
        if (RegExp(r'\b' + RegExp.escape(w) + r'\b').hasMatch(text)) w,
    ];

/// Text in quotes on one line of code, in either kind of quote.
final _quoted = RegExp(r"""'((?:[^'\\\n]|\\.)*)'|"((?:[^"\\\n]|\\.)*)" """.trim());

/// Where the player's words live.
bool _isPlayerFacing(String path) {
  final p = path.replaceAll(r'\', '/');
  return p.startsWith('lib/features/') ||
      const {
        'lib/domain/guide.dart',
        'lib/domain/reminders.dart',
        'lib/domain/recommendations.dart',
        'lib/domain/chad.dart',
      }.contains(p);
}

void main() {
  test('the check itself catches what it should', () {
    expect(_hits('Copy My Data (JSON)'), ['JSON']);
    expect(_hits('Reads the database and the API'), ['database', 'API']);
    expect(_hits('Copy a Full Backup'), isEmpty);
    expect(_hits('Bodyweight squats'), isEmpty);
    // The reader for text in quotes finds both kinds of quote.
    expect(_quoted.allMatches("label: 'Copy My Data (JSON)', hint: \"Paste it here\"").length, 2);
  });

  test('text the player reads has no technical words', () {
    final files = [
      for (final f in Directory('lib').listSync(recursive: true).whereType<File>())
        if (f.path.endsWith('.dart') && _isPlayerFacing(f.path)) f,
    ];
    expect(files.length, greaterThan(10));
    final found = <String>[];
    for (final f in files) {
      for (final (i, line) in f.readAsLinesSync().indexed) {
        final t = line.trimLeft();
        if (t.startsWith('//') || t.startsWith('import ') || t.startsWith('export ') || t.startsWith('part ')) continue;
        for (final m in _quoted.allMatches(line)) {
          final text = m.group(1) ?? m.group(2) ?? '';
          // Only sentences and labels: a single token is a key or an id, not words a player reads.
          if (!text.contains(' ')) continue;
          for (final w in _hits(text)) {
            found.add('${f.path}:${i + 1} "$w" in "$text"');
          }
        }
      }
    }
    expect(found, isEmpty, reason: found.join('\n'));
  });
}
