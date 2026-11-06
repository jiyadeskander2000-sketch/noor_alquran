import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/audio_manager.dart';
import '../services/storage_service.dart';
import '../screens/listen_only_screen.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioManager>(
      builder: (context, audioManager, child) {
        if (audioManager.currentSurah == null) {
          return const SizedBox.shrink();
        }

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final primaryColor = Theme.of(context).primaryColor;
        final goldColor = const Color(0xFFD4AF37);
        final surah = audioManager.currentSurah!;
        final reciterName = StorageService.reciterName;

        double progress = 0.0;
        if (audioManager.duration.inMilliseconds > 0) {
          progress = (audioManager.position.inMilliseconds / audioManager.duration.inMilliseconds)
              .clamp(0.0, 1.0);
        }

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ListenOnlyScreen()),
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF162235) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: goldColor.withValues(alpha: isDark ? 0.3 : 0.4),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Linear progress bar at top of player
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(goldColor),
                    minHeight: 3,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: Row(
                      children: [
                        // Surah icon badge
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isDark
                                  ? [goldColor.withValues(alpha: 0.3), primaryColor.withValues(alpha: 0.3)]
                                  : [primaryColor.withValues(alpha: 0.15), goldColor.withValues(alpha: 0.2)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(color: goldColor, width: 1.2),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.graphic_eq_rounded,
                              color: isDark ? goldColor : primaryColor,
                              size: 22,
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                surah.name,
                                style: GoogleFonts.cairo(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '$reciterName • الآية ${audioManager.currentAyahIndex + 1}',
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  color: isDark ? Colors.white60 : Colors.grey.shade600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                        // Next Surah button
                        IconButton(
                          onPressed: () => audioManager.nextSurah(),
                          icon: const Icon(Icons.skip_previous_rounded),
                          tooltip: 'السورة التالية',
                        ),

                        // Play / Pause button
                        IconButton(
                          onPressed: () => audioManager.togglePlayPause(),
                          icon: Icon(
                            audioManager.isPlaying
                                ? Icons.pause_circle_filled_rounded
                                : Icons.play_circle_fill_rounded,
                            color: goldColor,
                            size: 38,
                          ),
                        ),
                      ],
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
