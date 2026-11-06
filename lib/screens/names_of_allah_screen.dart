import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/muslim_bag_service.dart';
import '../services/azkar_audio_service.dart';
import '../providers/theme_provider.dart';
import '../widgets/mini_player.dart';

class NamesOfAllahScreen extends StatefulWidget {
  const NamesOfAllahScreen({super.key});

  @override
  State<NamesOfAllahScreen> createState() => _NamesOfAllahScreenState();
}

class _NamesOfAllahScreenState extends State<NamesOfAllahScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  double _fontSize = 18.0;
  bool _isLoading = true;
  bool _isGridView = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await MuslimBagService.loadAll();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    AzkarAudioService().stop();
    super.dispose();
  }

  void _showNameDetailsModal(BuildContext context, NameOfAllah nameItem, bool isDark, Color goldColor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161F2E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: goldColor.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Name Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: goldColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: goldColor.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      'الاسم رقم ${nameItem.id}',
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: goldColor,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.volume_up_rounded, color: Colors.teal),
                        tooltip: 'استماع صوتي',
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          AzkarAudioService().speakSingleDhikr(
                            '${nameItem.name}. معناه: ${nameItem.meaning}. الشاهد من القرآن: ${nameItem.proof}',
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 20),
                        tooltip: 'نسخ',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(
                            text: '${nameItem.name}\nالمعنى: ${nameItem.meaning}\nالدليل: ${nameItem.proof}',
                          ));
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('تم نسخ الاسم ومعناه')),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Calligraphic Big Name
              Center(
                child: Text(
                  nameItem.name,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.amiri(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: goldColor,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Meaning
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'معنى الاسم الجليل:',
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: goldColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      nameItem.meaning,
                      textDirection: TextDirection.rtl,
                      style: GoogleFonts.cairo(
                        fontSize: _fontSize,
                        height: 1.8,
                        color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),
              if (nameItem.proof.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: goldColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: goldColor.withValues(alpha: 0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الشاهد والدليل من القرآن الكريم:',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: goldColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '﴿ ${nameItem.proof} ﴾',
                        textDirection: TextDirection.rtl,
                        style: GoogleFonts.amiri(
                          fontSize: _fontSize + 1,
                          fontWeight: FontWeight.bold,
                          color: goldColor,
                          height: 1.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final goldColor = isDark ? const Color(0xFFE2C974) : const Color(0xFFB8860B);

    final filtered = MuslimBagService.namesOfAllah.where((n) {
      if (_searchQuery.isEmpty) return true;
      return n.name.contains(_searchQuery) ||
          n.meaning.contains(_searchQuery) ||
          n.proof.contains(_searchQuery) ||
          n.id.toString() == _searchQuery;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome_rounded, color: goldColor, size: 22),
            const SizedBox(width: 8),
            Text(
              'أسماء الله الحسنى (99)',
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          // View Switcher (Grid vs List)
          IconButton(
            icon: Icon(_isGridView ? Icons.view_agenda_rounded : Icons.grid_view_rounded),
            tooltip: _isGridView ? 'عرض البطاقات الموسعة' : 'عرض الشبكة المدمجة',
            onPressed: () {
              setState(() => _isGridView = !_isGridView);
            },
          ),
          // Audio stop if playing
          ValueListenableBuilder<bool>(
            valueListenable: AzkarAudioService().isPlayingNotifier,
            builder: (ctx, isPlaying, _) {
              if (!isPlaying) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.stop_circle_rounded, color: Colors.amber),
                tooltip: 'إيقاف الصوت',
                onPressed: () => AzkarAudioService().stop(),
              );
            },
          ),
          // Font size controls
          IconButton(
            icon: const Icon(Icons.text_decrease_rounded, size: 20),
            tooltip: 'تصغير الخط',
            onPressed: () {
              if (_fontSize > 14) setState(() => _fontSize -= 1);
            },
          ),
          IconButton(
            icon: const Icon(Icons.text_increase_rounded, size: 20),
            tooltip: 'تكبير الخط',
            onPressed: () {
              if (_fontSize < 28) setState(() => _fontSize += 1);
            },
          ),
        ],
      ),
      bottomNavigationBar: const MiniPlayer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Noble Hadith Card (محسن الرؤية - مريح وغير مزدحم)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF13221C), const Color(0xFF0D1B15)]
                          : [const Color(0xFFF0FDF4), const Color(0xFFE8F5E9)],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: goldColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: goldColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.stars_rounded, color: goldColor, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'قال رسول الله ﷺ: «إنَّ للهِ تسعةً وتسعين اسمًا، مَن أحصاها دخل الجنة»',
                              textDirection: TextDirection.rtl,
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: goldColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'إحصاؤها: حفظها، وفهم معانيها، والدعاء والعمل بمقتضاها.',
                              textDirection: TextDirection.rtl,
                              style: GoogleFonts.cairo(
                                fontSize: 11,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: SizedBox(
                    height: 46,
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val.trim()),
                      textDirection: TextDirection.rtl,
                      style: GoogleFonts.cairo(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'ابحث باسم من أسماء الله، أو معناه، أو الشاهد...',
                        hintStyle: GoogleFonts.cairo(fontSize: 12, color: Colors.grey),
                        prefixIcon: Icon(Icons.search_rounded, size: 20, color: goldColor),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF161F2E) : Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ),

                // Main Content View
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Text(
                            'لا توجد نتائج مطابقة لاسم الله المستعلم عنه',
                            style: GoogleFonts.cairo(fontSize: 14, color: Colors.grey),
                          ),
                        )
                      : _isGridView
                          ? _buildNamesGrid(filtered, isDark, goldColor)
                          : _buildNamesList(filtered, isDark, goldColor),
                ),
              ],
            ),
    );
  }

  Widget _buildNamesGrid(List<NameOfAllah> items, bool isDark, Color goldColor) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 80),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.95,
      ),
      itemCount: items.length,
      itemBuilder: (ctx, idx) {
        final n = items[idx];
        return InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            _showNameDetailsModal(context, n, isDark, goldColor);
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1A2639), const Color(0xFF121B29)]
                    : [const Color(0xFFFFFFFF), const Color(0xFFF9FAFB)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: goldColor.withValues(alpha: 0.25)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: goldColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${n.id}',
                    style: GoogleFonts.cairo(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: goldColor,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    n.name,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.amiri(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: goldColor,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'اضغط للتفاصيل',
                  style: GoogleFonts.cairo(fontSize: 9, color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNamesList(List<NameOfAllah> items, bool isDark, Color goldColor) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 80),
      itemCount: items.length,
      itemBuilder: (ctx, idx) {
        final n = items[idx];
        return Card(
          elevation: isDark ? 2 : 1,
          margin: const EdgeInsets.only(bottom: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: goldColor.withValues(alpha: 0.28)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top row with Name, Badge, Audio and Copy
                Row(
                  children: [
                    // Number Badge
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: goldColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(color: goldColor.withValues(alpha: 0.4)),
                      ),
                      child: Center(
                        child: Text(
                          '${n.id}',
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: goldColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Name in Majestic Calligraphy
                    Expanded(
                      child: Text(
                        n.name,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.amiri(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: goldColor,
                        ),
                      ),
                    ),
                    // Audio Button
                    IconButton(
                      icon: const Icon(Icons.volume_up_rounded, color: Colors.teal),
                      tooltip: 'استماع صوتي للاسم وشرحه',
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        AzkarAudioService().speakSingleDhikr(
                          '${n.name}. معناه: ${n.meaning}. ومن القرآن: ${n.proof}',
                        );
                      },
                    ),
                    // Copy Button
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 20),
                      tooltip: 'نسخ الاسم ومعناه',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(
                          text: '${n.name}\nالمعنى: ${n.meaning}\nالدليل: ${n.proof}',
                        ));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تم نسخ الاسم ومعناه إلى الحافظة')),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Meaning (Spacious & Clean typography)
                Text(
                  n.meaning,
                  textDirection: TextDirection.rtl,
                  style: GoogleFonts.cairo(
                    fontSize: _fontSize - 3,
                    height: 1.7,
                    color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                  ),
                ),
                if (n.proof.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: goldColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: goldColor.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      '﴿ ${n.proof} ﴾',
                      textDirection: TextDirection.rtl,
                      style: GoogleFonts.amiri(
                        fontSize: _fontSize - 1,
                        fontWeight: FontWeight.bold,
                        color: goldColor,
                        height: 1.8,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
