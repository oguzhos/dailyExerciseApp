import 'package:flutter/material.dart';
import 'screens/welcome_screen.dart';

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HealthAppWelcomeScreen(), // Giriş ekranı sınıf ismin
    ),
  );
}
