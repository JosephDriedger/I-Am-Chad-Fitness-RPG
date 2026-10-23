import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import '../../domain/pose.dart';
import 'pose_camera.dart';

/// The phone camera plus Google's on-device ML Kit pose detector.
///
/// Everything happens on the device: camera frames go to the detector and are
/// dropped. Nothing is saved, and no network is used.
class MlKitPoseCamera implements PoseCamera {
  MlKitPoseCamera();

  final _detector = PoseDetector(options: PoseDetectorOptions());
  final _out = StreamController<PoseSample>.broadcast();
  final _clock = Stopwatch()..start();

  List<CameraDescription> _cameras = const [];
  int _index = 0;
  CameraController? _controller;
  bool _busy = false;
  bool _disposed = false;

  @override
  Stream<PoseSample> get poses => _out.stream;

  @override
  bool get canFlip => _cameras.length > 1;

  CameraDescription? get _camera => _cameras.isEmpty ? null : _cameras[_index];

  @override
  bool get mirrored => _camera?.lensDirection == CameraLensDirection.front;

  @override
  double get previewAspect {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return 3 / 4;
    // The reported aspect ratio is for a landscape sensor; we are portrait.
    return 1 / c.value.aspectRatio;
  }

  @override
  Future<PoseCameraStatus> start() async {
    try {
      _cameras = await availableCameras();
    } on CameraException {
      return PoseCameraStatus.failed;
    }
    if (_cameras.isEmpty) return PoseCameraStatus.noCamera;
    // Facing the player is the natural way to prop a phone up.
    final front = _cameras.indexWhere((c) => c.lensDirection == CameraLensDirection.front);
    _index = front >= 0 ? front : 0;
    return _open();
  }

  Future<PoseCameraStatus> _open() async {
    final camera = _camera!;
    final controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: defaultTargetPlatform == TargetPlatform.android
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );
    try {
      await controller.initialize();
      await controller.lockCaptureOrientation(DeviceOrientation.portraitUp);
      if (_disposed) {
        await controller.dispose();
        return PoseCameraStatus.failed;
      }
      _controller = controller;
      await controller.startImageStream(_onImage);
      return PoseCameraStatus.ready;
    } on CameraException catch (e) {
      await controller.dispose();
      _controller = null;
      return e.code.startsWith('CameraAccess')
          ? PoseCameraStatus.permissionDenied
          : PoseCameraStatus.failed;
    }
  }

  @override
  Future<void> flip() async {
    if (!canFlip) return;
    final old = _controller;
    _controller = null;
    if (old != null) {
      try {
        if (old.value.isStreamingImages) await old.stopImageStream();
      } on CameraException {
        // Already stopped.
      }
      await old.dispose();
    }
    _index = (_index + 1) % _cameras.length;
    await _open();
  }

  @override
  Widget buildPreview(BuildContext context) {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return const SizedBox.shrink();
    return CameraPreview(c);
  }

  Future<void> _onImage(CameraImage image) async {
    if (_busy || _disposed) return;
    _busy = true;
    try {
      final input = _toInput(image);
      if (input == null) return;
      final poses = await _detector.processImage(input);
      if (_disposed || _out.isClosed) return;
      _out.add(PoseSample(
        poses.isEmpty ? null : _convert(poses.first, image, input.metadata!.rotation),
        _clock.elapsedMilliseconds,
      ));
    } catch (e) {
      // A bad frame is not worth stopping for, but don't hide a real fault
      // from whoever is developing.
      if (kDebugMode) debugPrint('Pose frame skipped: $e');
    } finally {
      _busy = false;
    }
  }

  InputImage? _toInput(CameraImage image) {
    final camera = _camera;
    if (camera == null || image.planes.length != 1) return null;
    final rotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation);
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (rotation == null || format == null) return null;
    final plane = image.planes.first;
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  /// ML Kit reports landmarks in the upright image on Android, which is the
  /// camera image turned by the sensor rotation. iOS images arrive upright.
  BodyPose _convert(Pose pose, CameraImage image, InputImageRotation rotation) {
    final turned = defaultTargetPlatform == TargetPlatform.android &&
        (rotation == InputImageRotation.rotation90deg ||
            rotation == InputImageRotation.rotation270deg);
    final width = (turned ? image.height : image.width).toDouble();
    final height = (turned ? image.width : image.height).toDouble();

    JointPoint? pick(PoseLandmarkType t) {
      final l = pose.landmarks[t];
      return l == null ? null : JointPoint(l.x, l.y, confidence: l.likelihood);
    }

    final map = <Joint, JointPoint>{};
    void put(Joint j, PoseLandmarkType t) {
      final p = pick(t);
      if (p != null) map[j] = p;
    }

    put(Joint.nose, PoseLandmarkType.nose);
    put(Joint.leftShoulder, PoseLandmarkType.leftShoulder);
    put(Joint.rightShoulder, PoseLandmarkType.rightShoulder);
    put(Joint.leftElbow, PoseLandmarkType.leftElbow);
    put(Joint.rightElbow, PoseLandmarkType.rightElbow);
    put(Joint.leftWrist, PoseLandmarkType.leftWrist);
    put(Joint.rightWrist, PoseLandmarkType.rightWrist);
    put(Joint.leftHip, PoseLandmarkType.leftHip);
    put(Joint.rightHip, PoseLandmarkType.rightHip);
    put(Joint.leftKnee, PoseLandmarkType.leftKnee);
    put(Joint.rightKnee, PoseLandmarkType.rightKnee);
    put(Joint.leftAnkle, PoseLandmarkType.leftAnkle);
    put(Joint.rightAnkle, PoseLandmarkType.rightAnkle);
    return BodyPose(width: width, height: height, joints: map);
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    final c = _controller;
    _controller = null;
    if (c != null) {
      try {
        if (c.value.isStreamingImages) await c.stopImageStream();
      } on CameraException {
        // Already stopped.
      }
      await c.dispose();
    }
    await _detector.close();
    await _out.close();
  }
}
