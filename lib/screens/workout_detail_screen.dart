import 'package:flutter/material.dart';
import 'camera_exercise_screen.dart';

const Color primaryGreen = Color(0xFF4A6849);
const Color backgroundBeige = Color(0xFFFDFCF4);
const Color cardBeige = Color(0xFFF2F0E4);
const Color textDark = Color(0xFF2C3E2C);

// --- ANALİZ TİPİ ---
enum AnalysisType {
  sitToStand,
  straightLegRaise,
  heelSlide,
  miniSquat,
  hipAbduction,
  pelvicTilt,
  bridge,
  birdDog,
  wallPushUp,
  shoulderFlexion,
  shoulderAbduction,
  heelRaise,
  singleLegStand,
  general,
}

// --- EGZERSİZ MODELİ ---
class Exercise {
  final String name;
  final String detail;
  final String description;
  final IconData icon;
  final int targetReps;
  final bool isTimeBased;
  final String imageUrl;
  final AnalysisType analysisType;

  const Exercise({
    required this.name,
    required this.detail,
    required this.description,
    required this.icon,
    required this.imageUrl,
    required this.analysisType,
    this.targetReps = 10,
    this.isTimeBased = false,
  });
}

// --- KATEGORİ MODELİ ---
class ExerciseCategory {
  final String name;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final List<Exercise> exercises;

  const ExerciseCategory({
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.exercises,
  });
}

