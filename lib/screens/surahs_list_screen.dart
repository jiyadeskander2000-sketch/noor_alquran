import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/surah.dart';
import '../services/audio_manager.dart';
import '../services/quran_service.dart';
import '../services/storage_service.dart';
import '../providers/theme_provider.dart';
import '../widgets/mini_player.dart';
import 'quran_read_screen.dart';
import 'listen_only_screen.dart';
import 'listen_read_screen.dart';

class SurahsListScreen extends StatefulWidget {
  const SurahsListScreen({super.key});

  @override
  State<SurahsListScreen> createState() => _SurahsListScreenState();
}

class _SurahsListScreenState extends State<SurahsListScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'all'; // 'all', 'meccan', 'medinan', 'custom_audio'

  void _showSurahActionDialog(Surah surah) {
    final goldColor = const Color(0xFFD4AF37);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
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
                surah.name,
                style: GoogleFonts.amiri(fontSize: 26, fontWeight: FontWeight.bold, color: goldColor),
              ),
              Text(
                'سورة ${surah.typeArabic} • ${surah.numberOfAyahs} آية',
                style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 18),
              // Option 1: Read only
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                tileColor: isDark ? const Color(0xFF1A263A) : const Color(0xFFF9F7F2),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.menu_book_rounded, color: Colors.blue),
                ),
                title: Text('أقرأ وحدي (المصحف والتفسير)', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                subtitle: Text('عرض الآيات وقراءة التفسير الميسر', style: GoogleFonts.cairo(fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => QuranReadScreen(initialSurah: surah)),
                  );
                },
              ),
              const SizedBox(height: 10),
              // Option 2: Listen only
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                tileColor: isDark ? const Color(0xFF1A263A) : const Color(0xFFF9F7F2),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.headphones_rounded, color: Colors.purple),
                ),
                title: Text('أستمع فقط (مشغل الصوتيات)', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                subtitle: Text('الاستماع لتلاوة القارئ مع التحكم الكامل', style: GoogleFonts.cairo(fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  final audioManager = Provider.of<AudioManager>(context, listen: false);
                  audioManager.playSurah(surah);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ListenOnlyScreen()),
                  );
                },
              ),
              const SizedBox(height: 10),
              // Option 3: Listen and Read (Sync)
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                tileColor: isDark ? const Color(0xFF1A263A) : const Color(0xFFF9F7F2),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: goldColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.auto_mode_rounded, color: goldColor),
                ),
                title: Text('أستمع وأقرأ معاً (المزامنة الذكية)', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                subtitle: Text('متابعة الآية أثناء التلاوة مع التحديث التلقائي', style: GoogleFonts.cairo(fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ListenReadScreen(initialSurah: surah)),
                  );
                },
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

    final audioMap = StorageService.getSurahAudioMap();
    final allSurahs = QuranService.surahs;

    final filtered = allSurahs.where((s) {
      // Filter category
      if (_selectedFilter == 'meccan' && !s.isMeccan) return false;
      if (_selectedFilter == 'medinan' && s.isMeccan) return false;
      if (_selectedFilter == 'custom_audio' && !audioMap.containsKey(s.number)) return false;

      // Query
      if (_searchQuery.isEmpty) return true;
      final normQuery = QuranService.normalizeArabic(_searchQuery);
      final normName = QuranService.normalizeArabic(s.name);
      return normName.contains(normQuery) || s.number.toString() == _searchQuery;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'فهرس سور القرآن الكريم',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18),
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
        ],
      ),
      bottomNavigationBar: const MiniPlayer(),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              style: GoogleFonts.cairo(),
              decoration: InputDecoration(
                hintText: 'ابحث عن اسم السورة أو رقمها...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: isDark ? const Color(0xFF131D2D) : Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade300),
                ),
              ),
            ),
          ),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                ChoiceChip(
                  label: Text('الكل (${allSurahs.length})', style: GoogleFonts.cairo(fontSize: 12)),
                  selected: _selectedFilter == 'all',
                  onSelected: (_) => setState(() => _selectedFilter = 'all'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  avatar: const Text('🕋', style: TextStyle(fontSize: 12)),
                  label: Text('مكية (${allSurahs.where((s) => s.isMeccan).length})', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold)),
                  selected: _selectedFilter == 'meccan',
                  selectedColor: goldColor.withValues(alpha: 0.25),
                  onSelected: (_) => setState(() => _selectedFilter = 'meccan'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  avatar: const Text('🕌', style: TextStyle(fontSize: 12)),
                  label: Text('مدنية (${allSurahs.where((s) => !s.isMeccan).length})', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold)),
                  selected: _selectedFilter == 'medinan',
                  selectedColor: const Color(0xFF0F5132).withValues(alpha: 0.25),
                  onSelected: (_) => setState(() => _selectedFilter = 'medinan'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  avatar: const Icon(Icons.mic_rounded, size: 14),
                  label: Text('تسجيلات القارئ (${audioMap.length})', style: GoogleFonts.cairo(fontSize: 12)),
                  selected: _selectedFilter == 'custom_audio',
                  onSelected: (_) => setState(() => _selectedFilter = 'custom_audio'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Surah List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              physics: const BouncingScrollPhysics(),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final surah = filtered[index];
                final hasCustomAudio = audioMap.containsKey(surah.number);

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: hasCustomAudio ? goldColor.withValues(alpha: 0.4) : (isDark ? Colors.white10 : Colors.grey.shade200),
                      width: 1,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    onTap: () => _showSurahActionDialog(surah),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: goldColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(color: goldColor.withValues(alpha: 0.6), width: 1.2),
                      ),
                      child: Center(
                        child: Text(
                          '${surah.number}',
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: goldColor,
                          ),
                        ),
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            surah.name,
                            style: GoogleFonts.amiri(fontSize: 20, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: surah.isMeccan
                                ? goldColor.withValues(alpha: 0.16)
                                : const Color(0xFF0F5132).withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: surah.isMeccan
                                  ? goldColor.withValues(alpha: 0.4)
                                  : const Color(0xFF0F5132).withValues(alpha: 0.4),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                surah.isMeccan ? '🕋' : '🕌',
                                style: const TextStyle(fontSize: 10),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                surah.isMeccan ? 'مكية' : 'مدنية',
                                style: GoogleFonts.cairo(
                                  fontSize: 10,
                                  color: surah.isMeccan ? goldColor : const Color(0xFF0F5132),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (hasCustomAudio) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.mic_rounded, color: Colors.green, size: 12),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Text(
                      'سورة ${surah.typeArabic} • ${surah.numberOfAyahs} آية',
                      style: GoogleFonts.cairo(fontSize: 12, color: isDark ? Colors.white60 : Colors.grey.shade600),
                    ),
                    trailing: const Icon(Icons.arrow_back_ios_new_rounded, size: 14),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
