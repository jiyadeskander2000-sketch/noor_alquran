import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/surah.dart';
import '../models/ayah.dart';
import 'quran_service.dart';
import 'storage_service.dart';

enum RepeatMode { off, surah, ayah }

class AudioManager extends ChangeNotifier {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal() {
    _initAudioPlayer();
  }

  final AudioPlayer _player = AudioPlayer();

  Surah? _currentSurah;
  SurahDetail? _currentSurahDetail;
  int _currentAyahIndex = 0; // 0-based index in the surah ayahs list (-1 = reciting Basmalah)
  bool _isRecitingBasmalah = false;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  double _playbackSpeed = 1.0;
  RepeatMode _repeatMode = RepeatMode.off;
  Timer? _sleepTimer;
  int _sleepMinutesRemaining = 0;
  int _syncOffsetMs = 0;

  Surah? get currentSurah => _currentSurah;
  SurahDetail? get currentSurahDetail => _currentSurahDetail;
  int get currentAyahIndex => _currentAyahIndex;
  bool get isRecitingBasmalah => _isRecitingBasmalah;
  int get syncOffsetMs => _syncOffsetMs;

  void adjustSyncOffset(int deltaMs) {
    _syncOffsetMs = (_syncOffsetMs + deltaMs).clamp(-5000, 5000);
    _updateCurrentAyahFromPosition();
    notifyListeners();
  }

  void resetSyncOffset() {
    _syncOffsetMs = 0;
    _updateCurrentAyahFromPosition();
    notifyListeners();
  }

  bool get hasOpeningBasmalah {
    if (_currentSurah == null) return false;
    // Surah 1 has Basmalah as Ayah 1. Surah 9 has no Basmalah.
    return _currentSurah!.number != 1 && _currentSurah!.number != 9;
  }

  double get basmalahDurationMs {
    if (!hasOpeningBasmalah) return 0.0;
    // Standard Basmalah length in recitations is approx. 5.5 to 6.2 seconds with pause
    if (_duration.inMilliseconds > 0 && _duration.inMilliseconds < 20000) {
      return _duration.inMilliseconds * 0.28;
    }
    return 5800.0;
  }

  Ayah? get currentAyah {
    if (_currentSurahDetail != null &&
        _currentAyahIndex >= 0 &&
        _currentAyahIndex < _currentSurahDetail!.ayahs.length) {
      return _currentSurahDetail!.ayahs[_currentAyahIndex];
    }
    return null;
  }

  bool get isPlaying => _isPlaying;
  Duration get duration => _duration;
  Duration get position => _position;
  double get playbackSpeed => _playbackSpeed;
  RepeatMode get repeatMode => _repeatMode;
  int get sleepMinutesRemaining => _sleepMinutesRemaining;

  void _initAudioPlayer() {
    _player.onPlayerStateChanged.listen((state) {
      _isPlaying = state == PlayerState.playing;
      notifyListeners();
    });

    _player.onDurationChanged.listen((d) {
      _duration = d;
      notifyListeners();
    });

    _player.onPositionChanged.listen((p) {
      _position = p;
      _updateCurrentAyahFromPosition();
      notifyListeners();
    });

    _player.onPlayerComplete.listen((_) {
      _onTrackCompleted();
    });
  }

  // Calculate proportional timestamps for each ayah accounting for opening Basmalah and pauses
  List<double> _calculateAyahTimeOffsets() {
    if (_currentSurahDetail == null || _duration.inMilliseconds == 0) return [];

    final durationMs = _duration.inMilliseconds.toDouble();

    // Special accurate calibrated profile for Surah Al-Fatiha (Surah 1)
    if (_currentSurah?.number == 1 && _currentSurahDetail!.ayahs.length == 7) {
      const fatihaFractions = [0.0, 0.13, 0.28, 0.40, 0.52, 0.65, 0.77];
      return fatihaFractions.map((f) => f * durationMs).toList();
    }

    final bismillahMs = basmalahDurationMs;
    final remainingMs = (durationMs - bismillahMs).clamp(0.0, double.infinity);

    // Each ayah has weight = text length + verse pause factor (28)
    const pauseWeight = 28;
    int totalWeight = 0;
    for (var ayah in _currentSurahDetail!.ayahs) {
      totalWeight += ayah.text.length + pauseWeight;
    }
    if (totalWeight == 0) return [];

    List<double> offsets = [];
    double accumulated = bismillahMs;
    for (var ayah in _currentSurahDetail!.ayahs) {
      offsets.add(accumulated);
      double weight = (ayah.text.length + pauseWeight).toDouble();
      double fraction = weight / totalWeight;
      accumulated += fraction * remainingMs;
    }
    return offsets;
  }

