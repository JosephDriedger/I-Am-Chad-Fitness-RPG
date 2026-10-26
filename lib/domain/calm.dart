/// Chad's calm minute: a short, optional stretch of slow breathing, for the end of
/// a session, a rest day, or any time. It pays nothing, saves nothing and never
/// nags, and it never asks for a particular depth of breath: the circle only sets
/// a pace, and going smaller or quicker is always fine. See
/// docs/CONTENT_GUIDELINES.md before changing the words.
library;

/// One part of a breath.
enum CalmPhase {
  inhale('Breathe in', 4),
  hold('Rest here', 2),
  exhale('Breathe out', 6);

  const CalmPhase(this.label, this.seconds);

  final String label;
  final int seconds;
}

class Calm {
  const Calm._();

  static const title = 'A Calm Minute With Chad';

  static const intro =
      'About a minute of slow breathing. In through the nose, out slowly, at whatever size feels easy. Stop whenever you like, and nothing is counted.';

  /// How many breaths make a minute.
  static const breaths = 5;

  /// One cue for each breath, so the minute has a little company in it.
  static const cues = <String>[
    'Let your shoulders drop. There is nowhere else to be for a minute.',
    'Follow the circle, or ignore it and breathe your own way.',
    'If your mind wanders, that is fine. Just come back to the next breath.',
    'Nice and slow. Longer out than in, if that feels comfortable.',
    'Last one. Notice that you are a little softer than a minute ago.',
  ];

  static const finish =
      'And that is a calm minute! It earned nothing but a quiet moment, which is a fine thing to earn. If you ever feel dizzy, just breathe normally.';

  static const note = 'No rewards, nothing to log. Rest is training, and this is a small piece of it.';

  /// The seconds one breath takes.
  static int get breathSeconds => CalmPhase.values.fold(0, (a, p) => a + p.seconds);

  static int get totalSeconds => breathSeconds * breaths;

  /// Which breath (from 0) and which part of it [elapsed] seconds into the minute,
  /// and how many seconds of that part are left. Null once the minute is over.
  static ({int breath, CalmPhase phase, int left})? at(int elapsed) {
    if (elapsed < 0 || elapsed >= totalSeconds) return null;
    final inBreath = elapsed % breathSeconds;
    var used = 0;
    for (final p in CalmPhase.values) {
      if (inBreath < used + p.seconds) {
        return (breath: elapsed ~/ breathSeconds, phase: p, left: used + p.seconds - inBreath);
      }
      used += p.seconds;
    }
    return null;
  }

  /// Every line a player reads, for tests.
  static List<String> get words => [
        title,
        intro,
        finish,
        note,
        for (final p in CalmPhase.values) p.label,
        ...cues,
      ];
}
