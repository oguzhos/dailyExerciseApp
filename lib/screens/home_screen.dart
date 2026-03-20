import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // <--- EKLENDİ: Firebase Veritabanı
import 'package:firebase_auth/firebase_auth.dart'; // <--- EKLENDİ: Firebase Kimlik Doğrulama
import 'profile_screen.dart'; // <--- EKLENDİ: Profil Ekranı Yönlendirmesi
import 'onboarding_screen.dart';
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
  String _userName = ''; // Lokal kullanıcı adı yedeği

  @override
  void initState() {
    super.initState();
    _loadScenario();
  }

  // Geçmiş veriden senaryoyu ve streak'i otomatik hesapla
  Future<void> _loadScenario() async {
    // Not: Arkadaşının kurduğu yapıya dokunulmadı
    final history = await WorkoutHistoryService.getHistory();
    final prefs = await SharedPreferences.getInstance();
    final onboardingDone = prefs.getInt('user_scenario') ?? 0;
    final userName = prefs.getString('user_name') ?? '';

    // Hiç onboarding yapılmamışsa → Senaryo 0
    if (onboardingDone == 0) {
      setState(() {
        _userScenario = 0;
        _streakCount = 0;
        _userName = userName;
      });
      return;
    }

    // Hiç egzersiz yapılmamışsa → Senaryo 1 (onboarding bitti ama egzersiz yok)
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

    // Bugün egzersiz yapıldı mı?
    final todayWorkout = history.any((h) {
      final d = DateTime(h.date.year, h.date.month, h.date.day);
      return d == today;
    });

    // Son 7 günde kaç gün egzersiz yapıldı?
    int daysWithWorkout = 0;
    for (int i = 0; i < 7; i++) {
      final day = today.subtract(Duration(days: i));
      final hasWorkout = history.any((h) {
        final d = DateTime(h.date.year, h.date.month, h.date.day);
        return d == day;
      });
      if (hasWorkout) daysWithWorkout++;
    }

    // Streak: son 7 günde 6+ gün egzersiz yapıldıysa streak var
    final hasStreak = daysWithWorkout >= 6;
    final streakCount = daysWithWorkout;

    // Bugünkü doğruluk oranını bul
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

    // Kaç gündür yapılmadı?
    int missedDays = 0;
    if (!todayWorkout) {
      for (int i = 1; i <= 30; i++) {
        final day = today.subtract(Duration(days: i));
        final hasWorkout = history.any((h) {
          final d = DateTime(h.date.year, h.date.month, h.date.day);
          return d == day;
        });
        if (hasWorkout) break;
        missedDays++;
      }
    }

    int scenario;
    if (todayWorkout) {
      scenario = 2;
    } else if (!hasStreak && daysWithWorkout < 4) {
      scenario = 3;
    } else {
      scenario = 1;
    }

    setState(() {
      _userScenario = scenario;
      _streakCount = streakCount;
      _todayAccuracy = todayAccuracy;
      _missedDays = missedDays;
      _userName = userName;
    });
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
            // <--- DEĞİŞTİRİLDİ: Statik isim yerine Firebase'den dinamik isim çekiyoruz
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser?.uid)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Text(
                    "Merhaba, ...",
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  );
                }

                if (snapshot.hasData && snapshot.data!.exists) {
                  String firstName = snapshot.data!['firstName'] ?? "Yolcu";
                  return Text(
                    "Merhaba, $firstName",
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  );
                }

                // Hata veya veri yoksa arkadaşının lokal _userName'ini yedek olarak kullanıyoruz
                return Text(
                  _userName.isEmpty ? "Merhaba!" : "Merhaba, $_userName",
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                );
              },
            ),
            const Text(
              "Bugün kendini nasıl hissediyorsun?",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
        actions: [
          // <--- DEĞİŞTİRİLDİ: Sadece resim yerine tıklanabilir ve Profil Sayfasına giden buton yapıldı
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
    // SENARYO 0: İLK KEZ GİRİŞ
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
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OnboardingScreen(),
                  ),
                );
                // Onboarding'den dönünce senaryo güncelle
                _loadScenario();
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

    // SENARYO 1: GÜNLÜK EGZERSİZ HENÜZ YAPILMADI
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

    // SENARYO 2: GÜNLÜK EGZERSİZ BİTTİ
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

    // SENARYO 3: STREAK BOZULDU
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
        // Ana sayfaya geçince senaryoyu yenile
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
