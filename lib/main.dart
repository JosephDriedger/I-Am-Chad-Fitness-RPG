import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/providers.dart';
import 'domain/player_state.dart';
import 'dev/preview.dart';

/// Set with --dart-define=PREVIEW=cast|duel|expedition|hub (dev only).
const _preview = String.fromEnvironment('PREVIEW');

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(ProviderScope(
    overrides: [
      // Dev previews run in a throttled browser pane: skip animation and sound.
      if (_preview.isNotEmpty)
        prefsProvider.overrideWithValue(const AppPrefs(reducedMotion: true, soundOn: false, hapticsOn: false)),
    ],
    child: IAmChadApp(
      homeOverride: _preview.isEmpty ? null : previewHome(_preview),
    ),
  ));
}
