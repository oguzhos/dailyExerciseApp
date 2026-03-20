import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';

// Renk paleti (home_screen.dart ile uyumlu)
class _Colors {
  static const background = Color(0xFFFDFCF4);
  static const card = Color(0xFFF2F0E4);
  static const primaryGreen = Color(0xFF4A6849);
  static const lightGreen = Color(0xFF8FA98F);
  static const textDark = Color(0xFF2C3E2C);
}

// --- ANA ONBOARDING EKRANI ---
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  // 'name': İsim girişi (YENİ - ilk adım)
  // 'main': Ana seçim (2 büyük buton)
  // 'doctor': Doktor kodu girişi
  // 'sport': Spor kategorisi seçimi
  // 'suggest': "Sen öner" serbest metin
  // 'result': Sahte AI önerileri
  String _step = 'name'; // İlk adım artık isim

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Colors.background,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          transitionBuilder: (child, animation) => SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
            child: child,
          ),
          child: _buildStep(),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 'name':
        return _NameScreen(
          key: const ValueKey('name'),
          onNext: () => setState(() => _step = 'main'),
        );
      case 'main':
        return _MainSelection(
          key: const ValueKey('main'),
          onDoctor: () => setState(() => _step = 'doctor'),
          onSport: () => setState(() => _step = 'sport'),
        );
      case 'doctor':
        return _DoctorCodeScreen(
          key: const ValueKey('doctor'),
          onBack: () => setState(() => _step = 'main'),
        );
      case 'sport':
        return _SportCategoryScreen(
          key: const ValueKey('sport'),
          onBack: () => setState(() => _step = 'main'),
          onSuggest: () => setState(() => _step = 'suggest'),
        );
      case 'suggest':
        return _SuggestScreen(
          key: const ValueKey('suggest'),
          onBack: () => setState(() => _step = 'sport'),
          onResult: (answers) => setState(() => _step = 'result'),
        );
      case 'result':
        return _SuggestionResultScreen(
          key: const ValueKey('result'),
          onBack: () => setState(() => _step = 'suggest'),
        );
      default:
        return const SizedBox();
    }
  }
}

// --- ADIM 0: İSİM GİRİŞİ ---
class _NameScreen extends StatefulWidget {
  final VoidCallback onNext;

  const _NameScreen({super.key, required this.onNext});

  @override
  State<_NameScreen> createState() => _NameScreenState();
}

class _NameScreenState extends State<_NameScreen> {
  final _controller = TextEditingController();
  bool _isValid = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          // İkon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _Colors.card,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.waving_hand_rounded,
                color: _Colors.primaryGreen, size: 40),
          ),
          const SizedBox(height: 28),
          const Text(
            "Merhaba!\nSenin adın ne?",
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: _Colors.textDark,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "Sana nasıl hitap edelim?",
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 40),

          // İsim input
          TextField(
            controller: _controller,
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: _Colors.textDark,
            ),
            decoration: InputDecoration(
              hintText: "Adını yaz...",
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: 22,
                fontWeight: FontWeight.normal,
              ),
              filled: true,
              fillColor: _Colors.card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                    color: _Colors.primaryGreen, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 18),
            ),
            onChanged: (val) {
              setState(() => _isValid = val.trim().length >= 2);
            },
          ),
          const Spacer(),

          // Devam butonu
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _isValid
                  ? () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString(
                          'user_name', _controller.text.trim());
                      widget.onNext();
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _Colors.primaryGreen,
                disabledBackgroundColor: Colors.grey[300],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                "DEVAM ET",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// --- ADIM 1: ANA SEÇİM ---
class _MainSelection extends StatelessWidget {
  final VoidCallback onDoctor;
  final VoidCallback onSport;