// --- EGZERSİZ KÜTÜPHANESİ ---
class ExerciseLibrary {
  static const List<ExerciseCategory> categories = [
    ExerciseCategory(
      name: 'Alt Vücut',
      subtitle: 'Rehabilitasyon',
      icon: Icons.directions_walk_rounded,
      color: Color(0xFF4A6849),
      bgColor: Color(0xFFE8F5E9),
      exercises: [
        Exercise(
          name: 'Sit-to-Stand',
          detail: '10 Tekrar • Fonksiyonel kalkış',
          description: 'Sandalyeden kalkarken dizleri 90°\'den 160°\'ye getir. Dizler içe çökmesin.',
          icon: Icons.airline_seat_legroom_extra,
          imageUrl: 'https://images.unsplash.com/photo-1574680096145-d05b474e2155?auto=format&fit=crop&w=600&q=80',
          analysisType: AnalysisType.sitToStand,
          targetReps: 10,
        ),
        Exercise(
          name: 'Straight Leg Raise',
          detail: '10 Tekrar • Quadriceps aktivasyonu',
          description: 'Sırt üstü yatarak bacağını düz tutup 45° kaldır. Diz hiç kırılmamalı.',
          icon: Icons.accessibility_new,
          imageUrl: 'https://images.unsplash.com/photo-1518611012118-696072aa579a?auto=format&fit=crop&w=600&q=80',
          analysisType: AnalysisType.straightLegRaise,
          targetReps: 10,
        ),
        Exercise(
          name: 'Heel Slide',
          detail: '10 Tekrar • Diz mobilitesi',
          description: 'Sırt üstü yatarak topuğu yavaşça kendine çek. Diz 180°\'den 60°\'ye gelsin.',
          icon: Icons.swap_vert_rounded,
          imageUrl: 'https://images.unsplash.com/photo-1595078475328-1ab05d0a6a0e?auto=format&fit=crop&w=600&q=80',
          analysisType: AnalysisType.heelSlide,
          targetReps: 10,
        ),
        Exercise(
          name: 'Mini Squat',
          detail: '10 Tekrar • Güç ve kontrol',
          description: 'Ayakta hafifçe çömel. Diz 180°\'den 120°\'ye gelsin, ayak hizasını geçmesin.',
          icon: Icons.fitness_center,
          imageUrl: 'https://images.unsplash.com/photo-1574680096145-d05b474e2155?auto=format&fit=crop&w=600&q=80',
          analysisType: AnalysisType.miniSquat,
          targetReps: 10,
        ),
        Exercise(
          name: 'Hip Abduction',
          detail: '10 Tekrar • Kalça stabilitesi',
          description: 'Yan yatarak bacağını 30-45° kaldır. Diz düz, gövde sabit kalmalı.',
          icon: Icons.open_with,
          imageUrl: 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?auto=format&fit=crop&w=600&q=80',
          analysisType: AnalysisType.hipAbduction,
          targetReps: 10,
        ),
      ],
    ),
    ExerciseCategory(
      name: 'Core',
      subtitle: 'Gövde Stabilitesi',
      icon: Icons.self_improvement_rounded,
      color: Color(0xFF7986CB),
      bgColor: Color(0xFFEEF0FB),
      exercises: [
        Exercise(
          name: 'Pelvic Tilt',
          detail: '15 Tekrar • Bel kontrolü',
          description: 'Sırt üstü yatarak beli yavaşça zemine bastır. Küçük (5-15°) kontrollü hareket.',
          icon: Icons.sync_rounded,
          imageUrl: 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?auto=format&fit=crop&w=600&q=80',
          analysisType: AnalysisType.pelvicTilt,
          targetReps: 15,
        ),
        Exercise(
          name: 'Bridge',
          detail: '12 Tekrar • Glute ve core',
          description: 'Sırt üstü dizler 90°, kalçayı kaldır. Omuz-kalça-diz düz çizgi oluşturmalı.',
          icon: Icons.landscape_rounded,
          imageUrl: 'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?auto=format&fit=crop&w=600&q=80',
          analysisType: AnalysisType.bridge,
          targetReps: 12,
        ),
        Exercise(
          name: 'Bird Dog',
          detail: '10 Tekrar • Stabilite',
          description: 'Dört ayak pozisyonunda karşı kol ve bacağı düz uzat. Gövde döndürülmemeli.',
          icon: Icons.pets_rounded,
          imageUrl: 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?auto=format&fit=crop&w=600&q=80',
          analysisType: AnalysisType.birdDog,
          targetReps: 10,
        ),
      ],
    ),
    ExerciseCategory(
      name: 'Üst Vücut',
      subtitle: 'Omuz ve Kol',
      icon: Icons.fitness_center_rounded,
      color: Color(0xFFE57373),
      bgColor: Color(0xFFFDEDED),
      exercises: [
        Exercise(
          name: 'Wall Push-up',
          detail: '12 Tekrar • Hafif kuvvet',
          description: 'Duvara karşı şınav. Dirsek 180°\'den 90°\'ye gelsin, vücut düz kalmalı.',
          icon: Icons.crop_landscape_rounded,
          imageUrl: 'https://images.unsplash.com/photo-1595078475328-1ab05d0a6a0e?auto=format&fit=crop&w=600&q=80',
          analysisType: AnalysisType.wallPushUp,
          targetReps: 12,
        ),
        Exercise(
          name: 'Shoulder Flexion',
          detail: '10 Tekrar • Omuz mobilitesi',
          description: 'Kolu öne doğru 150-180° kaldır. Kontrollü, gövde geriye kaçmamalı.',
          icon: Icons.arrow_upward_rounded,
          imageUrl: 'https://images.unsplash.com/photo-1574680096145-d05b474e2155?auto=format&fit=crop&w=600&q=80',
          analysisType: AnalysisType.shoulderFlexion,
          targetReps: 10,
        ),
        Exercise(
          name: 'Shoulder Abduction',
          detail: '10 Tekrar • Omuz güçlendirme',
          description: 'Kolu yana doğru 90° kaldır. Kol düz, dirsek kırılmamalı.',
          icon: Icons.open_in_full_rounded,
          imageUrl: 'https://images.unsplash.com/photo-1518611012118-696072aa579a?auto=format&fit=crop&w=600&q=80',
          analysisType: AnalysisType.shoulderAbduction,
          targetReps: 10,
        ),
      ],
    ),
    ExerciseCategory(
      name: 'Denge',
      subtitle: 'Stabilite ve Koordinasyon',
      icon: Icons.balance_rounded,
      color: Color(0xFFFFB74D),
      bgColor: Color(0xFFFFF3E0),
      exercises: [
        Exercise(
          name: 'Heel Raise',
          detail: '15 Tekrar • Baldır ve denge',
          description: 'Ayakta parmak ucuna yüksel. Ayak bileği 90°\'den 120°\'ye gelsin, dengeli.',
          icon: Icons.arrow_circle_up_rounded,
          imageUrl: 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?auto=format&fit=crop&w=600&q=80',
          analysisType: AnalysisType.heelRaise,
          targetReps: 15,
        ),
        Exercise(
          name: 'Single Leg Stand',
          detail: '30 Saniye • Denge',
          description: 'Tek ayak üzerinde dur. Diz 170-180° düz, gövde sabit kalmalı.',
          icon: Icons.accessibility_new_rounded,
          imageUrl: 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?auto=format&fit=crop&w=600&q=80',
          analysisType: AnalysisType.singleLegStand,
          targetReps: 0,
          isTimeBased: true,
        ),
      ],
    ),
  ];
}

