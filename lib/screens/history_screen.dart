import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Color _primaryGreen = Color(0xFF4A6849);
const Color _backgroundBeige = Color(0xFFFDFCF4);
const Color _cardBeige = Color(0xFFF2F0E4);
const Color _textDark = Color(0xFF2C3E2C);
const Color _warningText = Color(0xFFB45454);

// --- GEÇMİŞ VERİ MODELİ ---
class WorkoutHistory {
  final String programName;
  final DateTime date;
  final int accuracyRate;
  final bool cameraEnabled;
  final int totalReps;

  WorkoutHistory({
    required this.programName,
    required this.date,
    required this.accuracyRate,
    required this.cameraEnabled,
    required this.totalReps,
  });

  // JSON'a çevir (kaydetmek için)
  Map<String, dynamic> toJson() => {
    'programName': programName,
    'date': date.toIso8601String(),
    'accuracyRate': accuracyRate,
    'cameraEnabled': cameraEnabled,
    'totalReps': totalReps,
  };

  // JSON'dan oku
  factory WorkoutHistory.fromJson(Map<String, dynamic> json) => WorkoutHistory(
    programName: json['programName'] as String,
    date: DateTime.parse(json['date'] as String),
    accuracyRate: json['accuracyRate'] as int,
    cameraEnabled: json['cameraEnabled'] as bool,
    totalReps: json['totalReps'] as int,
  );
}

// --- GEÇMİŞ KAYDETME/OKUMA SERVİSİ ---
class WorkoutHistoryService {
  static const String _key = 'workout_history';

  // Tüm geçmişi oku
  static Future<List<WorkoutHistory>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw.map((e) => WorkoutHistory.fromJson(jsonDecode(e))).toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // En yeni önce
  }

  // Yeni egzersiz kaydet
  static Future<void> saveWorkout(WorkoutHistory history) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    raw.add(jsonEncode(history.toJson()));
    await prefs.setStringList(_key, raw);
  }

  // Geçmişi temizle
  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

// --- GEÇMİŞ EKRANI ---
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<WorkoutHistory> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history = await WorkoutHistoryService.getHistory();
    if (mounted) {
      setState(() {
        _history = history;
        _isLoading = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;
    if (diff == 0) return 'Bugün';
    if (diff == 1) return 'Dün';
    const days = [
      'Pazartesi',
      'Salı',
      'Çarşamba',
      'Perşembe',
      'Cuma',
      'Cumartesi',
      'Pazar',
    ];
    final dayName = days[date.weekday - 1];
    return '$dayName, ${date.day}.${date.month}.${date.year}';
  }

  Color _accuracyColor(int rate, bool cameraEnabled) {
    if (!cameraEnabled) return Colors.grey;
    if (rate == 0) return _warningText;
    if (rate < 60) return Colors.orange;
    if (rate < 80) return Colors.amber[700]!;
    return _primaryGreen;
  }

  String _accuracyLabel(int rate, bool cameraEnabled) {
    if (!cameraEnabled) return 'Kamera Kapalı';
    if (rate >= 80) return 'Mükemmel';
    if (rate >= 60) return 'İyi';
    if (rate > 0) return 'Geliştirilmeli';
    return 'Ölçülmedi';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundBeige,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Geçmişim',
          style: TextStyle(
            color: _textDark,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: _textDark),
            onPressed: () async {
              await WorkoutHistoryService.clearHistory();
              _loadHistory();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primaryGreen))
          : _history.isEmpty
          ? _buildEmpty()
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 4),
                  _buildSummaryCard(),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Text(
                        'Egzersiz Kayıtları',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: _textDark,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_history.length} kayıt',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.separated(
                      itemCount: _history.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _buildHistoryCard(_history[index]);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard() {
    final cameraOnes = _history.where((h) => h.cameraEnabled).toList();
    final avgAccuracy = cameraOnes.isEmpty
        ? 0
        : cameraOnes.map((h) => h.accuracyRate).reduce((a, b) => a + b) ~/
              cameraOnes.length;
    final totalReps = _history.map((h) => h.totalReps).fold(0, (a, b) => a + b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _primaryGreen,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _summaryItem(
            '${_history.length}',
            'Toplam\nSeans',
            Icons.calendar_today_rounded,
          ),
          _verticalDivider(),
          _summaryItem(
            '%$avgAccuracy',
            'Ort.\nDoğruluk',
            Icons.track_changes_rounded,
          ),
          _verticalDivider(),
          _summaryItem('$totalReps', 'Toplam\nTekrar', Icons.repeat_rounded),
        ],
      ),
    );
  }

  Widget _summaryItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _verticalDivider() {
    return Container(
      height: 50,
      width: 1,
      color: Colors.white.withOpacity(0.2),
    );
  }

  Widget _buildHistoryCard(WorkoutHistory item) {
    final color = _accuracyColor(item.accuracyRate, item.cameraEnabled);
    final label = _accuracyLabel(item.accuracyRate, item.cameraEnabled);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBeige, width: 1.5),
      ),
      child: Row(
        children: [
          // Doğruluk göstergesi
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.3), width: 2),
            ),
            child: Center(
              child: Text(
                item.cameraEnabled ? '%${item.accuracyRate}' : '%0',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Program adı ve tarih
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.programName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: _textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 12,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(item.date),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.repeat_rounded,
                      size: 12,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${item.totalReps} tekrar',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Sağ: durum etiketi + kamera ikonu
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Icon(
                item.cameraEnabled
                    ? Icons.videocam_rounded
                    : Icons.videocam_off_rounded,
                size: 16,
                color: item.cameraEnabled ? _primaryGreen : Colors.grey[400],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'Henüz kayıt yok',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'İlk egzersizini yaptıktan sonra\nburada görünecek.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
