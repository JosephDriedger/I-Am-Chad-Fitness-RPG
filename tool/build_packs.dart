// Writes the downloadable story packs and their manifest.
//
//   dart run tool/build_packs.dart            (writes docs/packs/)
//   dart run tool/build_packs.dart <folder>   (writes somewhere else)
//
// Run it after changing any script in tool/story_content, and commit the
// result: test/domain/story_packs_test.dart fails if docs/packs is out of date.
// See docs/CONTENT_PACKS.md for how the folder is published.
import 'dart:convert';
import 'dart:io';

import 'story_content/content.dart';

void main(List<String> args) {
  final dir = Directory(args.isEmpty ? 'docs/packs' : args.first)..createSync(recursive: true);
  for (final e in StoryContent.files().entries) {
    // Written byte for byte (no line-ending changes), so the checksums in the manifest stay true.
    final bytes = utf8.encode(e.value);
    File('${dir.path}/${e.key}').writeAsBytesSync(bytes);
    stdout.writeln('${e.key}  ${bytes.length} bytes');
  }
}
