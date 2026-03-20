import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'camera_exercise_screen.dart';

const Color primaryGreen = Color(0xFF4A6849);
const Color backgroundBeige = Color(0xFFFDFCF4);
const Color cardBeige = Color(0xFFF2F0E4);
const Color textDark = Color(0xFF2C3E2C);

// --- EGZERSİZ MODELİ ---
class Exercise {
  final String name;
  final String detail;
  final IconData icon;
  final int targetReps;
  final bool isTimeBased;
  final String imageUrl; // Hareket görseli

  const Exercise({
    required this.name,
    required this.detail,
    required this.icon,
    required this.imageUrl,
    this.targetReps = 10,
    this.isTimeBased = false,
  });
}

// --- EGZERSİZ PROGRAMLARI ---
class WorkoutPrograms {
  static const Map<String, Map<String, dynamic>> doctorPrograms = {
    'DR001': {
      'title': 'Diz Rehabilitasyon Programı',
      'image': 'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?auto=format&fit=crop&w=1000&q=80',
      'duration': '20 Dk',
      'calories': '80 Kal',
      'level': 'Hafif',
      'exercises': [
        Exercise(
          name: 'Diz Fleksiyonu',
          detail: '15 Tekrar • Ayakta diz bükme hareketi',
          icon: Icons.accessibility_new,
          imageUrl: 'https://images.unsplash.com/photo-1595078475328-1ab05d0a6a0e?auto=format&fit=crop&w=600&q=80',
          targetReps: 15,
        ),
        Exercise(
          name: 'Düz Bacak Kaldırma',
          detail: '10 Tekrar • Sırtüstü bacak ekstansiyonu',
          icon: Icons.airline_seat_legroom_extra,
          imageUrl: 'https://images.unsplash.com/photo-1518611012118-696072aa579a?auto=format&fit=crop&w=600&q=80',
          targetReps: 10,
        ),
        Exercise(
          name: 'Mini Squat',
          detail: '8 Tekrar • Kısmi diz bükme egzersizi',
          icon: Icons.fitness_center,
          imageUrl: 'https://images.unsplash.com/photo-1574680096145-d05b474e2155?auto=format&fit=crop&w=600&q=80',
          targetReps: 8,
        ),
        Exercise(
          name: 'Kuadriseps Gerilmesi',
          detail: '12 Tekrar • Ön uyluk kası aktivasyonu',
          icon: Icons.self_improvement,
          imageUrl: 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?auto=format&fit=crop&w=600&q=80',
          targetReps: 12,
        ),
        Exercise(
          name: 'Terminal Diz Ekstansiyonu',
          detail: '10 Tekrar • Son açıda diz düzeltme',
          icon: Icons.directions_walk,
          imageUrl: 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?auto=format&fit=crop&w=600&q=80',
          targetReps: 10,
        ),
      ],
    },
    'DR002': {
      'title': 'Sırt Güçlendirme Programı',
      'image': 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?auto=format&fit=crop&w=1000&q=80',
      'duration': '25 Dk',
      'calories': '100 Kal',
      'level': 'Orta',
      'exercises': [
        Exercise(
          name: 'Köprü Egzersizi',
          detail: '12 Tekrar • Kalça ekstansörü aktivasyonu',
          icon: Icons.landscape,
          imageUrl: 'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?auto=format&fit=crop&w=600&q=80',
          targetReps: 12,
        ),
        Exercise(
          name: 'Kuş-Köpek',
          detail: '10 Tekrar • Çapraz ekstremite stabilizasyonu',
          icon: Icons.pets,
          imageUrl: 'https://images.unsplash.com/photo-1518611012118-696072aa579a?auto=format&fit=crop&w=600&q=80',
          targetReps: 10,
        ),
        Exercise(
          name: 'Süperman Hareketi',
          detail: '10 Tekrar • Sırtüstü gövde ekstansiyonu',
          icon: Icons.flight,
          imageUrl: 'https://images.unsplash.com/photo-1574680096145-d05b474e2155?auto=format&fit=crop&w=600&q=80',
          targetReps: 10,
        ),
        Exercise(
          name: 'Pron Plank',
          detail: '30 Saniye • Gövde stabilizasyon egzersizi',
          icon: Icons.horizontal_rule,
          imageUrl: 'https://images.unsplash.com/photo-1595078475328-1ab05d0a6a0e?auto=format&fit=crop&w=600&q=80',
          targetReps: 0,
          isTimeBased: true,
        ),
        Exercise(
          name: 'Pelvik Tilt',
          detail: '15 Tekrar • Lumbar stabilizasyon hareketi',
          icon: Icons.sync,
          imageUrl: 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?auto=format&fit=crop&w=600&q=80',
          targetReps: 15,
        ),
      ],
    },
    'DEMO': {
      'title': 'Demo Rehabilitasyon Programı',
      'image': 'https://images.unsplash.com/photo-1518611012118-696072aa579a?auto=format&fit=crop&w=1000&q=80',
      'duration': '15 Dk',
      'calories': '60 Kal',
      'level': 'Kolay',
      'exercises': [
        Exercise(
          name: 'Servikal Rotasyon',
          detail: '5 Tekrar • Boyun dönme hareketi',
          icon: Icons.rotate_right,
          imageUrl: 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?auto=format&fit=crop&w=600&q=80',
          targetReps: 5,
        ),
        Exercise(
          name: 'Omuz Retraksiyon',
          detail: '10 Tekrar • Kürek kemiği germe egzersizi',
          icon: Icons.open_with,
          imageUrl: 'https://images.unsplash.com/photo-1574680096145-d05b474e2155?auto=format&fit=crop&w=600&q=80',
          targetReps: 10,
        ),
        Exercise(
          name: 'Lumbar Fleksiyon',
          detail: '8 Tekrar • Bel bölgesi esneme hareketi',
          icon: Icons.airline_seat_legroom_extra,
          imageUrl: 'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?auto=format&fit=crop&w=600&q=80',
          targetReps: 8,
        ),
      ],
    },
  };

