import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Color primaryGreen = Color(0xFF4A6849);
const Color backgroundBeige = Color(0xFFFDFCF4);
const Color cardBeige = Color(0xFFF2F0E4);
const Color textDark = Color(0xFF2C3E2C);

// --- EGZERSİZ MODELİ ---
class Exercise {
  final String name;
  final String detail;
  final IconData icon;

  const Exercise({
    required this.name,
    required this.detail,
    required this.icon,
  });
}

// --- EGZERSİZ PROGRAMLARI ---
class WorkoutPrograms {
  // Doktor programları
  static const Map<String, Map<String, dynamic>> doctorPrograms = {
    'DR001': {
      'title': 'Diz Rehabilitasyon Programı',
      'image': 'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?auto=format&fit=crop&w=1000&q=80',
      'duration': '20 Dk',
      'calories': '80 Kal',
      'level': 'Hafif',
      'exercises': [
        Exercise(name: '1. Isınma & Nefes', detail: '3 Dakika', icon: Icons.air),
        Exercise(name: '2. Diz Bükme', detail: '15 Tekrar', icon: Icons.accessibility_new),
        Exercise(name: '3. Bacak Kaldırma', detail: '10 Tekrar', icon: Icons.airline_seat_legroom_extra),
        Exercise(name: '4. Diz Destekli Squat', detail: '8 Tekrar', icon: Icons.fitness_center),
        Exercise(name: '5. Soğuma Esneme', detail: '3 Dakika', icon: Icons.spa),
      ],
    },
    'DR002': {
      'title': 'Sırt Güçlendirme Programı',
      'image': 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?auto=format&fit=crop&w=1000&q=80',
      'duration': '25 Dk',
      'calories': '100 Kal',
      'level': 'Orta',
      'exercises': [
        Exercise(name: '1. Isınma', detail: '3 Dakika', icon: Icons.air),
        Exercise(name: '2. Köprü Hareketi', detail: '12 Tekrar', icon: Icons.landscape),
        Exercise(name: '3. Kuş-Köpek', detail: '10 Tekrar', icon: Icons.pets),
        Exercise(name: '4. Süperman', detail: '10 Tekrar', icon: Icons.flight),
        Exercise(name: '5. Plank', detail: '30 Saniye', icon: Icons.horizontal_rule),
        Exercise(name: '6. Soğuma', detail: '3 Dakika', icon: Icons.spa),
      ],
    },
    'DEMO': {
      'title': 'Demo Rehabilitasyon Programı',
      'image': 'https://images.unsplash.com/photo-1518611012118-696072aa579a?auto=format&fit=crop&w=1000&q=80',
      'duration': '15 Dk',
      'calories': '60 Kal',
      'level': 'Kolay',
      'exercises': [
        Exercise(name: '1. Isınma', detail: '2 Dakika', icon: Icons.air),
        Exercise(name: '2. Boyun Esneme', detail: '5 Tekrar', icon: Icons.accessibility_new),
        Exercise(name: '3. Omuz Döndürme', detail: '10 Tekrar', icon: Icons.rotate_right),
        Exercise(name: '4. Bel Esneme', detail: '8 Tekrar', icon: Icons.airline_seat_legroom_extra),
        Exercise(name: '5. Soğuma', detail: '2 Dakika', icon: Icons.spa),
      ],
    },
  };

