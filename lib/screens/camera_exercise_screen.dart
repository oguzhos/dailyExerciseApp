import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'workout_detail_screen.dart';
import 'history_screen.dart';

const Color _primaryGreen = Color(0xFF4A6849);
const Color _backgroundBeige = Color(0xFFFDFCF4);
const Color _textDark = Color(0xFF2C3E2C);

// ─────────────────────────────────────────────
// STATE MACHINE
// ─────────────────────────────────────────────
enum RepState { start, mid, end }

class CameraExerciseScreen extends StatefulWidget {
  final List<Exercise> exercises;
  final bool cameraEnabled;

  const CameraExerciseScreen({
    super.key,
    required this.exercises,
    required this.cameraEnabled,
  });

  @override
  State<CameraExerciseScreen> createState() => _CameraExerciseScreenState();
}

class _CameraExerciseScreenState extends State<CameraExerciseScreen> {
  CameraController? _cameraController;
  final PoseDetector _poseDetector = PoseDetector(
    options: PoseDetectorOptions(mode: PoseDetectionMode.stream),
  );
  bool _isInitialized = false;
  bool _isDetecting = false;
  final _smoother = LandmarkSmoother(windowSize: 5);

  int _currentExerciseIndex = 0;
  final List<int> _actualReps = [];
  int _currentReps = 0;

  Pose? _currentPose;
  double _accuracyRate = 0.0;
  double _smoothedAccuracy = 0.0;
  String _feedback = "Hazırlanıyor...";
  bool _isInCorrectPosition = false;

  // State Machine
  RepState _repState = RepState.start;
  DateTime? _stateEnteredAt;

  bool _testMode = false;
  Timer? _testTimer;
  int _testStep = 0;
  bool _showingConfirmation = false;

  @override
  void initState() {
    super.initState();
    _actualReps.addAll(List.filled(widget.exercises.length, 0));
    if (widget.cameraEnabled) {
      _initCamera();
    } else {
      setState(() => _isInitialized = true);
    }
  }

