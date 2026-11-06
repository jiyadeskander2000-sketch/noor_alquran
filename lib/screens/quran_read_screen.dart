import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/surah.dart';
import '../models/ayah.dart';
import '../services/quran_service.dart';
import '../services/storage_service.dart';
import '../providers/theme_provider.dart';
import '../widgets/tafsir_bottom_sheet.dart';
import '../widgets/mini_player.dart';

class QuranReadScreen extends StatefulWidget {
  final Surah initialSurah;
  final int initialAyahIndex;

  const QuranReadScreen({
    super.key,
    required this.initialSurah,
    this.initialAyahIndex = 0,
  });

  @override
  State<QuranReadScreen> createState() => _QuranReadScreenState();
}

class _QuranReadScreenState extends State<QuranReadScreen> {
  late Surah _currentSurah;
  SurahDetail? _surahDetail;
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _ayahKeys = {};
  int? _highlightedAyahIndex;
  Timer? _highlightTimer;

  @override
  void initState() {
    super.initState();
    _currentSurah = widget.initialSurah;
    _highlightedAyahIndex = widget.initialAyahIndex;
    _loadSurahDetail();

    if (widget.initialAyahIndex > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToInitialAyah();
      });
    }
  }

  @override
  void dispose() {
    _highlightTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToInitialAyah() {
    if (widget.initialAyahIndex <= 0) return;
    Future.delayed(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      final key = _ayahKeys[widget.initialAyahIndex];
      if (key?.currentContext != null) {
        Scrollable.ensureVisible(
          key!.currentContext!,
          duration: const Duration(milliseconds: 650),
          curve: Curves.easeInOutCubic,
          alignment: 0.28,
        );
      }
      _highlightTimer?.cancel();
      _highlightTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) {
          setState(() {
            _highlightedAyahIndex = null;
          });
        }
      });
    });
  }

  void _loadSurahDetail() {
    setState(() {
      _surahDetail = QuranService.getSurahDetail(_currentSurah.number);
      _ayahKeys.clear();
      if (_surahDetail != null) {
        for (int i = 0; i < _surahDetail!.ayahs.length; i++) {
          _ayahKeys[i] = GlobalKey();
        }
      }
    });

    StorageService.saveLastRead(
      surahNumber: _currentSurah.number,
      ayahNumber: widget.initialAyahIndex + 1,
      surahName: _currentSurah.name,
    );
  }

  void _goToSurah(int surahNumber) {
    if (surahNumber < 1 || surahNumber > 114) return;
    final nextS = QuranService.getSurahByNumber(surahNumber);
    if (nextS != null) {
      setState(() {
        _currentSurah = nextS;
        _highlightedAyahIndex = null;
        _loadSurahDetail();
      });
      _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  void _showFontSizeDialog() {
    final themeProv = Provider.of<ThemeProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Text(
              'حجم الخط القرآني',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
                  style: GoogleFonts.amiri(
                    fontSize: themeProv.fontSize,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Slider(
                  value: themeProv.fontSize,
                  min: 18.0,
                  max: 38.0,
                  divisions: 10,
                  label: themeProv.fontSize.round().toString(),
                  onChanged: (val) {
                    setDialogState(() {
                      themeProv.setFontSize(val);
                    });
                  },
                ),
              ],
            ),
            actions: [
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('تم', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final goldColor = const Color(0xFFD4AF37);
    final themeProv = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        title: Column(
          children: [
            Text(
              _currentSurah.name,
              style: GoogleFonts.amiri(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              '${_currentSurah.isMeccan ? 'مكية 🕋' : 'مدنية 🕌'} • ${_currentSurah.numberOfAyahs} آية',
              style: GoogleFonts.cairo(fontSize: 12, color: isDark ? Colors.white60 : Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              themeProv.isDarkMode ? Icons.wb_sunny_rounded : Icons.nightlight_round,
              color: goldColor,
            ),
            tooltip: themeProv.isDarkMode ? 'الوضع النهاري' : 'الوضع الليلي',
            onPressed: () => themeProv.toggleTheme(),
          ),
          IconButton(
            icon: const Icon(Icons.format_size_rounded),
            tooltip: 'تغيير حجم الخط',
            onPressed: _showFontSizeDialog,
          ),
        ],
      ),
      bottomNavigationBar: const MiniPlayer(),
      body: _surahDetail == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Top Surah Navigator Bar (Clean & Spacious)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF131D2D) : Colors.white,
                    border: Border(
                      bottom: BorderSide(
                        color: isDark ? Colors.white10 : Colors.grey.shade200,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: _currentSurah.number > 1
                            ? () => _goToSurah(_currentSurah.number - 1)
                            : null,
                        icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                        label: Text('السابقة', style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: goldColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: goldColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          'الجزء ${_surahDetail!.ayahs.first.juz} • صفحة ${_surahDetail!.ayahs.first.page}',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: goldColor,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _currentSurah.number < 114
                            ? () => _goToSurah(_currentSurah.number + 1)
                            : null,
                        icon: const Icon(Icons.arrow_back_ios_rounded, size: 14),
                        label: Text('التالية', style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),

                // Main Expanded Quran Reading View
                Expanded(
                  child: ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      // Surah Header Ornamental Banner (Clean & Spacious)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? [const Color(0xFF152238), const Color(0xFF10192A)]
                                : [const Color(0xFFF9F6F0), const Color(0xFFF3ECE1)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: goldColor.withValues(alpha: 0.4), width: 1.5),
                        ),
                        child: Column(
                          children: [
                            Text(
                              _currentSurah.name,
                              style: GoogleFonts.amiri(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: goldColor,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'سورة ${_currentSurah.typeArabic} • آياتها ${_currentSurah.numberOfAyahs}',
                              style: GoogleFonts.cairo(
                                fontSize: 13,
                                color: isDark ? Colors.white70 : Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Bismillah Banner (except Surah 9 At-Tawbah)
                      if (_currentSurah.number != 9) ...[
                        Center(
                          child: Text(
                            'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.amiri(
                              fontSize: themeProv.fontSize + 4,
                              fontWeight: FontWeight.bold,
                              color: isDark ? const Color(0xFFF3C64F) : const Color(0xFF0F5132),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                      ],

                      // Flowing Quran Ayahs Layout (Spacious, Clean, Un-crowded)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF131D2D) : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          textDirection: TextDirection.rtl,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: _surahDetail!.ayahs.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final ayah = entry.value;
                            final isHighlighted = _highlightedAyahIndex == idx;

                            return AnimatedContainer(
                              key: _ayahKeys[idx],
                              duration: const Duration(milliseconds: 350),
                              margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: isHighlighted
                                    ? goldColor.withValues(alpha: isDark ? 0.28 : 0.20)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: isHighlighted
                                    ? Border.all(color: goldColor, width: 1.5)
                                    : null,
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: () {
                                  if (isHighlighted) {
                                    setState(() => _highlightedAyahIndex = null);
                                  }
                                  TafsirBottomSheet.show(context, _currentSurah, ayah);
                                  StorageService.saveLastRead(
                                    surahNumber: _currentSurah.number,
                                    ayahNumber: ayah.numberInSurah,
                                    surahName: _currentSurah.name,
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                                  child: RichText(
                                    textDirection: TextDirection.rtl,
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: '${ayah.text} ',
                                          style: GoogleFonts.amiri(
                                            fontSize: themeProv.fontSize,
                                            height: 2.3,
                                            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
                                            color: isHighlighted
                                                ? (isDark ? const Color(0xFFFDE047) : const Color(0xFF854D0E))
                                                : (isDark ? const Color(0xFFF8FAFC) : const Color(0xFF1E293B)),
                                          ),
                                        ),
                                        WidgetSpan(
                                          alignment: PlaceholderAlignment.middle,
                                          child: Container(
                                            margin: const EdgeInsets.symmetric(horizontal: 6),
                                            padding: const EdgeInsets.all(5),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(color: goldColor, width: 1.2),
                                              color: isHighlighted
                                                  ? goldColor
                                                  : goldColor.withValues(alpha: 0.12),
                                            ),
                                            child: Text(
                                              '${ayah.numberInSurah}',
                                              style: GoogleFonts.cairo(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: isHighlighted ? Colors.black : goldColor,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      const SizedBox(height: 28),

                      Center(
                        child: Text(
                          'اضغط على أي آية لعرض تفسيرها الميسر أو نسخها وحفظها.',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: isDark ? Colors.white54 : Colors.grey.shade600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
