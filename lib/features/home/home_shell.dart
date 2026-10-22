import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import 'hub_screen.dart';

/// The app's main screen once a hero exists: the guild hall.
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ready = ref.watch(playerProvider) != null;
    return Scaffold(
      body: ready
          ? const HubScreen()
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