  void _updateCurrentAyahFromPosition() {
    if (_currentSurahDetail == null || _duration.inMilliseconds == 0) return;
    final rawCurrentMs = _position.inMilliseconds.toDouble();
    // Apply user sync calibration offset
    final currentMs = (rawCurrentMs + _syncOffsetMs).clamp(0.0, _duration.inMilliseconds.toDouble());
    final bismillahMs = basmalahDurationMs;

    // Check if player is currently in the opening Basmalah period
    if (hasOpeningBasmalah && currentMs < bismillahMs) {
      bool changed = false;
      if (!_isRecitingBasmalah) {
        _isRecitingBasmalah = true;
        changed = true;
      }
      if (_currentAyahIndex != -1) {
        _currentAyahIndex = -1; // -1 represents Basmalah
        changed = true;
      }
      if (changed) notifyListeners();
      return;
    }

    if (_isRecitingBasmalah) {
      _isRecitingBasmalah = false;
    }

    final offsets = _calculateAyahTimeOffsets();
    if (offsets.isEmpty) return;

    int newIndex = 0;
    for (int i = 0; i < offsets.length; i++) {
      if (currentMs >= offsets[i]) {
        newIndex = i;
      } else {
        break;
      }
    }

    if (newIndex != _currentAyahIndex) {
      _currentAyahIndex = newIndex;
      notifyListeners();
    }
  }

  Future<void> playSurah(Surah surah, {int initialAyahIndex = 0}) async {
    _currentSurah = surah;
    _currentSurahDetail = QuranService.getSurahDetail(surah.number);
    _currentAyahIndex = initialAyahIndex;
    _position = Duration.zero;
    _duration = Duration.zero;

    // Check 1: User's imported local audio file
    Map<int, String> audioMap = StorageService.getSurahAudioMap();
    String? localAudioPath = audioMap[surah.number];

    try {
      String? assetPath = await _findAssetAudio(surah.number);

      if (localAudioPath != null && localAudioPath.isNotEmpty && !kIsWeb && File(localAudioPath).existsSync()) {
        // 1. Play from device local offline storage
        await _player.stop();
        await _player.setSourceDeviceFile(localAudioPath);
      } else if (assetPath != null) {
        // 2. Play from bundled app assets (Baked directly into APK/app)
        await _player.stop();
        await _player.setSource(AssetSource(assetPath));
      } else if (kIsWeb && localAudioPath != null && localAudioPath.isNotEmpty) {
        await _player.stop();
        await _player.setSourceUrl(localAudioPath);
      } else {
        // 3. Fallback default stream
        await _playDefaultStream(surah.number);
      }

      await _player.setPlaybackRate(_playbackSpeed);
      await _player.resume();

      if (initialAyahIndex > 0) {
        // If an initial ayah was requested, wait for duration and jump
        Future.delayed(const Duration(milliseconds: 500), () {
          jumpToAyah(initialAyahIndex);
        });
      }
    } catch (e) {
      debugPrint('Error playing audio: $e');
    }
    notifyListeners();
  }

  Future<String?> _findAssetAudio(int surahNumber) async {
    final candidates = [
      'assets/audio/$surahNumber.mp3',
      'assets/audio/surah_$surahNumber.mp3',
      'assets/audio/${surahNumber.toString().padLeft(3, '0')}.mp3',
    ];
    for (var c in candidates) {
      try {
        await rootBundle.load(c);
        return c.replaceFirst('assets/', '');
      } catch (_) {}
    }
    return null;
  }

