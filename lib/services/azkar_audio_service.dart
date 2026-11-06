import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/azkar.dart';

class AzkarAudioService {
  static final AzkarAudioService _instance = AzkarAudioService._internal();
  factory AzkarAudioService() => _instance;
  AzkarAudioService._internal() {
    _initAudioPlayer();
  }

  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts _flutterTts = FlutterTts();

  // State Notifiers
  final ValueNotifier<bool> isPlayingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<int> currentIndexNotifier = ValueNotifier<int>(-1);
  final ValueNotifier<int> currentRepeatNotifier = ValueNotifier<int>(1);
  final ValueNotifier<String> statusMessageNotifier = ValueNotifier<String>('');
  final ValueNotifier<Duration> positionNotifier = ValueNotifier<Duration>(Duration.zero);
  final ValueNotifier<Duration> durationNotifier = ValueNotifier<Duration>(Duration.zero);
  final ValueNotifier<bool> isFullContinuousNotifier = ValueNotifier<bool>(false);

  List<AzkarItem> _currentPlaylist = [];
  bool _isAutoSequence = false;
  bool _isTtsInitialized = false;
  bool _isUsingAudioPlayer = false;

  void _initAudioPlayer() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (_isUsingAudioPlayer) {
        isPlayingNotifier.value = (state == PlayerState.playing);
      }
    });

    _audioPlayer.onDurationChanged.listen((d) {
      durationNotifier.value = d;
    });

    _audioPlayer.onPositionChanged.listen((p) {
      positionNotifier.value = p;
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      if (_isUsingAudioPlayer) {
        _onAudioPlayerCompleted();
      }
    });
  }

  Future<void> _initTts() async {
    if (_isTtsInitialized) return;
    try {
      try {
        await _flutterTts.awaitSpeakCompletion(false);
      } catch (_) {}

      bool langSet = false;
      try {
        final dynamic langs = await _flutterTts.getLanguages;
        if (langs is List && langs.isNotEmpty) {
          final priorityLocales = ['ar-SA', 'ar_SA', 'ar-EG', 'ar_EG', 'ar-AE', 'ar'];
          for (final loc in priorityLocales) {
            if (langs.any((l) =>
                l.toString().toLowerCase().contains(loc.toLowerCase().replaceAll('-', '_')) ||
                l.toString().toLowerCase() == loc.toLowerCase())) {
              await _flutterTts.setLanguage(loc);
              langSet = true;
              break;
            }
          }
        }
      } catch (_) {}

      if (!langSet) {
        try {
          await _flutterTts.setLanguage('ar');
        } catch (_) {}
      }

      await _flutterTts.setSpeechRate(0.42);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      _flutterTts.setStartHandler(() {
        if (!_isUsingAudioPlayer) {
          isPlayingNotifier.value = true;
        }
      });

      _flutterTts.setCompletionHandler(() {
        if (!_isUsingAudioPlayer) {
          _onTtsCompleted();
        }
      });

      _flutterTts.setErrorHandler((msg) {
        debugPrint('FlutterTts Error: $msg');
        if (!_isUsingAudioPlayer) {
          isPlayingNotifier.value = false;
          statusMessageNotifier.value = 'تنبيه: يمكنك الاستماع بالصوت المسجل المدمج في التطبيق';
        }
      });

      _flutterTts.setCancelHandler(() {
        if (!_isUsingAudioPlayer) {
          isPlayingNotifier.value = false;
        }
      });

      _isTtsInitialized = true;
    } catch (e) {
      debugPrint('Error initializing TTS: $e');
    }
  }

  /// Get asset path for a given Dhikr index in morning/evening collection
  String? _getAssetForIndex(int idx) {
    if (idx < 0) return null;
    if (idx == 0) {
      // Ayat Al-Kursi - Sheikh Mishary Alafasy
      return 'audio/002255.mp3';
    }
    final assetNum = 75 + idx;
    if (assetNum >= 75 && assetNum <= 98) {
      return 'audio/azkar_$assetNum.mp3';
    }
    return null;
  }

  /// Play the full authentic recorded audio file (أذكار الصباح والمساء كاملة مسجلة)
  Future<void> playFullRecordedAudio({required bool isSabah}) async {
    await stop();
    _isUsingAudioPlayer = true;
    isFullContinuousNotifier.value = true;
    _isAutoSequence = false;
    currentIndexNotifier.value = -1;
    currentRepeatNotifier.value = 1;
    statusMessageNotifier.value = isSabah
        ? 'تشغيل أذكار الصباح كاملة بصوت عذب ندي'
        : 'تشغيل أذكار المساء كاملة بصوت عذب ندي';

    try {
      final assetPath = isSabah ? 'audio/adhkar_sabah.mp3' : 'audio/adhkar_masa.mp3';
      await _audioPlayer.play(AssetSource(assetPath));
      isPlayingNotifier.value = true;
    } catch (e) {
      debugPrint('Error playing full recorded audio: $e');
      // Fallback to adhkar_full.mp3
      try {
        await _audioPlayer.play(AssetSource('audio/adhkar_full.mp3'));
        isPlayingNotifier.value = true;
      } catch (e2) {
        debugPrint('Fallback error: $e2');
        statusMessageNotifier.value = 'تعذر تشغيل الملف الصوتي';
      }
    }
  }

  /// Play a single dhikr either using bundled authentic audio MP3 or TTS fallback
  Future<void> speakSingleDhikr(String text, {int itemIndex = -1, String categoryName = ''}) async {
    await stop();

    final asset = _getAssetForIndex(itemIndex);
    if (asset != null) {
      // Play local high-quality MP3 recording directly
      _isUsingAudioPlayer = true;
      isFullContinuousNotifier.value = false;
      _isAutoSequence = false;
      currentIndexNotifier.value = itemIndex;
      currentRepeatNotifier.value = 1;
      statusMessageNotifier.value = 'جاري الاستماع للذكر بصوت الشيخ...';

      try {
        await _audioPlayer.play(AssetSource(asset));
        isPlayingNotifier.value = true;
        return;
      } catch (e) {
        debugPrint('Error playing asset $asset: $e. Falling back to TTS');
      }
    }

    // Fallback to TTS for text without MP3 asset (like Names of Allah, custom stories)
    _isUsingAudioPlayer = false;
    isFullContinuousNotifier.value = false;
    await _initTts();

    _isAutoSequence = false;
    currentIndexNotifier.value = itemIndex;
    currentRepeatNotifier.value = 1;
    isPlayingNotifier.value = true;
    statusMessageNotifier.value = 'جاري القراءة الصوتية...';

    final clean = _sanitizeForTts(text);
    try {
      final res = await _flutterTts.speak(clean);
      if (res == 0) {
        try {
          await _flutterTts.setLanguage('ar');
          await _flutterTts.speak(clean);
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('Speak error: $e');
      statusMessageNotifier.value = 'تنبيه: يمكنك تفعيل محرك قراءة النصوص في إعدادات الهاتف';
    }
  }

  /// Play an entire category sequentially with repeat counting
  Future<void> playSequence(List<AzkarItem> items, {int startIndex = 0}) async {
    if (items.isEmpty) return;
    await stop();

    _currentPlaylist = List.from(items);
    _isAutoSequence = true;
    isFullContinuousNotifier.value = false;
    currentIndexNotifier.value = startIndex;
    currentRepeatNotifier.value = 1;
    statusMessageNotifier.value = 'تشغيل الأذكار متتابعة بالصوت';

    await _playCurrentPlaylistItem();
  }

  Future<void> _playCurrentPlaylistItem() async {
    final idx = currentIndexNotifier.value;
    if (idx < 0 || idx >= _currentPlaylist.length) {
      await stop();
      statusMessageNotifier.value = 'تم الانتهاء من جميع الأذكار بحمد الله';
      return;
    }

    final item = _currentPlaylist[idx];
    statusMessageNotifier.value =
        'الذكر (${idx + 1} من ${_currentPlaylist.length}) - التكرار (${currentRepeatNotifier.value}/${item.count})';

    final asset = _getAssetForIndex(idx);
    if (asset != null) {
      _isUsingAudioPlayer = true;
      try {
        await _audioPlayer.play(AssetSource(asset));
        isPlayingNotifier.value = true;
        return;
      } catch (e) {
        debugPrint('Asset playback error: $e, falling back to TTS');
      }
    }

    // TTS Fallback
    _isUsingAudioPlayer = false;
    await _initTts();
    isPlayingNotifier.value = true;
    final clean = _sanitizeForTts(item.text);
    await _flutterTts.speak(clean);
  }

  void _onAudioPlayerCompleted() {
    if (!isPlayingNotifier.value && !_isAutoSequence) return;

    if (isFullContinuousNotifier.value) {
      // Completed full continuous track
      stop();
      statusMessageNotifier.value = 'تقبل الله ذكركم، اكتملت الأذكار بحمد الله';
      return;
    }

    if (!_isAutoSequence) {
      isPlayingNotifier.value = false;
      statusMessageNotifier.value = 'تمت القراءة';
      return;
    }

    _handleSequenceAdvance();
  }

  void _onTtsCompleted() {
    if (!isPlayingNotifier.value) return;

    if (!_isAutoSequence) {
      isPlayingNotifier.value = false;
      statusMessageNotifier.value = 'تمت القراءة';
      return;
    }

    _handleSequenceAdvance();
  }

  void _handleSequenceAdvance() {
    final idx = currentIndexNotifier.value;
    if (idx < 0 || idx >= _currentPlaylist.length) {
      stop();
      return;
    }

    final currentItem = _currentPlaylist[idx];

    // If repeat count not yet reached, repeat the same dhikr
    if (currentRepeatNotifier.value < currentItem.count) {
      currentRepeatNotifier.value += 1;
      Future.delayed(const Duration(milliseconds: 600), () {
        if (isPlayingNotifier.value && _isAutoSequence) {
          _playCurrentPlaylistItem();
        }
      });
      return;
    }

    // Move to next item
    if (idx + 1 < _currentPlaylist.length) {
      currentIndexNotifier.value = idx + 1;
      currentRepeatNotifier.value = 1;
      Future.delayed(const Duration(milliseconds: 800), () {
        if (isPlayingNotifier.value && _isAutoSequence) {
          _playCurrentPlaylistItem();
        }
      });
    } else {
      stop();
      statusMessageNotifier.value = 'تقبل الله ذكركم، اكتملت الأذكار بحمد الله';
    }
  }

  /// Next Dhikr in sequence
  Future<void> nextDhikr() async {
    if (!_isAutoSequence || _currentPlaylist.isEmpty) return;
    final nextIdx = currentIndexNotifier.value + 1;
    if (nextIdx < _currentPlaylist.length) {
      await _audioPlayer.stop();
      await _flutterTts.stop();
      currentIndexNotifier.value = nextIdx;
      currentRepeatNotifier.value = 1;
      await _playCurrentPlaylistItem();
    }
  }

  /// Previous Dhikr in sequence
  Future<void> previousDhikr() async {
    if (!_isAutoSequence || _currentPlaylist.isEmpty) return;
    final prevIdx = currentIndexNotifier.value - 1;
    if (prevIdx >= 0) {
      await _audioPlayer.stop();
      await _flutterTts.stop();
      currentIndexNotifier.value = prevIdx;
      currentRepeatNotifier.value = 1;
      await _playCurrentPlaylistItem();
    }
  }

  /// Pause current audio
  Future<void> pause() async {
    isPlayingNotifier.value = false;
    if (_isUsingAudioPlayer) {
      try {
        await _audioPlayer.pause();
      } catch (_) {}
    } else {
      try {
        await _flutterTts.stop();
      } catch (_) {}
    }
  }

  /// Resume playback
  Future<void> resume() async {
    if (_isUsingAudioPlayer) {
      try {
        await _audioPlayer.resume();
        isPlayingNotifier.value = true;
      } catch (_) {}
    }
  }

  /// Seek position in full track
  Future<void> seek(Duration pos) async {
    if (_isUsingAudioPlayer) {
      try {
        await _audioPlayer.seek(pos);
      } catch (_) {}
    }
  }

  /// Stop all playback immediately
  Future<void> stop() async {
    isPlayingNotifier.value = false;
    _isAutoSequence = false;
    isFullContinuousNotifier.value = false;
    currentIndexNotifier.value = -1;
    currentRepeatNotifier.value = 1;
    statusMessageNotifier.value = '';
    positionNotifier.value = Duration.zero;

    try {
      await _audioPlayer.stop();
    } catch (_) {}
    try {
      await _flutterTts.stop();
    } catch (_) {}
  }

  String _sanitizeForTts(String text) {
    return text
        .replaceAll('۞', '')
        .replaceAll('﴿', '')
        .replaceAll('﴾', '')
        .replaceAll('۩', '')
        .replaceAll('ۜ', '')
        .replaceAll('ۢ', '')
        .replaceAll('ۚ', '')
        .replaceAll('ۖ', '')
        .replaceAll('ۗ', '')
        .replaceAll('  ', ' ')
        .trim();
  }

  void dispose() {
    _audioPlayer.dispose();
    _flutterTts.stop();
  }
}
