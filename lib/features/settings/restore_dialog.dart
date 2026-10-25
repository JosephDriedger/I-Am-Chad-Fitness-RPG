import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../app/backup_files.dart';
import '../../app/game_ui.dart';
import '../../data/backup.dart';
import '../../data/repository.dart';

/// Restores a pasted backup. Two steps, so nothing is replaced by accident: the
/// backup is read and checked first (nothing on the phone is touched), the player
/// sees what it holds, and only then is it restored. Returns the hero's name once
/// the restore is done, or null if they stopped.
Future<String?> showRestoreBackup(BuildContext context, GameRepository repo, BackupFiles files) async {
  final restore = _Restore(repo, files);
  final result = await showGameDialog<String>(
    context: context,
    title: 'Restore a Backup',
    dismissible: false,
    content: ListenableBuilder(listenable: restore, builder: (_, _) => _Body(restore)),
    actions: [
      ListenableBuilder(
        listenable: restore,
        builder: (ctx, _) => _Actions(restore, close: (name) => Navigator.of(ctx).pop(name)),
      ),
    ],
  );
  // Only flag it as finished: the dialog is still animating away, so its text box must not be disposed yet.
  restore.close();
  return result;
}

enum _Step { paste, confirm, working, failed }

class _Restore extends ChangeNotifier {
  _Restore(this.repo, this.files);

  final GameRepository repo;
  final BackupFiles files;
  final text = TextEditingController();

  _Step step = _Step.paste;
  Backup? backup;
  BackupProblem? problem;
  bool _disposed = false;

  void _set(_Step s, {BackupProblem? because}) {
    if (_disposed) return;
    step = s;
    problem = because;
    notifyListeners();
  }

  Future<void> pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && !_disposed) {
      text.text = data!.text!;
      notifyListeners();
    }
  }

  /// Lets the player choose a backup file, then checks it straight away.
  Future<void> chooseFile() async {
    final chosen = await files.choose();
    if (chosen == null || _disposed) return;
    text.text = chosen;
    check();
  }

  /// Reads the backup without changing anything.
  void check() {
    try {
      backup = repo.readBackup(text.text);
      _set(_Step.confirm);
    } on BackupException catch (e) {
      _set(_Step.paste, because: e.problem);
    }
  }

  Future<String?> restore() async {
    _set(_Step.working);
    try {
      await repo.restoreBackup(backup!);
      return heroName;
    } on BackupException catch (e) {
      _set(_Step.failed, because: e.problem);
      return null;
    }
  }

  String get heroName {
    final heroes = backup?.rows('heroes') ?? const [];
    final name = heroes.isEmpty ? null : heroes.first['name'];
    return name is String && name.isNotEmpty ? name : 'Hero';
  }

  int get workouts => backup?.rows('workouts').length ?? 0;

  /// The dialog has gone: ignore anything still arriving. The text box is left for the garbage collector,
  /// because the dialog is still animating away when this is called.
  void close() => _disposed = true;
}

String _words(BackupProblem p) => switch (p) {
      BackupProblem.notABackup => 'That does not look like a backup from this game. Nothing was changed.',
      BackupProblem.newerVersion =>
        'This backup was made by a newer version of the game. Update the game, then try again. Nothing was changed.',
      BackupProblem.damaged => 'That backup cannot be used, so nothing was changed.',
    };

class _Body extends StatelessWidget {
  const _Body(this.r);

  final _Restore r;

  @override
  Widget build(BuildContext context) {
    switch (r.step) {
      case _Step.paste:
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${r.files.isSupported ? 'Choose the backup file you saved, or paste a backup you copied from Settings.' : 'Paste a backup you copied from Settings.'} '
              'Nothing changes until you have seen what it holds and said yes.',
            ),
            const SizedBox(height: 10),
            TextField(
              key: const Key('restore_text'),
              controller: r.text,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(hintText: 'Paste your backup here'),
              style: const TextStyle(fontSize: 12),
            ),
            if (r.problem != null) ...[
              const SizedBox(height: 10),
              Text(_words(r.problem!), key: const Key('restore_problem'), style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ],
        );
      case _Step.confirm:
        final made = DateFormat('MMM d, y').format(r.backup!.createdAt);
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('A backup of ${r.heroName}, from $made.', key: const Key('restore_summary'), style: gameTitle(18)),
            const SizedBox(height: 6),
            Text('${r.workouts} ${r.workouts == 1 ? 'workout' : 'workouts'}, with the hero, gear, expeditions and story progress.'),
            const SizedBox(height: 10),
            const Text(
              'Restoring replaces everything on this phone: the hero, workouts, gear and story progress. '
              'Your phone\'s own settings, such as units and sound, stay as they are.',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        );
      case _Step.working:
        return const Row(children: [
          SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5)),
          SizedBox(width: 12),
          Expanded(child: Text('Restoring...')),
        ]);
      case _Step.failed:
        return Text('${_words(r.problem ?? BackupProblem.damaged)} Your game on this phone is as it was.', key: const Key('restore_problem'));
    }
  }
}

class _Actions extends StatelessWidget {
  const _Actions(this.r, {required this.close});

  final _Restore r;
  final void Function(String?) close;

  @override
  Widget build(BuildContext context) {
    final cancel = GameButton(key: const Key('restore_cancel'), label: 'Cancel', kind: GameButtonKind.secondary, onPressed: () => close(null));
    switch (r.step) {
      case _Step.paste:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (r.files.isSupported) ...[
              GameButton(
                key: const Key('restore_file'),
                label: 'Choose a Backup File',
                icon: Icons.folder_open_rounded,
                kind: GameButtonKind.positive,
                onPressed: r.chooseFile,
              ),
              const SizedBox(height: 8),
            ],
            GameButton(
              key: const Key('restore_paste'),
              label: 'Paste From Clipboard',
              icon: Icons.content_paste_rounded,
              kind: GameButtonKind.secondary,
              onPressed: r.pasteFromClipboard,
            ),
            const SizedBox(height: 8),
            GameButton(key: const Key('restore_check'), label: 'Check This Backup', kind: GameButtonKind.positive, onPressed: r.check),
            const SizedBox(height: 8),
            cancel,
          ],
        );
      case _Step.confirm:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GameButton(
              key: const Key('restore_go'),
              label: 'Restore It',
              icon: Icons.restore_rounded,
              kind: GameButtonKind.danger,
              onPressed: () async {
                final name = await r.restore();
                if (name != null) close(name);
              },
            ),
            const SizedBox(height: 8),
            GameButton(
              key: const Key('restore_back'),
              label: 'Back',
              kind: GameButtonKind.secondary,
              onPressed: () => r._set(_Step.paste),
            ),
          ],
        );
      case _Step.working:
        return const SizedBox.shrink();
      case _Step.failed:
        return cancel;
    }
  }
}