  Exercise get _currentExercise => widget.exercises[_currentExerciseIndex];
  int get _targetReps => _currentExercise.targetReps;
  bool get _isLastExercise => _currentExerciseIndex == widget.exercises.length - 1;

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;
    final camera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );
    _cameraController = CameraController(
      camera, ResolutionPreset.medium,
      enableAudio: false, imageFormatGroup: ImageFormatGroup.nv21,
    );
    await _cameraController!.initialize();
    if (!mounted) return;
    setState(() => _isInitialized = true);
    _cameraController!.startImageStream(_processFrame);
  }

  Future<void> _processFrame(CameraImage image) async {
    if (_isDetecting || _testMode || _showingConfirmation) return;
    _isDetecting = true;
    try {
      final inputImage = _convertToInputImage(image);
      if (inputImage == null) { _isDetecting = false; return; }
      final poses = await _poseDetector.processImage(inputImage);
      if (poses.isNotEmpty && mounted) {
        final smoothed = _smoother.smooth(poses.first);
        final result = _analyzeExercise(smoothed, _currentExercise.analysisType);
        _smoothedAccuracy = _smoothedAccuracy * 0.7 + (result['accuracy'] as double) * 0.3;
        if (_smoothedAccuracy > 97.5) _smoothedAccuracy = 100.0;
        setState(() {
          _currentPose = smoothed;
          _accuracyRate = _smoothedAccuracy;
          _feedback = result['feedback'] as String;
          _isInCorrectPosition = result['isCorrect'] as bool;
        });
      }
    } catch (e) { debugPrint('Pose detection hatası: $e'); }
    _isDetecting = false;
  }

  void _onRepCompleted() {
    final newReps = _currentReps + 1;
    setState(() {
      _currentReps = newReps;
      _actualReps[_currentExerciseIndex] = newReps;
      _repState = RepState.start;
      _stateEnteredAt = null;
    });
    if (_targetReps > 0 && newReps >= _targetReps) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _showNextExerciseConfirmation(completed: true);
      });
    }
  }

  // Tempo kontrolü — min 0.8 sn
  bool _isTempoValid() {
    if (_stateEnteredAt == null) return true;
    return DateTime.now().difference(_stateEnteredAt!).inMilliseconds >= 800;
  }

  Map<String, dynamic> _analyzeExercise(Pose pose, AnalysisType type) {
    switch (type) {
      case AnalysisType.sitToStand:        return _analyzeSitToStand(pose);
      case AnalysisType.straightLegRaise:  return _analyzeStraightLegRaise(pose);
      case AnalysisType.heelSlide:         return _analyzeHeelSlide(pose);
      case AnalysisType.miniSquat:         return _analyzeMiniSquat(pose);
      case AnalysisType.hipAbduction:      return _analyzeHipAbduction(pose);
      case AnalysisType.pelvicTilt:        return _analyzePelvicTilt(pose);
      case AnalysisType.bridge:            return _analyzeBridge(pose);
      case AnalysisType.birdDog:           return _analyzeBirdDog(pose);
      case AnalysisType.wallPushUp:        return _analyzeWallPushUp(pose);
      case AnalysisType.shoulderFlexion:   return _analyzeShoulderFlexion(pose);
      case AnalysisType.shoulderAbduction: return _analyzeShoulderAbduction(pose);
      case AnalysisType.heelRaise:         return _analyzeHeelRaise(pose);
      case AnalysisType.singleLegStand:    return _analyzeSingleLegStand(pose);
      case AnalysisType.general:           return _analyzeGeneral(pose);
    }
  }

  // 1. SIT-TO-STAND
  Map<String, dynamic> _analyzeSitToStand(Pose pose) {
    final hip = pose.landmarks[PoseLandmarkType.leftHip];
    final knee = pose.landmarks[PoseLandmarkType.leftKnee];
    final ankle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final shoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    if (!_checkLikelihood([hip, knee, ankle, shoulder])) return _notDetected();
    final kneeAngle = _angle(hip!.x, hip.y, knee!.x, knee.y, ankle!.x, ankle.y);
    final hipAngle = _angle(shoulder!.x, shoulder.y, hip.x, hip.y, knee.x, knee.y);
    double acc = 0; String fb = ''; bool ok = false;
    switch (_repState) {
      case RepState.start:
        if (kneeAngle >= 80 && kneeAngle <= 110) {
          acc = 100; fb = "Oturma pozisyonu ✓ Kalk!"; ok = true;
          _repState = RepState.mid; _stateEnteredAt = DateTime.now();
        } else { acc = 50; fb = "Dizi 90° bükerek otur"; }
        break;
      case RepState.mid:
        if (kneeAngle > 170 && hipAngle > 170) {
          if (_isTempoValid()) { acc = 100; fb = "Tam ayakta! 💪"; ok = true; _repState = RepState.end; _stateEnteredAt = DateTime.now(); }
          else { acc = 80; fb = "Çok hızlı! Yavaşla"; }
        } else if (kneeAngle > 140 && hipAngle > 150) { acc = 75; fb = "Neredeyse! Tam dik dur"; }
        else { acc = 55; fb = "Kalkmaya devam et"; }
        break;
      case RepState.end:
        if (kneeAngle <= 110) { if (_isTempoValid()) _onRepCompleted(); acc = 100; fb = "Tekrar otur ✓"; }
        else { acc = 85; fb = "Şimdi otur"; }
        break;
    }
    return {'accuracy': acc, 'feedback': fb, 'isCorrect': ok, 'isDown': false};
  }

  // 2. STRAIGHT LEG RAISE
  Map<String, dynamic> _analyzeStraightLegRaise(Pose pose) {
    final hip = pose.landmarks[PoseLandmarkType.leftHip];
    final knee = pose.landmarks[PoseLandmarkType.leftKnee];
    final ankle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final shoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    if (!_checkLikelihood([hip, knee, ankle, shoulder])) return _notDetected();
    final kneeAngle = _angle(hip!.x, hip.y, knee!.x, knee.y, ankle!.x, ankle.y);
    final hipFlexion = _angle(shoulder!.x, shoulder.y, hip.x, hip.y, knee.x, knee.y);
    double acc = 0; String fb = ''; bool ok = false;
    switch (_repState) {
      case RepState.start:
        if (hipFlexion < 15 && kneeAngle > 170) { acc = 100; fb = "Başlangıç ✓ Kaldır!"; ok = true; _repState = RepState.mid; _stateEnteredAt = DateTime.now(); }
        else if (kneeAngle < 170) { acc = 30; fb = "Dizi düzelt!"; }
        else { acc = 60; fb = "Bacağı indir"; }
        break;
      case RepState.mid:
        if (kneeAngle < 170) { acc = 20; fb = "Diz kırılıyor!"; }
        else if (hipFlexion >= 30 && hipFlexion <= 50 && kneeAngle > 175) {
          if (_isTempoValid()) { acc = 100; fb = "Mükemmel! 45° ✓"; ok = true; _repState = RepState.end; _stateEnteredAt = DateTime.now(); }
          else { acc = 80; fb = "Çok hızlı!"; }
        } else if (hipFlexion < 30) { acc = 60; fb = "Daha kaldır"; }
        else { acc = 70; fb = "Biraz indir"; }
        break;
      case RepState.end:
        if (hipFlexion < 15) { if (_isTempoValid()) _onRepCompleted(); acc = 100; fb = "İndir ✓"; }
        else { acc = 75; fb = "Kontrollü indir"; }
        break;
    }
    return {'accuracy': acc, 'feedback': fb, 'isCorrect': ok, 'isDown': false};
  }

  // 3. HEEL SLIDE
  Map<String, dynamic> _analyzeHeelSlide(Pose pose) {
    final hip = pose.landmarks[PoseLandmarkType.leftHip];
    final knee = pose.landmarks[PoseLandmarkType.leftKnee];
    final ankle = pose.landmarks[PoseLandmarkType.leftAnkle];
    if (!_checkLikelihood([hip, knee, ankle])) return _notDetected();
    final kneeAngle = _angle(hip!.x, hip.y, knee!.x, knee.y, ankle!.x, ankle.y);
    double acc = 0; String fb = ''; bool ok = false;
    switch (_repState) {
      case RepState.start:
        if (kneeAngle > 155) { acc = 100; fb = "Başlangıç ✓ Çek!"; ok = true; _repState = RepState.mid; _stateEnteredAt = DateTime.now(); }
        else { acc = 50; fb = "Bacağı uzat"; }
        break;
      case RepState.mid:
        if (kneeAngle < 100) {
          if (_isTempoValid()) { acc = 100; fb = "Mükemmel fleksiyon! ✓"; ok = true; _repState = RepState.end; _stateEnteredAt = DateTime.now(); }
          else { acc = 70; fb = "Çok hızlı!"; }
        } else if (kneeAngle < 130) { acc = 70; fb = "Biraz daha çek"; }
        else { acc = 50; fb = "Topuğu çek"; }
        break;
      case RepState.end:
        if (kneeAngle > 155) { if (_isTempoValid()) _onRepCompleted(); acc = 100; fb = "Uzat ✓"; }
        else { acc = 70; fb = "Kontrollü uzat"; }
        break;
    }
    return {'accuracy': acc, 'feedback': fb, 'isCorrect': ok, 'isDown': false};
  }

  // 4. MINI SQUAT
  Map<String, dynamic> _analyzeMiniSquat(Pose pose) {
    final hip = pose.landmarks[PoseLandmarkType.leftHip];
    final knee = pose.landmarks[PoseLandmarkType.leftKnee];
    final ankle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final shoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    if (!_checkLikelihood([hip, knee, ankle, shoulder])) return _notDetected();
    final kneeAngle = _angle(hip!.x, hip.y, knee!.x, knee.y, ankle!.x, ankle.y);
    final hipAngle = _angle(shoulder!.x, shoulder.y, hip.x, hip.y, knee.x, knee.y);
    double acc = 0; String fb = ''; bool ok = false;
    switch (_repState) {
      case RepState.start:
        if (kneeAngle > 160) { acc = 100; fb = "Hazır ✓ Çömel!"; ok = true; _repState = RepState.mid; _stateEnteredAt = DateTime.now(); }
        else { acc = 60; fb = "Dik dur"; }
        break;
      case RepState.mid:
        if (kneeAngle >= 110 && kneeAngle <= 135 && hipAngle < 155) {
          if (_isTempoValid()) { acc = 100; fb = "Mükemmel mini squat! 💪"; ok = true; _repState = RepState.end; _stateEnteredAt = DateTime.now(); }
          else { acc = 80; fb = "Çok hızlı!"; }
        } else if (kneeAngle > 135) { acc = 60; fb = "Biraz daha çömel"; }
        else if (kneeAngle < 110) { acc = 50; fb = "Çok derin!"; }
        else { acc = 65; fb = "Kalçayı geri çek"; }
        break;
      case RepState.end:
        if (kneeAngle > 160) { if (_isTempoValid()) _onRepCompleted(); acc = 100; fb = "Dik dur ✓"; }
        else { acc = 70; fb = "Kalkışı tamamla"; }
        break;
    }
    return {'accuracy': acc, 'feedback': fb, 'isCorrect': ok, 'isDown': false};
  }

  // 5. HIP ABDUCTION
  Map<String, dynamic> _analyzeHipAbduction(Pose pose) {
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
    if (!_checkLikelihood([leftHip, rightHip, leftKnee])) return _notDetected();
    final abAngle = _angle(rightHip!.x, rightHip.y, leftHip!.x, leftHip.y, leftKnee!.x, leftKnee.y);
    double acc = 0; String fb = ''; bool ok = false;
    switch (_repState) {
      case RepState.start:
        if (abAngle > 165) { acc = 100; fb = "Hazır ✓ Kaldır!"; ok = true; _repState = RepState.mid; _stateEnteredAt = DateTime.now(); }
        else { acc = 60; fb = "Bacağı indir"; }
        break;
      case RepState.mid:
        if (abAngle >= 120 && abAngle <= 150) {
          if (_isTempoValid()) { acc = 100; fb = "Harika! ✓"; ok = true; _repState = RepState.end; _stateEnteredAt = DateTime.now(); }
          else { acc = 75; fb = "Çok hızlı!"; }
        } else if (abAngle > 150) { acc = 65; fb = "Daha kaldır"; }
        else { acc = 70; fb = "Biraz indir"; }
        break;
      case RepState.end:
        if (abAngle > 165) { if (_isTempoValid()) _onRepCompleted(); acc = 100; fb = "İndir ✓"; }
        else { acc = 75; fb = "Aşağı indir"; }
        break;
    }
    return {'accuracy': acc, 'feedback': fb, 'isCorrect': ok, 'isDown': false};
  }

  // 6. PELVIC TILT
  Map<String, dynamic> _analyzePelvicTilt(Pose pose) {
    final shoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final hip = pose.landmarks[PoseLandmarkType.leftHip];
    final knee = pose.landmarks[PoseLandmarkType.leftKnee];
    if (!_checkLikelihood([shoulder, hip, knee])) return _notDetected();
    final bodyAngle = _angle(shoulder!.x, shoulder.y, hip!.x, hip.y, knee!.x, knee.y);
    double acc = 0; String fb = ''; bool ok = false;
    switch (_repState) {
      case RepState.start:
        if (bodyAngle > 175) { acc = 100; fb = "Hazır ✓ Bastır!"; ok = true; _repState = RepState.mid; _stateEnteredAt = DateTime.now(); }
        else { acc = 60; fb = "Rahat pozisyon al"; }
        break;
      case RepState.mid:
        if (bodyAngle >= 163 && bodyAngle <= 173) {
          if (_isTempoValid()) { acc = 100; fb = "Doğru tilt! ✓"; ok = true; _repState = RepState.end; _stateEnteredAt = DateTime.now(); }
          else { acc = 80; fb = "Tut..."; }
        } else if (bodyAngle > 173) { acc = 60; fb = "Beli zemine bastır"; }
        else { acc = 50; fb = "Çok fazla, yavaşla"; }
        break;
      case RepState.end:
        if (bodyAngle > 175) { if (_isTempoValid()) _onRepCompleted(); acc = 100; fb = "Bırak ✓"; }
        else { acc = 70; fb = "Gevşet"; }
        break;
    }
    return {'accuracy': acc, 'feedback': fb, 'isCorrect': ok, 'isDown': false};
  }

  // 7. BRIDGE
  Map<String, dynamic> _analyzeBridge(Pose pose) {
    final shoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final hip = pose.landmarks[PoseLandmarkType.leftHip];
    final knee = pose.landmarks[PoseLandmarkType.leftKnee];
    final ankle = pose.landmarks[PoseLandmarkType.leftAnkle];
    if (!_checkLikelihood([shoulder, hip, knee, ankle])) return _notDetected();
    final hipAngle = _angle(shoulder!.x, shoulder.y, hip!.x, hip.y, knee!.x, knee.y);
    final kneeAngle = _angle(hip.x, hip.y, knee.x, knee.y, ankle!.x, ankle.y);
    final goodKnee = kneeAngle >= 75 && kneeAngle <= 105;
    double acc = 0; String fb = ''; bool ok = false;
    switch (_repState) {
      case RepState.start:
        if (hipAngle < 135 && goodKnee) { acc = 100; fb = "Hazır ✓ Kaldır!"; ok = true; _repState = RepState.mid; _stateEnteredAt = DateTime.now(); }
        else if (!goodKnee) { acc = 40; fb = "Dizi 90° ayarla"; }
        else { acc = 60; fb = "Kalçayı yere koy"; }
        break;
      case RepState.mid:
        if (hipAngle > 160 && goodKnee) {
          if (_isTempoValid()) { acc = 100; fb = "Mükemmel köprü! 💪"; ok = true; _repState = RepState.end; _stateEnteredAt = DateTime.now(); }
          else { acc = 80; fb = "Tut!"; }
        } else if (!goodKnee) { acc = 40; fb = "Diz kayıyor!"; }
        else if (hipAngle >= 140) { acc = 70; fb = "Biraz daha yukarı"; }
        else { acc = 50; fb = "Kalçayı kaldır"; }
        break;
      case RepState.end:
        if (hipAngle < 135) { if (_isTempoValid()) _onRepCompleted(); acc = 100; fb = "İndir ✓"; }
        else { acc = 75; fb = "Kontrollü indir"; }
        break;
    }
    return {'accuracy': acc, 'feedback': fb, 'isCorrect': ok, 'isDown': false};
  }

  // 8. BIRD DOG
  Map<String, dynamic> _analyzeBirdDog(Pose pose) {
    final ls = pose.landmarks[PoseLandmarkType.leftShoulder];
    final le = pose.landmarks[PoseLandmarkType.leftElbow];
    final lw = pose.landmarks[PoseLandmarkType.leftWrist];
    final lh = pose.landmarks[PoseLandmarkType.leftHip];
    final lk = pose.landmarks[PoseLandmarkType.leftKnee];
    final la = pose.landmarks[PoseLandmarkType.leftAnkle];
    if (!_checkLikelihood([ls, le, lw, lh, lk, la])) return _notDetected();
    final armAngle = _angle(ls!.x, ls.y, le!.x, le.y, lw!.x, lw.y);
    final legAngle = _angle(lh!.x, lh.y, lk!.x, lk.y, la!.x, la.y);
    double acc = 0; String fb = ''; bool ok = false;
    switch (_repState) {
      case RepState.start:
        if (armAngle < 110 && legAngle < 110) { acc = 100; fb = "Dört ayak ✓ Uzan!"; ok = true; _repState = RepState.mid; _stateEnteredAt = DateTime.now(); }
        else { acc = 60; fb = "Dört ayak pozisyonu"; }
        break;
      case RepState.mid:
        if (armAngle > 160 && legAngle > 160) {
          if (_isTempoValid()) { acc = 100; fb = "Stabil! ✓"; ok = true; _repState = RepState.end; _stateEnteredAt = DateTime.now(); }
          else { acc = 80; fb = "Tut!"; }
        } else if (armAngle > 160) { acc = 65; fb = "Bacağı da uzat"; }
        else if (legAngle > 160) { acc = 65; fb = "Kolu da uzat"; }
        else { acc = 50; fb = "Kol ve bacağı uzat"; }
        break;
      case RepState.end:
        if (armAngle < 110 && legAngle < 110) { if (_isTempoValid()) _onRepCompleted(); acc = 100; fb = "Geri çek ✓"; }
        else { acc = 75; fb = "Pozisyona dön"; }
        break;
    }
    return {'accuracy': acc, 'feedback': fb, 'isCorrect': ok, 'isDown': false};
  }

  // 9. WALL PUSH-UP
  Map<String, dynamic> _analyzeWallPushUp(Pose pose) {
    final shoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final elbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final wrist = pose.landmarks[PoseLandmarkType.leftWrist];
    if (!_checkLikelihood([shoulder, elbow, wrist])) return _notDetected();
    final elbowAngle = _angle(shoulder!.x, shoulder.y, elbow!.x, elbow.y, wrist!.x, wrist.y);
    double acc = 0; String fb = ''; bool ok = false;
    switch (_repState) {
      case RepState.start:
        if (elbowAngle > 155) { acc = 100; fb = "Hazır ✓ Eğil!"; ok = true; _repState = RepState.mid; _stateEnteredAt = DateTime.now(); }
        else { acc = 60; fb = "Kolları düzelt"; }
        break;
      case RepState.mid:
        if (elbowAngle >= 85 && elbowAngle <= 100) {
          if (_isTempoValid()) { acc = 100; fb = "Mükemmel! 💪"; ok = true; _repState = RepState.end; _stateEnteredAt = DateTime.now(); }
          else { acc = 80; fb = "Tut!"; }
        } else if (elbowAngle > 100) { acc = 65; fb = "Biraz daha eğil"; }
        else { acc = 55; fb = "Çok fazla, geri gel"; }
        break;
      case RepState.end:
        if (elbowAngle > 155) { if (_isTempoValid()) _onRepCompleted(); acc = 100; fb = "İt ✓"; }
        else { acc = 70; fb = "Kolları uzat"; }
        break;
    }
    return {'accuracy': acc, 'feedback': fb, 'isCorrect': ok, 'isDown': false};
  }

  // 10. SHOULDER FLEXION
  Map<String, dynamic> _analyzeShoulderFlexion(Pose pose) {
    final hip = pose.landmarks[PoseLandmarkType.leftHip];
    final shoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final elbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final wrist = pose.landmarks[PoseLandmarkType.leftWrist];
    if (!_checkLikelihood([hip, shoulder, elbow, wrist])) return _notDetected();
    final shoulderAngle = _angle(hip!.x, hip.y, shoulder!.x, shoulder.y, elbow!.x, elbow.y);
    final elbowAngle = _angle(shoulder.x, shoulder.y, elbow.x, elbow.y, wrist!.x, wrist.y);
    double acc = 0; String fb = ''; bool ok = false;
    switch (_repState) {
      case RepState.start:
        if (shoulderAngle < 25) { acc = 100; fb = "Hazır ✓ Kaldır!"; ok = true; _repState = RepState.mid; _stateEnteredAt = DateTime.now(); }
        else { acc = 60; fb = "Kolu indir"; }
        break;
      case RepState.mid:
        if (elbowAngle < 155) { acc = 30; fb = "Dirsek kırılıyor!"; }
        else if (shoulderAngle >= 120 && shoulderAngle <= 160 && elbowAngle > 160) {
          if (_isTempoValid()) { acc = 100; fb = "Harika! ✓"; ok = true; _repState = RepState.end; _stateEnteredAt = DateTime.now(); }
          else { acc = 80; fb = "Çok hızlı!"; }
        } else if (shoulderAngle < 120) { acc = 65; fb = "Daha kaldır"; }
        else { acc = 70; fb = "Biraz indir"; }
        break;
      case RepState.end:
        if (shoulderAngle < 25) { if (_isTempoValid()) _onRepCompleted(); acc = 100; fb = "İndir ✓"; }
        else { acc = 75; fb = "Kontrollü indir"; }
        break;
    }
    return {'accuracy': acc, 'feedback': fb, 'isCorrect': ok, 'isDown': false};
  }

  // 11. SHOULDER ABDUCTION
  Map<String, dynamic> _analyzeShoulderAbduction(Pose pose) {
    final hip = pose.landmarks[PoseLandmarkType.leftHip];
    final shoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final elbow = pose.landmarks[PoseLandmarkType.leftElbow];
    if (!_checkLikelihood([hip, shoulder, elbow])) return _notDetected();
    final abAngle = _angle(hip!.x, hip.y, shoulder!.x, shoulder.y, elbow!.x, elbow.y);
    double acc = 0; String fb = ''; bool ok = false;
    switch (_repState) {
      case RepState.start:
        if (abAngle < 25) { acc = 100; fb = "Hazır ✓ Yana kaldır!"; ok = true; _repState = RepState.mid; _stateEnteredAt = DateTime.now(); }
        else { acc = 60; fb = "Kolu indir"; }
        break;
      case RepState.mid:
        if (abAngle >= 70 && abAngle <= 105) {
          if (_isTempoValid()) { acc = 100; fb = "90° — Mükemmel! ✓"; ok = true; _repState = RepState.end; _stateEnteredAt = DateTime.now(); }
          else { acc = 80; fb = "Çok hızlı!"; }
        } else if (abAngle < 70) { acc = 65; fb = "Daha kaldır"; }
        else { acc = 70; fb = "Biraz indir"; }
        break;
      case RepState.end:
        if (abAngle < 25) { if (_isTempoValid()) _onRepCompleted(); acc = 100; fb = "İndir ✓"; }
        else { acc = 75; fb = "Aşağı indir"; }
        break;
    }
    return {'accuracy': acc, 'feedback': fb, 'isCorrect': ok, 'isDown': false};
  }

  // 12. HEEL RAISE
  Map<String, dynamic> _analyzeHeelRaise(Pose pose) {
    final hip = pose.landmarks[PoseLandmarkType.leftHip];
    final knee = pose.landmarks[PoseLandmarkType.leftKnee];
    final ankle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final shoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    if (!_checkLikelihood([hip, knee, ankle, shoulder])) return _notDetected();
    final kneeAngle = _angle(hip!.x, hip.y, knee!.x, knee.y, ankle!.x, ankle.y);
    final hipAngle = _angle(shoulder!.x, shoulder.y, hip.x, hip.y, knee.x, knee.y);
    double acc = 0; String fb = ''; bool ok = false;
    switch (_repState) {
      case RepState.start:
        if (kneeAngle > 170 && hipAngle > 170) { acc = 100; fb = "Dik dur ✓ Yüksel!"; ok = true; _repState = RepState.mid; _stateEnteredAt = DateTime.now(); }
        else { acc = 60; fb = "Düz ayakta dur"; }
        break;
      case RepState.mid:
        if (kneeAngle > 170 && hipAngle > 170) {
          if (_isTempoValid()) { acc = 100; fb = "Parmak ucunda! ✓"; ok = true; _repState = RepState.end; _stateEnteredAt = DateTime.now(); }
          else { acc = 80; fb = "Tut!"; }
        } else if (kneeAngle < 170) { acc = 40; fb = "Diz bükme!"; }
        else { acc = 60; fb = "Kalçayı öne eğme"; }
        break;
      case RepState.end:
        if (kneeAngle > 168 && hipAngle > 168) { if (_isTempoValid()) _onRepCompleted(); acc = 100; fb = "İndir ✓"; }
        else { acc = 70; fb = "Kontrollü in"; }
        break;
    }
    return {'accuracy': acc, 'feedback': fb, 'isCorrect': ok, 'isDown': false};
  }

  // 13. SINGLE LEG STAND
  Map<String, dynamic> _analyzeSingleLegStand(Pose pose) {
    final hip = pose.landmarks[PoseLandmarkType.leftHip];
    final knee = pose.landmarks[PoseLandmarkType.leftKnee];
    final ankle = pose.landmarks[PoseLandmarkType.leftAnkle];
    if (!_checkLikelihood([hip, knee, ankle])) return _notDetected();
    final kneeAngle = _angle(hip!.x, hip.y, knee!.x, knee.y, ankle!.x, ankle.y);
    if (kneeAngle >= 165) return {'accuracy': 100.0, 'feedback': 'Dengeni koru! ✓', 'isCorrect': true, 'isDown': false};
    return {'accuracy': 50.0, 'feedback': 'Bacağı düzelt', 'isCorrect': false, 'isDown': false};
  }

  Map<String, dynamic> _analyzeGeneral(Pose pose) {
    final nose = pose.landmarks[PoseLandmarkType.nose];
    if (nose == null) return _notDetected();
    return {'accuracy': 80.0, 'feedback': "Devam et! 👍", 'isCorrect': true, 'isDown': false};
  }

  bool _checkLikelihood(List<PoseLandmark?> landmarks) =>
      landmarks.every((l) => l != null && l.likelihood >= 0.5);

  Map<String, dynamic> _notDetected() => {
    'accuracy': 0.0, 'feedback': "Kameraya tam görün", 'isCorrect': false, 'isDown': false,
  };

  double _angle(double ax, double ay, double bx, double by, double cx, double cy) {
    final r = atan2(cy - by, cx - bx) - atan2(ay - by, ax - bx);
    double a = r * (180 / pi);
    if (a < 0) a += 360;
    if (a > 180) a = 360 - a;
    return a;
  }

  InputImage? _convertToInputImage(CameraImage image) {
    if (_cameraController == null) return null;
    final rotation = InputImageRotationValue.fromRawValue(_cameraController!.description.sensorOrientation);
    if (rotation == null) return null;
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null || (format != InputImageFormat.nv21 && format != InputImageFormat.yuv_420_888)) return null;
    final plane = image.planes.first;
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation, format: format, bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  void _showNextExerciseConfirmation({bool completed = false}) {
    if (_showingConfirmation) return;
    _testTimer?.cancel();
    setState(() => _showingConfirmation = true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(completed ? "Egzersizi Tamamladın! 🎉" : "Egzersizi Bitir?",
            style: const TextStyle(fontWeight: FontWeight.bold, color: _textDark)),
        content: Text(
          completed
              ? "${_currentExercise.name} — $_currentReps tekrar ✓"
              : "${_currentExercise.name} — $_currentReps / $_targetReps tekrar",
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          if (!completed)
            TextButton(
              onPressed: () { Navigator.pop(context); setState(() { _showingConfirmation = false; _testMode = false; }); },
              child: const Text("Devam Et", style: TextStyle(color: Colors.grey)),
            ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() { _showingConfirmation = false; _testMode = false; _testStep = 0; });
              _finishWorkout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: _primaryGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text("Bitir", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _finishWorkout() {
    Navigator.pushReplacement(context, MaterialPageRoute(
      builder: (_) => WorkoutSummaryScreen(
        exercises: widget.exercises, actualReps: _actualReps,
        cameraEnabled: widget.cameraEnabled, accuracyRate: _accuracyRate.toInt(),
      ),
    ));
  }

  void _toggleTestMode() {
    if (_testMode) {
      _testTimer?.cancel();
      setState(() {
        _testMode = false; _testStep = 0;
        _repState = RepState.start; _stateEnteredAt = null;
        _accuracyRate = 0.0; _feedback = "Hazırlanıyor..."; _isInCorrectPosition = false;
      });
    } else {
      setState(() { _testMode = true; _testStep = 0; });
      _runTestSimulation();
    }
  }

  void _runTestSimulation() {
    final steps = [
      {'accuracy': 100.0, 'feedback': 'Başlangıç pozisyonu ✓', 'isCorrect': true},
      {'accuracy': 70.0, 'feedback': 'Hareket ediliyor...', 'isCorrect': false},
      {'accuracy': 100.0, 'feedback': 'Hedef pozisyon! ✓', 'isCorrect': true},
      {'accuracy': 100.0, 'feedback': 'Tut...', 'isCorrect': true},
      {'accuracy': 80.0, 'feedback': 'Geri dön...', 'isCorrect': false},
      {'accuracy': 20.0, 'feedback': 'Hazırlan...', 'isCorrect': false},
    ];
    int simState = 0;
    _testTimer = Timer.periodic(const Duration(milliseconds: 700), (timer) {
      if (!mounted || !_testMode) { timer.cancel(); return; }
      final step = steps[_testStep % steps.length];
      final idx = _testStep % steps.length;
      if (idx == 0 && simState == 0) { _repState = RepState.start; _stateEnteredAt = DateTime.now().subtract(const Duration(seconds: 1)); simState = 1; }
      else if (idx == 2 && simState == 1) { _repState = RepState.mid; _stateEnteredAt = DateTime.now().subtract(const Duration(seconds: 1)); simState = 2; }
      else if (idx == 4 && simState == 2) { _repState = RepState.end; _stateEnteredAt = DateTime.now().subtract(const Duration(seconds: 1)); _onRepCompleted(); simState = 0; }
      setState(() {
        _accuracyRate = step['accuracy'] as double;
        _feedback = step['feedback'] as String;
        _isInCorrectPosition = step['isCorrect'] as bool;
        _testStep++;
      });
    });
  }

  Color _stateColor() {
    switch (_repState) {
      case RepState.start: return Colors.blue;
      case RepState.mid:   return Colors.orange;
      case RepState.end:   return _primaryGreen;
    }
  }

  String _stateLabel() {
    switch (_repState) {
      case RepState.start: return "BAŞLA";
      case RepState.mid:   return "HEDEF";
      case RepState.end:   return "GERİ";
    }
  }

  @override
  void dispose() {
    _testTimer?.cancel();
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _poseDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: !_isInitialized
          ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              CircularProgressIndicator(color: _primaryGreen), SizedBox(height: 16),
              Text("Kamera başlatılıyor...", style: TextStyle(color: Colors.white70)),
            ]))
          : Stack(fit: StackFit.expand, children: [
              if (widget.cameraEnabled && _cameraController != null)
                Transform(alignment: Alignment.center, transform: Matrix4.identity()..scale(-1.0, 1.0), child: CameraPreview(_cameraController!))
              else Container(color: const Color(0xFF1A1A2E)),

              if (_currentPose != null && widget.cameraEnabled)
                CustomPaint(painter: PoseOverlayPainter(
                  pose: _currentPose!,
                  imageSize: Size(_cameraController!.value.previewSize!.height, _cameraController!.value.previewSize!.width),
                  screenSize: MediaQuery.of(context).size,
                )),

              // Üst bar
              Positioned(top: 0, left: 0, right: 0, child: SafeArea(child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.close, color: Colors.white, size: 22)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_currentExercise.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis),
                    Text(_currentExercise.detail, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11), overflow: TextOverflow.ellipsis),
                  ])),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: _stateColor().withOpacity(0.85), borderRadius: BorderRadius.circular(20)),
                    child: Text(_stateLabel(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(color: _primaryGreen.withOpacity(0.85), borderRadius: BorderRadius.circular(20)),
                    child: Text(_targetReps > 0 ? "$_currentReps / $_targetReps" : "$_currentReps tekrar",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _toggleTestMode,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: _testMode ? Colors.orange.withOpacity(0.9) : Colors.white24, borderRadius: BorderRadius.circular(20), border: Border.all(color: _testMode ? Colors.orange : Colors.white38, width: 1)),
                      child: Row(children: [
                        Icon(_testMode ? Icons.stop_rounded : Icons.science_rounded, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(_testMode ? "DUR" : "TEST", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                      ]),
                    ),
                  ),
                ]),
              ))),

              // Alt panel
              Positioned(bottom: 0, left: 0, right: 0, child: SafeArea(child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.75), borderRadius: BorderRadius.circular(24)),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(_currentExercise.imageUrl, height: 80, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink())),
                  const SizedBox(height: 12),
                  Text(_feedback, style: TextStyle(color: _isInCorrectPosition ? const Color(0xFF81C784) : Colors.orange, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 14),
                  Row(children: [
                    const Text("Doğruluk", style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const Spacer(),
                    Text("%${_accuracyRate.toInt()}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  ]),
                  const SizedBox(height: 8),
                  ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(
                    value: _accuracyRate / 100, minHeight: 10, backgroundColor: Colors.white24,
                    valueColor: AlwaysStoppedAnimation<Color>(_accuracyRate >= 80 ? const Color(0xFF81C784) : _accuracyRate >= 50 ? Colors.orange : Colors.redAccent),
                  )),
                  const SizedBox(height: 16),
                  SizedBox(width: double.infinity, child: OutlinedButton(
                    onPressed: () => _showNextExerciseConfirmation(completed: false),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white38), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), padding: const EdgeInsets.symmetric(vertical: 12)),
                    child: const Text("Egzersizi Bitir", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  )),
                ]),
              ))),
            ]),
    );
  }
}

