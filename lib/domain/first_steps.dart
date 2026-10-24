/// Gentle guidance for someone who has not logged a workout yet. It shows on the
/// Train and log screens until the first one is saved and then never again, never
/// blocks anything, and has no timer. See docs/CONTENT_GUIDELINES.md before
/// changing the words.
library;

class FirstStep {
  const FirstStep(this.title, this.text);

  final String title;
  final String text;
}

class FirstSteps {
  const FirstSteps._();

  /// Chad on the Train screen before anything has been logged.
  static const trainLine =
      'First time here? Pick anything you did today, even a short walk. Any version counts, and nothing you log is ever wrong.';

  static const logTitle = 'Your First Log';

  static const logIntro = 'Rough numbers are fine, and you can edit or delete it later.';

  static const logSteps = <FirstStep>[
    FirstStep('Say How Long or How Many', 'A time, some reps, or a distance, whichever fits what you did.'),
    FirstStep('Pick Your Version', 'An easier one earns exactly the same as a harder one.'),
    FirstStep('Tap Save Workout', 'You will see your XP and energy, and exactly how they were counted.'),
  ];

  /// Every line a player reads, for tests.
  static List<String> get words => [
        trainLine,
        logTitle,
        logIntro,
        for (final s in logSteps) ...[s.title, s.text],
      ];
}
