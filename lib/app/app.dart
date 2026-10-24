import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/home/home_shell.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/onboarding/title_screen.dart';
import 'game_ui.dart';
import 'music.dart';
import 'providers.dart';
import 'store.dart';
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

class _GateState extends ConsumerState<_Gate> with WidgetsBindingObserver {
  bool _titleDone = false;

  @override
  void initState() {
    super.initState();
    // Listen to the store from launch, so a purchase that finished while the
    // app was closed (a parent approving one, say) is delivered and saved.
    ref.read(storeProvider);
    // Background music follows its switch, the screen in front and whether the
    // app is showing. It stays off unless the player turns it on.
    // A listener, not a read: it has to react every time the switch, the screen
    // or the foreground changes, and an unwatched provider only rebuilds lazily.
    ref.listenManual(musicProvider, (_, _) {});
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Quiet when the player leaves the game, back when they return. A brief
    // "inactive" (a permission prompt, the notification shade) keeps playing.
    final away = state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached;
    ref.read(appActiveProvider.notifier).set(!away);
  }

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