  static const Map<String, Map<String, dynamic>> sportPrograms = {
    'weight_loss': {
      'title': 'Kilo Verme Programı',
      'image': 'https://images.unsplash.com/photo-1538805060514-97d9cc17730c?auto=format&fit=crop&w=1000&q=80',
      'duration': '30 Dk',
      'calories': '250 Kal',
      'level': 'Orta',
      'exercises': [
        Exercise(
          name: 'Squat',
          detail: '15 Tekrar • Diz ve kalça fleksiyonu',
          icon: Icons.airline_seat_legroom_extra,
          imageUrl: 'https://images.unsplash.com/photo-1574680096145-d05b474e2155?auto=format&fit=crop&w=600&q=80',
          targetReps: 15,
        ),
        Exercise(
          name: 'Plank',
          detail: '30 Saniye • Gövde stabilizasyonu',
          icon: Icons.horizontal_rule,
          imageUrl: 'https://images.unsplash.com/photo-1595078475328-1ab05d0a6a0e?auto=format&fit=crop&w=600&q=80',
          targetReps: 0,
          isTimeBased: true,
        ),
        Exercise(
          name: 'Lunge',
          detail: '10 Tekrar • Tek bacak öne adım egzersizi',
          icon: Icons.directions_run,
          imageUrl: 'https://images.unsplash.com/photo-1518611012118-696072aa579a?auto=format&fit=crop&w=600&q=80',
          targetReps: 10,
        ),
      ],
    },
    'yoga': {
      'title': 'Esneklik & Yoga Programı',
      'image': 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?auto=format&fit=crop&w=1000&q=80',
      'duration': '25 Dk',
      'calories': '90 Kal',
      'level': 'Kolay',
      'exercises': [
        Exercise(
          name: 'Hamstring Gerilmesi',
          detail: '5 Tekrar • Arka uyluk esneme hareketi',
          icon: Icons.self_improvement,
          imageUrl: 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?auto=format&fit=crop&w=600&q=80',
          targetReps: 5,
        ),
        Exercise(
          name: 'Kalça Fleksör Gerilmesi',
          detail: '5 Tekrar • Ön kalça bölgesi esneme',
          icon: Icons.accessibility_new,
          imageUrl: 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?auto=format&fit=crop&w=600&q=80',
          targetReps: 5,
        ),
        Exercise(
          name: 'Torasik Ekstansiyon',
          detail: '8 Tekrar • Üst sırt açma hareketi',
          icon: Icons.open_with,
          imageUrl: 'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?auto=format&fit=crop&w=600&q=80',
          targetReps: 8,
        ),
      ],
    },
    'rehab': {
      'title': 'Rehabilitasyon & Sağlık',
      'image': 'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?auto=format&fit=crop&w=1000&q=80',
      'duration': '20 Dk',
      'calories': '70 Kal',
      'level': 'Hafif',
      'exercises': [
        Exercise(
          name: 'Servikal Lateral Fleksiyon',
          detail: '5 Tekrar • Boyun yan eğme hareketi',
          icon: Icons.accessibility_new,
          imageUrl: 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?auto=format&fit=crop&w=600&q=80',
          targetReps: 5,
        ),
        Exercise(
          name: 'Omuz Elevasyonu',
          detail: '10 Tekrar • Omuz yükseltme egzersizi',
          icon: Icons.open_with,
          imageUrl: 'https://images.unsplash.com/photo-1574680096145-d05b474e2155?auto=format&fit=crop&w=600&q=80',
          targetReps: 10,
        ),
        Exercise(
          name: 'Lumbar Rotasyon',
          detail: '8 Tekrar • Bel dönme hareketi',
          icon: Icons.sync,
          imageUrl: 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?auto=format&fit=crop&w=600&q=80',
          targetReps: 8,
        ),
      ],
    },
    'general': {
      'title': 'Genel Fitness Programı',
      'image': 'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?auto=format&fit=crop&w=1000&q=80',
      'duration': '30 Dk',
      'calories': '180 Kal',
      'level': 'Orta',
      'exercises': [
        Exercise(
          name: 'Squat',
          detail: '15 Tekrar • Diz ve kalça fleksiyonu',
          icon: Icons.airline_seat_legroom_extra,
          imageUrl: 'https://images.unsplash.com/photo-1574680096145-d05b474e2155?auto=format&fit=crop&w=600&q=80',
          targetReps: 15,
        ),
        Exercise(
          name: 'Pron Plank',
          detail: '45 Saniye • Gövde stabilizasyonu',
          icon: Icons.horizontal_rule,
          imageUrl: 'https://images.unsplash.com/photo-1595078475328-1ab05d0a6a0e?auto=format&fit=crop&w=600&q=80',
          targetReps: 0,
          isTimeBased: true,
        ),
        Exercise(
          name: 'Lunge',
          detail: '10 Tekrar • Tek bacak öne adım egzersizi',
          icon: Icons.directions_run,
          imageUrl: 'https://images.unsplash.com/photo-1518611012118-696072aa579a?auto=format&fit=crop&w=600&q=80',
          targetReps: 10,
        ),
      ],
    },
    'suggested': {
      'title': 'Kişisel Öneri Programı',
      'image': 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?auto=format&fit=crop&w=1000&q=80',
      'duration': '20 Dk',
      'calories': '100 Kal',
      'level': 'Kolay',
      'exercises': [
        Exercise(
          name: 'Servikal Rotasyon',
          detail: '8 Tekrar • Boyun dönme hareketi',
          icon: Icons.rotate_right,
          imageUrl: 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?auto=format&fit=crop&w=600&q=80',
          targetReps: 8,
        ),
        Exercise(
          name: 'Torasik Ekstansiyon',
          detail: '8 Tekrar • Üst sırt açma hareketi',
          icon: Icons.open_with,
          imageUrl: 'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?auto=format&fit=crop&w=600&q=80',
          targetReps: 8,
        ),
        Exercise(
          name: 'Köprü Egzersizi',
          detail: '10 Tekrar • Kalça ekstansörü aktivasyonu',
          icon: Icons.landscape,
          imageUrl: 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?auto=format&fit=crop&w=600&q=80',
          targetReps: 10,
        ),
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
    final programType = prefs.getString('program_type'); // ?? kaldırıldı

    // Onboarding yapılmamışsa null döner
    if (programType == null) {
      setState(() {
        _program = null;
        _isLoading = false;
      });
      return;
    }

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
        body: Center(child: CircularProgressIndicator(color: primaryGreen)),
      );
    }

    // Program seçilmemişse boş ekran göster
    if (_program == null) {
      return Scaffold(
        backgroundColor: backgroundBeige,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.fitness_center_outlined, size: 80, color: Colors.grey[300]),
              const SizedBox(height: 16),
              const Text(
                'Henüz program seçilmedi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ana sayfadan programını seç.',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    final exercises = _program!['exercises'] as List<Exercise>;

    return Scaffold(
      backgroundColor: backgroundBeige,
      body: CustomScrollView(
        slivers: [
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
                  ...exercises.map((e) => _exerciseItem(e)),
                  const SizedBox(height: 30),
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
            style: const TextStyle(fontWeight: FontWeight.bold, color: textDark),
          ),
        ],
      ),
    );
  }

  Widget _exerciseItem(Exercise exercise) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          // Hareket görseli
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              bottomLeft: Radius.circular(16),
            ),
            child: Image.network(
              exercise.imageUrl,
              width: 85,
              height: 85,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 85, height: 85,
                color: cardBeige,
                child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textDark),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    exercise.detail,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      exercise.isTimeBased ? "Süre bazlı" : "${exercise.targetReps} tekrar",
                      style: const TextStyle(color: primaryGreen, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.play_circle_fill, color: Colors.grey, size: 28),
          ),
        ],
      ),
    );
  }

  void _showCameraModal(BuildContext context) {
    final exercises = _program!['exercises'] as List<Exercise>;
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

            // Kamera AÇIK
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CameraExerciseScreen(
                      exercises: exercises,
                      cameraEnabled: true,
                    ),
                  ),
                );
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
                          Text("Kamera Açık",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textDark)),
                          SizedBox(height: 4),
                          Text("Hareketlerin doğruluk oranı ölçülür.",
                              style: TextStyle(color: Colors.grey, fontSize: 13)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Kamera KAPALI
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CameraExerciseScreen(
                      exercises: exercises,
                      cameraEnabled: false,
                    ),
                  ),
                );
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
                          const Text("Kamera Kapalı",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textDark)),
                          const SizedBox(height: 4),
                          Text("Doğruluk oranı %0 olarak kaydedilir.",
                              style: TextStyle(color: Colors.grey[500], fontSize: 13)),
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
}