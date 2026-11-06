import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/audio_manager.dart';
import '../services/quran_service.dart';
import '../services/storage_service.dart';
import '../providers/theme_provider.dart';

class ListenOnlyScreen extends StatelessWidget {
  const ListenOnlyScreen({super.key});

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    if (d.inHours > 0) {
      return '${d.inHours}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  void _showSleepTimerDialog(BuildContext context, AudioManager audioManager) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131D2D) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'مؤقت النوم (إيقاف التشغيل تلقائياً)',
                style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text('إيقاف المؤقت', style: GoogleFonts.cairo()),
                leading: const Icon(Icons.timer_off_outlined),
                onTap: () {
                  audioManager.setSleepTimer(0);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                title: Text('15 دقيقة', style: GoogleFonts.cairo()),
                leading: const Icon(Icons.timer_outlined),
                onTap: () {
                  audioManager.setSleepTimer(15);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                title: Text('30 دقيقة', style: GoogleFonts.cairo()),
                leading: const Icon(Icons.timer_outlined),
                onTap: () {
                  audioManager.setSleepTimer(30);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                title: Text('45 دقيقة', style: GoogleFonts.cairo()),
                leading: const Icon(Icons.timer_outlined),
                onTap: () {
                  audioManager.setSleepTimer(45);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                title: Text('60 دقيقة (ساعة كاملة)', style: GoogleFonts.cairo()),
                leading: const Icon(Icons.timer_outlined),
                onTap: () {
                  audioManager.setSleepTimer(60);
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPlaylistSheet(BuildContext context, AudioManager audioManager) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final goldColor = const Color(0xFFD4AF37);
        final surahs = QuranService.surahs;

        return Container(
          height: MediaQuery.of(ctx).size.height * 0.7,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131D2D) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'قائمة سور القرآن الكريم',
                  style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: surahs.length,
                  itemBuilder: (ctx, idx) {
                    final s = surahs[idx];
                    final isPlayingThis = audioManager.currentSurah?.number == s.number;
                    return ListTile(
                      leading: Text(
                        '${s.number}',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                      ),
                      title: Text(
                        s.name,
                        style: GoogleFonts.amiri(
                          fontSize: 18,
                          fontWeight: isPlayingThis ? FontWeight.bold : FontWeight.normal,
                          color: isPlayingThis ? goldColor : null,
                        ),
                      ),
                      subtitle: Text('${s.typeArabic} • ${s.numberOfAyahs} آية', style: GoogleFonts.cairo(fontSize: 12)),
                      trailing: isPlayingThis
                          ? Icon(Icons.volume_up_rounded, color: goldColor)
                          : null,
                      onTap: () {
                        audioManager.playSurah(s);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
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
        final surah = audioManager.currentSurah ?? QuranService.getSurahByNumber(1)!;
        final reciterName = StorageService.reciterName;

        double progress = 0.0;
        if (audioManager.duration.inMilliseconds > 0) {
          progress = (audioManager.position.inMilliseconds / audioManager.duration.inMilliseconds)
              .clamp(0.0, 1.0);
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'مشغل القرآن الكريم',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            actions: [
              // Theme toggle button in header
              IconButton(
                icon: Icon(
                  themeProv.isDarkMode ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                  color: goldColor,
                ),
                tooltip: themeProv.isDarkMode ? 'الوضع النهاري' : 'الوضع الليلي',
                onPressed: () => themeProv.toggleTheme(),
              ),
              // Playlist button
              IconButton(
                icon: const Icon(Icons.queue_music_rounded),
                tooltip: 'قائمة السور',
                onPressed: () => _showPlaylistSheet(context, audioManager),
              ),
            ],
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final discSize = math.min(
                250.0,
                math.min(constraints.maxWidth - 48, constraints.maxHeight * 0.38),
              ).clamp(120.0, 250.0).toDouble();
              final ringSize = discSize * 0.84;

              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: math.max(0.0, constraints.maxHeight - 32),
                      ),
                      child: Column(
                        mainAxisAlignment: constraints.maxHeight < 480
                            ? MainAxisAlignment.start
                            : MainAxisAlignment.spaceEvenly,
                        children: [
                  // Illuminated Quran Disc / Cover
                  Center(
                    child: Container(
                      width: discSize,
                      height: discSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: isDark
                              ? [const Color(0xFF1E2E44), const Color(0xFF0F1722)]
                              : [const Color(0xFFEADBCE), const Color(0xFFFAF7F2)],
                          radius: 0.8,
                        ),
                        border: Border.all(color: goldColor, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: goldColor.withValues(alpha: isDark ? 0.3 : 0.2),
                            blurRadius: 30,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer decorative ring
                          Container(
                              width: ringSize,
                              height: ringSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: goldColor.withValues(alpha: 0.4),
                                width: 1.5,
                              ),
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.auto_stories_rounded,
                                color: goldColor,
                                size: discSize * 0.16,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                surah.name,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.amiri(
                                  fontSize: discSize * 0.136,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF0F5132),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${surah.typeArabic} • ${surah.numberOfAyahs} آية',
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Reciter Info & Ayah Tracker
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: goldColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: goldColor.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.mic_none_rounded, size: 16, color: goldColor),
                            const SizedBox(width: 6),
                            Text(
                              reciterName,
                              style: GoogleFonts.cairo(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isDark ? const Color(0xFFF3C64F) : const Color(0xFF0F5132),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'الآية الحالية: ${audioManager.currentAyahIndex + 1} من ${surah.numberOfAyahs}',
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),

                  // Slider & Time
                  Column(
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: goldColor,
                          inactiveTrackColor: isDark ? Colors.white24 : Colors.grey.shade300,
                          thumbColor: goldColor,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                          overlayColor: goldColor.withValues(alpha: 0.2),
                          trackHeight: 4,
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
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(audioManager.position),
                              style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey),
                            ),
                            Text(
                              _formatDuration(audioManager.duration),
                              style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Main Controls: Previous, Skip-10, Play/Pause, Skip+10, Next
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Previous Surah
                      IconButton(
                        onPressed: () => audioManager.previousSurah(),
                        icon: const Icon(Icons.skip_next_rounded, size: 30),
                        tooltip: 'السورة السابقة',
                      ),
                      const SizedBox(width: 8),
                      // Skip -10s
                      IconButton(
                        onPressed: () => audioManager.seekBackward10(),
                        icon: const Icon(Icons.replay_10_rounded, size: 28),
                        tooltip: 'رجوع 10 ثوانٍ',
                      ),
                      const SizedBox(width: 14),
                      // Play / Pause Circle
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [goldColor, const Color(0xFFB8860B)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: goldColor.withValues(alpha: 0.4),
                              blurRadius: 18,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: () {
                            if (audioManager.currentSurah == null) {
                              audioManager.playSurah(surah);
                            } else {
                              audioManager.togglePlayPause();
                            }
                          },
                          icon: Icon(
                            audioManager.isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            size: 40,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Skip +10s
                      IconButton(
                        onPressed: () => audioManager.seekForward10(),
                        icon: const Icon(Icons.forward_10_rounded, size: 28),
                        tooltip: 'تقديم 10 ثوانٍ',
                      ),
                      const SizedBox(width: 8),
                      // Next Surah
                      IconButton(
                        onPressed: () => audioManager.nextSurah(),
                        icon: const Icon(Icons.skip_previous_rounded, size: 30),
                        tooltip: 'السورة التالية',
                      ),
                    ],
                  ),

                  // Secondary Controls: Sleep Timer, Speed, Repeat
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Sleep timer
                      TextButton.icon(
                        onPressed: () => _showSleepTimerDialog(context, audioManager),
                        icon: Icon(
                          audioManager.sleepMinutesRemaining > 0
                              ? Icons.alarm_on_rounded
                              : Icons.bedtime_outlined,
                          size: 18,
                          color: audioManager.sleepMinutesRemaining > 0 ? goldColor : null,
                        ),
                        label: Text(
                          audioManager.sleepMinutesRemaining > 0
                              ? '${audioManager.sleepMinutesRemaining} د'
                              : 'مؤقت النوم',
                          style: GoogleFonts.cairo(fontSize: 12),
                        ),
                      ),

                      // Speed selector
                      PopupMenuButton<double>(
                        initialValue: audioManager.playbackSpeed,
                        onSelected: (val) => audioManager.setSpeed(val),
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(value: 0.75, child: Text('0.75x')),
                          const PopupMenuItem(value: 1.0, child: Text('1.0x (العادي)')),
                          const PopupMenuItem(value: 1.25, child: Text('1.25x')),
                          const PopupMenuItem(value: 1.5, child: Text('1.5x')),
                          const PopupMenuItem(value: 2.0, child: Text('2.0x')),
                        ],
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          child: Row(
                            children: [
                              const Icon(Icons.speed_rounded, size: 18),
                              const SizedBox(width: 4),
                              Text('${audioManager.playbackSpeed}x', style: GoogleFonts.cairo(fontSize: 12)),
                            ],
                          ),
                        ),
                      ),

                      // Repeat mode
                      IconButton(
                        onPressed: () => audioManager.toggleRepeatMode(),
                        icon: Icon(
                          audioManager.repeatMode == RepeatMode.ayah
                              ? Icons.repeat_one_rounded
                              : audioManager.repeatMode == RepeatMode.surah
                                  ? Icons.repeat_rounded
                                  : Icons.repeat_rounded,
                          color: audioManager.repeatMode != RepeatMode.off ? goldColor : Colors.grey,
                        ),
                        tooltip: audioManager.repeatMode == RepeatMode.ayah
                            ? 'تكرار الآية'
                            : audioManager.repeatMode == RepeatMode.surah
                                ? 'تكرار السورة'
                                : 'بدون تكرار',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  ),
);
},
);
}
}
