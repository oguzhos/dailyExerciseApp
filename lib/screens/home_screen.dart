import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'onboarding_screen.dart';
import 'workout_detail_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _loadScenario();
  }

  // SharedPreferences'tan senaryo yükle
  Future<void> _loadScenario() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userScenario = prefs.getInt('user_scenario') ?? 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBeige,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Merhaba, Oğuz",
              style: TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            Text(
              "Bugün kendini nasıl hissediyorsun?",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: CircleAvatar(
              backgroundColor: AppColors.lightGreen.withOpacity(0.3),
              child: const Icon(Icons.person, color: AppColors.primaryGreen),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // GELİŞTİRİCİ TEST PANELİ
          Container(
            height: 40,
            color: Colors.black12,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _devButton("1. İlk Giriş", 0, 0),
                _devButton("2. Yapılmadı", 1, 5),
                _devButton("3. Bitti", 2, 6),
                _devButton("4. Bozuldu", 3, 0),
              ],
            ),
          ),
          Expanded(
            child: _selectedIndex == 1
                ? _buildHomeContent()
                : _selectedIndex == 0
                    ? const WorkoutDetailScreen() // Egzersizlerim sekmesi
                    : Center(
                        child: Text(
                          "Geçmiş",
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
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
                          color:
                              _streakCount > 0 ? Colors.orange : Colors.grey,
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
                  value: _streakCount > 0 ? 0.7 : 0.0,
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
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 10)
                ],
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
          border:
              Border.all(color: AppColors.primaryGreen.withOpacity(0.3)),
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Doğruluk Oranı:",
                      style: TextStyle(color: Colors.grey)),
                  SizedBox(width: 10),
                  Text(
                    "%85",
                    style: TextStyle(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Hareketlerin %85'ini doğru yaptınız.",
              style: TextStyle(fontSize: 12, color: Colors.grey),
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
            const Text(
              "3 gündür egzersiz yapmıyorsunuz.",
              textAlign: TextAlign.center,
              style: TextStyle(
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
              onPressed: () {},
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
              color:
                  isSelected ? AppColors.primaryGreen : Colors.grey[400],
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

  Widget _devButton(String label, int scenario, int streak) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _userScenario = scenario;
            _streakCount = streak;
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black87,
          padding: const EdgeInsets.symmetric(horizontal: 10),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.white),
        ),
      ),
    );
  }
}