// ─────────────────────────────────────────────
// POSE OVERLAY
// ─────────────────────────────────────────────
class PoseOverlayPainter extends CustomPainter {
  final Pose pose;
  final Size imageSize;
  final Size screenSize;
  PoseOverlayPainter({required this.pose, required this.imageSize, required this.screenSize});

  static const List<List<PoseLandmarkType>> connections = [
    [PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder],
    [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow],
    [PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist],
    [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow],
    [PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist],
    [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip],
    [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip],
    [PoseLandmarkType.leftHip, PoseLandmarkType.rightHip],
    [PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee],
    [PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle],
    [PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee],
    [PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final pp = Paint()..color = _primaryGreen..strokeWidth = 8..strokeCap = StrokeCap.round;
    final lp = Paint()..color = _primaryGreen.withOpacity(0.7)..strokeWidth = 3..strokeCap = StrokeCap.round;
    for (final c in connections) {
      final s = pose.landmarks[c[0]]; final e = pose.landmarks[c[1]];
      if (s != null && e != null) canvas.drawLine(_translatePoint(s.x, s.y, size), _translatePoint(e.x, e.y, size), lp);
    }
    for (final lm in pose.landmarks.values) canvas.drawCircle(_translatePoint(lm.x, lm.y, size), 5, pp);
  }

  Offset _translatePoint(double x, double y, Size size) {
  final scaleX = size.width / imageSize.width;
  final scaleY = size.height / imageSize.height;
  return Offset(size.width - x * scaleX, y * scaleY);
}

  @override
  bool shouldRepaint(PoseOverlayPainter old) => true;
}

// ─────────────────────────────────────────────
// LANDMARK SMOOTHER
// ─────────────────────────────────────────────
class LandmarkSmoother {
  final int windowSize;
  final Map<PoseLandmarkType, List<Offset>> _history = {};
  LandmarkSmoother({required this.windowSize});

