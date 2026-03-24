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

  int _currentExerciseIndex = 0;
  final List<int> _actualReps = [];
  int _currentReps = 0;

  Pose? _currentPose;
  double _accuracyRate = 0.0;
  double _smoothedAccuracy = 0.0;
  String _feedback = "Hazırlanıyor...";
  bool _isInCorrectPosition = false;
  bool _wasDown = false;
  bool _achievedProperForm = false;

  final _smoother = LandmarkSmoother(windowSize: 5);

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
  bool get _isLastExercise =>
      _currentExerciseIndex == widget.exercises.length - 1;

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
        final pose = poses.first;
        final smoothedPose = _smoother.smooth(pose);
        final result = _analyzeExercise(smoothedPose, _currentExercise.name);

        // 1. ÇÖZÜM: Yüzde 100 olmama sorununu ufak bir hileyle çözüyoruz
        _smoothedAccuracy =
            _smoothedAccuracy * 0.7 + (result['accuracy'] as double) * 0.3;
        if (_smoothedAccuracy > 97.5) {
          _smoothedAccuracy = 100.0; // 98'i geçerse direkt 100'e yuvarla
        }

        final isDown = result['isDown'] as bool;
        final isCorrect = result['isCorrect'] as bool;

        // 2. ÇÖZÜM: ASIL SAYIM MANTIĞI
        // Kullanıcı aşağıdayken doğru pozisyonu yakaladıysa mühürle
        if (isDown && isCorrect) {
          _achievedProperForm = true;
        }

        // Önceki karede aşağıdaydı, şimdi yukarı kalktıysa (Tekrar bittiyse)
        if (_wasDown && !isDown) {
          if (_achievedProperForm) {
            // Eğer aşağıdayken hareketi düzgün yaptıysa say
            _onRepCompleted();
          }
          _achievedProperForm = false; // Yeni tekrar için hafızayı sıfırla
        }

        setState(() {
          _currentPose = smoothedPose;
          _accuracyRate = _smoothedAccuracy;
          _feedback = result['feedback'] as String;
          _isInCorrectPosition = isCorrect;
          _wasDown = isDown;
        });
      }
    } catch (e) {
      debugPrint('Pose detection hatası: $e');
    }

    _isDetecting = false;
  }

  void _onRepCompleted() {
    final newReps = _currentReps + 1;
    setState(() {
      _currentReps = newReps;
      _actualReps[_currentExerciseIndex] = newReps;
    });

    if (_targetReps > 0 && newReps >= _targetReps) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _showNextExerciseConfirmation(completed: true);
      });
    }
  }

  void _showNextExerciseConfirmation({bool completed = false}) {
    if (_showingConfirmation) return;
    _testTimer?.cancel(); // Test modunu durdur
    setState(() => _showingConfirmation = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          completed ? "Hareketi Tamamladın! 🎉" : "Hareketi Geç?",
          style: const TextStyle(fontWeight: FontWeight.bold, color: _textDark),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              completed
                  ? "${_currentExercise.name} hareketini $_currentReps tekrar tamamladın."
                  : "${_currentExercise.name} hareketini $_currentReps tekrar yaptın.\nHedef: $_targetReps tekrar.",
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            if (!_isLastExercise)
              Text(
                "Sıradaki: ${widget.exercises[_currentExerciseIndex + 1].name}",
                style: const TextStyle(
                  color: _primaryGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        actions: [
          if (!completed)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _showingConfirmation = false;
                  _testMode = false; // Test modunu sıfırla
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
              _goToNextExercise();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              _isLastExercise ? "Egzersizi Bitir" : "Sonraki Hareket →",
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _goToNextExercise() {
    if (_isLastExercise) {
      _finishWorkout();
      return;
    }

    setState(() {
      _currentExerciseIndex++;
      _currentReps = 0;
      _accuracyRate = 0.0;
      _smoothedAccuracy = 0.0;
      _feedback = "Hazırlanıyor...";
      _wasDown = false;
      _achievedProperForm = false; // YENİ EKLENDİ
      _smoother.reset();
    });
  }

  void _finishWorkout() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => WorkoutSummaryScreen(
          exercises: widget.exercises,
          actualReps: _actualReps,
          cameraEnabled: widget.cameraEnabled,
          accuracyRate: _accuracyRate.toInt(),
        ),
      ),
    );
  }

  InputImage? _convertToInputImage(CameraImage image) {
    if (_cameraController == null) return null;
    final camera = _cameraController!.description;
    final rotation = InputImageRotationValue.fromRawValue(
      camera.sensorOrientation,
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

  Map<String, dynamic> _analyzeExercise(Pose pose, String exerciseName) {
    if (exerciseName.toLowerCase().contains('squat') ||
        exerciseName.toLowerCase().contains('çömelme'))
      return _analyzeSquat(pose);
    if (exerciseName.toLowerCase().contains('plank'))
      return _analyzePlank(pose);
    if (exerciseName.toLowerCase().contains('diz') ||
        exerciseName.toLowerCase().contains('fleksiy'))
      return _analyzeKneeBend(pose);
    if (exerciseName.toLowerCase().contains('köprü'))
      return _analyzeBridge(pose);
    return _analyzeGeneral(pose);
  }

  Map<String, dynamic> _analyzeSquat(Pose pose) {
    final hip = pose.landmarks[PoseLandmarkType.leftHip];
    final knee = pose.landmarks[PoseLandmarkType.leftKnee];
    final ankle = pose.landmarks[PoseLandmarkType.leftAnkle];
    if (hip == null || knee == null || ankle == null) return _notDetected();
    if (hip.likelihood < 0.5 || knee.likelihood < 0.5 || ankle.likelihood < 0.5)
      return _notDetected();
    final kneeAngle = _calculateAngle(
      hip.x,
      hip.y,
      knee.x,
      knee.y,
      ankle.x,
      ankle.y,
    );
    final isDown = kneeAngle < 120;
    double accuracy;
    String feedback;
    bool isCorrect = false;
    if (kneeAngle >= 80 && kneeAngle <= 110) {
      accuracy = 100;
      feedback = "Mükemmel squat! 💪";
      isCorrect = true;
    } else if (kneeAngle >= 60 && kneeAngle < 80) {
      accuracy = 70;
      feedback = "Çok derin, biraz kalk";
    } else if (kneeAngle > 110 && kneeAngle <= 140) {
      accuracy = 60;
      feedback = "Biraz daha çömel";
    } else if (kneeAngle > 140) {
      accuracy = 30;
      feedback = "Çömelmeye başla";
    } else {
      accuracy = 50;
      feedback = "Pozisyonu düzelt";
    }
    return {
      'accuracy': accuracy,
      'feedback': feedback,
      'isCorrect': isCorrect,
      'isDown': isDown,
    };
  }

  Map<String, dynamic> _analyzePlank(Pose pose) {
    final shoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final hip = pose.landmarks[PoseLandmarkType.leftHip];
    final ankle = pose.landmarks[PoseLandmarkType.leftAnkle];
    if (shoulder == null || hip == null || ankle == null) return _notDetected();
    if (shoulder.likelihood < 0.5 ||
        hip.likelihood < 0.5 ||
        ankle.likelihood < 0.5)
      return _notDetected();
    final bodyAngle = _calculateAngle(
      shoulder.x,
      shoulder.y,
      hip.x,
      hip.y,
      ankle.x,
      ankle.y,
    );
    double accuracy;
    String feedback;
    bool isCorrect = false;
    if (bodyAngle >= 160 && bodyAngle <= 180) {
      accuracy = 100;
      feedback = "Mükemmel plank! 🔥";
      isCorrect = true;
    } else if (bodyAngle >= 140 && bodyAngle < 160) {
      accuracy = 70;
      feedback = "Kalçanı biraz indir";
    } else if (bodyAngle < 140) {
      accuracy = 40;
      feedback = "Vücudunu düz tut";
    } else {
      accuracy = 50;
      feedback = "Pozisyonu ayarla";
    }
    return {
      'accuracy': accuracy,
      'feedback': feedback,
      'isCorrect': isCorrect,
      'isDown': false,
    };
  }

  Map<String, dynamic> _analyzeKneeBend(Pose pose) {
    final hip = pose.landmarks[PoseLandmarkType.leftHip];
    final knee = pose.landmarks[PoseLandmarkType.leftKnee];
    final ankle = pose.landmarks[PoseLandmarkType.leftAnkle];
    if (hip == null || knee == null || ankle == null) return _notDetected();
    if (hip.likelihood < 0.5 || knee.likelihood < 0.5 || ankle.likelihood < 0.5)
      return _notDetected();
    final kneeAngle = _calculateAngle(
      hip.x,
      hip.y,
      knee.x,
      knee.y,
      ankle.x,
      ankle.y,
    );
    final isDown = kneeAngle < 130;
    double accuracy;
    String feedback;
    bool isCorrect = false;
    if (kneeAngle >= 90 && kneeAngle <= 120) {
      accuracy = 100;
      feedback = "Harika! Doğru açı ✓";
      isCorrect = true;
    } else if (kneeAngle > 120 && kneeAngle <= 150) {
      accuracy = 60;
      feedback = "Biraz daha bük";
    } else if (kneeAngle > 150) {
      accuracy = 30;
      feedback = "Dizini bükmeden başla";
    } else {
      accuracy = 50;
      feedback = "Fazla büküyor, geri gel";
    }
    return {
      'accuracy': accuracy,
      'feedback': feedback,
      'isCorrect': isCorrect,
      'isDown': isDown,
    };
  }

  Map<String, dynamic> _analyzeBridge(Pose pose) {
    final shoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final hip = pose.landmarks[PoseLandmarkType.leftHip];
    final knee = pose.landmarks[PoseLandmarkType.leftKnee];
    if (shoulder == null || hip == null || knee == null) return _notDetected();
    if (shoulder.likelihood < 0.5 ||
        hip.likelihood < 0.5 ||
        knee.likelihood < 0.5)
      return _notDetected();
    final hipAngle = _calculateAngle(
      shoulder.x,
      shoulder.y,
      hip.x,
      hip.y,
      knee.x,
      knee.y,
    );
    final isDown = hipAngle < 150;
    double accuracy;
    String feedback;
    bool isCorrect = false;
    if (hipAngle >= 150 && hipAngle <= 180) {
      accuracy = 100;
      feedback = "Mükemmel köprü! 💪";
      isCorrect = true;
    } else if (hipAngle >= 120 && hipAngle < 150) {
      accuracy = 65;
      feedback = "Kalçanı daha yukarı kaldır";
    } else {
      accuracy = 30;
      feedback = "Kalçanı kaldır";
    }
    return {
      'accuracy': accuracy,
      'feedback': feedback,
      'isCorrect': isCorrect,
      'isDown': isDown,
    };
  }

  Map<String, dynamic> _analyzeGeneral(Pose pose) {
    final nose = pose.landmarks[PoseLandmarkType.nose];
    if (nose == null) return _notDetected();
    return {
      'accuracy': 80.0,
      'feedback': "Devam et! 👍",
      'isCorrect': true,
      'isDown': false,
    };
  }

  Map<String, dynamic> _notDetected() => {
    'accuracy': 0.0,
    'feedback': "Kameraya tam görün",
    'isCorrect': false,
    'isDown': false,
  };

  double _calculateAngle(
    double ax,
    double ay,
    double bx,
    double by,
    double cx,
    double cy,
  ) {
    final radians = atan2(cy - by, cx - bx) - atan2(ay - by, ax - bx);
    double angle = radians * (180 / pi);
    if (angle < 0) angle += 360;
    if (angle > 180) angle = 360 - angle;
    return angle;
  }

  void _toggleTestMode() {
    if (_testMode) {
      _testTimer?.cancel();
      setState(() {
        _testMode = false;
        _testStep = 0;
        _wasDown = false;
        _accuracyRate = 0.0;
        _feedback = "Hazırlanıyor...";
        _isInCorrectPosition = false;
      });
    } else {
      setState(() {
        _testMode = true;
        _wasDown = false;
        _testStep = 0;
      });
      _runTestSimulation();
    }
  }

  void _runTestSimulation() {
    // Adım dizisi: aşağı git (isDown:true, isCorrect:true) → yukarı gel (isDown:false, isCorrect:true)
    // Yukarı gelince _wasDown=true && isDown=false && isCorrect=true → TEKRAR SAYILIR
    final steps = [
      // Başlangıç pozisyonu
      {
        'accuracy': 20.0,
        'feedback': 'Harekete hazırlan...',
        'isCorrect': false,
        'isDown': false,
      },
      // Aşağı inme
      {
        'accuracy': 60.0,
        'feedback': 'Biraz daha bük',
        'isCorrect': false,
        'isDown': true,
      },
      // Doğru pozisyon (aşağıda)
      {
        'accuracy': 100.0,
        'feedback': 'Mükemmel! 💪',
        'isCorrect': true,
        'isDown': true,
      },
      // Hâlâ aşağıda
      {
        'accuracy': 100.0,
        'feedback': 'Mükemmel! 💪',
        'isCorrect': true,
        'isDown': true,
      },
      // Yukarı çıkma — isCorrect:true, isDown:false → SAYIM TETİKLENİR
      {
        'accuracy': 100.0,
        'feedback': 'Harika! Tekrar say!',
        'isCorrect': true,
        'isDown': false,
      },
      // Dinlenme
      {
        'accuracy': 20.0,
        'feedback': 'Sonraki tekrar...',
        'isCorrect': false,
        'isDown': false,
      },
    ];

    _testTimer = Timer.periodic(const Duration(milliseconds: 600), (timer) {
      if (!mounted || !_testMode) {
        timer.cancel();
        return;
      }

      final step = steps[_testStep % steps.length];
      final isDown = step['isDown'] as bool;
      final isCorrect = step['isCorrect'] as bool;

      // SAYIM: önceki adımda aşağıdaydı + şimdi yukarı çıktı + doğru pozisyondayken
      if (_wasDown && !isDown && isCorrect && !_showingConfirmation) {
        _onRepCompleted();
      }

      setState(() {
        _accuracyRate = step['accuracy'] as double;
        _feedback = step['feedback'] as String;
        _isInCorrectPosition = isCorrect;
        _wasDown = isDown;
        _testStep++;
      });
    });
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
                // Kamera veya siyah arka plan
                if (widget.cameraEnabled && _cameraController != null)
                  Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..scale(-1.0, 1.0),
                    child: CameraPreview(_cameraController!),
                  )
                else
                  Container(color: const Color(0xFF1A1A2E)),

                // Pose overlay
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

                // Üst bar
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
                                  "${_currentExerciseIndex + 1} / ${widget.exercises.length}",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Tekrar sayacı
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
                              _targetReps > 0
                                  ? "$_currentReps / $_targetReps"
                                  : "$_currentReps tekrar",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // TEST MODU
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
                                    _testMode ? "DURDUR" : "TEST",
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

                // İlerleme çubuğu
                Positioned(
                  top: 90,
                  left: 16,
                  right: 16,
                  child: SafeArea(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: widget.exercises.isEmpty
                            ? 0
                            : (_currentExerciseIndex +
                                      (_targetReps > 0
                                          ? _currentReps / _targetReps
                                          : 0)) /
                                  widget.exercises.length,
                        minHeight: 4,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          _primaryGreen,
                        ),
                      ),
                    ),
                  ),
                ),

                // Alt panel
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
                          // Hareket görseli
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
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
                              child: Text(
                                _isLastExercise ? "Bitir" : "Sonraki →",
                                style: const TextStyle(
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

// --- POSE OVERLAY ÇİZİCİ ---
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
    final pointPaint = Paint()
      ..color = _primaryGreen
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    final linePaint = Paint()
      ..color = _primaryGreen.withOpacity(0.7)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    for (final connection in connections) {
      final start = pose.landmarks[connection[0]];
      final end = pose.landmarks[connection[1]];
      if (start != null && end != null) {
        canvas.drawLine(
          _translatePoint(start.x, start.y, size),
          _translatePoint(end.x, end.y, size),
          linePaint,
        );
      }
    }

    for (final landmark in pose.landmarks.values) {
      canvas.drawCircle(
        _translatePoint(landmark.x, landmark.y, size),
        5,
        pointPaint,
      );
    }
  }

  Offset _translatePoint(double x, double y, Size size) {
    final scaleX = size.width / imageSize.width;
    final scaleY = size.height / imageSize.height;
    return Offset(size.width - x * scaleX, y * scaleY);
  }

  @override
  bool shouldRepaint(PoseOverlayPainter oldDelegate) => true;
}

// --- LANDMARK SMOOTHER ---
class LandmarkSmoother {
  final int windowSize;
  final Map<PoseLandmarkType, List<Offset>> _history = {};

  LandmarkSmoother({required this.windowSize});

  Pose smooth(Pose pose) {
    final smoothedLandmarks = <PoseLandmarkType, PoseLandmark>{};
    for (final entry in pose.landmarks.entries) {
      final type = entry.key;
      final landmark = entry.value;
      _history.putIfAbsent(type, () => []);
      _history[type]!.add(Offset(landmark.x, landmark.y));
      if (_history[type]!.length > windowSize) _history[type]!.removeAt(0);
      final history = _history[type]!;
      final avgX =
          history.map((o) => o.dx).reduce((a, b) => a + b) / history.length;
      final avgY =
          history.map((o) => o.dy).reduce((a, b) => a + b) / history.length;
      smoothedLandmarks[type] = PoseLandmark(
        type: type,
        x: avgX,
        y: avgY,
        z: landmark.z,
        likelihood: landmark.likelihood,
      );
    }
    return Pose(landmarks: smoothedLandmarks);
  }

  void reset() => _history.clear();
}

// --- EGZERSİZ ÖZETİ EKRANI ---
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
                itemBuilder: (context, index) {
                  final exercise = exercises[index];
                  final done = actualReps[index];
                  final target = exercise.targetReps;
                  final isTimeBased = exercise.isTimeBased;
                  final isComplete =
                      isTimeBased || (target > 0 && done >= target);

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
                            exercise.icon,
                            color: isComplete ? _primaryGreen : Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                exercise.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: _textDark,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isTimeBased
                                    ? exercise.detail
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
                  // Geçmişe kaydet
                  final totalReps = actualReps.fold(0, (sum, r) => sum + r);
                  await WorkoutHistoryService.saveWorkout(
                    WorkoutHistory(
                      programName: exercises.isNotEmpty
                          ? exercises.first.name.split(' ').skip(1).join(' ')
                          : 'Egzersiz',
                      date: DateTime.now(),
                      accuracyRate: cameraEnabled ? accuracyRate : 0,
                      cameraEnabled: cameraEnabled,
                      totalReps: totalReps,
                    ),
                  );
                  if (context.mounted) {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
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