  // Spor kategorisi programları
  static const Map<String, Map<String, dynamic>> sportPrograms = {
    'weight_loss': {
      'title': 'Kilo Verme Programı',
      'image': 'https://images.unsplash.com/photo-1538805060514-97d9cc17730c?auto=format&fit=crop&w=1000&q=80',
      'duration': '30 Dk',
      'calories': '250 Kal',
      'level': 'Orta',
      'exercises': [
        Exercise(name: '1. Yürüyüş Isınma', detail: '5 Dakika', icon: Icons.directions_walk),
        Exercise(name: '2. Jumping Jacks', detail: '45 Saniye', icon: Icons.directions_run),
        Exercise(name: '3. Squat', detail: '15 Tekrar', icon: Icons.airline_seat_legroom_extra),
        Exercise(name: '4. Burpee', detail: '10 Tekrar', icon: Icons.fitness_center),
        Exercise(name: '5. Mountain Climber', detail: '30 Saniye', icon: Icons.terrain),
        Exercise(name: '6. Soğuma', detail: '5 Dakika', icon: Icons.spa),
      ],
    },
    'yoga': {
      'title': 'Esneklik & Yoga Programı',
      'image': 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?auto=format&fit=crop&w=1000&q=80',
      'duration': '25 Dk',
      'calories': '90 Kal',
      'level': 'Kolay',
      'exercises': [
        Exercise(name: '1. Nefes Egzersizi', detail: '3 Dakika', icon: Icons.air),
        Exercise(name: '2. Güneş Selamı', detail: '5 Tekrar', icon: Icons.wb_sunny_outlined),
        Exercise(name: '3. Çocuk Pozu', detail: '1 Dakika', icon: Icons.child_care),
        Exercise(name: '4. Köpek Pozu', detail: '1 Dakika', icon: Icons.pets),
        Exercise(name: '5. Savaşçı Pozu', detail: '30 Saniye / Taraf', icon: Icons.self_improvement),
        Exercise(name: '6. Meditasyon', detail: '5 Dakika', icon: Icons.spa),
      ],
    },
    'rehab': {
      'title': 'Rehabilitasyon & Sağlık',
      'image': 'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?auto=format&fit=crop&w=1000&q=80',
      'duration': '20 Dk',
      'calories': '70 Kal',
      'level': 'Hafif',
      'exercises': [
        Exercise(name: '1. Isınma', detail: '3 Dakika', icon: Icons.air),
        Exercise(name: '2. Boyun Esneme', detail: '5 Tekrar', icon: Icons.accessibility_new),
        Exercise(name: '3. Omuz Açma', detail: '10 Tekrar', icon: Icons.rotate_right),
        Exercise(name: '4. Bel Döndürme', detail: '8 Tekrar', icon: Icons.sync),
        Exercise(name: '5. Soğuma', detail: '3 Dakika', icon: Icons.spa),
      ],
    },
    'general': {
      'title': 'Genel Fitness Programı',
      'image': 'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?auto=format&fit=crop&w=1000&q=80',
      'duration': '30 Dk',
      'calories': '180 Kal',
      'level': 'Orta',
      'exercises': [
        Exercise(name: '1. Isınma', detail: '5 Dakika', icon: Icons.directions_walk),
        Exercise(name: '2. Şınav', detail: '12 Tekrar', icon: Icons.fitness_center),
        Exercise(name: '3. Squat', detail: '15 Tekrar', icon: Icons.airline_seat_legroom_extra),
        Exercise(name: '4. Plank', detail: '45 Saniye', icon: Icons.horizontal_rule),
        Exercise(name: '5. Lunge', detail: '10 Tekrar / Bacak', icon: Icons.directions_run),
        Exercise(name: '6. Soğuma', detail: '5 Dakika', icon: Icons.spa),
      ],
    },
    'suggested': {
      'title': 'Kişisel Öneri Programı',
      'image': 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?auto=format&fit=crop&w=1000&q=80',
      'duration': '20 Dk',
      'calories': '100 Kal',
      'level': 'Kolay',
      'exercises': [
        Exercise(name: '1. Sabah Esneme', detail: '5 Dakika', icon: Icons.wb_sunny_outlined),
        Exercise(name: '2. Sırt Esneme', detail: '8 Tekrar', icon: Icons.accessibility_new),
        Exercise(name: '3. Nefes Egzersizi', detail: '3 Dakika', icon: Icons.air),
        Exercise(name: '4. Hafif Yürüyüş', detail: '10 Dakika', icon: Icons.directions_walk),
        Exercise(name: '5. Soğuma', detail: '2 Dakika', icon: Icons.spa),
      ],
    },
  };
}

