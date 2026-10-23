import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/home/home_shell.dart';
import '../features/onboarding/onboarding_screen.dart';
import 'providers.dart';
import 'theme.dart';

class IAmChadApp extends ConsumerWidget {
  const IAmChadApp({super.key, this.homeOverride});

  /// Dev preview only (see lib/dev/preview.dart).
  final Widget? homeOverride;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reduceMotion = ref.watch(prefsProvider.select((p) => p.reducedMotion));
    return MaterialApp(
      title: 'I Am Chad',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      // Honour the in-app "reduce motion" switch on top of the OS setting.
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            disableAnimations: reduceMotion || mq.disableAnimations,
          ),
          child: child!,
        );
      },
      home: homeOverride ?? const _Gate(),
    );
  }
}

/// Shows onboarding until a hero exists, then the main app.
class _Gate extends ConsumerWidget {
  const _Gate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hero = ref.watch(heroProvider);
    return hero.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Something went wrong loading your save:\n$e',
                textAlign: TextAlign.center),
          ),
        ),
      ),
      data: (h) => h == null ? const OnboardingScreen() : const HomeShell(),
    );
  }
}
