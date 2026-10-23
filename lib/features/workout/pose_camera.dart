import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/pose.dart';
import 'ml_kit_pose_camera.dart';

/// One frame of pose detection. [pose] is null when nobody was found.
class PoseSample {
  const PoseSample(this.pose, this.millis);

  final BodyPose? pose;

  /// When the frame was seen, in milliseconds on a steadily increasing clock.
  final int millis;
}

enum PoseCameraStatus { ready, permissionDenied, noCamera, failed }

/// A camera that reports body poses. The real one wraps the phone camera and
/// an on-device pose detector (see `ml_kit_pose_camera.dart`); tests supply a
/// fake. Frames are processed live and are never stored or sent anywhere.
abstract class PoseCamera {
  /// Opens the camera and starts detecting. Asks for permission if needed.
  Future<PoseCameraStatus> start();

  Stream<PoseSample> get poses;

  /// True when the preview is a mirror image (a front camera), so anything
  /// drawn over it must be flipped to match.
  bool get mirrored;

  /// Width divided by height of the upright preview.
  double get previewAspect;

  Widget buildPreview(BuildContext context);

  /// Switches between the front and back cameras, if the phone has both.
  Future<void> flip();
  bool get canFlip;

  Future<void> dispose();
}

typedef PoseCameraFactory = PoseCamera Function();

/// How to make a camera, or null where there is none to use (web, desktop).
final poseCameraFactoryProvider = Provider<PoseCameraFactory?>((ref) {
  if (kIsWeb) return null;
  return switch (defaultTargetPlatform) {
    TargetPlatform.android || TargetPlatform.iOS => MlKitPoseCamera.new,
    _ => null,
  };
});
