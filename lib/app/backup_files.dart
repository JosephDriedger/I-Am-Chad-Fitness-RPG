import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

/// The edge between the game and the phone's own ways of keeping a file: the
/// share sheet (to save a backup to Files or a drive, or send it to oneself) and
/// the file chooser (to bring one back). The game decides what a backup holds
/// (lib/data/backup.dart); this only moves the text in and out. Where a phone
/// cannot do it, [isSupported] is false and Settings offers copy and paste alone.
abstract class BackupFiles {
  bool get isSupported;

  /// Opens the share sheet with [text] as a file called [fileName]. [mimeType] says what
  /// kind of file it is (a spreadsheet, say), and is plain text unless told.
  Future<void> send(String fileName, String text, {String mimeType = 'text/plain'});

  /// Lets the player choose a backup file, and returns what is in it, or null if
  /// they changed their mind.
  Future<String?> choose();
}

/// Used where the phone cannot share or choose files.
class NoBackupFiles implements BackupFiles {
  const NoBackupFiles();

  @override
  bool get isSupported => false;

  @override
  Future<void> send(String fileName, String text, {String mimeType = 'text/plain'}) async {}

  @override
  Future<String?> choose() async => null;
}

/// A pretend phone, for tests: it remembers what was sent and offers what it is told to.
class TestBackupFiles implements BackupFiles {
  TestBackupFiles({this.supported = true, this.toChoose});

  final bool supported;

  /// What the pretend file chooser returns (null is "changed my mind").
  String? toChoose;

  final sent = <({String fileName, String text, String mimeType})>[];
  int chooseCalls = 0;

  @override
  bool get isSupported => supported;

  @override
  Future<void> send(String fileName, String text, {String mimeType = 'text/plain'}) async =>
      sent.add((fileName: fileName, text: text, mimeType: mimeType));

  @override
  Future<String?> choose() async {
    chooseCalls++;
    return toChoose;
  }
}

/// The real thing, on Android and iOS.
class DeviceBackupFiles implements BackupFiles {
  const DeviceBackupFiles();

  /// Whether this platform has a share sheet and a file chooser.
  static bool get platformCanShare =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  /// Far larger than any backup, so a wrong file chosen by mistake is not read whole.
  static const maxBytes = 20 * 1024 * 1024;

  @override
  bool get isSupported => platformCanShare;

  @override
  Future<void> send(String fileName, String text, {String mimeType = 'text/plain'}) async {
    await SharePlus.instance.share(ShareParams(
      files: [XFile.fromData(utf8.encode(text), mimeType: mimeType)],
      fileNameOverrides: [fileName],
      subject: mimeType == 'text/csv' ? 'My I Am Chad workouts' : 'My I Am Chad backup',
    ));
  }

  @override
  Future<String?> choose() async {
    final file = await FilePicker.pickFile();
    if (file == null) return null;
    final size = await file.length();
    if (size != null && size > maxBytes) return '';
    return utf8.decode(await file.readAsBytes(), allowMalformed: true);
  }
}

final backupFilesProvider = Provider<BackupFiles>((_) => const NoBackupFiles());
