import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookmarkItem {
  final int surahNumber;
  final int ayahNumber;
  final String surahName;
  final String ayahText;
  final DateTime createdAt;

  BookmarkItem({
    required this.surahNumber,
    required this.ayahNumber,
    required this.surahName,
    required this.ayahText,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'surahNumber': surahNumber,
    'ayahNumber': ayahNumber,
    'surahName': surahName,
    'ayahText': ayahText,
    'createdAt': createdAt.toIso8601String(),
  };

  factory BookmarkItem.fromJson(Map<String, dynamic> json) => BookmarkItem(
    surahNumber: json['surahNumber'] as int,
    ayahNumber: json['ayahNumber'] as int,
    surahName: json['surahName'] as String,
    ayahText: json['ayahText'] as String,
    createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
  );
}

class StorageService {
  static const String _keyThemeMode = 'app_theme_mode';
  static const String _keyReciterName = 'custom_reciter_name';
  static const String _keyAdminPin = 'admin_secret_pin';
  static const String _keySurahAudioMap = 'surah_audio_file_map';
  static const String _keyBookmarks = 'quran_bookmarks';
  static const String _keyLastReadSurah = 'last_read_surah';
  static const String _keyLastReadAyah = 'last_read_ayah';
  static const String _keyLastReadSurahName = 'last_read_surah_name';
  static const String _keyFontSize = 'quran_font_size';
  static const String _keyFontFamily = 'quran_font_family';

  static SharedPreferences? _prefs;
  static String _defaultReciterName = 'الشيخ محمد وليد الشرعبي';
  static String _defaultAdminPin = '7777';
  static final Set<int> _bundledAssetSurahs = {};

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();

    // Load bundled configuration from assets/data/reciter_config.json
    try {
      final configStr = await rootBundle.loadString('assets/data/reciter_config.json');
      final Map<String, dynamic> config = jsonDecode(configStr);
      if (config['reciterName'] != null) {
        _defaultReciterName = config['reciterName'] as String;
      }
      if (config['adminPin'] != null) {
        _defaultAdminPin = config['adminPin'] as String;
      }
    } catch (e) {
      debugPrint('No bundled reciter config found or error loading it: $e');
    }

    // Check which surahs exist as bundled assets
    await detectBundledAssetSurahs();
  }

  static Future<void> detectBundledAssetSurahs() async {
    _bundledAssetSurahs.clear();
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final audioPattern = RegExp(r'^assets/audio/(?:surah_)?(\d{1,3})\.mp3$');

      for (final assetPath in manifest.listAssets()) {
        final match = audioPattern.firstMatch(assetPath);
        if (match == null) continue;

        final surahNumber = int.parse(match.group(1)!);
        if (surahNumber >= 1 && surahNumber <= 114) {
          _bundledAssetSurahs.add(surahNumber);
        }
      }
    } catch (e) {
      debugPrint('Could not inspect bundled audio assets: $e');
    }
  }

  static bool hasBundledAsset(int surahNumber) {
    return _bundledAssetSurahs.contains(surahNumber);
  }

  // Theme
  static bool get isDarkMode => _prefs?.getBool(_keyThemeMode) ?? false;
  static Future<void> setDarkMode(bool isDark) async {
    await _prefs?.setBool(_keyThemeMode, isDark);
  }

  // Reciter Name
  static String get reciterName => _prefs?.getString(_keyReciterName) ?? _defaultReciterName;
  static Future<void> setReciterName(String name) async {
    await _prefs?.setString(_keyReciterName, name.trim());
    // Also try to update assets/data/reciter_config.json if possible
    _tryUpdateBundledConfigFile(name.trim(), adminPin);
  }

  // Admin PIN (Default is 7777 or from reciter_config.json)
  static String get adminPin => _prefs?.getString(_keyAdminPin) ?? _defaultAdminPin;
  static Future<void> setAdminPin(String pin) async {
    await _prefs?.setString(_keyAdminPin, pin.trim());
    _tryUpdateBundledConfigFile(reciterName, pin.trim());
  }

  static void _tryUpdateBundledConfigFile(String reciter, String pin) {
    if (!kIsWeb) {
      try {
        final configFile = File('assets/data/reciter_config.json');
        if (configFile.existsSync()) {
          configFile.writeAsStringSync(jsonEncode({
            'reciterName': reciter,
            'adminPin': pin,
          }));
        }
      } catch (_) {}
    }
  }

  // Surah Audio File Mapping
  static Map<int, String> getSurahAudioMap() {
    String? jsonStr = _prefs?.getString(_keySurahAudioMap);
    if (jsonStr == null || jsonStr.isEmpty) return {};
    try {
      Map<String, dynamic> decoded = jsonDecode(jsonStr);
      return decoded.map((key, value) => MapEntry(int.parse(key), value as String));
    } catch (e) {
      debugPrint('Error parsing audio map: $e');
      return {};
    }
  }

  static Future<void> setAudioForSurah(int surahNumber, String filePath) async {
    Map<int, String> current = getSurahAudioMap();
    current[surahNumber] = filePath;
    Map<String, String> toSave = current.map((key, value) => MapEntry(key.toString(), value));
    await _prefs?.setString(_keySurahAudioMap, jsonEncode(toSave));

    // Also attempt to copy to assets/audio/ for project bundling
    if (!kIsWeb) {
      try {
        final assetsAudioDir = Directory('assets/audio');
        if (assetsAudioDir.existsSync()) {
          String ext = p.extension(filePath);
          if (ext.isEmpty) ext = '.mp3';
          final targetInAssets = File(p.join(assetsAudioDir.path, '$surahNumber$ext'));
          await File(filePath).copy(targetInAssets.path);
          _bundledAssetSurahs.add(surahNumber);
        }
      } catch (e) {
        debugPrint('Could not copy to assets/audio directly: $e');
      }
    }
  }

  static Future<void> removeAudioForSurah(int surahNumber) async {
    Map<int, String> current = getSurahAudioMap();
    if (current.containsKey(surahNumber)) {
      String? oldPath = current[surahNumber];
      if (oldPath != null && !kIsWeb) {
        try {
          final file = File(oldPath);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e) {
          debugPrint('Error deleting file: $e');
        }
      }
      current.remove(surahNumber);
      Map<String, String> toSave = current.map((key, value) => MapEntry(key.toString(), value));
      await _prefs?.setString(_keySurahAudioMap, jsonEncode(toSave));
    }
  }

  // Copy picked audio file permanently to local app storage
  static Future<String> copyAudioToLocalStorage(String sourcePath, int surahNumber) async {
    if (kIsWeb) {
      return sourcePath;
    }
    final appDir = await getApplicationDocumentsDirectory();
    final audioDir = Directory(p.join(appDir.path, 'reciter_audio'));
    if (!await audioDir.exists()) {
      await audioDir.create(recursive: true);
    }

    String extension = p.extension(sourcePath);
    if (extension.isEmpty) extension = '.mp3';
    final targetPath = p.join(
      audioDir.path,
      'surah_${surahNumber}_${DateTime.now().millisecondsSinceEpoch}$extension',
    );

    final sourceFile = File(sourcePath);
    await sourceFile.copy(targetPath);
    return targetPath;
  }

  // Bookmarks
  static List<BookmarkItem> getBookmarks() {
    List<String>? list = _prefs?.getStringList(_keyBookmarks);
    if (list == null) return [];
    return list.map((item) {
      try {
        return BookmarkItem.fromJson(jsonDecode(item));
      } catch (e) {
        return null;
      }
    }).whereType<BookmarkItem>().toList();
  }

  static Future<void> toggleBookmark(BookmarkItem bookmark) async {
    List<BookmarkItem> current = getBookmarks();
    int index = current.indexWhere(
      (b) => b.surahNumber == bookmark.surahNumber && b.ayahNumber == bookmark.ayahNumber,
    );
    if (index >= 0) {
      current.removeAt(index);
    } else {
      current.insert(0, bookmark);
    }
    List<String> toSave = current.map((b) => jsonEncode(b.toJson())).toList();
    await _prefs?.setStringList(_keyBookmarks, toSave);
  }

  static bool isBookmarked(int surahNumber, int ayahNumber) {
    List<BookmarkItem> current = getBookmarks();
    return current.any((b) => b.surahNumber == surahNumber && b.ayahNumber == ayahNumber);
  }

  // Last read
  static Future<void> saveLastRead({
    required int surahNumber,
    required int ayahNumber,
    required String surahName,
  }) async {
    await _prefs?.setInt(_keyLastReadSurah, surahNumber);
    await _prefs?.setInt(_keyLastReadAyah, ayahNumber);
    await _prefs?.setString(_keyLastReadSurahName, surahName);
  }

  static Map<String, dynamic>? getLastRead() {
    int? surah = _prefs?.getInt(_keyLastReadSurah);
    int? ayah = _prefs?.getInt(_keyLastReadAyah);
    String? name = _prefs?.getString(_keyLastReadSurahName);
    if (surah == null || ayah == null) return null;
    return {
      'surahNumber': surah,
      'ayahNumber': ayah,
      'surahName': name ?? 'سورة الفاتحة',
    };
  }

  // Font Size (default 26.0)
  static double get fontSize => _prefs?.getDouble(_keyFontSize) ?? 26.0;
  static Future<void> setFontSize(double size) async {
    await _prefs?.setDouble(_keyFontSize, size);
  }

  // Font Family
  static String get fontFamily => _prefs?.getString(_keyFontFamily) ?? 'Amiri';
  static Future<void> setFontFamily(String family) async {
    await _prefs?.setString(_keyFontFamily, family);
  }
}
