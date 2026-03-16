import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/welcome_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Daha önce giriş yapılmış mı kontrol et
  final prefs = await SharedPreferences.getInstance();
  final bool isLoggedIn = prefs.getBool('is_logged_in') ?? false;

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: isLoggedIn
          ? const MainHealthScreen()   // Daha önce giriş yaptıysa direkt ana sayfa
          : const HealthAppWelcomeScreen(), // İlk kez açılıyorsa giriş ekranı
    ),
  );
}