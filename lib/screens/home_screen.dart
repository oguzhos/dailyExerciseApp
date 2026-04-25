import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile_screen.dart';
import 'workout_detail_screen.dart';
import 'history_screen.dart';

// --- RENK PALETİ (Sakin Doğa Tonları) ---
class AppColors {
  static const Color backgroundBeige = Color(0xFFFDFCF4);
  static const Color cardBeige = Color(0xFFF2F0E4);
  static const Color primaryGreen = Color(0xFF4A6849);
  static const Color lightGreen = Color(0xFF8FA98F);
  static const Color textDark = Color(0xFF2C3E2C);
  static const Color warningText = Color(0xFFB45454);
}

class MainHealthScreen extends StatefulWidget {
  const MainHealthScreen({super.key});

  @override
  State<MainHealthScreen> createState() => _MainHealthScreenState();
}

class _MainHealthScreenState extends State<MainHealthScreen> {
  int _selectedIndex = 1;
  int _userScenario = 0;
  int _streakCount = 0;
  int _todayAccuracy = 0;
  int _missedDays = 0;
  String _userName = ''; // Kullanıcı adı burada tutulacak

  @override
  void initState() {
    super.initState();
    _loadScenario();
  }

  // Geçmiş veriden senaryoyu ve streak'i GERÇEK bir şekilde hesapla
  Future<void> _loadScenario() async {
    final history = await WorkoutHistoryService.getHistory();
    final prefs = await SharedPreferences.getInstance();
    int onboardingDone = prefs.getInt('user_scenario') ?? 0;
    String userName = prefs.getString('user_name') ?? '';

    // --- CİHAZ SIFIRLANMIŞSA BULUTTAN KURTARMA VE İSİM ÇEKME OPERASYONU ---
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final data = userDoc.data()!;

          // KRİTİK EKLEME: İsmi veritabanından SADECE BİR KERE çekip değişkene atıyoruz
          userName = data['firstName'] ?? "Yolcu";

          // Cihaz sıfırlanmışsa onboarding kurtarma operasyonu
          if (onboardingDone == 0 && data['onboardingDone'] == true) {
            onboardingDone = 1; // Başlangıç adımını atla
            await prefs.setInt('user_scenario', 1);
            await prefs.setString(
              'program_type',
              data['program_type'] ?? 'sport',
            );
            if (data['doctor_code'] != null) {
              await prefs.setString('doctor_code', data['doctor_code']);
            }
            if (data['sport_category'] != null) {
              await prefs.setString('sport_category', data['sport_category']);
            }
          }
        }
      } catch (e) {
        debugPrint("Buluttan veri çekilemedi: $e");
      }
    }
    // ----------------------------------------------------------------------

    // Hiç onboarding yapılmamışsa
    if (onboardingDone == 0) {
      setState(() {
        _userScenario = 0;
        _streakCount = 0;
        _userName = userName;
      });
      return;
    }

    // Hiç egzersiz yapılmamışsa
    if (history.isEmpty) {
      setState(() {
        _userScenario = 1;
        _streakCount = 0;
        _userName = userName;
      });
      return;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    // 1. Tüm antrenman tarihlerini benzersiz (unique) gün olarak al ve sırala
    final historyDates = history
        .map((h) => DateTime(h.date.year, h.date.month, h.date.day))
        .toSet()
        .toList();
    historyDates.sort((a, b) => b.compareTo(a)); // En yeni tarih en başta

    final todayWorkout = historyDates.contains(today);
    final yesterdayWorkout = historyDates.contains(yesterday);

    // 2. GERÇEK STREAK (SERİ) HESAPLAMASI
    int streakCount = 0;
    if (todayWorkout || yesterdayWorkout) {
      // Eğer bugün veya dün antrenman varsa seri devam ediyordur, kesintisiz günleri geriye doğru say
      DateTime checkDate = todayWorkout ? today : yesterday;
      while (historyDates.contains(checkDate)) {
        streakCount++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      }
    } else {
      // Dün de bugün de antrenman yoksa seri KESİNLİKLE kopmuştur
      streakCount = 0;
    }

    // 3. KAÇ GÜN KAÇIRILDI HESAPLAMASI (Matematiksel Fark)
    int missedDays = 0;
    if (historyDates.isNotEmpty && !todayWorkout) {
      final lastWorkoutDate = historyDates.first;
      missedDays = today.difference(lastWorkoutDate).inDays;
    }

    // 4. BUGÜNKÜ DOĞRULUK ORANI
    int todayAccuracy = 0;
    if (todayWorkout) {
      final todayWorkouts = history.where((h) {
        final d = DateTime(h.date.year, h.date.month, h.date.day);
        return d == today;
      }).toList();
      if (todayWorkouts.isNotEmpty) {
        todayAccuracy = todayWorkouts.last.accuracyRate;
      }
    }

    // 5. SENARYO BELİRLEME
    int scenario;
    if (todayWorkout) {
      scenario = 2; // Bugün antrenman yapılmış -> "Harikasın" ekranı
    } else if (streakCount == 0 && missedDays > 1) {
      scenario =
          3; // Seri kopmuş ve üzerinden 1 günden fazla geçmiş -> "Özledik" ekranı
    } else {
      scenario =
          1; // Bugün antrenman yapılmamış ama seri henüz kopmamış (dün yapmış) -> "Günün Hedefi"
    }

    setState(() {
      _userScenario = scenario;
      _streakCount = streakCount;
      _todayAccuracy = todayAccuracy;
      _missedDays = missedDays;
      _userName = userName; // İsim UI'a yansıtılıyor
    });

    // 6. FIREBASE'İ GÜNCELLE
    if (user != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'currentStreak': streakCount})
          .catchError((error) => debugPrint("Streak güncellenemedi: $error"));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBeige,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // GÜNCELLENEN KISIM: FutureBuilder kaldırıldı, değişken kullanıldı
            Text(
              _userName.isEmpty ? "Merhaba!" : "Merhaba, $_userName",
              style: const TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            const Text(
              "Bugün kendini nasıl hissediyorsun?",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: IconButton(
              icon: CircleAvatar(
                backgroundColor: AppColors.lightGreen.withOpacity(0.3),
                child: const Icon(Icons.person, color: AppColors.primaryGreen),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _selectedIndex == 1
                ? _buildHomeContent()
                : _selectedIndex == 0
                ? const WorkoutDetailScreen()
                : HistoryScreen(key: ValueKey(_selectedIndex)),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  icon: Icons.fitness_center_rounded,
                  label: "Egzersizlerim",
                  index: 0,
                ),
                _buildNavItem(
                  icon: Icons.home_rounded,
                  label: "Ana Sayfa",
                  index: 1,
                ),
                _buildNavItem(
                  icon: Icons.history_rounded,
                  label: "Geçmiş",
                  index: 2,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          Expanded(flex: 3, child: _buildDynamicStatusCard()),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.cardBeige, width: 2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Seri Durumu",
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(
                          Icons.local_fire_department_rounded,
                          color: _streakCount > 0 ? Colors.orange : Colors.grey,
                          size: 28,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "$_streakCount Gün",
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                CircularProgressIndicator(
                  value: _streakCount > 0
                      ? (_streakCount / 7).clamp(0.0, 1.0)
                      : 0.0,
                  backgroundColor: AppColors.cardBeige,
                  color: AppColors.primaryGreen,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDynamicStatusCard() {
    if (_userScenario == 0) {
      return Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: AppColors.primaryGreen,
          borderRadius: BorderRadius.circular(30),
          image: const DecorationImage(
            image: NetworkImage(
              "https://images.unsplash.com/photo-1518611012118-696072aa579a?auto=format&fit=crop&w=800&q=80",
            ),
            fit: BoxFit.cover,
            opacity: 0.2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.spa_rounded, color: Colors.white, size: 60),
            const SizedBox(height: 20),
            const Text(
              "Yolculuğun Başlıyor!",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Henüz hiç egzersiz yapmadın. Sağlıklı bir yaşama ilk adımını atmaya hazır mısın?",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () async {
                // Onboarding tamamlandı olarak işaretle
                final prefs = await SharedPreferences.getInstance();
                await prefs.setInt('user_scenario', 1);

                // Firestore'a da yaz
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .set({'onboardingDone': true}, SetOptions(merge: true));
                }

                if (context.mounted) {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const WorkoutDetailScreen(),
                    ),
                  );
                  _loadScenario();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primaryGreen,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                "İLK ADIMI AT",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }

    if (_userScenario == 1) {
      return Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: AppColors.cardBeige,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: const Icon(
                Icons.timer_outlined,
                size: 50,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Günün Hedefi Bekliyor",
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Günlük egzersiziniz henüz yapılmadı. Kendine 15 dakika ayırabilirsin.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const WorkoutDetailScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text("EGZERSİZE BAŞLA"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 25,
                  vertical: 15,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_userScenario == 2) {
      return Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.lightGreen.withOpacity(0.5),
              AppColors.backgroundBeige,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppColors.primaryGreen.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.primaryGreen,
              size: 80,
            ),
            const SizedBox(height: 20),
            const Text(
              "Harikasın!",
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Günlük egzersizlerini bitirdiniz.",
              style: TextStyle(color: AppColors.textDark, fontSize: 16),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Doğruluk Oranı:",
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "%$_todayAccuracy",
                    style: const TextStyle(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Hareketlerin %$_todayAccuracy'ini doğru yaptınız.",
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_userScenario == 3) {
      return Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: AppColors.warningText.withOpacity(0.2),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.broken_image_rounded,
              color: AppColors.warningText.withOpacity(0.8),
              size: 60,
            ),
            const SizedBox(height: 20),
            const Text(
              "Seni Özledik!",
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "$_missedDays gündür egzersiz yapmıyorsunuz.",
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.warningText,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Vücudun hareketi seviyor. Küçük bir esneme ile geri dönmeye ne dersin?",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const WorkoutDetailScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warningText,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 12,
                ),
              ),
              child: const Text(
                "TELAFİ ET",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox();
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        if (index == 1) _loadScenario();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: isSelected
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 8)
            : const EdgeInsets.all(8),
        decoration: isSelected
            ? BoxDecoration(
                color: AppColors.cardBeige,
                borderRadius: BorderRadius.circular(20),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primaryGreen : Colors.grey[400],
              size: 26,
            ),
            if (isSelected) ...[
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.primaryGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