  const _MainSelection({
    super.key,
    required this.onDoctor,
    required this.onSport,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          // Başlık
          const Text(
            "Seni tanıyalım",
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: _Colors.textDark,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Sana en uygun programı oluşturabilmemiz için birkaç soruya ihtiyacımız var.",
            style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
          ),
          const Spacer(),

          // SEÇENEK 1: Doktor Hareketi
          _BigOptionCard(
            icon: Icons.medical_services_rounded,
            iconColor: const Color(0xFF4A7FA5),
            iconBg: const Color(0xFFE8F4FD),
            title: "Yapmam gereken\nhareketler var",
            subtitle: "Doktorumun verdiği egzersiz programını takip etmek istiyorum.",
            onTap: onDoctor,
          ),
          const SizedBox(height: 20),

          // SEÇENEK 2: Spor
          _BigOptionCard(
            icon: Icons.directions_run_rounded,
            iconColor: _Colors.primaryGreen,
            iconBg: const Color(0xFFE8F5E9),
            title: "Sağlığım için\nspor yapıyorum",
            subtitle: "Kendi hedeflerim doğrultusunda egzersiz yapmak istiyorum.",
            onTap: onSport,
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

// Büyük seçim kartı
class _BigOptionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _BigOptionCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _Colors.card, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: iconColor, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _Colors.textDark,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }
}

// --- ADIM 2A: DOKTOR KODU ---
class _DoctorCodeScreen extends StatefulWidget {
  final VoidCallback onBack;

  const _DoctorCodeScreen({super.key, required this.onBack});

  @override
  State<_DoctorCodeScreen> createState() => _DoctorCodeScreenState();
}

class _DoctorCodeScreenState extends State<_DoctorCodeScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String? _errorText;

  // Sahte doktor kodu kontrolü
  void _checkCode() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() => _errorText = 'Lütfen bir kod girin.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    // Sahte yükleme animasyonu
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    // Geçerli sahte kodlar: DR001, DR002, DEMO
    if (['DR001', 'DR002', 'DEMO'].contains(code)) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('user_scenario', 1);
      await prefs.setString('program_type', 'doctor');
      await prefs.setString('doctor_code', code); // Kodu kaydediyoruz
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      setState(() {
        _isLoading = false;
        _errorText = 'Geçersiz kod. Lütfen doktorunuzdan aldığınız kodu kontrol edin.';
      });
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          // Geri butonu
          GestureDetector(
            onTap: widget.onBack,
            child: const Row(
              children: [
                Icon(Icons.arrow_back_ios_rounded,
                    size: 18, color: _Colors.textDark),
                SizedBox(width: 4),
                Text("Geri",
                    style: TextStyle(
                        color: _Colors.textDark, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // İkon
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F4FD),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.medical_services_rounded,
                color: Color(0xFF4A7FA5), size: 36),
          ),
          const SizedBox(height: 20),

          const Text(
            "Doktor Kodunu Gir",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: _Colors.textDark,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Doktorunuzun size verdiği kodu girerek egzersiz programınızı yükleyin.",
            style: TextStyle(fontSize: 15, color: Colors.grey, height: 1.5),
          ),
          const SizedBox(height: 40),

          // Kod input
          TextField(
            controller: _codeController,
            textCapitalization: TextCapitalization.characters,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 8,
              color: _Colors.textDark,
            ),
            decoration: InputDecoration(
              hintText: "DR001",
              hintStyle: TextStyle(
                color: Colors.grey[300],
                letterSpacing: 8,
                fontSize: 28,
              ),
              errorText: _errorText,
              filled: true,
              fillColor: _Colors.card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                    color: _Colors.primaryGreen, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 20),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Test için: DR001, DR002 veya DEMO",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey[400]),
          ),
          const Spacer(),

          // Devam butonu
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _checkCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: _Colors.primaryGreen,
                disabledBackgroundColor: _Colors.lightGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text(
                      "PROGRAMI YÜKLE",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// --- ADIM 2B: SPOR KATEGORİSİ ---
class _SportCategoryScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onSuggest;

  const _SportCategoryScreen({
    super.key,
    required this.onBack,
    required this.onSuggest,
  });

  @override
  State<_SportCategoryScreen> createState() => _SportCategoryScreenState();
}

class _SportCategoryScreenState extends State<_SportCategoryScreen> {
  String? _selected;

  final List<Map<String, dynamic>> _categories = [
    {
      'id': 'weight_loss',
      'title': 'Kilo Vermek',
      'icon': Icons.monitor_weight_outlined,
      'color': const Color(0xFFE57373),
      'bg': const Color(0xFFFDEDED),
    },
    {
      'id': 'yoga',
      'title': 'Esneklik / Yoga',
      'icon': Icons.self_improvement_rounded,
      'color': const Color(0xFF7986CB),
      'bg': const Color(0xFFEEF0FB),
    },
    {
      'id': 'rehab',
      'title': 'Rehabilitasyon / Sağlık',
      'icon': Icons.favorite_border_rounded,
      'color': const Color(0xFF66BB6A),
      'bg': const Color(0xFFEDF7EE),
    },
    {
      'id': 'general',
      'title': 'Genel Fitness',
      'icon': Icons.fitness_center_rounded,
      'color': _Colors.primaryGreen,
      'bg': const Color(0xFFE8F5E9),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          GestureDetector(
            onTap: widget.onBack,
            child: const Row(
              children: [
                Icon(Icons.arrow_back_ios_rounded,
                    size: 18, color: _Colors.textDark),
                SizedBox(width: 4),
                Text("Geri",
                    style: TextStyle(
                        color: _Colors.textDark,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(height: 30),

          const Text(
            "Hedefini seç",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: _Colors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Sana en uygun programı hazırlayabiliriz.",
            style: TextStyle(fontSize: 15, color: Colors.grey),
          ),
          const SizedBox(height: 30),

          // Kategori listesi
          ...(_categories.map((cat) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _CategoryTile(
                  icon: cat['icon'] as IconData,
                  iconColor: cat['color'] as Color,
                  iconBg: cat['bg'] as Color,
                  title: cat['title'] as String,
                  isSelected: _selected == cat['id'],
                  onTap: () => setState(() => _selected = cat['id'] as String),
                ),
              ))),

          const SizedBox(height: 10),

          // "Bir fikrim yok" seçeneği
          GestureDetector(
            onTap: widget.onSuggest,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _Colors.primaryGreen.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: _Colors.primaryGreen.withOpacity(0.3), width: 1.5),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_awesome_rounded,
                      color: _Colors.primaryGreen, size: 20),
                  SizedBox(width: 10),
                  Text(
                    "Bir fikrim yok, sen öner ✨",
                    style: TextStyle(
                      color: _Colors.primaryGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Spacer(),

          // Devam butonu
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _selected == null
                  ? null
                  : () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setInt('user_scenario', 1);
                      await prefs.setString('program_type', 'sport');
                      await prefs.setString('sport_category', _selected!); // Kategoriyi kaydediyoruz
                      if (!mounted) return;
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: _Colors.primaryGreen,
                disabledBackgroundColor: Colors.grey[300],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                "DEVAM ET",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? iconBg : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? iconColor : _Colors.card,
            width: isSelected ? 2 : 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.w500,
                color: _Colors.textDark,
              ),
            ),
            const Spacer(),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isSelected ? 1.0 : 0.0,
              child: Icon(Icons.check_circle_rounded,
                  color: iconColor, size: 22),
            ),
          ],
        ),
      ),
    );
  }
}

// --- ADIM 3B: SERBEST METİN (SEN ÖNER) ---
class _SuggestScreen extends StatefulWidget {
  final VoidCallback onBack;
  final Function(String) onResult;

  const _SuggestScreen({
    super.key,
    required this.onBack,
    required this.onResult,
  });

  @override
  State<_SuggestScreen> createState() => _SuggestScreenState();
}

class _SuggestScreenState extends State<_SuggestScreen> {
  final _controller = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _analyze() async {
    if (_controller.text.trim().isEmpty) return;

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;
    setState(() => _isLoading = false);
    widget.onResult(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          GestureDetector(
            onTap: widget.onBack,
            child: const Row(
              children: [
                Icon(Icons.arrow_back_ios_rounded,
                    size: 18, color: _Colors.textDark),
                SizedBox(width: 4),
                Text("Geri",
                    style: TextStyle(
                        color: _Colors.textDark,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(height: 30),

          const Icon(Icons.auto_awesome_rounded,
              color: _Colors.primaryGreen, size: 40),
          const SizedBox(height: 16),

          const Text(
            "Seni dinliyorum",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: _Colors.textDark,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Kendini nasıl hissediyorsun? Hangi alanda gelişmek istiyorsun? Dilediğin gibi anlat.",
            style: TextStyle(fontSize: 15, color: Colors.grey, height: 1.5),
          ),
          const SizedBox(height: 30),

          // Serbest metin alanı
          Expanded(
            child: TextField(
              controller: _controller,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: const TextStyle(
                fontSize: 16,
                color: _Colors.textDark,
                height: 1.6,
              ),
              decoration: InputDecoration(
                hintText:
                    "Örn: Son zamanlarda sırt ağrım var, biraz esnemek istiyorum. Fazla yorulmadan başlamak istiyorum...",
                hintStyle: TextStyle(color: Colors.grey[400], height: 1.6),
                filled: true,
                fillColor: _Colors.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                      color: _Colors.primaryGreen, width: 2),
                ),
                contentPadding: const EdgeInsets.all(20),
              ),
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _analyze,
              style: ElevatedButton.styleFrom(
                backgroundColor: _Colors.primaryGreen,
                disabledBackgroundColor: _Colors.lightGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isLoading
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text("Analiz ediliyor...",
                            style: TextStyle(color: Colors.white)),
                      ],
                    )
                  : const Text(
                      "ÖNERİLERİ GÖSTER",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// --- ADIM 4B: SAHTE AI ÖNERİLERİ ---
class _SuggestionResultScreen extends StatelessWidget {
  final VoidCallback onBack;

  const _SuggestionResultScreen({super.key, required this.onBack});

  // Sahte öneri listesi
  static const List<Map<String, dynamic>> _suggestions = [
    {
      'title': 'Sabah Esneme Rutini',
      'desc': '10 dakikalık hafif esneme hareketleri ile güne başla.',
      'duration': '10 dk',
      'level': 'Kolay',
      'icon': Icons.wb_sunny_outlined,
      'color': Color(0xFFFFB74D),
    },
    {
      'title': 'Sırt & Boyun Rahatlatma',
      'desc': 'Masa başı çalışanlara özel boyun ve sırt egzersizleri.',
      'duration': '15 dk',
      'level': 'Kolay',
      'icon': Icons.accessibility_new_rounded,
      'color': Color(0xFF66BB6A),
    },
    {
      'title': 'Nefes & Denge',
      'desc': 'Zihin ve bedeni dinginleştiren nefes teknikleri.',
      'duration': '12 dk',
      'level': 'Başlangıç',
      'icon': Icons.self_improvement_rounded,
      'color': Color(0xFF7986CB),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          GestureDetector(
            onTap: onBack,
            child: const Row(
              children: [
                Icon(Icons.arrow_back_ios_rounded,
                    size: 18, color: _Colors.textDark),
                SizedBox(width: 4),
                Text("Geri",
                    style: TextStyle(
                        color: _Colors.textDark,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(height: 30),

          const Text(
            "Senin için öneriler ✨",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: _Colors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Anlattıklarına göre şu programları öneririm:",
            style: TextStyle(fontSize: 15, color: Colors.grey),
          ),
          const SizedBox(height: 24),

          // Öneri kartları
          ...(_suggestions.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _Colors.card, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (s['color'] as Color).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(s['icon'] as IconData,
                            color: s['color'] as Color, size: 26),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s['title'] as String,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: _Colors.textDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              s['desc'] as String,
                              style: const TextStyle(
                                  fontSize: 13, color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _chip(s['duration'] as String,
                                    Icons.timer_outlined),
                                const SizedBox(width: 8),
                                _chip(s['level'] as String,
                                    Icons.bar_chart_rounded),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ))),

          const Spacer(),

          // Programı onayla butonu
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setInt('user_scenario', 1);
                await prefs.setString('program_type', 'suggested');
                if (!context.mounted) return;
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _Colors.primaryGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                "PROGRAMI ONAYLA VE BAŞLA",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _chip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _Colors.card,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: Colors.grey),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }
}