// --- EGZERSİZ DETAY EKRANI ---
class WorkoutDetailScreen extends StatefulWidget {
  const WorkoutDetailScreen({super.key});

  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  ExerciseCategory? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundBeige,
      appBar: _selectedCategory != null
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded, color: textDark),
                onPressed: () => setState(() => _selectedCategory = null),
              ),
              title: Text(
                _selectedCategory!.name,
                style: const TextStyle(
                  color: textDark,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            )
          : null,
      body: _selectedCategory == null
          ? _buildCategoryList()
          : _buildExerciseList(_selectedCategory!),
    );
  }

  // --- KATEGORİ LİSTESİ ---
  Widget _buildCategoryList() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          const Text(
            'Egzersizlerim',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Bir kategori seç',
            style: TextStyle(fontSize: 15, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
              ),
              itemCount: ExerciseLibrary.categories.length,
              itemBuilder: (context, index) {
                final cat = ExerciseLibrary.categories[index];
                return _buildCategoryCard(cat);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(ExerciseCategory cat) {
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = cat),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: cat.color.withOpacity(0.2), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cat.bgColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(cat.icon, color: cat.color, size: 28),
            ),
            const Spacer(),
            Text(
              cat.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              cat.subtitle,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 6),
            Text(
              '${cat.exercises.length} egzersiz',
              style: TextStyle(
                fontSize: 11,
                color: cat.color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- EGZERSİZ LİSTESİ ---
  Widget _buildExerciseList(ExerciseCategory cat) {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: cat.exercises.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        return _buildExerciseCard(cat.exercises[index], cat.color);
      },
    );
  }

  Widget _buildExerciseCard(Exercise exercise, Color categoryColor) {
    return GestureDetector(
      onTap: () => _showCameraModal(context, exercise),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Görsel
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                bottomLeft: Radius.circular(18),
              ),
              child: Image.network(
                exercise.imageUrl,
                width: 90,
                height: 90,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 90,
                  height: 90,
                  color: cardBeige,
                  child: const Icon(Icons.image_not_supported_outlined,
                      color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      exercise.description,
                      style: const TextStyle(
                          fontSize: 11, color: Colors.grey, height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: categoryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        exercise.isTimeBased
                            ? exercise.detail.split('•').first.trim()
                            : '${exercise.targetReps} tekrar',
                        style: TextStyle(
                          color: categoryColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Icon(Icons.play_circle_fill,
                  color: categoryColor, size: 32),
            ),
          ],
        ),
      ),
    );
  }

  // --- KAMERA MODAL ---
  void _showCameraModal(BuildContext context, Exercise exercise) {
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
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            // Egzersiz başlığı
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: cardBeige,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(exercise.icon, color: primaryGreen),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: textDark,
                        ),
                      ),
                      Text(
                        exercise.detail,
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              "Egzersizi Nasıl Yapmak İstiyorsun?",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
            const SizedBox(height: 20),

            // Kamera AÇIK
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CameraExerciseScreen(
                      exercises: [exercise],
                      cameraEnabled: true,
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: primaryGreen.withOpacity(0.4), width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: primaryGreen.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.videocam_rounded,
                          color: primaryGreen, size: 26),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Kamera Açık',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: textDark)),
                          SizedBox(height: 3),
                          Text('Hareketlerin doğruluğu ölçülür.',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        size: 14, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Kamera KAPALI
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CameraExerciseScreen(
                      exercises: [exercise],
                      cameraEnabled: false,
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[300]!, width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.videocam_off_rounded,
                          color: Colors.grey[600], size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Kamera Kapalı',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: textDark)),
                          const SizedBox(height: 3),
                          Text('Doğruluk oranı %0 olarak kaydedilir.',
                              style: TextStyle(
                                  color: Colors.grey[500], fontSize: 12)),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded,
                        size: 14, color: Colors.grey[400]),
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