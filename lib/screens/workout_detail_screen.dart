import 'package:flutter/material.dart';

// Ana sayfadaki renkleri kullanmak için (İstersen buraya da AppColors sınıfını taşıyabiliriz)
// Şimdilik manuel yazıyorum uyum için.
const Color primaryGreen = Color(0xFF4A6849);
const Color backgroundBeige = Color(0xFFFDFCF4);

class WorkoutDetailScreen extends StatelessWidget {
  const WorkoutDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundBeige,
      body: CustomScrollView(
        slivers: [
          // 1. ESNEK BAŞLIK (Resimli Kısım)
          SliverAppBar(
            expandedHeight: 250.0,
            pinned: true, // Yukarı kaydırınca bar sabit kalsın mı?
            backgroundColor: primaryGreen,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                "Gün 1: Başlangıç",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Image.network(
                "https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?auto=format&fit=crop&w=1000&q=80",
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 2. İÇERİK KISMI
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bilgi Kartları (Süre, Kalori vb.)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _infoBadge(Icons.timer, "15 Dk"),
                      _infoBadge(Icons.local_fire_department, "120 Kal"),
                      _infoBadge(Icons.fitness_center, "Kolay"),
                    ],
                  ),
                  const SizedBox(height: 25),

                  const Text(
                    "Hareketler",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E2C),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Hareket Listesi
                  _exerciseItem(
                    "1. Isınma & Esneme",
                    "2 Dakika",
                    Icons.accessibility_new,
                  ),
                  _exerciseItem(
                    "2. Jumping Jacks",
                    "30 Saniye",
                    Icons.directions_run,
                  ),
                  _exerciseItem(
                    "3. Squat (Çömelme)",
                    "12 Tekrar",
                    Icons.airline_seat_legroom_extra,
                  ),
                  _exerciseItem("4. Plank", "30 Saniye", Icons.landscape),
                  _exerciseItem("5. Soğuma", "2 Dakika", Icons.spa),

                  const SizedBox(height: 30),

                  // Başla Butonu
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () {
                        // Video oynatıcı veya zamanlayıcıya gidecek
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Egzersiz Başlatılıyor..."),
                          ),
                        );
                      },
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

  // Yardımcı Widget: Bilgi Kutucuğu
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
              color: Color(0xFF2C3E2C),
            ),
          ),
        ],
      ),
    );
  }

  // Yardımcı Widget: Hareket Satırı
  Widget _exerciseItem(String title, String subtitle, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
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
              color: backgroundBeige,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: primaryGreen),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                subtitle,
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
}