  Pose smooth(Pose pose) {
    final smoothed = <PoseLandmarkType, PoseLandmark>{};
    for (final entry in pose.landmarks.entries) {
      final type = entry.key; final lm = entry.value;
      _history.putIfAbsent(type, () => []);
      _history[type]!.add(Offset(lm.x, lm.y));
      if (_history[type]!.length > windowSize) _history[type]!.removeAt(0);
      final h = _history[type]!;
      final avgX = h.map((o) => o.dx).reduce((a, b) => a + b) / h.length;
      final avgY = h.map((o) => o.dy).reduce((a, b) => a + b) / h.length;
      smoothed[type] = PoseLandmark(type: type, x: avgX, y: avgY, z: lm.z, likelihood: lm.likelihood);
    }
    return Pose(landmarks: smoothed);
  }

  void reset() => _history.clear();
}

// ─────────────────────────────────────────────
// EGZERSİZ ÖZETİ
// ─────────────────────────────────────────────
class WorkoutSummaryScreen extends StatelessWidget {
  final List<Exercise> exercises;
  final List<int> actualReps;
  final bool cameraEnabled;
  final int accuracyRate;

  const WorkoutSummaryScreen({super.key, required this.exercises, required this.actualReps, required this.cameraEnabled, required this.accuracyRate});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundBeige,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, automaticallyImplyLeading: false,
          title: const Text("Egzersiz Özeti", style: TextStyle(color: _textDark, fontWeight: FontWeight.bold))),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          Container(
            width: double.infinity, padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: _primaryGreen, borderRadius: BorderRadius.circular(24)),
            child: Column(children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 60),
              const SizedBox(height: 12),
              const Text("Tebrikler!", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(cameraEnabled ? "Doğruluk Oranı: %$accuracyRate" : "Doğruluk Oranı: %0 (Kamera kapalı)",
                  style: const TextStyle(color: Colors.white70, fontSize: 16)),
            ]),
          ),
          const SizedBox(height: 24),
          const Align(alignment: Alignment.centerLeft, child: Text("Hareket Detayları",
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: _textDark))),
          const SizedBox(height: 12),
          Expanded(child: ListView.separated(
            itemCount: exercises.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final ex = exercises[i]; final done = actualReps[i]; final target = ex.targetReps;
              final isComplete = ex.isTimeBased || (target > 0 && done >= target);
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isComplete ? _primaryGreen.withOpacity(0.3) : Colors.orange.withOpacity(0.3), width: 1.5)),
                child: Row(children: [
                  Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: isComplete ? _primaryGreen.withOpacity(0.1) : Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: Icon(ex.icon, color: isComplete ? _primaryGreen : Colors.orange)),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(ex.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _textDark)),
                    const SizedBox(height: 4),
                    Text(ex.isTimeBased ? ex.detail : target > 0 ? "$done / $target tekrar" : "$done tekrar",
                        style: TextStyle(color: isComplete ? _primaryGreen : Colors.orange, fontSize: 13, fontWeight: FontWeight.w600)),
                  ])),
                  Icon(isComplete ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                      color: isComplete ? _primaryGreen : Colors.orange),
                ]),
              );
            },
          )),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, height: 52, child: ElevatedButton(
            onPressed: () async {
              final totalReps = actualReps.fold(0, (sum, r) => sum + r);
              await WorkoutHistoryService.saveWorkout(WorkoutHistory(
                programName: exercises.isNotEmpty ? exercises.first.name : 'Egzersiz',
                date: DateTime.now(), accuracyRate: cameraEnabled ? accuracyRate : 0,
                cameraEnabled: cameraEnabled, totalReps: totalReps,
              ));
              if (context.mounted) Navigator.of(context).popUntil((route) => route.isFirst);
            },
            style: ElevatedButton.styleFrom(backgroundColor: _primaryGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            child: const Text("Ana Sayfaya Dön", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          )),
        ]),
      ),
    );
  }
}