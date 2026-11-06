import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/surah.dart';
import '../models/ayah.dart';
import '../models/azkar.dart';

class SearchResult {
  final Surah surah;
  final Ayah ayah;

  SearchResult({required this.surah, required this.ayah});
}

class QuranService {
  static List<Surah> _surahs = [];
  static Map<int, SurahDetail> _surahsDetailMap = {};
  static List<AzkarCategory> _azkarList = [];
  static bool _isLoaded = false;

  static bool get isLoaded => _isLoaded;
  static List<Surah> get surahs => _surahs;
  static List<AzkarCategory> get azkarList => _azkarList;

  static Future<void> loadQuranData() async {
    if (_isLoaded) return;

    try {
      // 1. Load Full Quran with Tafsir
      final quranString = await rootBundle.loadString('assets/data/quran.json');
      final Map<String, dynamic> quranJson = jsonDecode(quranString);
      _surahsDetailMap = quranJson.map(
        (key, value) => MapEntry(
          int.parse(key),
          SurahDetail.fromJson(value as Map<String, dynamic>),
        ),
      );

      // 2. Load metadata and derive ayah counts from the Quran data.
      final surahsString = await rootBundle.loadString('assets/data/surahs.json');
      final List<dynamic> surahsJson = jsonDecode(surahsString);
      _surahs = surahsJson.map((item) {
        final json = item as Map<String, dynamic>;
        final detail = _surahsDetailMap[json['number'] as int];
        return Surah.fromJson({
          ...json,
          'numberOfAyahs': json['numberOfAyahs'] ?? detail?.ayahs.length ?? 0,
        });
      }).toList();

      // 3. Load Azkar
      final azkarString = await rootBundle.loadString('assets/data/azkar.json');
      final List<dynamic> azkarJson = jsonDecode(azkarString);
      _azkarList = azkarJson.map((a) => AzkarCategory.fromJson(a as Map<String, dynamic>)).toList();

      _isLoaded = true;
    } catch (e) {
      // Fallback or debug
      debugPrint('Error loading Quran data: $e');
    }
  }

  static Surah? getSurahByNumber(int number) {
    try {
      return _surahs.firstWhere((s) => s.number == number);
    } catch (_) {
      return null;
    }
  }

  static SurahDetail? getSurahDetail(int number) {
    return _surahsDetailMap[number];
  }

  @visibleForTesting
  static void setMockData({
    required List<Surah> surahs,
    required Map<int, SurahDetail> surahsDetailMap,
    required List<AzkarCategory> azkarList,
  }) {
    _surahs = surahs;
    _surahsDetailMap = surahsDetailMap;
    _azkarList = azkarList;
    _isLoaded = true;
  }

  // Normalize Arabic text for diacritic-free search
  static String normalizeArabic(String text) {
    return text
        .replaceAll(RegExp(r'[\u064B-\u0652\u0670\u06D6-\u06ED]'), '') // Remove Tashkeel & Quranic marks
        .replaceAll(RegExp(r'[إأآٱا]'), 'ا') // Normalize Alif variants, including alif wasla
        .replaceAll('ة', 'ه') // Normalize Ta Marbuta
        .replaceAll('ى', 'ي') // Normalize Alif Maqsura
        .replaceAll('ؤ', 'و')
        .replaceAll('ئ', 'ي')
        .trim()
        .toLowerCase();
  }

  static List<SearchResult> search(String query) {
    if (query.trim().isEmpty) return [];
    final normQuery = normalizeArabic(query);
    List<SearchResult> results = [];

    for (var surahDetail in _surahsDetailMap.values) {
      final surahMeta = getSurahByNumber(surahDetail.number);
      if (surahMeta == null) continue;

      for (var ayah in surahDetail.ayahs) {
        final normText = normalizeArabic(ayah.text);
        if (normText.contains(normQuery)) {
          results.add(SearchResult(surah: surahMeta, ayah: ayah));
          if (results.length >= 100) return results; // Limit for performance
        }
      }
    }
    return results;
  }
}
