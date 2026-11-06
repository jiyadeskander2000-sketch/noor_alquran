import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/surah.dart';
import '../models/ayah.dart';
import '../services/audio_manager.dart';
import '../services/quran_service.dart';
import '../services/storage_service.dart';
import '../providers/theme_provider.dart';
import '../widgets/tafsir_bottom_sheet.dart';

class ListenReadScreen extends StatefulWidget {
  final Surah initialSurah;
  final int initialAyahIndex;

  const ListenReadScreen({
    super.key,
    required this.initialSurah,
    this.initialAyahIndex = 0,
  });

  @override
  State<ListenReadScreen> createState() => _ListenReadScreenState();
}

class _ListenReadScreenState extends State<ListenReadScreen> {
  late Surah _currentSurah;
  SurahDetail? _surahDetail;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _basmalahKey = GlobalKey();
  final Map<int, GlobalKey> _ayahKeys = {};
  int _lastScrolledIndex = -999;

  @override
  void initState() {
    super.initState();
    _currentSurah = widget.initialSurah;
    _loadSurah();

    // Start playing if not already playing this surah, or jump to initialAyahIndex
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final audioManager = Provider.of<AudioManager>(context, listen: false);
      if (audioManager.currentSurah?.number != _currentSurah.number) {
        audioManager.playSurah(_currentSurah, initialAyahIndex: widget.initialAyahIndex);
      } else if (widget.initialAyahIndex > 0) {
        audioManager.jumpToAyah(widget.initialAyahIndex);
      }
      if (widget.initialAyahIndex > 0) {
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) {
            _scrollToActiveAyah(widget.initialAyahIndex, false);
          }
        });
      }
    });
  }

  void _loadSurah() {
    setState(() {
      _surahDetail = QuranService.getSurahDetail(_currentSurah.number);
      _ayahKeys.clear();
      _lastScrolledIndex = -999;
      if (_surahDetail != null) {
        for (int i = 0; i < _surahDetail!.ayahs.length; i++) {
          _ayahKeys[i] = GlobalKey();
        }
      }
    });

    StorageService.saveLastRead(
      surahNumber: _currentSurah.number,
      ayahNumber: 1,
      surahName: _currentSurah.name,
    );
  }

  void _scrollToActiveAyah(int ayahIndex, bool isBasmalah) {
    if (isBasmalah || ayahIndex == -1) {
      if (_lastScrolledIndex != -1) {
        _lastScrolledIndex = -1;
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
        }
      }
      return;
    }

    if (ayahIndex == _lastScrolledIndex) return;
    _lastScrolledIndex = ayahIndex;

    final key = _ayahKeys[ayahIndex];
    if (key != null && key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
        alignment: 0.32,
      );
    }
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void _showSpeedDialog(BuildContext context, AudioManager audioManager) {
    final speeds = [0.75, 1.0, 1.25, 1.5];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final gold = const Color(0xFFD4AF37);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF141F2D) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'سرعة التلاوة',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: speeds.map((s) {
                  final isSelected = audioManager.playbackSpeed == s;
                  return ChoiceChip(
                    label: Text('${s}x', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                    selected: isSelected,
                    selectedColor: gold,
                    onSelected: (_) {
                      audioManager.setSpeed(s);
                      Navigator.pop(ctx);
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFontSizeDialog(BuildContext context, ThemeProvider themeProv) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final gold = const Color(0xFFD4AF37);

        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF141F2D) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'حجم خط الآيات: ${themeProv.fontSize.toInt()}',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  SliderTheme(
                    data: SliderTheme.of(ctx).copyWith(
                      activeTrackColor: gold,
                      thumbColor: gold,
                    ),
                    child: Slider(
                      value: themeProv.fontSize,
                      min: 16.0,
                      max: 36.0,
                      divisions: 10,
                      onChanged: (val) {
                        themeProv.setFontSize(val);
                        setDialogState(() {});
                      },
                    ),
                  ),
                  Text(
                    'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
                    style: GoogleFonts.amiri(fontSize: themeProv.fontSize, color: gold),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final goldColor = const Color(0xFFD4AF37);
    final themeProv = Provider.of<ThemeProvider>(context);

    return Consumer<AudioManager>(
      builder: (context, audioManager, child) {
        // Auto-sync Surah if audio manager switched to next/prev
        if (audioManager.currentSurah != null &&
            audioManager.currentSurah!.number != _currentSurah.number) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _currentSurah = audioManager.currentSurah!;
              _loadSurah();
            });
          });
        }

        // Auto-scroll to active ayah or Bismillah when it changes
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToActiveAyah(
            audioManager.currentAyahIndex,
            audioManager.isRecitingBasmalah,
          );
        });

        double progress = 0.0;
        if (audioManager.duration.inMilliseconds > 0) {
          progress = (audioManager.position.inMilliseconds / audioManager.duration.inMilliseconds)
              .clamp(0.0, 1.0);
        }

        final hasBasmalah = _currentSurah.number != 9;
        final isBasmalahActive = audioManager.isRecitingBasmalah;

        return Scaffold(
          appBar: AppBar(
            title: Column(
              children: [
                Text(
                  _currentSurah.name,
                  style: GoogleFonts.amiri(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                Text(
                  'المزامنة الحية المتقنة • ${StorageService.reciterName}',
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    color: goldColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.format_size_rounded),
                tooltip: 'تغيير حجم الخط',
                onPressed: () => _showFontSizeDialog(context, themeProv),
              ),
              IconButton(
                icon: Icon(
                  themeProv.isDarkMode ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                  color: goldColor,
                ),
                tooltip: themeProv.isDarkMode ? 'الوضع النهاري' : 'الوضع الليلي',
                onPressed: () => themeProv.toggleTheme(),
              ),
            ],
          ),
          body: _surahDetail == null
              ? const Center(child: CircularProgressIndicator())
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 820),
                    child: Column(
                      children: [
                        // Synchronized Quran Ayahs List
                        Expanded(
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            physics: const BouncingScrollPhysics(),
                            itemCount: _surahDetail!.ayahs.length + 1,
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                // Header + Animated Synchronized Bismillah Card
                                return Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF162235) : const Color(0xFFF9F7F2),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: goldColor.withValues(alpha: 0.4), width: 1.2),
                                      ),
                                      child: Column(
                                        children: [
                                          Text(
                                            _currentSurah.name,
                                            style: GoogleFonts.amiri(
                                              fontSize: 28,
                                              fontWeight: FontWeight.bold,
                                              color: goldColor,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'سورة ${_currentSurah.typeArabic} • ${_currentSurah.numberOfAyahs} آية',
                                            style: GoogleFonts.cairo(fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    // Dynamic Synchronized Bismillah Card
                                    if (hasBasmalah) ...[
                                      AnimatedContainer(
                                        key: _basmalahKey,
                                        duration: const Duration(milliseconds: 300),
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                        decoration: BoxDecoration(
                                          color: isBasmalahActive
                                              ? (isDark
                                                  ? goldColor.withValues(alpha: 0.22)
                                                  : const Color(0xFFFEF3C7))
                                              : (isDark ? const Color(0xFF131D2D) : Colors.white),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: isBasmalahActive
                                                ? goldColor
                                                : (isDark ? Colors.white10 : Colors.grey.shade200),
                                            width: isBasmalahActive ? 2.2 : 1.0,
                                          ),
                                          boxShadow: isBasmalahActive
                                              ? [
                                                  BoxShadow(
                                                    color: goldColor.withValues(alpha: 0.3),
                                                    blurRadius: 16,
                                                    spreadRadius: 2,
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(20),
                                          onTap: () {
                                            audioManager.jumpToBasmalah();
                                          },
                                          child: Column(
                                            children: [
                                              if (isBasmalahActive) ...[
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(Icons.graphic_eq_rounded, color: goldColor, size: 18),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      'القارئ يتلو البسملة الشريفة الآن...',
                                                      style: GoogleFonts.cairo(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.bold,
                                                        color: goldColor,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                              ],
                                              Text(
                                                'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
                                                textAlign: TextAlign.center,
                                                style: GoogleFonts.amiri(
                                                  fontSize: themeProv.fontSize + 2,
                                                  fontWeight: FontWeight.bold,
                                                  color: isBasmalahActive
                                                      ? (isDark ? const Color(0xFFF3C64F) : const Color(0xFF0F5132))
                                                      : (isDark ? Colors.white70 : const Color(0xFF1E293B)),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '(اضغط هنا للاستماع من بداية البسملة)',
                                                style: GoogleFonts.cairo(
                                                  fontSize: 10,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                  ],
                                );
                              }

                              final ayahIdx = index - 1;
                              final ayah = _surahDetail!.ayahs[ayahIdx];
                              final isActive = (!isBasmalahActive && ayahIdx == audioManager.currentAyahIndex);

                              return AnimatedContainer(
                                key: _ayahKeys[ayahIdx],
                                duration: const Duration(milliseconds: 300),
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? (isDark
                                          ? goldColor.withValues(alpha: 0.18)
                                          : const Color(0xFFFEF3C7))
                                      : (isDark ? const Color(0xFF131D2D) : Colors.white),
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(
                                    color: isActive
                                        ? goldColor
                                        : (isDark ? Colors.white10 : Colors.grey.shade200),
                                    width: isActive ? 2.0 : 1.0,
                                  ),
                                  boxShadow: isActive
                                      ? [
                                          BoxShadow(
                                            color: goldColor.withValues(alpha: 0.25),
                                            blurRadius: 18,
                                            spreadRadius: 2,
                                          ),
                                        ]
                                      : [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(22),
                                  onTap: () {
                                    // Jump audio directly to this specific Ayah
                                    audioManager.jumpToAyah(ayahIdx);
                                  },
                                  onLongPress: () {
                                    // Show Tafsir
                                    TafsirBottomSheet.show(context, _currentSurah, ayah);
                                  },
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Ayah number badge / sound wave indicator
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: isActive ? goldColor : (isDark ? Colors.white10 : Colors.grey.shade100),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              isActive ? Icons.volume_up_rounded : Icons.menu_book_rounded,
                                              size: 16,
                                              color: isActive ? Colors.black : Colors.grey,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            isActive
                                                ? 'الآية (${ayah.numberInSurah}) • جاري التلاوة 🔊'
                                                : 'الآية (${ayah.numberInSurah})',
                                            style: GoogleFonts.cairo(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: isActive ? goldColor : Colors.grey,
                                            ),
                                          ),
                                          const Spacer(),
                                          // Tafsir quick button
                                          TextButton.icon(
                                            onPressed: () => TafsirBottomSheet.show(context, _currentSurah, ayah),
                                            icon: const Icon(Icons.auto_stories_rounded, size: 14),
                                            label: Text('التفسير', style: GoogleFonts.cairo(fontSize: 11)),
                                            style: TextButton.styleFrom(
                                              visualDensity: VisualDensity.compact,
                                              padding: const EdgeInsets.symmetric(horizontal: 8),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      // Ayah Text
                                      Text(
                                        ayah.text,
                                        textAlign: TextAlign.right,
                                        textDirection: TextDirection.rtl,
                                        style: GoogleFonts.amiri(
                                          fontSize: themeProv.fontSize,
                                          height: 2.1,
                                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                          color: isActive
                                              ? (isDark ? Colors.white : const Color(0xFF0F5132))
                                              : (isDark ? const Color(0xFFF8FAFC) : const Color(0xFF1E293B)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        // Docked Player Controls at Bottom
                        Container(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF131D2D) : Colors.white,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                            border: Border(
                              top: BorderSide(
                                color: goldColor.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 16,
                                offset: const Offset(0, -4),
                              ),
                            ],
                          ),
                          child: SafeArea(
                            top: false,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Progress Slider & Timing
                                Row(
                                  children: [
                                    Text(_formatDuration(audioManager.position), style: GoogleFonts.cairo(fontSize: 11)),
                                    Expanded(
                                      child: SliderTheme(
                                        data: SliderTheme.of(context).copyWith(
                                          activeTrackColor: goldColor,
                                          inactiveTrackColor: isDark ? Colors.white12 : Colors.grey.shade300,
                                          thumbColor: goldColor,
                                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                          trackHeight: 3,
                                        ),
                                        child: Slider(
                                          value: progress,
                                          onChanged: (val) {
                                            if (audioManager.duration.inMilliseconds > 0) {
                                              final targetMs = (val * audioManager.duration.inMilliseconds).toInt();
                                              audioManager.seek(Duration(milliseconds: targetMs));
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                    Text(_formatDuration(audioManager.duration), style: GoogleFonts.cairo(fontSize: 11)),
                                  ],
                                ),

                                // Control buttons & Speed
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    // Playback Speed chip
                                    TextButton(
                                      onPressed: () => _showSpeedDialog(context, audioManager),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      child: Text(
                                        '${audioManager.playbackSpeed}x',
                                        style: GoogleFonts.cairo(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: goldColor,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => audioManager.previousSurah(),
                                      icon: const Icon(Icons.skip_next_rounded),
                                      tooltip: 'السورة السابقة',
                                    ),
                                    IconButton(
                                      onPressed: () => audioManager.seekBackward10(),
                                      icon: const Icon(Icons.replay_10_rounded),
                                      tooltip: 'رجوع 10 ثوانٍ',
                                    ),
                                    Container(
                                      width: 52,
                                      height: 52,
                                      decoration: BoxDecoration(
                                        color: goldColor,
                                        shape: BoxShape.circle,
                                      ),
                                      child: IconButton(
                                        onPressed: () => audioManager.togglePlayPause(),
                                        icon: Icon(
                                          audioManager.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                          color: Colors.black,
                                          size: 32,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => audioManager.seekForward10(),
                                      icon: const Icon(Icons.forward_10_rounded),
                                      tooltip: 'تقديم 10 ثوانٍ',
                                    ),
                                    IconButton(
                                      onPressed: () => audioManager.nextSurah(),
                                      icon: const Icon(Icons.skip_previous_rounded),
                                      tooltip: 'السورة التالية',
                                    ),
                                    // Repeat toggle
                                    IconButton(
                                      onPressed: () => audioManager.toggleRepeatMode(),
                                      icon: Icon(
                                        audioManager.repeatMode == RepeatMode.off
                                            ? Icons.repeat_rounded
                                            : (audioManager.repeatMode == RepeatMode.surah
                                                ? Icons.repeat_on_rounded
                                                : Icons.repeat_one_rounded),
                                        color: audioManager.repeatMode != RepeatMode.off ? goldColor : Colors.grey,
                                        size: 20,
                                      ),
                                      tooltip: 'التكرار',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }
}
