import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'welcome_screen.dart'; // <--- Çıkış yapınca döneceğimiz ekran

// --- RENK PALETİ (Senin Ana Sayfa Kodundan Alınan Renkler) ---
// Bu renkleri profil sayfasında da kullanmak için buraya kopyaladım.
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

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Verileri Firestore'dan okuyup saklayacağımız değişkenler
  String _firstName = "";
  String _lastName = "";
  String _email = "";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData(); // <--- Ekran açılınca verileri çek
  }

  Future<void> _fetchUserData() async {
    try {
      // 1. Mevcut kullanıcının UID'sini al
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // 2. O UID'ye ait Firestore dokümanını oku
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          // 3. Verileri değişkenlere ata
          if (mounted) {
            setState(() {
              _firstName = doc['firstName'];
              _lastName = doc['lastName'];
              _email = doc['email'];
              _isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Kullanıcı verileri çekilemedi.")),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  // --- Çıkış Yapma Fonksiyonu ---
  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      // Çıkış yaptıktan sonra welcome_screen'e geri dönerken navigasyon stack'ini temizliyoruz.
      // pushReplacement/popUntil yerine en temiz yol budur.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HealthAppWelcomeScreen()),
        (Route<dynamic> route) =>
            false, // Geri butonu stack'teki tüm ekranları silsin
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors
          .backgroundBeige, // <--- Hafif krem arkaplan (Ana Screen ile uyumlu)
      // --- ÜST KISIM (APP BAR / HEADER) ---
      appBar: AppBar(
        title: const Text(
          "Hesap Detayları",
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent, // Clinical teal yerine şeffaf
        elevation: 0,
        iconTheme: const IconThemeData(
          color: AppColors.primaryGreen,
        ), // Geri butonu orman yeşili
      ),

      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen),
            )
          : Padding(
              padding: const EdgeInsets.all(25.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- Profil Fotoğrafı (Büyük, Senin Tasarım Dilin) ---
                  Center(
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: AppColors.lightGreen.withOpacity(
                        0.3,
                      ), // Hafif bej arkaplan
                      child: Icon(
                        Icons.person,
                        size: 70,
                        color: AppColors.primaryGreen,
                      ), // Orman yeşili ikonu
                    ),
                  ),
                  const SizedBox(height: 40),

                  // --- Hesap Detayları Kartı (Clinical cyan yerine subtle kartlar) ---
                  _buildDetailCard(
                    context,
                    title: "Ad Soyad",
                    value: "$_firstName $_lastName", // Dinamik isim-soyad
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 15),
                  _buildDetailCard(
                    context,
                    title: "E-posta",
                    value: _email, // Dinamik e-posta
                    icon: Icons.email_outlined,
                  ),
                  const SizedBox(height: 15),
                  _buildDetailCard(
                    context,
                    title: "Şifre",
                    value: "********", // Şifreyi göstermek güvenli değil
                    icon: Icons.lock_outline,
                  ),

                  const Spacer(), // <--- Kalan tüm boşluğu kapla
                  // --- ÇIKIŞ YAP BUTONU ---
                  SizedBox(
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: _signOut,
                      icon: const Icon(
                        Icons.logout_rounded,
                        color: Colors.white,
                      ),
                      label: const Text(
                        "ÇIKIŞ YAP",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors
                            .warningText, // Kırmızı clinical çıkış butonu yerine soft kırmızı
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildDetailCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors
            .cardBeige, // <--- Clinical card yerine subtle koyu bej kart
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: AppColors.primaryGreen.withOpacity(0.3),
          width: 1.5,
        ), // Subtle yeşil sınır
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.backgroundBeige, // Hafif krem arkaplan
            child: Icon(
              icon,
              color: AppColors.primaryGreen,
              size: 24,
            ), // Orman yeşili ikonu
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ), // Koyu yeşilimsi siyah yazı
            ],
          ),
        ],
      ),
    );
  }
}
