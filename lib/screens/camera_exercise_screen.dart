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

  final int _currentExerciseIndex = 0;
  final List<int> _actualReps = [];
  int _currentReps = 0;

  // --- Gerçek Doğruluk Hesaplama ---
  // Her tekrar için "mid" state'inde ulaşılan en yüksek pozisyon puanını
  // takip ediyoruz. Bu, kullanıcının hedef pozisyona ne kadar düzgün
  // ulaştığını gösterir. Tekrar tamamlanınca _allRepsAccuracies'e eklenir.
  double _currentRepPeak = 0.0;
  final List<double> _allRepsAccuracies = [];

  Pose? _currentPose;
  double _accuracyRate = 0.0;
  double _smoothedAccuracy = 0.0;
  // Peak takibi için ayrı yumuşatılmış "hedef pozisyon puanı".
  // Display puanı max(start, target) olduğu için tek başına hedefe ne
  // kadar yaklaşıldığını ayrı tutmamız gerekiyor.
  double _smoothedTargetScore = 0.0;
  String _feedback = "Kameraya tam görün...";
  bool _isInCorrectPosition = false;

  // setState'i ~10 Hz ile sınırlamak için (titreme önler)
  DateTime? _lastUiUpdateAt;

  // State Machine
  RepState _repState = RepState.start;
  DateTime? _stateEnteredAt;
  DateTime? _lastTickAt;

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

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;
    final camera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );
    _cameraController = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.nv21,
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
      if (inputImage == null) {
        _isDetecting = false;
        return;
      }
      final poses = await _poseDetector.processImage(inputImage);
      if (poses.isNotEmpty && mounted) {
        final smoothed = _smoother.smooth(poses.first);
        final result = _analyzeExercise(
          smoothed,
          _currentExercise.analysisType,
        );

        final double rawDisplay = result['accuracy'] as double;
        // Analizör hedef pozisyonun puanını ayrıca verir; vermezse display'i
        // kullan. Display = max(startPos, targetPos), hedef puanı sadece
        // "hedefe ne kadar yaklaştın" → rep peak'i için bu kullanılmalı.
        final double rawTarget =
            (result['targetScore'] as double?) ?? rawDisplay;

        // Asimetrik EMA: yükselişte hızlı (0.30 attack), düşüşte yumuşak
        // (0.15 decay). Bar 100'e hızlı ulaşır ama düşerken titremez.
        // Kullanıcı kısa süre hedefte kalsa bile bar yetişir.
        final attackOrDecay =
            rawDisplay > _smoothedAccuracy ? 0.30 : 0.15;
        _smoothedAccuracy =
            _smoothedAccuracy * (1 - attackOrDecay) + rawDisplay * attackOrDecay;
        if (_smoothedAccuracy > 99.0) _smoothedAccuracy = 100.0;
        if (_smoothedAccuracy < 0.5) _smoothedAccuracy = 0.0;

        // Hedef puanı: peak tracking için aynı asimetrik smoothing.
        final targetAlpha =
            rawTarget > _smoothedTargetScore ? 0.30 : 0.15;
        _smoothedTargetScore = _smoothedTargetScore * (1 - targetAlpha) +
            rawTarget * targetAlpha;

        // Sadece "mid" state'te (kullanıcı hedefe doğru hareket ederken)
        // hedef puanının zirvesini al → bu tekrarın puanı.
        if (_repState == RepState.mid &&
            _smoothedTargetScore > _currentRepPeak) {
          _currentRepPeak = _smoothedTargetScore;
        }

        // setState'i ~10 Hz ile sınırla → bar ve metin stabil görünür.
        // Rep counting ve smoothing her karede çalışmaya devam eder.
        final now = DateTime.now();
        final shouldUpdateUi = _lastUiUpdateAt == null ||
            now.difference(_lastUiUpdateAt!).inMilliseconds >= 100;
        if (shouldUpdateUi) {
          _lastUiUpdateAt = now;
          setState(() {
            _currentPose = smoothed;
            _accuracyRate = _smoothedAccuracy;
            _feedback = result['feedback'] as String;
            _isInCorrectPosition = result['isCorrect'] as bool;
          });
        }
      }
    } catch (e) {
      debugPrint('Pose detection hatası: $e');
    }
    _isDetecting = false;
  }

  void _onRepCompleted() {
    final newReps = _currentReps + 1;

    // Tekrar tamamlandı — bu tekrarda mid state boyunca ulaşılan en yüksek
    // pozisyon puanını kaydet. Eğer hiçbir örneklem alınmadıysa (ör. test
    // modunda veya çok hızlı geçişte) mevcut smoothed değerini kullan.
    final repScore = _currentRepPeak > 0 ? _currentRepPeak : _smoothedAccuracy;
    _allRepsAccuracies.add(repScore);
    _currentRepPeak = 0.0;

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

  bool _isTempoValid() {
    if (_stateEnteredAt == null) return true;
    return DateTime.now().difference(_stateEnteredAt!).inMilliseconds >= 800;
  }

  /// Açının istenen aralığa olan yakınlığını 0–100 puana çevirir.
  /// Aralık içinde 100, dışında [falloff] derece sonra 0 olur (lineer azalma).
  double _scoreNear(
    double angle, {
    required double idealMin,
    required double idealMax,
    double falloff = 50,
  }) {
    if (angle >= idealMin && angle <= idealMax) return 100.0;
    final diff = angle < idealMin ? idealMin - angle : angle - idealMax;
    if (diff >= falloff) return 0.0;
    return 100.0 - (diff / falloff) * 100.0;
  }

  Map<String, dynamic> _analyzeExercise(Pose pose, AnalysisType type) {
    switch (type) {
      case AnalysisType.sitToStand:
        return _analyzeSitToStand(pose);
      case AnalysisType.miniSquat:
        return _analyzeMiniSquat(pose);
      case AnalysisType.shoulderAbduction:
        return _analyzeShoulderAbduction(pose);
      case AnalysisType.singleLegStand:
        return _analyzeSingleLegStand(pose);
      case AnalysisType.highKnees:
        return _analyzeHighKnees(pose);
      case AnalysisType.sideBend:
        return _analyzeSideBend(pose);
      default:
        return _analyzeGeneral(pose);
    }
  }

  // 1. SIT-TO-STAND (Sandalyeden Kalkma)
  Map<String, dynamic> _analyzeSitToStand(Pose pose) {
    final hip =
        pose.landmarks[PoseLandmarkType.leftHip] ??
        pose.landmarks[PoseLandmarkType.rightHip];
    final knee =
        pose.landmarks[PoseLandmarkType.leftKnee] ??
        pose.landmarks[PoseLandmarkType.rightKnee];
    final ankle =
        pose.landmarks[PoseLandmarkType.leftAnkle] ??
        pose.landmarks[PoseLandmarkType.rightAnkle];

    if (!_checkLikelihood([hip, knee, ankle])) return _notDetected();

    final kneeAngle = _angle(hip!.x, hip.y, knee!.x, knee.y, ankle!.x, ankle.y);

    // Sandalyeden kalkma egzersizi → kullanıcı tercihi: bar sadece tam
    // OTURURKEN %100 olsun (rep cycle'ı tamamlama göstergesi).
    // Peak tracking için ayrıca standScore hesaplıyoruz (gerçek rep hedefi).
    final sitScore =
        _scoreNear(kneeAngle, idealMin: 70, idealMax: 110, falloff: 30);
    final standScore =
        _scoreNear(kneeAngle, idealMin: 158, idealMax: 180, falloff: 45);
    final displayAcc = sitScore;

    String fb;
    bool ok = false;

    switch (_repState) {
      case RepState.start:
        if (kneeAngle < 115) {
          fb = "Oturuyorsun ✓ Şimdi Kalk!";
          ok = true;
          _repState = RepState.mid;
          _stateEnteredAt = DateTime.now();
        } else {
          fb = "Başlamak için sandalyeye tam otur";
        }
        break;
      case RepState.mid:
        if (kneeAngle > 160) {
          if (_isTempoValid()) {
            fb = "Tam ayaktasın! 💪 Şimdi Otur";
            ok = true;
            _repState = RepState.end;
            _stateEnteredAt = DateTime.now();
          } else {
            fb = "Harika, bekle...";
            ok = true;
          }
        } else {
          fb = "Kalkmaya devam et...";
          ok = true;
        }
        break;
      case RepState.end:
        if (kneeAngle < 115) {
          if (_isTempoValid()) _onRepCompleted();
          fb = "Oturdun ✓ Harika!";
          ok = true;
        } else {
          fb = "Kontrollü şekilde otur...";
          ok = true;
        }
        break;
    }
    return {
      'accuracy': displayAcc,
      'targetScore': standScore, // hedef = ayağa kalkma
      'feedback': fb,
      'isCorrect': ok,
      'isDown': false,
    };
  }

  // 2. MINI SQUAT (Yarım Çömelme)
  Map<String, dynamic> _analyzeMiniSquat(Pose pose) {
    final hip =
        pose.landmarks[PoseLandmarkType.leftHip] ??
        pose.landmarks[PoseLandmarkType.rightHip];
    final knee =
        pose.landmarks[PoseLandmarkType.leftKnee] ??
        pose.landmarks[PoseLandmarkType.rightKnee];
    final ankle =
        pose.landmarks[PoseLandmarkType.leftAnkle] ??
        pose.landmarks[PoseLandmarkType.rightAnkle];

    if (!_checkLikelihood([hip, knee, ankle])) return _notDetected();

    final kneeAngle = _angle(hip!.x, hip.y, knee!.x, knee.y, ankle!.x, ankle.y);

    // Yarım squat → kullanıcı tercihi: bar sadece EĞİLİNCE %100 olsun.
    // İdeal aralık state eşiğini (≤135) kapsar + biraz aşar → eşiği geçer
    // geçmez bar 100 oluyor, smoothing yetişiyor.
    double squatScore =
        _scoreNear(kneeAngle, idealMin: 95, idealMax: 140, falloff: 30);
    // Form hatası: 90°'nin altı = çok derin → puanı sınırla
    if (kneeAngle < 90) {
      squatScore = squatScore.clamp(0.0, 35.0);
    }
    final displayAcc = squatScore;

    String fb;
    bool ok = false;

    switch (_repState) {
      case RepState.start:
        if (kneeAngle > 165) {
          fb = "Dik duruyorsun ✓ Çömel!";
          ok = true;
          _repState = RepState.mid;
          _stateEnteredAt = DateTime.now();
        } else {
          fb = "Tamamen dik dur";
        }
        break;
      case RepState.mid:
        if (kneeAngle < 90) {
          fb = "Çok fazla çöktün, yarım squat yap!";
          ok = false;
        } else if (kneeAngle <= 135) {
          if (_isTempoValid()) {
            fb = "Mükemmel! ✓ Şimdi kalk";
            ok = true;
            _repState = RepState.end;
            _stateEnteredAt = DateTime.now();
          } else {
            fb = "Harika, bekle...";
            ok = true;
          }
        } else {
          fb = "Kalçanı geriye doğru indir...";
          ok = true;
        }
        break;
      case RepState.end:
        if (kneeAngle > 165) {
          if (_isTempoValid()) _onRepCompleted();
          fb = "Kalktın ✓ Tekrar et";
          ok = true;
        } else {
          fb = "Tamamen doğrul...";
          ok = true;
        }
        break;
    }
    return {
      'accuracy': displayAcc,
      'targetScore': squatScore, // hedef = yarım squat pozisyonu
      'feedback': fb,
      'isCorrect': ok,
      'isDown': false,
    };
  }

  // 3. SHOULDER ABDUCTION (Yana Kol Açma)
  Map<String, dynamic> _analyzeShoulderAbduction(Pose pose) {
    final hip = pose.landmarks[PoseLandmarkType.leftHip];
    final shoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final elbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final wrist = pose.landmarks[PoseLandmarkType.leftWrist];

    if (shoulder == null ||
        elbow == null ||
        wrist == null ||
        shoulder.likelihood < 0.5 ||
        elbow.likelihood < 0.5 ||
        wrist.likelihood < 0.5) {
      return _notDetected();
    }

    final double hipX = hip?.x ?? shoulder.x;
    final double hipY = hip?.y ?? (shoulder.y + 100);

    final abAngle = _angle(
      hipX,
      hipY,
      shoulder.x,
      shoulder.y,
      elbow.x,
      elbow.y,
    );
    final elbowStraightAngle = _angle(
      shoulder.x,
      shoulder.y,
      elbow.x,
      elbow.y,
      wrist.x,
      wrist.y,
    );

    // Form puanı: dirsek bükük → tüm puanı sınırlar (alttan).
    final elbowFormScore = _scoreNear(
      elbowStraightAngle,
      idealMin: 160,
      idealMax: 180,
      falloff: 60,
    );
    if (elbowStraightAngle < 145) {
      return {
        'accuracy': elbowFormScore.clamp(0.0, 40.0),
        'targetScore': elbowFormScore.clamp(0.0, 40.0),
        'feedback': "Dirseğini bükme, kolunu düz tut!",
        'isCorrect': false,
        'isDown': false,
      };
    }

    // Yana kol açma → kullanıcı tercihi: bar sadece KOL OMUZ HİZASINDAYKEN
    // %100 olsun. İdeal aralık state eşiğini (≥75) kapsayacak şekilde 75-125
    // → kullanıcı eşiği geçer geçmez bar 100 oluyor.
    double upScore =
        _scoreNear(abAngle, idealMin: 75, idealMax: 125, falloff: 25);
    // Form: çok kaldırdı → upScore'u sınırla
    if (abAngle > 130) {
      upScore = upScore.clamp(0.0, 55.0);
    }
    // Display ve target: form (dirsek) ile sınırlı
    final displayAcc = min(upScore, elbowFormScore);
    final targetWithForm = displayAcc;

    String fb;
    bool ok = false;

    switch (_repState) {
      case RepState.start:
        if (abAngle < 35) {
          fb = "Hazır ✓ Kolu yana kaldır!";
          ok = true;
          _repState = RepState.mid;
          _stateEnteredAt = DateTime.now();
        } else {
          fb = "Kolu tamamen indir";
        }
        break;
      case RepState.mid:
        if (abAngle > 125) {
          fb = "Çok kaldırdın, omuz hizasında tut";
          ok = false;
        } else if (abAngle >= 75) {
          if (_isTempoValid()) {
            fb = "Harika! ✓ Şimdi indir";
            ok = true;
            _repState = RepState.end;
            _stateEnteredAt = DateTime.now();
          } else {
            fb = "Mükemmel, bekle...";
            ok = true;
          }
        } else {
          fb = "Kaldırmaya devam et...";
          ok = true;
        }
        break;
      case RepState.end:
        if (abAngle < 35) {
          if (_isTempoValid()) _onRepCompleted();
          fb = "İndirdin ✓ Tekrarla";
          ok = true;
        } else {
          fb = "Kontrollü şekilde indir...";
          ok = true;
        }
        break;
    }
    return {
      'accuracy': displayAcc,
      'targetScore': targetWithForm,
      'feedback': fb,
      'isCorrect': ok,
      'isDown': false,
    };
  }

  // 4. SINGLE LEG STAND (Tek Ayak Denge)
  Map<String, dynamic> _analyzeSingleLegStand(Pose pose) {
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
    final rightKnee = pose.landmarks[PoseLandmarkType.rightKnee];

    if (!_checkLikelihood([leftAnkle, rightAnkle, leftKnee, rightKnee]))
      return _notDetected();

    final leftY = leftAnkle!.y;
    final rightY = rightAnkle!.y;
    final standingAnkleY = max(leftY, rightY);
    final liftedAnkleY = min(leftY, rightY);
    final yDifference = standingAnkleY - liftedAnkleY;

    final standingKneeY = (standingAnkleY == leftY)
        ? leftKnee!.y
        : rightKnee!.y;
    final shinLength = (standingAnkleY - standingKneeY).abs();
    final threshold = shinLength * 0.20;
    final isOneLegLifted = yDifference > threshold;

    double acc;
    String fb;
    bool ok = false;

    if (isOneLegLifted) {
      ok = true;
      fb = "Dengedesin! Pozisyonu koru...";

      // Bacak ne kadar yukarı kalkmış? Eşik = %20 → 100 puan, %50+ = mükemmel.
      // Smooth puan: kaldırma oranı arttıkça (eşiğin üstünde) puan artar.
      final liftRatio = shinLength > 0 ? (yDifference / shinLength) : 0.0;
      acc = (60.0 + (liftRatio - 0.20) * 200.0).clamp(60.0, 100.0);

      if (_lastTickAt == null) {
        _lastTickAt = DateTime.now();
      } else if (DateTime.now().difference(_lastTickAt!).inSeconds >= 1) {
        // Saniye geçti = 1 "tekrar". O an smoothed accuracy'i puan olarak ekle.
        _allRepsAccuracies.add(_smoothedAccuracy);
        setState(() {
          _currentReps++;
          _actualReps[_currentExerciseIndex] = _currentReps;
        });
        _lastTickAt = DateTime.now();

        if (_currentReps >= 30) {
          _lastTickAt = null;
          if (mounted) {
            _showNextExerciseConfirmation(completed: true);
          }
        }
      }
    } else {
      // Denge yok. yDifference / threshold oranıyla yumuşak skor — sıfıra yakın
      // değil de kullanıcıya "ne kadar yakınsın" gösterir.
      final progress = threshold > 0
          ? (yDifference / threshold).clamp(0.0, 1.0)
          : 0.0;
      acc = 20.0 + progress * 30.0; // 20 (hiç kalkmamış) → 50 (eşikte)
      fb = "Bir ayağını havaya kaldır ve bekle";
      _lastTickAt = null;
    }

    return {
      'accuracy': acc,
      'targetScore': acc,
      'feedback': fb,
      'isCorrect': ok,
      'isDown': false,
    };
  }

  // 5. HIGH KNEES (Ayakta Diz Çekme)
  Map<String, dynamic> _analyzeHighKnees(Pose pose) {
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
    final rightKnee = pose.landmarks[PoseLandmarkType.rightKnee];

    if (!_checkLikelihood([
      leftShoulder,
      rightShoulder,
      leftHip,
      rightHip,
      leftKnee,
      rightKnee,
    ]))
      return _notDetected();

    final leftHipAngle = _angle(
      leftShoulder!.x,
      leftShoulder.y,
      leftHip!.x,
      leftHip.y,
      leftKnee!.x,
      leftKnee.y,
    );
    final rightHipAngle = _angle(
      rightShoulder!.x,
      rightShoulder.y,
      rightHip!.x,
      rightHip.y,
      rightKnee!.x,
      rightKnee.y,
    );
    final activeHipAngle = min(leftHipAngle, rightHipAngle);

    // Diz çekme → kullanıcı tercihi: bar sadece DİZ YUKARIDAYKEN %100 olsun.
    // İdeal aralık state eşiğini (≤120) kapsayacak şekilde 60-125 → kullanıcı
    // eşiği geçer geçmez bar 100 oluyor.
    final kneeUpScore = _scoreNear(
      activeHipAngle,
      idealMin: 60,
      idealMax: 125,
      falloff: 30,
    );
    final displayAcc = kneeUpScore;

    String fb;
    bool ok = false;

    switch (_repState) {
      case RepState.start:
        if (activeHipAngle > 165) {
          fb = "Hazır ✓ Dizini çek!";
          ok = true;
          _repState = RepState.mid;
          _stateEnteredAt = DateTime.now();
        } else {
          fb = "Ayakta düz dur";
        }
        break;
      case RepState.mid:
        if (activeHipAngle <= 120) {
          if (_isTempoValid()) {
            fb = "Mükemmel! ✓ İndir";
            ok = true;
            _repState = RepState.end;
            _stateEnteredAt = DateTime.now();
          } else {
            fb = "Harika, bekle...";
            ok = true;
          }
        } else {
          fb = "Dizini karna doğru çek...";
          ok = true;
        }
        break;
      case RepState.end:
        if (activeHipAngle > 165) {
          if (_isTempoValid()) _onRepCompleted();
          fb = "İndirdin ✓ Devam et";
          ok = true;
        } else {
          fb = "Bacağını tamamen indir...";
          ok = true;
        }
        break;
    }
    return {
      'accuracy': displayAcc,
      'targetScore': kneeUpScore,
      'feedback': fb,
      'isCorrect': ok,
      'isDown': false,
    };
  }

  // 6. SIDE BEND (Ayakta Yana Eğilme)
  Map<String, dynamic> _analyzeSideBend(Pose pose) {
    final ls = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rs = pose.landmarks[PoseLandmarkType.rightShoulder];
    final lh = pose.landmarks[PoseLandmarkType.leftHip];
    final rh = pose.landmarks[PoseLandmarkType.rightHip];
    final la = pose.landmarks[PoseLandmarkType.leftAnkle];
    final ra = pose.landmarks[PoseLandmarkType.rightAnkle];

    if (!_checkLikelihood([ls, rs, lh, rh, la, ra])) return _notDetected();

    final midShoulderX = (ls!.x + rs!.x) / 2;
    final midShoulderY = (ls.y + rs.y) / 2;
    final midHipX = (lh!.x + rh!.x) / 2;
    final midHipY = (lh.y + rh.y) / 2;
    final midAnkleX = (la!.x + ra!.x) / 2;
    final midAnkleY = (la.y + ra.y) / 2;

    final bodyAngle = _angle(
      midShoulderX,
      midShoulderY,
      midHipX,
      midHipY,
      midAnkleX,
      midAnkleY,
    );

    // Yana eğilme → kullanıcı tercihi: bar sadece YANA EĞİKKEN %100 olsun.
    // Dik dururken bar düşük olacak ki eğilince yükseliş görünsün.
    final bentScore =
        _scoreNear(bodyAngle, idealMin: 140, idealMax: 162, falloff: 20);
    final displayAcc = bentScore;

    String fb;
    bool ok = false;

    switch (_repState) {
      case RepState.start:
        if (bodyAngle > 170) {
          fb = "Dik duruyorsun ✓ Yana eğil!";
          ok = true;
          _repState = RepState.mid;
          _stateEnteredAt = DateTime.now();
        } else {
          fb = "Tam dik dur";
        }
        break;
      case RepState.mid:
        if (bodyAngle <= 160) {
          if (_isTempoValid()) {
            fb = "Çok iyi esniyorsun! ✓ Düzel";
            ok = true;
            _repState = RepState.end;
            _stateEnteredAt = DateTime.now();
          } else {
            fb = "Harika, tut...";
            ok = true;
          }
        } else {
          fb = "Yana doğru eğil...";
          ok = true;
        }
        break;
      case RepState.end:
        if (bodyAngle > 170) {
          if (_isTempoValid()) _onRepCompleted();
          fb = "Düzeldin ✓ Tekrarla";
          ok = true;
        } else {
          fb = "Tamamen dikleş...";
          ok = true;
        }
        break;
    }
    return {
      'accuracy': displayAcc,
      'targetScore': bentScore,
      'feedback': fb,
      'isCorrect': ok,
      'isDown': false,
    };
  }

  Map<String, dynamic> _analyzeGeneral(Pose pose) {
    return {
      'accuracy': 80.0,
      'feedback': "Devam et! 👍",
      'isCorrect': true,
      'isDown': false,
    };
  }

  bool _checkLikelihood(List<PoseLandmark?> landmarks) =>
      landmarks.every((l) => l != null && l.likelihood >= 0.5);

  Map<String, dynamic> _notDetected() => {
    'accuracy': 0.0,
    'feedback': "Kameraya tam görün...",
    'isCorrect': false,
    'isDown': false,
  };

  double _angle(
    double ax,
    double ay,
    double bx,
    double by,
    double cx,
    double cy,
  ) {
    final r = atan2(cy - by, cx - bx) - atan2(ay - by, ax - bx);
    double a = r * (180 / pi);
    if (a < 0) a += 360;
    if (a > 180) a = 360 - a;
    return a;
  }

  InputImage? _convertToInputImage(CameraImage image) {
    if (_cameraController == null) return null;
    final rotation = InputImageRotationValue.fromRawValue(
      _cameraController!.description.sensorOrientation,
    );
    if (rotation == null) return null;
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null ||
        (format != InputImageFormat.nv21 &&
            format != InputImageFormat.yuv_420_888))
      return null;
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

  void _showNextExerciseConfirmation({bool completed = false}) {
    if (_showingConfirmation) return;
    _testTimer?.cancel();
    setState(() => _showingConfirmation = true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          completed ? "Egzersizi Tamamladın! 🎉" : "Egzersizi Bitir?",
          style: const TextStyle(fontWeight: FontWeight.bold, color: _textDark),
        ),
        content: Text(
          completed
              ? "${_currentExercise.name} — $_currentReps ${_currentExercise.isTimeBased ? "saniye" : "tekrar"} ✓"
              : "${_currentExercise.name} — $_currentReps / ${_currentExercise.isTimeBased ? 30 : _targetReps} ${_currentExercise.isTimeBased ? "saniye" : "tekrar"}",
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          if (!completed)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _showingConfirmation = false;
                  _testMode = false;
                });
              },
              child: const Text(
                "Devam Et",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _showingConfirmation = false;
                _testMode = false;
                _testStep = 0;
              });
              _finishWorkout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Bitir", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _finishWorkout() {
    // Tüm tamamlanmış tekrarların peak puanlarının ortalaması.
    // (Tekrar tamamlanmadıysa hiç sayılmadığı için tüm puanlar
    // gerçek bir tekrarı temsil eder.)
    int finalOverallAccuracy = 0;
    if (_allRepsAccuracies.isNotEmpty) {
      final sum = _allRepsAccuracies.reduce((a, b) => a + b);
      finalOverallAccuracy = (sum / _allRepsAccuracies.length).round();
    } else {
      finalOverallAccuracy = _accuracyRate.round();
    }
    finalOverallAccuracy = finalOverallAccuracy.clamp(0, 100);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => WorkoutSummaryScreen(
          exercises: widget.exercises,
          actualReps: _actualReps,
          cameraEnabled: widget.cameraEnabled,
          accuracyRate: finalOverallAccuracy, // Ortalamayı gönderiyoruz
        ),
      ),
    );
  }

  void _toggleTestMode() {
    if (_testMode) {
      _testTimer?.cancel();
      setState(() {
        _testMode = false;
        _testStep = 0;
        _repState = RepState.start;
        _stateEnteredAt = null;
        _accuracyRate = 0.0;
        _smoothedAccuracy = 0.0;
        _smoothedTargetScore = 0.0;
        _feedback = "Hazırlanıyor...";
        _isInCorrectPosition = false;
        _allRepsAccuracies.clear();
        _currentRepPeak = 0.0;
      });
    } else {
      setState(() {
        _testMode = true;
        _testStep = 0;
      });
      _runTestSimulation();
    }
  }

  void _runTestSimulation() {
    final steps = [
      {
        'accuracy': 100.0,
        'feedback': 'Başlangıç pozisyonu ✓',
        'isCorrect': true,
      },
      {'accuracy': 85.0, 'feedback': 'Hareket ediliyor...', 'isCorrect': true},
      {'accuracy': 100.0, 'feedback': 'Hedef pozisyon! ✓', 'isCorrect': true},
      {'accuracy': 100.0, 'feedback': 'Tut...', 'isCorrect': true},
      {'accuracy': 85.0, 'feedback': 'Geri dön...', 'isCorrect': true},
      {'accuracy': 20.0, 'feedback': 'Hazırlan...', 'isCorrect': false},
    ];
    int simState = 0;
    _testTimer = Timer.periodic(const Duration(milliseconds: 700), (timer) {
      if (!mounted || !_testMode) {
        timer.cancel();
        return;
      }
      final step = steps[_testStep % steps.length];
      final idx = _testStep % steps.length;
      if (idx == 0 && simState == 0) {
        _repState = RepState.start;
        _stateEnteredAt = DateTime.now().subtract(const Duration(seconds: 1));
        simState = 1;
      } else if (idx == 2 && simState == 1) {
        _repState = RepState.mid;
        _stateEnteredAt = DateTime.now().subtract(const Duration(seconds: 1));
        simState = 2;
      } else if (idx == 4 && simState == 2) {
        _repState = RepState.end;
        _stateEnteredAt = DateTime.now().subtract(const Duration(seconds: 1));
        _onRepCompleted();
        simState = 0;
      }
      final stepAcc = step['accuracy'] as double;
      // Test modunda da gerçekçi davranmak için peak'i güncelle.
      if (_repState == RepState.mid && stepAcc > _currentRepPeak) {
        _currentRepPeak = stepAcc;
      }
      _smoothedAccuracy = stepAcc;
      _smoothedTargetScore = stepAcc;
      setState(() {
        _accuracyRate = stepAcc;
        _feedback = step['feedback'] as String;
        _isInCorrectPosition = step['isCorrect'] as bool;
        _testStep++;
      });
    });
  }

  Color _stateColor() {
    switch (_repState) {
      case RepState.start:
        return Colors.blue;
      case RepState.mid:
        return Colors.orange;
      case RepState.end:
        return _primaryGreen;
    }
  }

  String _stateLabel() {
    switch (_repState) {
      case RepState.start:
        return "BAŞLA";
      case RepState.mid:
        return "HEDEF";
      case RepState.end:
        return "GERİ";
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
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: _primaryGreen),
                  SizedBox(height: 16),
                  Text(
                    "Kamera başlatılıyor...",
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            )
          : Stack(
              fit: StackFit.expand,
              children: [
                if (widget.cameraEnabled && _cameraController != null)
                  CameraPreview(_cameraController!)
                else
                  Container(color: const Color(0xFF1A1A2E)),

                if (_currentPose != null && widget.cameraEnabled)
                  CustomPaint(
                    painter: PoseOverlayPainter(
                      pose: _currentPose!,
                      imageSize: Size(
                        _cameraController!.value.previewSize!.height,
                        _cameraController!.value.previewSize!.width,
                      ),
                      screenSize: MediaQuery.of(context).size,
                    ),
                  ),

                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black45,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _currentExercise.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  _currentExercise.detail,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 11,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: _stateColor().withOpacity(0.85),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _stateLabel(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _primaryGreen.withOpacity(0.85),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _currentExercise.isTimeBased
                                  ? "$_currentReps / 30 sn"
                                  : (_targetReps > 0
                                        ? "$_currentReps / $_targetReps"
                                        : "$_currentReps tekrar"),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _toggleTestMode,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _testMode
                                    ? Colors.orange.withOpacity(0.9)
                                    : Colors.white24,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _testMode
                                      ? Colors.orange
                                      : Colors.white38,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _testMode
                                        ? Icons.stop_rounded
                                        : Icons.science_rounded,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _testMode ? "DUR" : "TEST",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              _currentExercise.imageUrl,
                              height: 80,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const SizedBox.shrink(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _feedback,
                            style: TextStyle(
                              color: _isInCorrectPosition
                                  ? const Color(0xFF81C784)
                                  : Colors.orange,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              const Text(
                                "Doğruluk",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                "%${_accuracyRate.toInt()}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: _accuracyRate / 100,
                              minHeight: 10,
                              backgroundColor: Colors.white24,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _accuracyRate >= 80
                                    ? const Color(0xFF81C784)
                                    : _accuracyRate >= 50
                                    ? Colors.orange
                                    : Colors.redAccent,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () => _showNextExerciseConfirmation(
                                completed: false,
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.white38),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                              child: const Text(
                                "Egzersizi Bitir",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class PoseOverlayPainter extends CustomPainter {
  final Pose pose;
  final Size imageSize;
  final Size screenSize;
  PoseOverlayPainter({
    required this.pose,
    required this.imageSize,
    required this.screenSize,
  });

  static const List<List<PoseLandmarkType>> connections = [
    [PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder],
    [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip],
    [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip],
    [PoseLandmarkType.leftHip, PoseLandmarkType.rightHip],
    [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow],
    [PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist],
    [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow],
    [PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist],
    [PoseLandmarkType.leftWrist, PoseLandmarkType.leftThumb],
    [PoseLandmarkType.leftWrist, PoseLandmarkType.leftIndex],
    [PoseLandmarkType.leftWrist, PoseLandmarkType.leftPinky],
    [PoseLandmarkType.rightWrist, PoseLandmarkType.rightThumb],
    [PoseLandmarkType.rightWrist, PoseLandmarkType.rightIndex],
    [PoseLandmarkType.rightWrist, PoseLandmarkType.rightPinky],
    [PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee],
    [PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle],
    [PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee],
    [PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle],
    [PoseLandmarkType.leftAnkle, PoseLandmarkType.leftHeel],
    [PoseLandmarkType.leftHeel, PoseLandmarkType.leftFootIndex],
    [PoseLandmarkType.leftAnkle, PoseLandmarkType.leftFootIndex],
    [PoseLandmarkType.rightAnkle, PoseLandmarkType.rightHeel],
    [PoseLandmarkType.rightHeel, PoseLandmarkType.rightFootIndex],
    [PoseLandmarkType.rightAnkle, PoseLandmarkType.rightFootIndex],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final pp = Paint()
      ..color = _primaryGreen
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    final lp = Paint()
      ..color = _primaryGreen.withOpacity(0.7)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (final c in connections) {
      final s = pose.landmarks[c[0]];
      final e = pose.landmarks[c[1]];
      if (s != null && e != null)
        canvas.drawLine(
          _translatePoint(s.x, s.y, size),
          _translatePoint(e.x, e.y, size),
          lp,
        );
    }
    for (final lm in pose.landmarks.values)
      canvas.drawCircle(_translatePoint(lm.x, lm.y, size), 5, pp);
  }

  Offset _translatePoint(double x, double y, Size size) {
    final scaleX = size.width / imageSize.width;
    final scaleY = size.height / imageSize.height;
    return Offset(size.width - (x * scaleX), y * scaleY);
  }

  @override
  bool shouldRepaint(PoseOverlayPainter oldDelegate) => true;
}

class LandmarkSmoother {
  final int windowSize;
  final Map<PoseLandmarkType, List<Offset>> _history = {};
  LandmarkSmoother({required this.windowSize});

  Pose smooth(Pose pose) {
    final smoothed = <PoseLandmarkType, PoseLandmark>{};
    for (final entry in pose.landmarks.entries) {
      final type = entry.key;
      final lm = entry.value;
      _history.putIfAbsent(type, () => []);
      _history[type]!.add(Offset(lm.x, lm.y));
      if (_history[type]!.length > windowSize) _history[type]!.removeAt(0);
      final h = _history[type]!;
      final avgX = h.map((o) => o.dx).reduce((a, b) => a + b) / h.length;
      final avgY = h.map((o) => o.dy).reduce((a, b) => a + b) / h.length;
      smoothed[type] = PoseLandmark(
        type: type,
        x: avgX,
        y: avgY,
        z: lm.z,
        likelihood: lm.likelihood,
      );
    }
    return Pose(landmarks: smoothed);
  }
}

class WorkoutSummaryScreen extends StatelessWidget {
  final List<Exercise> exercises;
  final List<int> actualReps;
  final bool cameraEnabled;
  final int accuracyRate;

  const WorkoutSummaryScreen({
    super.key,
    required this.exercises,
    required this.actualReps,
    required this.cameraEnabled,
    required this.accuracyRate,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundBeige,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          "Egzersiz Özeti",
          style: TextStyle(color: _textDark, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _primaryGreen,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 60,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Tebrikler!",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    cameraEnabled
                        ? "Doğruluk Oranı: %$accuracyRate"
                        : "Doğruluk Oranı: %0 (Kamera kapalı)",
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Hareket Detayları",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: _textDark,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: exercises.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final ex = exercises[i];
                  final done = actualReps[i];
                  final target = ex.targetReps;
                  final isComplete =
                      ex.isTimeBased || (target > 0 && done >= target);
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isComplete
                            ? _primaryGreen.withOpacity(0.3)
                            : Colors.orange.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isComplete
                                ? _primaryGreen.withOpacity(0.1)
                                : Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            ex.icon,
                            color: isComplete ? _primaryGreen : Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ex.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: _textDark,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                ex.isTimeBased
                                    ? ex.detail
                                    : target > 0
                                    ? "$done / $target tekrar"
                                    : "$done tekrar",
                                style: TextStyle(
                                  color: isComplete
                                      ? _primaryGreen
                                      : Colors.orange,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          isComplete
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked,
                          color: isComplete ? _primaryGreen : Colors.orange,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () async {
                  final totalReps = actualReps.fold(0, (sum, r) => sum + r);
                  await WorkoutHistoryService.saveWorkout(
                    WorkoutHistory(
                      programName: exercises.isNotEmpty
                          ? exercises.first.name
                          : 'Egzersiz',
                      date: DateTime.now(),
                      accuracyRate: cameraEnabled ? accuracyRate : 0,
                      cameraEnabled: cameraEnabled,
                      totalReps: totalReps,
                    ),
                  );
                  if (context.mounted)
                    Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  "Ana Sayfaya Dön",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
