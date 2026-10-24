import 'dart:async';
import 'dart:math' as math;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/app/game_ui.dart';
import 'package:i_am_chad/data/database.dart';
import 'package:i_am_chad/data/repository.dart';
import 'package:i_am_chad/domain/activity.dart';
import 'package:i_am_chad/domain/hero.dart';
import 'package:i_am_chad/domain/pose.dart';
import 'package:i_am_chad/features/workout/pose_camera.dart';

import 'helpers.dart';

/// A camera that shows nothing and reports whatever the test tells it to.
class _FakeCamera implements PoseCamera {
  _FakeCamera(this.status);

  final PoseCameraStatus status;
  final _out = StreamController<PoseSample>.broadcast();
  int _now = 0;
  bool disposed = false;

  @override
  Future<PoseCameraStatus> start() async => status;

  @override
  Stream<PoseSample> get poses => _out.stream;

  @override
  bool get mirrored => true;

  @override
  double get previewAspect => 0.75;

  @override
  bool get canFlip => false;

  @override
  Future<void> flip() async {}

  @override
  Widget buildPreview(BuildContext context) => const ColoredBox(color: Colors.black);

  @override
  Future<void> dispose() async {
    disposed = true;
    await _out.close();
  }

  /// One frame of a push-up with the elbow at [degrees], 100 ms after the last.
  void frame(double? degrees) {
    _now += 100;
    BodyPose? pose;
    if (degrees != null) {
      final rad = degrees * math.pi / 180;
      pose = BodyPose(width: 480, height: 640, joints: {
        Joint.leftShoulder: const JointPoint(300, 300),
        Joint.leftElbow: const JointPoint(200, 300),
        Joint.leftWrist: JointPoint(200 + 100 * math.cos(rad), 300 + 100 * math.sin(rad)),
      });
    }
    _out.add(PoseSample(pose, _now));
  }

  /// A whole body in view, arms straight, ready to start.
  void fullBody() {
    _now += 100;
    _out.add(PoseSample(
      BodyPose(width: 480, height: 640, joints: {
        for (final j in Joint.values) j: JointPoint(100.0 + j.index * 20, 100.0 + j.index * 30),
        Joint.leftShoulder: const JointPoint(300, 300),
        Joint.leftElbow: const JointPoint(200, 300),
        Joint.leftWrist: const JointPoint(100, 300),
      }),
      _now,
    ));
  }

  Future<void> rep(WidgetTester tester) async {
    for (var i = 0; i <= 12; i++) {
      frame(170 - 90 * i / 12);
      await tester.pump(const Duration(milliseconds: 20));
    }
    for (var i = 0; i < 3; i++) {
      frame(80);
    }
    for (var i = 1; i <= 12; i++) {
      frame(80 + 90 * i / 12);
      await tester.pump(const Duration(milliseconds: 20));
    }
    for (var i = 0; i < 3; i++) {
      frame(170);
    }
    await tester.pump();
  }
}

Future<(AppDatabase, GameRepository, _FakeCamera)> _boot(
  WidgetTester tester, {
  PoseCameraStatus status = PoseCameraStatus.ready,
}) async {
  usePhone(tester);
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  final repo = GameRepository(db);
  await tester.runAsync(() => repo.createHero(const HeroProfile(
        name: 'Ada',
        appearanceStyle: 0,
        appearanceColor: 0,
        experience: ExperienceLevel.starting,
        preferredCategories: {ActivityCategory.bodyweight},
        hasDumbbells: false,
      )));
  final camera = _FakeCamera(status);
  await bootApp(tester, db, overrides: [
    poseCameraFactoryProvider.overrideWithValue(() => camera),
  ]);
  await tester.tap(find.text('Train'));
  await settle(tester, frames: 30);
  await openExercise(tester, 'Push-ups');
  return (db, repo, camera);
}

Future<void> _openCamera(WidgetTester tester) async {
  final button = find.text('Count My Reps With the Camera');
  await tester.scrollUntilVisible(button, 200, scrollable: find.byType(Scrollable).first);
  await tester.ensureVisible(button);
  await settle(tester, frames: 4);
  await tester.tap(button);
  await settle(tester);
}

