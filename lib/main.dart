import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // <--- EKLENDİ: Firebase Auth
import 'firebase_options.dart';
import 'screens/welcome_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  // 1. Flutter motorunu başlat
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Firebase'i başlat
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // 3. KRİTİK DEĞİŞİKLİK: SharedPreferences yerine Firebase'in canlı durumunu dinliyoruz
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Firebase bağlantıyı kontrol ederken yükleme ekranı göster
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFF4A6849)),
              ),
            );
          }

          // Eğer Firebase'de geçerli bir kullanıcı varsa ANA SAYFAYA git
          if (snapshot.hasData && snapshot.data != null) {
            return const MainHealthScreen();
          }

          // Kullanıcı yoksa, silinmişse veya token düştüyse GİRİŞ EKRANINA git
          return const HealthAppWelcomeScreen();
        },
      ),
    );
  }
}
