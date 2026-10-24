/// Chad's one-minute warm-up: a short, optional, guided stretch of four gentle
/// standing moves. It pays nothing, saves nothing and never nags. It is only
/// there so a first-timer has something easy to do with Chad straight away.
/// See docs/CONTENT_GUIDELINES.md before changing the words.
library;

class WarmUpStep {
  const WarmUpStep({
    required this.activityId,
    required this.seconds,
    required this.chadLine,
  });

  /// An exercise from the catalog, so its animated demonstration is shown.
  final String activityId;
  final int seconds;
  final String chadLine;
}

class WarmUp {
  const WarmUp._();

  static const title = 'Warm-Up With Chad';

  static const intro =
      'One minute, four gentle moves, no equipment. Stop whenever you like, skip any move, and go as small as you want.';

  static const steps = <WarmUpStep>[
    WarmUpStep(
      activityId: 'hip_circles',
      seconds: 15,
      chadLine: 'Hands on your hips, big slow circles. Switch direction halfway. Wobbling is allowed.',
    ),
    WarmUpStep(
      activityId: 'side_bend',
      seconds: 15,
      chadLine: 'Reach up and lean gently to one side, then the other. Think tall, not far.',
    ),
    WarmUpStep(
      activityId: 'shoulder_stretch',
      seconds: 15,
      chadLine: 'Bring an arm across your chest. Shoulders away from your ears. Breathe out.',
    ),
    WarmUpStep(
      activityId: 'sun_salutation',
      seconds: 15,
      chadLine: 'Soft knees, a slow flow, and let your breath set the pace. Skip any part you like.',
    ),
  ];

  static const finish =
      'And that is a warm-up! It took a minute and earned nothing but a good start, which is a fine thing to earn. Stop if anything hurts, always.';

  static const note = 'No rewards, nothing to log. It is just a nice way to begin.';

  static int get totalSeconds => steps.fold(0, (a, s) => a + s.seconds);

  /// Every line a player reads, for tests.
  static List<String> get words => [title, intro, finish, note, for (final s in steps) s.chadLine];
}