/// The intro is a long page; scroll down to the button before pressing it.
Future<void> _start(WidgetTester tester) async {
  final button = find.text('Start Camera');
  await tester.scrollUntilVisible(button, 300, scrollable: find.byType(Scrollable).first);
  await tester.ensureVisible(button);
  await settle(tester, frames: 4);
  await tester.tap(button);
  await settle(tester);
}

void main() {
  testWidgets('counts reps with the camera and fills in the log', (tester) async {
    final (db, repo, camera) = await _boot(tester);
    await _openCamera(tester);

    // The intro explains how to set the phone up, and the privacy promise.
    expect(find.text('Set Up Your Phone'), findsOneWidget);
    for (final step in [
      'Put Your Phone in Its Stand',
      'Stand Back About Two Big Steps',
      'Turn Side-On',
      'Give It Good Light',
      'Check the Screen',
    ]) {
      expect(find.text(step), findsOneWidget, reason: step);
    }
    expect(find.textContaining('low down near the floor'), findsOneWidget, reason: 'push-up specific');
    await tester.scrollUntilVisible(find.text('Your Privacy'), 300,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Your Privacy'), findsOneWidget);
    expect(find.textContaining('Nothing is recorded, saved or sent anywhere'), findsOneWidget);
    expect(find.textContaining('smaller range of motion still counts'), findsOneWidget);
    await _start(tester);
    await settle(tester);

    // The set-up check starts unticked and ticks as the camera sees you.
    expect(find.text('Whole Body in View'), findsOneWidget);
    expect(find.text('Ready Position'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
    camera.fullBody();
    await tester.pump();
    camera.fullBody();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byIcon(Icons.check_circle_rounded), findsNWidgets(2));
    // Nothing counted yet, so there is nothing to finish.
    expect(tester.widget<GameButton>(find.widgetWithText(GameButton, 'Finish')).onPressed, isNull);

    // Three steady reps.
    await camera.rep(tester);
    await camera.rep(tester);
    await camera.rep(tester);
    expect(find.text('3'), findsWidgets);

    await tester.tap(find.text('Finish'));
    await settle(tester, frames: 20);
    expect(camera.disposed, isTrue, reason: 'the camera must switch off when leaving');

    // Back on the log screen the numbers are filled in and marked.
    expect(find.text('Counted by the camera. Change the numbers any time.'), findsOneWidget);
    expect(tester.widget<TextField>(find.widgetWithText(TextField, 'Sets')).controller!.text, '1');
    expect(tester.widget<TextField>(find.widgetWithText(TextField, 'Reps per Set')).controller!.text, '3');

    // Saving needs no honesty question, and the entry remembers the camera.
    await tester.scrollUntilVisible(find.text('Save Workout'), 300, scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(find.text('Save Workout'));
    await tester.pump();
    await tester.ensureVisible(find.text('Save Workout'));
    await tester.ensureVisible(find.text('Save Workout'));
    await tester.tap(find.text('Save Workout'));
    await settle(tester);
    expect(find.text('Quick Honesty Check'), findsNothing);
    expect(find.text('Workout Saved!'), findsOneWidget);
    final saved = (await tester.runAsync(() => repo.watchWorkouts().first))!.single;
    expect(saved.activityId, 'push_up');
    expect(saved.reps, 3);
    expect(saved.cameraCounted, isTrue);

    await shutDown(tester, db);
  });

  testWidgets('several sets are kept, and editing the numbers drops the camera mark', (tester) async {
    final (db, repo, camera) = await _boot(tester);
    await _openCamera(tester);
    await _start(tester);
    await settle(tester);

    await camera.rep(tester);
    await camera.rep(tester);
    await camera.rep(tester);
    await tester.tap(find.text('Set Done'));
    await settle(tester);
    await camera.rep(tester);
    await camera.rep(tester);
    await tester.tap(find.text('Finish'));
    await settle(tester, frames: 20);

    String field(String label) =>
        tester.widget<TextField>(find.widgetWithText(TextField, label)).controller!.text;
    expect(field('Sets'), '2');
    expect(field('Reps per Set'), '3', reason: '(3 + 2) / 2 rounds up');
    expect(find.widgetWithText(TextField, 'Notes (Optional)'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.widgetWithText(TextField, 'Notes (Optional)')).controller!.text,
      'Camera counted: 3, 2',
    );

    // Typing different numbers means the camera no longer vouches for them.
    await tester.enterText(find.widgetWithText(TextField, 'Reps per Set'), '4');
    await settle(tester);
    expect(find.text('Counted by the camera. Change the numbers any time.'), findsNothing);

    await shutDown(tester, db);
  });

  testWidgets('leaving without finishing keeps nothing and still switches the camera off', (tester) async {
    final (db, repo, camera) = await _boot(tester);
    await _openCamera(tester);
    await _start(tester);
    await settle(tester);
    await camera.rep(tester);
    await tester.pageBack();
    await settle(tester, frames: 20);
    expect(camera.disposed, isTrue);
    expect(tester.widget<TextField>(find.widgetWithText(TextField, 'Sets')).controller!.text, isEmpty);
    expect(find.text('Counted by the camera. Change the numbers any time.'), findsNothing);
    await shutDown(tester, db);
  });

  testWidgets('the set-up help is one tap away while counting', (tester) async {
    final (db, repo, camera) = await _boot(tester);
    await _openCamera(tester);
    await _start(tester);
    await settle(tester);

    await tester.tap(find.byTooltip('How to Set Up'));
    await settle(tester);
    expect(find.text('How to Set Up'), findsWidgets);
    expect(find.text('Put Your Phone in Its Stand'), findsOneWidget);
    expect(find.text('Stand Back About Two Big Steps'), findsOneWidget);
    await tester.tap(find.text('Got It'));
    await settle(tester);
    expect(find.text('Put Your Phone in Its Stand'), findsNothing);
    // Still counting afterwards.
    expect(find.text('Finish'), findsOneWidget);
    await shutDown(tester, db);
  });

  testWidgets('squats get their own set-up advice', (tester) async {
    usePhone(tester);
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final repo = GameRepository(db);
    await tester.runAsync(() => repo.createHero(const HeroProfile(
          name: 'Ada',
          appearanceStyle: 0,
          appearanceColor: 0,
          experience: ExperienceLevel.returning,
          preferredCategories: {ActivityCategory.bodyweight},
          hasDumbbells: false,
        )));
    await bootApp(tester, db, overrides: [
      poseCameraFactoryProvider.overrideWithValue(() => _FakeCamera(PoseCameraStatus.ready)),
    ]);
    await tester.tap(find.text('Train'));
    await settle(tester, frames: 30);
    await openExercise(tester, 'Squats');
    await _openCamera(tester);
    expect(find.textContaining('about hip height'), findsOneWidget);
    expect(find.textContaining('low down near the floor'), findsNothing);
    await shutDown(tester, db);
  });

  testWidgets('a denied camera explains itself and typing still works', (tester) async {
    final (db, repo, camera) = await _boot(tester, status: PoseCameraStatus.permissionDenied);
    await _openCamera(tester);
    await _start(tester);
    await settle(tester);

    expect(find.text('No Camera Today'), findsOneWidget);
    expect(find.textContaining('switched off for I Am Chad'), findsOneWidget);
    await tester.tap(find.text('Back to Logging'));
    await settle(tester, frames: 20);

    await tester.enterText(find.widgetWithText(TextField, 'Sets'), '2');
    await tester.enterText(find.widgetWithText(TextField, 'Reps per Set'), '8');
    await tester.scrollUntilVisible(find.text('Save Workout'), 300, scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(find.text('Save Workout'));
    await tester.pump();
    await tester.ensureVisible(find.text('Save Workout'));
    await tester.ensureVisible(find.text('Save Workout'));
    await tester.tap(find.text('Save Workout'));
    await settle(tester);
    final saved = (await tester.runAsync(() => repo.watchWorkouts().first))!.single;
    expect(saved.cameraCounted, isFalse);
    expect(saved.reps, 8);
    await shutDown(tester, db);
  });

  testWidgets('the camera button only appears for exercises it can count', (tester) async {
    final (db, repo, camera) = await _boot(tester);
    expect(find.text('Count My Reps With the Camera'), findsOneWidget);
    await tester.pageBack();
    await settle(tester, frames: 20);
    await openExercise(tester, 'Walking');
    expect(find.text('Count My Reps With the Camera'), findsNothing);
    await shutDown(tester, db);
  });
}
