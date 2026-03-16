import 'package:flutter/material.dart';

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MainHealthScreen(),
    ),
  );
}

// --- RENK PALETİ (Sakin Doğa Tonları) ---
class AppColors {
  static const Color backgroundBeige = Color(0xFFFDFCF4); // Çok açık krem/bej
  static const Color cardBeige = Color(0xFFF2F0E4); // Kartlar için koyu bej
  static const Color primaryGreen = Color(
    0xFF4A6849,
  ); // Orman yeşili (Ana renk)
  static const Color lightGreen = Color(0xFF8FA98F); // Açık yeşil (Vurgular)
  static const Color textDark = Color(
    0xFF2C3E2C,
  ); // Koyu yeşilimsi siyah (Yazılar)
  static const Color warningText = Color(
    0xFFB45454,
  ); // Uyarılar için soft kırmızı
}

class MainHealthScreen extends StatefulWidget {
  const MainHealthScreen({super.key});

  @override
  State<MainHealthScreen> createState() => _MainHealthScreenState();
}

class _MainHealthScreenState extends State<MainHealthScreen> {
  // Alt Menü Seçimi (1 = Ortadaki Ana Sayfa)
  int _selectedIndex = 1;

  // --- SENARYO SİMÜLASYONU DEĞİŞKENLERİ ---
  // Bu değişkenleri backend gelene kadar durumu taklit etmek için kullanıyoruz.
  // 0: İlk Kez Giriş (Hiç veri yok)
  // 1: Günlük Egzersiz Yapılmadı (Bekliyor)
  // 2: Günlük Egzersiz Bitti (%85 Doğruluk)
  // 3: Streak Bozuldu (3 gündür yok)
  int _userScenario = 0;
  int _streakCount = 0; // Mevcut seri

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBeige,

      // --- ÜST KISIM (APP BAR / HEADER) ---
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
          // Profil Resmi veya İkonu
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: CircleAvatar(
              backgroundColor: AppColors.lightGreen.withOpacity(0.3),
              child: const Icon(Icons.person, color: AppColors.primaryGreen),
            ),
          ),
        ],
      ),

      // --- GÖVDE ---
      body: Column(
        children: [
          // GELİŞTİRİCİ TEST PANELİ (Senaryoları görmek için)
          // *Bu kısmı canlıya alırken sileceğiz*
          Container(
            height: 40,
            color: Colors.black12,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _devButton("1. İlk Giriş", 0, 0),
                _devButton("2. Yapılmadı", 1, 5),
                _devButton("3. Bitti", 2, 6), // 6. güne geçti
                _devButton("4. Bozuldu", 3, 0),
              ],
            ),
          ),

          Expanded(
            child: _selectedIndex == 1
                ? _buildHomeContent() // Ana Sayfa İçeriği
                : Center(
                    child: Text(
                      _selectedIndex == 0 ? "Egzersiz Listesi" : "Geçmiş",
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
          ),
        ],
      ),

      // --- ALT MENÜ (BOTTOM NAVIGATION) ---
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
                ), // Ortada
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

  // --- ANA SAYFA İÇERİĞİ ---
  Widget _buildHomeContent() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),

          // 1. DURUM KARTI (En önemli kısım burası)
          Expanded(flex: 3, child: _buildDynamicStatusCard()),

          const SizedBox(height: 20),

          // 2. STREAK (SERİ) SAYACI (En altta)
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
                // Küçük bir motive edici grafik veya ikon
                CircularProgressIndicator(
                  value: _streakCount > 0 ? 0.7 : 0.0, // Temsili doluluk
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

  // --- DİNAMİK DURUM KARTI MANTIĞI ---
  Widget _buildDynamicStatusCard() {
    // SENARYO 0: İLK KEZ GİRİŞ (HİÇ VERİ YOK)
    if (_userScenario == 0) {
      return Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: AppColors.primaryGreen, // Dikkat çekici olsun diye koyu yeşil
          borderRadius: BorderRadius.circular(30),
          image: const DecorationImage(
            image: NetworkImage(
              "https://images.unsplash.com/photo-1518611012118-696072aa579a?auto=format&fit=crop&w=800&q=80",
            ), // Doğa/Spor görseli
            fit: BoxFit.cover,
            opacity: 0.2, // Yazılar okunsun diye görseli soluklaştırıyoruz
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
              onPressed: () {
                // Egzersiz sayfasına yönlendirme veya başlatma
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
              onPressed: () {},
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

    // SENARYO 2: GÜNLÜK EGZERSİZ BİTTİ (BAŞARILI)
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
            // Doğruluk Oranı Kartı
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
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Doğruluk Oranı:", style: TextStyle(color: Colors.grey)),
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

    // SENARYO 3: STREAK BOZULDU (X GÜNDÜR YAPMIYORSUNUZ)
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
              "3 gündür egzersiz yapmıyorsunuz.", // Buradaki sayı dinamik olacak
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
              onPressed: () {
                // Telafi egzersizi başlat
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

    return const SizedBox(); // Default boş
  }

  // --- ALT MENÜ BUTON TASARIMI ---
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

  // TEST BUTONU YARDIMCISI (GELİŞTİRİCİ İÇİN)
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
