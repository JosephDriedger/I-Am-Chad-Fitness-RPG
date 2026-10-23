import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/home/home_shell.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/onboarding/title_screen.dart';
import 'game_ui.dart';
import 'providers.dart';
import 'theme.dart';

/// Whether returning players see the title screen on launch. Tests turn it
/// off so they can go straight to the guild hall.
final showTitleOnLaunchProvider = Provider<bool>((_) => true);

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
      theme: AppTheme.game(),
      darkTheme: AppTheme.game(),
      themeMode: ThemeMode.light,
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

/// Shows onboarding until a hero exists, then a title screen, then the hall.
class _Gate extends ConsumerStatefulWidget {
  const _Gate();

  @override
  ConsumerState<_Gate> createState() => _GateState();
}

class _GateState extends ConsumerState<_Gate> {
  bool _titleDone = false;

  @override
  Widget build(BuildContext context) {
    final hero = ref.watch(heroProvider);
    final showTitle = ref.watch(showTitleOnLaunchProvider);
    return hero.when(
      loading: () => const Scaffold(
        backgroundColor: GameColors.woodDark,
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
      data: (h) {
        if (h == null) return const OnboardingScreen();
        if (showTitle && !_titleDone) {
          return TitleScreen(
            heroName: h.name,
            level: ref.watch(playerProvider)?.level ?? 1,
            onContinue: () => setState(() => _titleDone = true),
          );
        }
        return const HomeShell();
      },
    );
  }
}
