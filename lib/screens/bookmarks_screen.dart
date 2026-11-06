import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import '../services/quran_service.dart';
import '../providers/theme_provider.dart';
import '../widgets/mini_player.dart';
import 'quran_read_screen.dart';
import 'listen_read_screen.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  List<BookmarkItem> _bookmarks = [];

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  void _loadBookmarks() {
    setState(() {
      _bookmarks = StorageService.getBookmarks();
    });
  }

  Future<void> _deleteBookmark(BookmarkItem bookmark) async {
    await StorageService.toggleBookmark(bookmark);
    _loadBookmarks();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف الإشارة المرجعية')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final goldColor = const Color(0xFFD4AF37);
    final themeProv = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'العلامات المرجعية',
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
      body: _bookmarks.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_border_rounded, size: 70, color: Colors.grey.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد علامات مرجعية محفوظة حالياً',
                    style: GoogleFonts.cairo(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'يمكنك حفظ أي آية بالضغط عليها أثناء القراءة.',
                    style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              physics: const BouncingScrollPhysics(),
              itemCount: _bookmarks.length,
              itemBuilder: (context, idx) {
                final b = _bookmarks[idx];
                final surah = QuranService.getSurahByNumber(b.surahNumber);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      if (surah != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => QuranReadScreen(
                              initialSurah: surah,
                              initialAyahIndex: b.ayahNumber - 1,
                            ),
                          ),
                        );
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Icon(Icons.bookmark_rounded, color: goldColor, size: 20),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        '${b.surahName} • الآية ${b.ayahNumber}',
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.cairo(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: goldColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                                tooltip: 'حذف الإشارة',
                                onPressed: () => _deleteBookmark(b),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            b.ayahText,
                            textAlign: TextAlign.right,
                            textDirection: TextDirection.rtl,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.amiri(
                              fontSize: 18,
                              height: 1.8,
                              color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            alignment: WrapAlignment.end,
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              TextButton.icon(
                                onPressed: () {
                                  if (surah != null) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => QuranReadScreen(
                                          initialSurah: surah,
                                          initialAyahIndex: b.ayahNumber - 1,
                                        ),
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.menu_book_rounded, size: 16),
                                label: Text('قراءة الآية', style: GoogleFonts.cairo(fontSize: 12)),
                              ),
                              ElevatedButton.icon(
                                onPressed: () {
                                  if (surah != null) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ListenReadScreen(
                                          initialSurah: surah,
                                          initialAyahIndex: b.ayahNumber - 1,
                                        ),
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.play_arrow_rounded, size: 16, color: Colors.white),
                                label: Text('استماع ومزامنة', style: GoogleFonts.cairo(fontSize: 12, color: Colors.white)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