  Future<void> _playDefaultStream(int surahNumber) async {
    String formattedNum = surahNumber.toString().padLeft(3, '0');
    // High-speed direct CDNs (No redirects, instant 200 OK playback)
    final primaryUrl = 'https://download.quranicaudio.com/quran/mishaari_raashid_al_3afaasee/$formattedNum.mp3';
    final fallbackUrl = 'https://cdn.mp3quran.net/audio/mishary-alafasy/r1/$formattedNum.mp3';

    await _player.stop();
    try {
      await _player.setSourceUrl(primaryUrl);
    } catch (_) {
      try {
        await _player.setSourceUrl(fallbackUrl);
      } catch (e) {
        debugPrint('Error loading audio stream: $e');
      }
    }
  }

  Future<void> pause() async {
    await _player.pause();
    notifyListeners();
  }

  Future<void> resume() async {
    await _player.resume();
    notifyListeners();
  }

  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      await pause();
    } else {
      await resume();
    }
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> jumpToAyah(int ayahIndex) async {
    if (_currentSurahDetail == null || ayahIndex < 0 || ayahIndex >= _currentSurahDetail!.ayahs.length) return;
    _currentAyahIndex = ayahIndex;
    _isRecitingBasmalah = false;
    final offsets = _calculateAyahTimeOffsets();
    if (offsets.isNotEmpty && ayahIndex < offsets.length) {
      final targetMs = offsets[ayahIndex].toInt();
      await seek(Duration(milliseconds: targetMs));
    }
    notifyListeners();
  }

  Future<void> jumpToBasmalah() async {
    _currentAyahIndex = -1;
    _isRecitingBasmalah = true;
    await seek(Duration.zero);
    notifyListeners();
  }

  Future<void> seekForward10() async {
    final target = _position + const Duration(seconds: 10);
    if (target < _duration) {
      await seek(target);
    } else {
      await seek(_duration);
    }
  }

  Future<void> seekBackward10() async {
    final target = _position - const Duration(seconds: 10);
    if (target > Duration.zero) {
      await seek(target);
    } else {
      await seek(Duration.zero);
    }
  }

  Future<void> nextSurah() async {
    if (_currentSurah == null) return;
    int nextNum = _currentSurah!.number + 1;
    if (nextNum > 114) nextNum = 1;
    final nextS = QuranService.getSurahByNumber(nextNum);
    if (nextS != null) {
      await playSurah(nextS);
    }
  }

  Future<void> previousSurah() async {
    if (_currentSurah == null) return;
    int prevNum = _currentSurah!.number - 1;
    if (prevNum < 1) prevNum = 114;
    final prevS = QuranService.getSurahByNumber(prevNum);
    if (prevS != null) {
      await playSurah(prevS);
    }
  }

  Future<void> setSpeed(double speed) async {
    _playbackSpeed = speed;
    await _player.setPlaybackRate(speed);
    notifyListeners();
  }

  void toggleRepeatMode() {
    if (_repeatMode == RepeatMode.off) {
      _repeatMode = RepeatMode.surah;
    } else if (_repeatMode == RepeatMode.surah) {
      _repeatMode = RepeatMode.ayah;
    } else {
      _repeatMode = RepeatMode.off;
    }
    notifyListeners();
  }

  void setSleepTimer(int minutes) {
    _sleepTimer?.cancel();
    if (minutes <= 0) {
      _sleepMinutesRemaining = 0;
      notifyListeners();
      return;
    }

    _sleepMinutesRemaining = minutes;
    notifyListeners();

    _sleepTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _sleepMinutesRemaining--;
      if (_sleepMinutesRemaining <= 0) {
        timer.cancel();
        pause();
      }
      notifyListeners();
    });
  }

  void _onTrackCompleted() {
    if (_repeatMode == RepeatMode.surah) {
      if (_currentSurah != null) {
        playSurah(_currentSurah!);
      }
    } else if (_repeatMode == RepeatMode.ayah) {
      jumpToAyah(_currentAyahIndex);
      resume();
    } else {
      // Auto-advance to next Surah
      nextSurah();
    }
  }

  @override
  void dispose() {
    _sleepTimer?.cancel();
    _player.dispose();
    super.dispose();
  }
}
