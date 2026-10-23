/// Activity catalog: what a player can log, and which fields each activity records.
library;

enum ActivityCategory {
  bodyweight('Bodyweight'),
  cardio('Cardio'),
  resistance('Resistance'),
  mobility('Mobility & Recovery');

  const ActivityCategory(this.label);
  final String label;
}

/// A field a workout entry can record.
enum Metric { sets, reps, duration, distance, load }

class ActivityType {
  const ActivityType({
    required this.id,
    required this.name,
    required this.category,
    required this.metrics,
    required this.formCue,
    this.secondsPerRep = 6,
    this.effortFactor = 1.0,
    this.minutesPerKm,
    this.plausibleRepsPerSet,
    this.plausibleKmh,
    this.variants = const [],
    this.easierAlternative,
  });

  /// Stable identifier persisted with workout records. Never rename.
  final String id;
  final String name;
  final ActivityCategory category;
  final Set<Metric> metrics;

  /// Short, conservative form cue shown while logging.
  final String formCue;

  /// Seconds of effort one rep is worth when the entry has no duration.
  final int secondsPerRep;

  /// Multiplier applied to duration-based effort (running > walking > stretching).
  final double effortFactor;

  /// Used only when distance is the sole metric entered.
  final double? minutesPerKm;

  /// Honesty check limits (see honesty.dart): more reps in one set, or a faster
  /// sustained pace, than almost anyone can manage. Null means "don't check".
  final int? plausibleRepsPerSet;
  final double? plausibleKmh;

  /// Easier/harder ways to do the same activity; all earn identical rewards.
  final List<String> variants;
  final String? easierAlternative;

  bool get usesReps => metrics.contains(Metric.reps);
  bool get usesDuration => metrics.contains(Metric.duration);
}

class ActivityCatalog {
  const ActivityCatalog._();

  static const pushUp = ActivityType(
    id: 'push_up',
    name: 'Push-ups',
    category: ActivityCategory.bodyweight,
    metrics: {Metric.sets, Metric.reps},
    plausibleRepsPerSet: 80,
    formCue: 'Keep your body in a straight line and move only as low as feels '
        'comfortable.',
    variants: ['Wall', 'Incline', 'Knee', 'Standard'],
    easierAlternative: 'Wall push-ups are a great place to start.',
  );
  static const squat = ActivityType(
    id: 'squat',
    name: 'Squats',
    category: ActivityCategory.bodyweight,
    metrics: {Metric.sets, Metric.reps},
    plausibleRepsPerSet: 120,
    formCue: 'Feet about shoulder-width apart, chest up, knees tracking over '
        'your toes.',
    variants: ['Sit-to-Stand (Chair)', 'Bodyweight'],
    easierAlternative: 'Try sitting down to a chair and standing back up.',
  );
  static const sitUp = ActivityType(
    id: 'sit_up',
    name: 'Sit-Ups / Crunches',
    category: ActivityCategory.bodyweight,
    metrics: {Metric.sets, Metric.reps},
    plausibleRepsPerSet: 120,
    formCue: 'Move slowly and keep your neck relaxed.',
    variants: ['Small Crunch', 'Sit-Up'],
  );
  static const plank = ActivityType(
    id: 'plank',
    name: 'Plank',
    category: ActivityCategory.bodyweight,
    metrics: {Metric.sets, Metric.duration},
    formCue: 'Hold a steady line from head to heels; stop if your back aches.',
    variants: ['Wall', 'Knee', 'Forearm'],
    easierAlternative: 'A wall plank is a gentle starting point.',
  );
  static const walking = ActivityType(
    id: 'walking',
    name: 'Walking',
    category: ActivityCategory.cardio,
    metrics: {Metric.duration, Metric.distance},
    plausibleKmh: 10,
    formCue: 'Pick a pace where you could still hold a conversation.',
    minutesPerKm: 12,
  );
  static const running = ActivityType(
    id: 'running',
    name: 'Running / Jogging',
    category: ActivityCategory.cardio,
    metrics: {Metric.duration, Metric.distance},
    plausibleKmh: 25,
    formCue: 'Start slow, and walk whenever you need to.',
    effortFactor: 1.25,
    minutesPerKm: 6.5,
    easierAlternative: 'Walk/jog intervals count just as much.',
  );
  static const dumbbellRow = ActivityType(
    id: 'dumbbell_row',
    name: 'Dumbbell Row',
    category: ActivityCategory.resistance,
    metrics: {Metric.sets, Metric.reps, Metric.load},
    plausibleRepsPerSet: 40,
    formCue: 'Brace with your free hand, pull towards your hip, lower slowly.',
  );
  static const dumbbellPress = ActivityType(
    id: 'dumbbell_press',
    name: 'Dumbbell Shoulder Press',
    category: ActivityCategory.resistance,
    metrics: {Metric.sets, Metric.reps, Metric.load},
    plausibleRepsPerSet: 40,
    formCue: 'Choose a light weight first; press up without arching your back.',
  );
  static const barbellSquat = ActivityType(
    id: 'barbell_squat',
    name: 'Barbell Squat',
    category: ActivityCategory.resistance,
    metrics: {Metric.sets, Metric.reps, Metric.load},
    plausibleRepsPerSet: 30,
    formCue: 'Use a spotter or safety rack, and learn the movement unloaded '
        'first.',
  );
  static const stretching = ActivityType(
    id: 'stretching',
    name: 'Stretching',
    category: ActivityCategory.mobility,
    metrics: {Metric.duration},
    formCue: 'Ease into each stretch. A gentle pull is enough; never bounce.',
    effortFactor: 0.6,
  );
  static const mobility = ActivityType(
    id: 'light_mobility',
    name: 'Light Mobility',
    category: ActivityCategory.mobility,
    metrics: {Metric.duration},
    formCue: 'Slow joint circles and easy movement. Stop if anything hurts.',
    effortFactor: 0.6,
  );

  static const all = <ActivityType>[
    pushUp,
    squat,
    sitUp,
    plank,
    walking,
    running,
    dumbbellRow,
    dumbbellPress,
    barbellSquat,
    stretching,
    mobility,
  ];

  static final Map<String, ActivityType> _byId = {
    for (final a in all) a.id: a,
  };

  /// Returns null for ids from a newer app version so old/new data never crash.
  static ActivityType? byId(String id) => _byId[id];

  static List<ActivityType> inCategory(ActivityCategory c) =>
      all.where((a) => a.category == c).toList();
}
