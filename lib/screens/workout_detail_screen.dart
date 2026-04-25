import 'package:flutter/material.dart';
import 'camera_exercise_screen.dart';

const Color primaryGreen = Color(0xFF4A6849);
const Color backgroundBeige = Color(0xFFFDFCF4);
const Color cardBeige = Color(0xFFF2F0E4);
const Color textDark = Color(0xFF2C3E2C);

// --- ANALİZ TİPİ (Eski hareketler temizlendi, sadece güncel olanlar) ---
enum AnalysisType {
  sitToStand,
  miniSquat,
  shoulderAbduction,
  singleLegStand,
  highKnees,
  sideBend,
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
      subtitle: 'Bacak ve Kalça Rehabilitasyonu',
      icon: Icons.directions_walk_rounded,
      color: Color(0xFF4A6849),
      bgColor: Color(0xFFE8F5E9),
      exercises: [
        Exercise(
          name: 'Sandalyeden Kalkma',
          detail: '10 Tekrar • Fonksiyonel Güç',
          description:
              'Sandalyeden destek almadan kalkıp tekrar kontrollü oturma hareketidir.\n\n👨‍⚕️ Kimler İçin: Diz veya kalça protezi ameliyatı sonrası (geç dönem) ve yaşlılığa bağlı kas erimesi (sarkopeni) yaşayanlar.\n🎯 Amaç: Düşme riskini azaltmak; üst/arka bacak ve kalça kaslarını günlük yaşama uygun güçlendirmek.',
          icon: Icons.airline_seat_legroom_extra,
          imageUrl: 'assets/exercises/sit_to_stand.png',
          analysisType: AnalysisType.sitToStand,
          targetReps: 10,
        ),
        Exercise(
          name: 'Yarım Squat',
          detail: '10 Tekrar • Eklem Kontrolü',
          description:
              'Ayakta dururken dizleri aşırı bükmeden yapılan yarım çömelme hareketidir.\n\n👨‍⚕️ Kimler İçin: Patellofemoral ağrı sendromu, menisküs onarımı sonrası ve genel diz kireçlenmesi (osteoartrit) hastaları.\n🎯 Amaç: Diz kapağı dizilimini düzeltmek ve ekleme aşırı yük bindirmeden bacak kaslarını (Quadriceps) güçlendirmek.',
          icon: Icons.fitness_center,
          imageUrl: 'assets/exercises/mini_squat.png',
          analysisType: AnalysisType.miniSquat,
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
          name: 'Ayakta Diz Çekme',
          detail: '12 Tekrar • Core ve Mobilite',
          description:
              'Ayaktayken dizleri sırayla karna doğru (en az 120 derece) çekme hareketidir.\n\n👨‍⚕️ Kimler İçin: Bel fıtığı sonrası yürüyüş mekaniği bozulanlar ve kalça kireçlenmesi olanlar.\n🎯 Amaç: Yerde mekik çekmenin riskli olduğu bel hastalarında alt karın ve kalça fleksör kaslarını (İliopsoas) güvenle çalıştırmak.',
          icon: Icons.directions_run_rounded,
          imageUrl: 'assets/exercises/high_knees.png',
          analysisType: AnalysisType.highKnees,
          targetReps: 12,
        ),
        Exercise(
          name: 'Ayakta Yana Eğilme',
          detail: '10 Tekrar • Omurga Esnekliği',
          description:
              'Dik duruş pozisyonundan gövdeyi sağa veya sola doğru (20-25 derece) esnetme hareketidir.\n\n👨‍⚕️ Kimler İçin: Skolyoz hastaları ve masa başı çalışmaya bağlı kronik sırt/bel ağrısı (postüral sendrom) çekenler.\n🎯 Amaç: Omurganın yana hareketliliğini artırmak, yan karın (Oblik) ve derin bel kaslarını esnetmek.',
          icon: Icons.accessibility_rounded,
          imageUrl: 'assets/exercises/side_bend.png',
          analysisType: AnalysisType.sideBend,
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
          name: 'Yana Kol Açma',
          detail: '10 Tekrar • Omuz Güçlendirme',
          description:
              'Kolları dirsekleri bükmeden omuz hizasına (90 derece) kadar yana kaldırma hareketidir.\n\n👨‍⚕️ Kimler İçin: Omuz sıkışma (Impingement) sendromu, donuk omuz veya rotator kılıf yırtığı sonrası fizik tedavi görenler.\n🎯 Amaç: Omuz eklem hareket açıklığını (ROM) geri kazanmak ve yan omuz kaslarını (Deltoid) güçlendirmek.',
          icon: Icons.open_in_full_rounded,
          imageUrl: 'assets/exercises/shoulder_abduction.png',
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
          name: 'Tek Ayak Denge',
          detail: '30 Saniye • Denge ve Koordinasyon',
          description:
              'Bir bacağı yerden hafifçe kaldırarak tek ayak üzerinde sabit durma egzersizidir.\n\n👨‍⚕️ Kimler İçin: Ayak bileği burkulmaları sonrası, inme (felç) geçirmiş hastalar veya iç kulak (vestibüler) sorunu yaşayanlar.\n🎯 Amaç: Propriyosepsiyon (vücut farkındalığı) duyusunu geliştirmek ve nörolojik/fiziksel dengeyi sağlamak.',
          icon: Icons.accessibility_new_rounded,
          imageUrl: 'assets/exercises/single_leg_stand.png',
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
                childAspectRatio:
                    1.05, // Metinler daha rahat sığsın diye biraz genişlettik
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
        padding: const EdgeInsets.all(16),
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
              child: Icon(cat.icon, color: cat.color, size: 24),
            ),
            const Spacer(),
            Text(
              cat.name,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              cat.subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Görsel
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                bottomLeft: Radius.circular(18),
              ),
              child: Image.asset(
                exercise.imageUrl,
                width: 100,
                height: 180,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 100,
                  height: 180,
                  color: cardBeige,
                  child: const Icon(
                    Icons.image_not_supported_outlined,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 8,
                ),
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
                    const SizedBox(height: 6),
                    Text(
                      exercise.description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        height: 1.4,
                      ),
                      maxLines:
                          7, // Klinik açıklamalar için sığdırma alanı genişletildi
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
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
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 14, top: 14),
              child: Icon(
                Icons.play_circle_fill,
                color: categoryColor,
                size: 28,
              ),
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
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
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
                    color: primaryGreen.withOpacity(0.4),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: primaryGreen.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.videocam_rounded,
                        color: primaryGreen,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kamera Açık',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: textDark,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Hareketlerin doğruluğu ölçülür.',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: Colors.grey,
                    ),
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
                      child: Icon(
                        Icons.videocam_off_rounded,
                        color: Colors.grey[600],
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Kamera Kapalı',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: textDark,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Doğruluk oranı %0 olarak kaydedilir.',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: Colors.grey[400],
                    ),
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
