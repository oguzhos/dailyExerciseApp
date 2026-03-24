import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart'; // <--- EKLENDİ
import 'package:cloud_firestore/cloud_firestore.dart'; // <--- EKLENDİ
import 'package:google_sign_in/google_sign_in.dart'; // <--- EKLENDİ
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart'; // <--- EKLENDİ
import 'home_screen.dart';

// --- ANA EKRAN (WELCOME SCREEN) ---
class HealthAppWelcomeScreen extends StatefulWidget {
  const HealthAppWelcomeScreen({super.key});

  @override
  State<HealthAppWelcomeScreen> createState() => _HealthAppWelcomeScreenState();
}

class _HealthAppWelcomeScreenState extends State<HealthAppWelcomeScreen> {
  bool _isLoginPanelVisible = false;
  bool _isEmailFormVisible = false;
  bool _isTermsAccepted = false;

  // <--- EKLENDİ: Firebase ve Backend Değişkenleri
  bool _isLoading = false;
  bool _isLoginMode = true;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController(); // <--- EKLENDİ
  final _lastNameController = TextEditingController(); // <--- EKLENDİ

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose(); // <--- EKLENDİ
    _lastNameController.dispose(); // <--- EKLENDİ
    super.dispose();
  }

  // --- E-Posta ile Giriş veya Kayıt İşlemi ---
  Future<void> _processEmailAuth() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isLoginMode && !_isTermsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Lütfen kullanım şartlarını kabul edin."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      if (_isLoginMode) {
        // --- GİRİŞ YAP ---
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        // --- YENİ KAYIT OL ---
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);

        String uid = userCredential.user!.uid;

        // Firestore'a kullanıcı bilgilerini kaydet
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'email': email,
          'currentStreak': 0,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // Arkadaşının eklediği SharedPreferences kaydı (Giriş yapıldı olarak işaretle)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);

      _navigateToHome();
    } on FirebaseAuthException catch (e) {
      _showError(e.code);
    } catch (e) {
      _showError("beklenmedik-hata");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- Google ile Giriş İşlemi (V7) ---
  Future<void> _signInWithGoogle() async {
    try {
      // 1. Google Giriş Akışını Başlat (V7 sürümü için instance üzerinden)
      await GoogleSignIn.instance.initialize();
      final GoogleSignInAccount? googleUser = await GoogleSignIn.instance
          .authenticate();

      if (googleUser == null) return; // Kullanıcı vazgeçerse çık

      // 2. Google'dan Kimlik Bilgilerini Al
      // NOT: Yeni sürümde authentication artık bir Future değil, direkt erişiliyor.
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // Firebase için gerekli olan idToken'ı kullanıyoruz
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // 3. Firebase ile Giriş Yap
      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        // 4. Firestore'da kullanıcı dökümanı var mı kontrol et
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (!userDoc.exists) {
          // İlk kez geliyorsa Google bilgilerini Firestore'a kaydet
          List<String> nameParts = (user.displayName ?? "Değerli Kullanıcı")
              .split(" ");
          String firstName = nameParts.first;
          String lastName = nameParts.length > 1
              ? nameParts.sublist(1).join(" ")
              : "";

          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
                'firstName': firstName,
                'lastName': lastName,
                'email': user.email,
                'createdAt': FieldValue.serverTimestamp(),
                'authType': 'google',
              });
        }

        // 5. SharedPreferences kaydı (Giriş durumu takibi için)
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_logged_in', true);

        // 6. Ana Sayfaya Yönlendir
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainHealthScreen()),
          );
        }
      }
    } catch (e) {
      print("Google Giriş Hatası: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Giriş yapılamadı: $e")));
      }
    }
  }

  // --- Facebook ile Giriş İşlemi ---
  Future<void> _signInWithFacebook() async {
    setState(() => _isLoading = true);
    try {
      final LoginResult result = await FacebookAuth.instance.login();
      if (result.status == LoginStatus.success) {
        final credential = FacebookAuthProvider.credential(
          result.accessToken!.tokenString,
        );
        await FirebaseAuth.instance.signInWithCredential(credential);

        // Arkadaşının eklediği SharedPreferences kaydı
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_logged_in', true);

        _navigateToHome();
      } else if (result.status == LoginStatus.cancelled) {
        // İptal edildi
      } else {
        _showError("facebook-hata");
      }
    } catch (e) {
      _showError("facebook-hata");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToHome() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainHealthScreen()),
      );
    }
  }

  void _showError(String errorCode) {
    if (!mounted) return;
    String errorMessage = "Bir hata oluştu. Lütfen tekrar deneyin.";

    if (errorCode == 'user-not-found')
      errorMessage = "Bu e-posta ile kayıtlı kullanıcı bulunamadı.";
    else if (errorCode == 'wrong-password' || errorCode == 'invalid-credential')
      errorMessage = "Hatalı şifre veya e-posta girdiniz.";
    else if (errorCode == 'email-already-in-use')
      errorMessage = "Bu e-posta adresi zaten kullanımda.";
    else if (errorCode == 'google-hata')
      errorMessage = "Google ile giriş yapılamadı.";
    else if (errorCode == 'facebook-hata')
      errorMessage = "Facebook ile giriş yapılamadı.";
    else if (errorCode == 'beklenmedik-hata')
      errorMessage = "Sunucu bağlantı hatası oluştu.";

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    // <--- DİNAMİK YÜKSEKLİK: Kayıt modu açıksa formu uzat
    final double targetHeight = _isEmailFormVisible
        ? (_isLoginMode ? 0.55 : 0.70)
        : 0.35;
    final double loginPanelHeight = screenHeight * targetHeight;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. KATMAN: Arkaplan Görseli
          Image.network(
            'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?ixlib=rb-4.0.3&auto=format&fit=crop&w=1520&q=80',
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: const Color(0xFF4A6849),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              );
            },
          ),

          // 2. KATMAN: Karartma
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.15),
                  Colors.black.withOpacity(0.75),
                ],
                stops: const [0.3, 1.0],
              ),
            ),
          ),

          // 3. KATMAN: Ana Başlıklar (ORTALANMIŞ - Arkadaşının Tasarımı)
          AnimatedOpacity(
            duration: const Duration(milliseconds: 400),
            opacity: _isLoginPanelVisible ? 0.0 : 1.0,
            child: Positioned(
              top: 0,
              left: 30,
              right: 30,
              bottom: 150,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: const [
                  Text(
                    "Kendine İyi Bak.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 1.1,
                    ),
                  ),
                  SizedBox(height: 15),
                  Text(
                    "Evinin huzurunda, bedeninle barışık,\ndaha sağlıklı bir yaşama adım at.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 17,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. KATMAN: Kaydırma Göstergesi (Ekranın ALT YARISI)
          if (!_isLoginPanelVisible)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: screenHeight * 0.5,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onVerticalDragUpdate: (details) {
                  if (details.primaryDelta! < -5) {
                    setState(() {
                      _isLoginPanelVisible = true;
                    });
                  }
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      height: 150,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.8),
                          ],
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(
                            Icons.keyboard_arrow_up_rounded,
                            color: Colors.white.withOpacity(0.8),
                            size: 30,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "Başlamak için yukarı kaydır",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 5. KATMAN: Animasyonlu Giriş Paneli
          AnimatedPositioned(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
            bottom: _isLoginPanelVisible ? 0 : -loginPanelHeight,
            left: 0,
            right: 0,
            height: loginPanelHeight,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onVerticalDragUpdate: (details) {
                if (details.primaryDelta! > 5) {
                  setState(() {
                    _isLoginPanelVisible = false;
                    _isEmailFormVisible = false;
                    _firstNameController.clear();
                    _lastNameController.clear();
                    _emailController.clear();
                    _passwordController.clear();
                    FocusScope.of(context).unfocus();
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 25,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 20,
                      offset: Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: _isEmailFormVisible
                          ? _buildEmailSignUpForm()
                          : _buildSocialSelectionButtons(),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // <--- EKLENDİ: Yükleme Ekranı Overlay
          if (_isLoading && !_isEmailFormVisible)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.teal),
              ),
            ),
        ],
      ),
    );
  }

  // --- 1. GÖRÜNÜM: Sosyal Medya Seçenekleri ---
  Widget _buildSocialSelectionButtons() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "Hesabını Oluştur veya Giriş Yap",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 25),
        _buildFullWidthSocialButton(
          icon: Icons.email_outlined,
          color: Colors.grey[800]!,
          label: "E-posta ile devam et",
          onTap: () {
            setState(() {
              _isEmailFormVisible = true;
            });
          },
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: _buildSocialButton(
                icon: Icons.g_mobiledata_rounded,
                color: const Color(0xFFDB4437),
                label: "Google",
                onTap: _signInWithGoogle, // <--- Dinamik fonksiyon
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildSocialButton(
                icon: Icons.facebook,
                color: const Color(0xFF4267B2),
                label: "Facebook",
                onTap: _signInWithFacebook, // <--- Dinamik fonksiyon
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- 2. GÖRÜNÜM: E-posta Kayıt/Giriş Formu ---
  Widget _buildEmailSignUpForm() {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    setState(() {
                      _isEmailFormVisible = false;
                      _firstNameController.clear();
                      _lastNameController.clear();
                      _emailController.clear();
                      _passwordController.clear();
                      FocusScope.of(context).unfocus();
                    });
                  },
                ),
                const SizedBox(width: 10),
                Text(
                  _isLoginMode
                      ? "Giriş Yap"
                      : "Kayıt Ol", // <--- Dinamik Başlık
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // <--- EKLENDİ: Ad ve Soyad Alanları (Sadece Kayıt modunda görünür)
            if (!_isLoginMode)
              Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _firstNameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.person_outline),
                          labelText: "Ad",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 15,
                          ),
                        ),
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Gerekli' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _lastNameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.person_outline),
                          labelText: "Soyad",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 15,
                          ),
                        ),
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Gerekli' : null,
                      ),
                    ),
                  ],
                ),
              ),

            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.email_outlined),
                labelText: "E-posta Adresi",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Lütfen e-posta adresinizi girin';
                }
                if (!value.contains('@')) {
                  return 'Geçerli bir e-posta adresi girin';
                }
                return null;
              },
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.lock_outline),
                labelText: "Şifre",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Lütfen bir şifre belirleyin';
                }
                if (value.length < 6) {
                  return 'Şifre en az 6 karakter olmalı';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // <--- GÜNCELLENDİ: Sadece Kayıt Modundayken Şartlar Çıksın
            if (!_isLoginMode)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: InkWell(
                  onTap: () => _openTermsModal(),
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: _isTermsAccepted,
                          activeColor: Colors.teal,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          onChanged: (val) => _openTermsModal(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            text: "Kullanım Şartları",
                            style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                            children: [
                              TextSpan(
                                text: " ve ",
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  decoration: TextDecoration.none,
                                ),
                              ),
                              const TextSpan(
                                text: "Gizlilik Politikası",
                                style: TextStyle(
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              TextSpan(
                                text: "'nı okudum ve kabul ediyorum.",
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            SizedBox(
              height: 50,
              child: ElevatedButton(
                // Login modundaysa veya şartlar kabul edildiyse butonu aktif et
                onPressed: (_isLoginMode || _isTermsAccepted) && !_isLoading
                    ? _processEmailAuth
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal[600],
                  disabledBackgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        _isLoginMode ? "GİRİŞ YAP" : "KAYDI TAMAMLA", // Dinamik
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            // <--- EKLENDİ: Giriş Yap / Kayıt Ol Geçiş Butonu
            TextButton(
              onPressed: () {
                setState(() {
                  _isLoginMode = !_isLoginMode;
                  _formKey.currentState?.reset();
                  _firstNameController.clear();
                  _lastNameController.clear();
                });
              },
              child: Text(
                _isLoginMode
                    ? "Hesabın yok mu? Hemen kayıt ol."
                    : "Zaten hesabın var mı? Giriş yap.",
                style: const TextStyle(
                  color: Colors.teal,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 20),
          ],
        ),
      ),
    );
  }

  Future<void> _openTermsModal() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const TermsAndConditionsModal(),
    );

    if (result == true) {
      setState(() {
        _isTermsAccepted = true;
      });
    }
  }

  Widget _buildFullWidthSocialButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 15),
        side: BorderSide(color: color.withOpacity(0.3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      icon: Icon(icon, size: 22),
      label: Text(
        label,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- ŞARTLAR VE KOŞULLAR MODALİ ---
class TermsAndConditionsModal extends StatefulWidget {
  const TermsAndConditionsModal({super.key});

  @override
  State<TermsAndConditionsModal> createState() =>
      _TermsAndConditionsModalState();
}

class _TermsAndConditionsModalState extends State<TermsAndConditionsModal> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolledToBottom = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 20) {
      if (!_isScrolledToBottom) {
        setState(() {
          _isScrolledToBottom = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Container(
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  "Kullanım Şartları ve Gizlilik",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Text(
                  "Onaylamak için sonuna kadar okuyun.",
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(25.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Sağlık Uygulaması Sözleşmesi",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ...List.generate(
                    12,
                    (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 18.0),
                      child: Text(
                        "Madde ${index + 1}: Bu uygulama genel sağlık önerileri sunar. Kullanıcı, sunulan bilgilerin tıbbi teşhis yerine geçmediğini kabul eder. Şifrenizin güvenliğinden siz sorumlusunuz. Verileriniz KVKK kapsamında korunmaktadır. Bu metin, okuma zorunluluğunu test etmek amacıyla uzun tutulmuştur. Lütfen onay butonunun aktif olması için aşağı kaydırmaya devam edin.",
                        style: TextStyle(
                          color: Colors.grey[800],
                          height: 1.6,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Center(
                    child: Text(
                      "--- Şartların Sonu ---",
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, -4),
                  blurRadius: 10,
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isScrolledToBottom
                    ? () {
                        Navigator.pop(context, true);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal[400],
                  disabledBackgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  _isScrolledToBottom
                      ? "OKUDUM VE KABUL EDİYORUM"
                      : "SONUNA KADAR KAYDIRIN",
                  style: TextStyle(
                    color: _isScrolledToBottom
                        ? Colors.white
                        : Colors.grey[500],
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
