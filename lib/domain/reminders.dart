/// Gentle, opt-in reminders: what they say, and when they may be sent. This is
/// only rules and words; delivering a notification is the platform's job (see
/// lib/app/reminders.dart). See docs/CONTENT_GUIDELINES.md before changing the
/// wording, and docs/DECISIONS.md for why these limits exist.
///
/// A reminder is a small kindness, never a nag:
///  * Off until the player turns it on, and every setting is theirs to change.
///  * At most one a day, only on days they picked, only between 8 am and 9 pm.
///  * Never on a day they have already moved, and never for the rest of a week
///    they have already met their goal.
///  * It never mentions streaks, missed days, or what they have not done, and
///    never counts, compares, pressures or sells.
///  * It plans only a fortnight ahead and is replanned each time the game is
///    opened, so if someone stops opening it the reminders simply stop. Nothing
///    escalates, and nothing follows them around.
library;

/// The player's choices. Off by default.
class ReminderPrefs {
  const ReminderPrefs({
    this.enabled = false,
    this.hour = 18,
    this.days = const {DateTime.monday, DateTime.wednesday, DateTime.friday},
  });

  final bool enabled;

  /// Local hour, from [earliestHour] to [latestHour].
  final int hour;

  /// Weekdays, 1 = Monday to 7 = Sunday.
  final Set<int> days;

  static const earliestHour = 8;
  static const latestHour = 21;

  ReminderPrefs copyWith({bool? enabled, int? hour, Set<int>? days}) => ReminderPrefs(
        enabled: enabled ?? this.enabled,
        hour: (hour ?? this.hour).clamp(earliestHour, latestHour),
        days: days ?? this.days,
      );

  /// The days as one number, for storing: bit 0 is Monday, bit 6 is Sunday.
  int get daysBits => days.fold(0, (a, d) => a | (1 << (d - 1)));

  static Set<int> daysFromBits(int bits) => {
        for (var d = 1; d <= 7; d++)
          if (bits & (1 << (d - 1)) != 0) d,
      };

  @override
  bool operator ==(Object other) =>
      other is ReminderPrefs && other.enabled == enabled && other.hour == hour && other.daysBits == daysBits;

  @override
  int get hashCode => Object.hash(enabled, hour, daysBits);
}

/// One notification to send, at a given local time.
class Reminder {
  const Reminder(this.at, this.text);

  final DateTime at;
  final String text;

  @override
  bool operator ==(Object other) => other is Reminder && other.at == at && other.text == text;

  @override
  int get hashCode => Object.hash(at, text);
}

class ReminderCopy {
  const ReminderCopy._();

  static const title = 'I Am Chad';

  /// Every line a reminder can say. Warm, a little silly, and about the player's
  /// own time, never about what they have not done.
  static const lines = <String>[
    'The guild hall is open whenever you are. No rush.',
    'Chad has put the kettle on. Come by if you feel like it.',
    'A short walk is a legendary quest. Only if you fancy it.',
    'Movement or rest, both are on the menu today.',
    'Biscuit is sitting by the door. He says there is no pressure.',
    'Whenever you have ten minutes, there is a chair for you here.',
    'Stretch, stroll or stare at the horizon. All three count.',
    'Your place in the chronicle is kept. Come and add to it when you like.',
    'A good day for a gentle adventure, or a good day for tea. You decide.',
    'The practice yard is open, and so is the sofa.',
    'Chad says rest is training. He wrote it on a banner.',
    'A little movement, a lot of kindness. The hall is ready when you are.',
  ];

  /// The line for a given day, stable for that day and varied across days.
  static String lineFor(DateTime day) {
    final n = DateTime.utc(day.year, day.month, day.day).difference(DateTime.utc(2024)).inDays;
    return lines[n.abs() % lines.length];
  }
}

class ReminderPlanner {
  const ReminderPlanner._();

  /// How far ahead reminders are planned. After this long without the game being
  /// opened, they stop by themselves.
  static const horizonDays = 14;

  /// The reminders to have scheduled, in order, from [now].
  ///
  /// [movedToday] is whether any movement has been logged today, and
  /// [goalMetThisWeek] whether this week's goal is already met. Each silences the
  /// reminders it makes pointless: a met goal silences the rest of this
  /// Monday-to-Sunday week.
  static List<Reminder> plan({
    required ReminderPrefs prefs,
    required DateTime now,
    required bool movedToday,
    required bool goalMetThisWeek,
  }) {
    if (!prefs.enabled || prefs.days.isEmpty) return const [];
    final out = <Reminder>[];
    final today = DateTime(now.year, now.month, now.day);
    // Midnight starting next Monday, built from the date so a clock change cannot shift it.
    final nextMonday = DateTime(today.year, today.month, today.day + (8 - today.weekday));
    for (var i = 0; i < horizonDays; i++) {
      final day = DateTime(today.year, today.month, today.day + i);
      if (!prefs.days.contains(day.weekday)) continue;
      if (i == 0 && movedToday) continue;
      if (goalMetThisWeek && day.isBefore(nextMonday)) continue;
      final at = DateTime(day.year, day.month, day.day, prefs.hour);
      if (!at.isAfter(now)) continue;
      out.add(Reminder(at, ReminderCopy.lineFor(day)));
    }
    return out;
  }
}
