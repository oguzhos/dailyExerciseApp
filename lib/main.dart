import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart'; // <--- EKLENDİ
import 'firebase_options.dart'; // <--- EKLENDİ
import 'screens/welcome_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  // 1. Flutter motorunu başlat
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Firebase'i başlat (Hatanın asıl ilacı burası kral)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 3. Daha önce giriş yapılmış mı kontrol et (Arkadaşının mantığı)
  final prefs = await SharedPreferences.getInstance();
  final bool isLoggedIn = prefs.getBool('is_logged_in') ?? false;

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      // Eğer giriş yapıldıysa Home'a, yapılmadıysa Welcome'a git
      home: isLoggedIn
          ? const MainHealthScreen()
          : const HealthAppWelcomeScreen(),
    ),
  );
}