// --- EGZERSİZ LİSTESİ EKRANI ---
class WorkoutDetailScreen extends StatefulWidget {
  const WorkoutDetailScreen({super.key});

  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  Map<String, dynamic>? _program;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProgram();
  }

  Future<void> _loadProgram() async {
    final prefs = await SharedPreferences.getInstance();
    final programType = prefs.getString('program_type') ?? 'general';

    Map<String, dynamic>? program;

    if (programType == 'doctor') {
      final code = prefs.getString('doctor_code') ?? 'DEMO';
      program = Map<String, dynamic>.from(
        WorkoutPrograms.doctorPrograms[code] ??
            WorkoutPrograms.doctorPrograms['DEMO']!,
      );
    } else if (programType == 'sport') {
      final category = prefs.getString('sport_category') ?? 'general';
      program = Map<String, dynamic>.from(
        WorkoutPrograms.sportPrograms[category] ??
            WorkoutPrograms.sportPrograms['general']!,
      );
    } else {
      // suggested
      program = Map<String, dynamic>.from(
        WorkoutPrograms.sportPrograms['suggested']!,
      );
    }

    setState(() {
      _program = program;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: backgroundBeige,
        body: Center(
          child: CircularProgressIndicator(color: primaryGreen),
        ),
      );
    }

    final exercises = _program!['exercises'] as List<Exercise>;

    return Scaffold(
      backgroundColor: backgroundBeige,
      body: CustomScrollView(
        slivers: [
          // Esnek başlık
          SliverAppBar(
            expandedHeight: 220.0,
            pinned: true,
            backgroundColor: primaryGreen,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                _program!['title'] as String,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              background: Image.network(
                _program!['image'] as String,
                fit: BoxFit.cover,
                color: Colors.black.withOpacity(0.3),
                colorBlendMode: BlendMode.darken,
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bilgi kartları
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _infoBadge(Icons.timer, _program!['duration'] as String),
                      _infoBadge(Icons.local_fire_department, _program!['calories'] as String),
                      _infoBadge(Icons.bar_chart_rounded, _program!['level'] as String),
                    ],
                  ),
                  const SizedBox(height: 25),

                  const Text(
                    "Hareketler",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Hareket listesi
                  ...exercises.map((e) => _exerciseItem(e)),

                  const SizedBox(height: 30),

                  // Başla butonu
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () => _showCameraModal(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text(
                        "EGZERSİZE BAŞLA",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: primaryGreen.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: primaryGreen, size: 24),
          const SizedBox(height: 5),
          Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _exerciseItem(Exercise exercise) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cardBeige,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(exercise.icon, color: primaryGreen),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                exercise.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              Text(
                exercise.detail,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
          const Spacer(),
          const Icon(Icons.play_circle_fill, color: Colors.grey),
        ],
      ),
    );
  }

  // --- KAMERA MODAL ---
  void _showCameraModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40, height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              "Egzersizi Nasıl Yapmak İstiyorsun?",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Kamera ile hareketlerin doğruluğu ölçülür.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 28),

            // Kamera AÇIK seçeneği
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                _startFakeCamera(context);
              },
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: primaryGreen.withOpacity(0.4), width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primaryGreen.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.videocam_rounded, color: primaryGreen, size: 28),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Kamera Açık",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: textDark,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Hareketlerin doğruluk oranı ölçülür.",
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Kamera KAPALI seçeneği
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                _startWithoutCamera(context);
              },
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.grey[300]!, width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(Icons.videocam_off_rounded, color: Colors.grey[600], size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Kamera Kapalı",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Doğruluk oranı %0 olarak kaydedilir.",
                            style: TextStyle(color: Colors.grey[500], fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey[400]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // Kamera AÇIK → Sahte kamera ekranı
  void _startFakeCamera(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FakeCameraScreen()),
    );
  }

  // Kamera KAPALI → Direkt egzersiz başlat
  void _startWithoutCamera(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ExerciseRunningScreen(cameraEnabled: false),
      ),
    );
  }
}

// --- SAHTE KAMERA EKRANI ---
class FakeCameraScreen extends StatefulWidget {
  const FakeCameraScreen({super.key});

  @override
  State<FakeCameraScreen> createState() => _FakeCameraScreenState();
}

class _FakeCameraScreenState extends State<FakeCameraScreen> {
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    // 2 saniye sonra "kamera hazır" görünümüne geç
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isInitializing = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Sahte kamera görünümü (koyu arka plan + grid)
          Container(
            color: const Color(0xFF1A1A2E),
            child: CustomPaint(painter: _GridPainter()),
          ),

          // Üst bar
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.circle, color: Colors.white, size: 10),
                          SizedBox(width: 6),
                          Text("CANLI", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Orta: İnsan silüeti / yükleme
          Center(
            child: _isInitializing
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: primaryGreen),
                      const SizedBox(height: 20),
                      Text(
                        "Kamera başlatılıyor...",
                        style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Sahte insan silueti
                      Icon(
                        Icons.accessibility_new_rounded,
                        color: primaryGreen.withOpacity(0.8),
                        size: 120,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: primaryGreen.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: primaryGreen, width: 1),
                        ),
                        child: const Text(
                          "Pozisyon algılandı ✓",
                          style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
          ),

          // Alt: Başla butonu (kamera hazır olduktan sonra)
          if (!_isInitializing)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ExerciseRunningScreen(cameraEnabled: true),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        "EGZERSİZE BAŞLA",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Sahte kamera arka plan grid çizici
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1;

    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 40) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// --- EGZERSİZ ÇALIŞIYOR EKRANI ---
class ExerciseRunningScreen extends StatelessWidget {
  final bool cameraEnabled;
  const ExerciseRunningScreen({super.key, required this.cameraEnabled});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundBeige,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Egzersiz Başladı",
          style: TextStyle(color: textDark, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                cameraEnabled ? Icons.videocam_rounded : Icons.videocam_off_rounded,
                size: 80,
                color: cameraEnabled ? primaryGreen : Colors.grey,
              ),
              const SizedBox(height: 24),
              Text(
                cameraEnabled
                    ? "Kamera Aktif\nHareketlerin ölçülüyor..."
                    : "Kamera Kapalı\nDoğruluk oranı %0 olarak kaydedilecek.",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  color: textDark,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              // İleride gerçek egzersiz akışı buraya gelecek
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardBeige,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "⏳ Egzersiz akışı yakında burada olacak...",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}