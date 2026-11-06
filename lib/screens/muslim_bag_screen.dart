import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/muslim_bag_service.dart';
import '../services/azkar_audio_service.dart';
import '../providers/theme_provider.dart';

class MuslimBagScreen extends StatefulWidget {
  const MuslimBagScreen({super.key});

  @override
  State<MuslimBagScreen> createState() => _MuslimBagScreenState();
}

class _MuslimBagScreenState extends State<MuslimBagScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  double _storyFontSize = 19.0;
  bool _isLoading = true;
  int? _activeCategoryIndex; // null means Category Hub / Dashboard with buttons!

  // Hisn Al Muslim counters state
  final Map<String, int> _hisnCounters = {};

  final List<({String title, String subtitle, IconData icon, Color color, int count})> _categoriesData = const [
    (title: 'قصص الأنبياء والمرسلين', subtitle: '٢٥ نبياً ورسولاً مع العبر والمعجزات', icon: Icons.stars_rounded, color: Colors.amber, count: 25),
    (title: 'الصحابة الكرام رضي الله عنهم', subtitle: 'العشرة المبشرون بالجنة وأبطال الإسلام', icon: Icons.shield_rounded, color: Colors.blue, count: 14),
    (title: 'أمهات المؤمنين وزوجات النبي ﷺ', subtitle: '١١ زوجة مباركة مع تاريخ الزواج والفضائل', icon: Icons.favorite_rounded, color: Colors.pink, count: 11),
    (title: 'الصحابيات الجليلات', subtitle: 'خيرة نساء الأمة وسيرهن العطرة', icon: Icons.spa_rounded, color: Colors.purple, count: 8),
    (title: 'أسماء الله الحسنى الـ 99', subtitle: 'معاني الأسماء الجليلة والشواهد القرآنية', icon: Icons.auto_awesome_rounded, color: Colors.deepOrange, count: 99),
    (title: 'كتاب حصن المسلم الشامل', subtitle: 'الأذكار والأدعية اليومية مع العداد الذكي', icon: Icons.menu_book_rounded, color: Colors.teal, count: 25),
    (title: 'قصص القرآن العظيم', subtitle: 'أصحاب الكهف، ذو القرنين، قارون والمزيد', icon: Icons.auto_stories_rounded, color: Colors.indigo, count: 8),
    (title: 'الحيوان في القرآن الكريم', subtitle: 'قصص الحيوانات المذكورة في التنزيل الحكيم', icon: Icons.pets_rounded, color: Colors.green, count: 8),
    (title: 'معارف وفضائل السور', subtitle: 'أسباب النزول والمقاصد والفضائل الجليلة', icon: Icons.library_books_rounded, color: Colors.blueGrey, count: 114),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 9, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging && _activeCategoryIndex != _tabController.index) {
        setState(() => _activeCategoryIndex = _tabController.index);
      }
    });
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
    _tabController.dispose();
    _searchController.dispose();
    AzkarAudioService().stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final goldColor = isDark ? const Color(0xFFE2C974) : const Color(0xFFB8860B);

    final isInsideCategory = _activeCategoryIndex != null;
    final currentCatTitle = isInsideCategory ? _categoriesData[_activeCategoryIndex!].title : 'حقيبة المسلم الشاملة';

    return PopScope(
      canPop: !isInsideCategory,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (isInsideCategory) {
          setState(() {
            _activeCategoryIndex = null;
            _searchQuery = '';
            _searchController.clear();
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: isInsideCategory
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  tooltip: 'العودة إلى أقسام الحقيبة',
                  onPressed: () {
                    setState(() {
                      _activeCategoryIndex = null;
                      _searchQuery = '';
                      _searchController.clear();
                    });
                  },
                )
              : null,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isInsideCategory ? _categoriesData[_activeCategoryIndex!].icon : Icons.auto_stories_rounded,
                color: goldColor,
                size: 22,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  currentCatTitle,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),
          centerTitle: true,
          actions: [
            // Global audio stop if playing
            ValueListenableBuilder<bool>(
              valueListenable: AzkarAudioService().isPlayingNotifier,
              builder: (ctx, isPlaying, _) {
                if (!isPlaying) return const SizedBox.shrink();
                return IconButton(
                  icon: const Icon(Icons.stop_circle_rounded, color: Colors.amber),
                  tooltip: 'إيقاف الصوت',
                  onPressed: () {
                    AzkarAudioService().stop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم إيقاف الصوت')),
                    );
                  },
                );
              },
            ),
            if (isInsideCategory) ...[
              // Font size decrease
              IconButton(
                icon: const Icon(Icons.text_decrease_rounded, size: 20),
                tooltip: 'تصغير الخط',
                onPressed: () {
                  if (_storyFontSize > 14) {
                    setState(() => _storyFontSize -= 1);
                  }
                },
              ),
              // Font size increase
              IconButton(
                icon: const Icon(Icons.text_increase_rounded, size: 20),
                tooltip: 'تكبير الخط',
                onPressed: () {
                  if (_storyFontSize < 34) {
                    setState(() => _storyFontSize += 1);
                  }
                },
              ),
            ],
          ],
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(isInsideCategory ? 98 : 60),
            child: Column(
              children: [
                // Search Input
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: SizedBox(
                    height: 44,
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val.trim()),
                      textDirection: TextDirection.rtl,
                      style: GoogleFonts.cairo(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: isInsideCategory
                            ? 'ابحث في $currentCatTitle...'
                            : 'ابحث في كافة أقسام وقصص حقيبة المسلم...',
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
                // Pill Switcher when inside category
                if (isInsideCategory)
                  SizedBox(
                    height: 42,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      scrollDirection: Axis.horizontal,
                      itemCount: _categoriesData.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (ctx, i) {
                        final cat = _categoriesData[i];
                        final isSelected = _activeCategoryIndex == i;
                        return InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            setState(() {
                              _activeCategoryIndex = i;
                              _tabController.index = i;
                              _searchQuery = '';
                              _searchController.clear();
                            });
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? goldColor
                                  : (isDark ? const Color(0xFF1E293B) : Colors.grey.shade200),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? goldColor : Colors.transparent,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  cat.icon,
                                  size: 15,
                                  color: isSelected
                                      ? (isDark ? Colors.black87 : Colors.white)
                                      : (isDark ? Colors.white70 : Colors.black87),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  cat.title.split(' ').take(2).join(' '),
                                  style: GoogleFonts.cairo(
                                    fontSize: 11,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected
                                        ? (isDark ? Colors.black87 : Colors.white)
                                        : (isDark ? Colors.white70 : Colors.black87),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : isInsideCategory
                ? _buildActiveCategoryView(isDark, goldColor)
                : _buildCategoryHub(isDark, goldColor),
      ),
    );
  }

  /// Hub of prominent category buttons (البوتنات المفهومة لكل قسم)
  Widget _buildCategoryHub(bool isDark, Color goldColor) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      children: [
        // Welcome and Intro Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF13221C), const Color(0xFF0D1B15)]
                  : [const Color(0xFFF0FDF4), const Color(0xFFE8F5E9)],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: goldColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: goldColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.menu_book_rounded, color: goldColor, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'موسوعة المسلم الشاملة',
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: goldColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'اختر القسم المناسب من الأزرار أدناه للاطلاع على القصص والسير العطرة وأسماء الله وحصن المسلم بسهولة تامة.',
                      textDirection: TextDirection.rtl,
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        height: 1.5,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Section Title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'أقسام الحقيبة (اضغط على أي قسم للدخول):',
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: goldColor,
            ),
          ),
        ),
        const SizedBox(height: 12),
        // 9 Prominent Category Buttons
        ...List.generate(_categoriesData.length, (index) {
          final cat = _categoriesData[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _activeCategoryIndex = index;
                    _tabController.index = index;
                    _searchQuery = '';
                    _searchController.clear();
                  });
                },
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF1E293B), const Color(0xFF152238)]
                          : [Colors.white, const Color(0xFFF9FAFB)],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: goldColor.withValues(alpha: 0.28),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Leading Icon Box
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: cat.color.withValues(alpha: isDark ? 0.2 : 0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: cat.color.withValues(alpha: 0.35)),
                        ),
                        child: Icon(cat.icon, color: cat.color, size: 28),
                      ),
                      const SizedBox(width: 14),
                      // Title & Subtitle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    cat.title,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.cairo(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: goldColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${cat.count}',
                                    style: GoogleFonts.cairo(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: goldColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              cat.subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textDirection: TextDirection.rtl,
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                height: 1.4,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: goldColor.withValues(alpha: 0.7),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildActiveCategoryView(bool isDark, Color goldColor) {
    switch (_activeCategoryIndex) {
      case 0:
        return _buildProphetsTab(isDark, goldColor);
      case 1:
        return _buildSahabaTab(isDark, goldColor);
      case 2:
        return _buildProphetWivesTab(isDark, goldColor);
      case 3:
        return _buildSahabiyatTab(isDark, goldColor);
      case 4:
        return _buildNamesOfAllahTab(isDark, goldColor);
      case 5:
        return _buildHisnAlMuslimTab(isDark, goldColor);
      case 6:
        return _buildQuranStoriesTab(isDark, goldColor);
      case 7:
        return _buildAnimalsTab(isDark, goldColor);
      case 8:
        return _buildSurahsTab(isDark, goldColor);
      default:
        return _buildProphetsTab(isDark, goldColor);
    }
  }

  // 1. Prophets Tab
  Widget _buildProphetsTab(bool isDark, Color gold) {
    final list = MuslimBagService.prophets.where((p) {
      if (_searchQuery.isEmpty) return true;
      return p.name.contains(_searchQuery) ||
          p.title.contains(_searchQuery) ||
          p.fullStory.contains(_searchQuery);
    }).toList();

    if (list.isEmpty) return _buildEmptyState('لا توجد نتائج مطابقة لقصص الأنبياء');

    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: list.length,
      itemBuilder: (ctx, i) {
        final p = list[i];
        return Card(
          elevation: isDark ? 2 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: gold.withValues(alpha: 0.2)),
          ),
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _showProphetDetailsModal(p, isDark, gold),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: gold.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${i + 1}',
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.bold,
                            color: gold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.name,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.amiri(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                                color: gold,
                              ),
                            ),
                            Text(
                              p.title,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.volume_up_rounded, color: Colors.teal),
                        tooltip: 'استماع صوتي للقصة',
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          AzkarAudioService().speakSingleDhikr('${p.name}. ${p.title}. ${p.fullStory}');
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    p.fullStory,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textDirection: TextDirection.rtl,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : Colors.black54,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _buildChip('القوم: ${p.people}', isDark),
                      _buildChip('المعجزة: ${p.miracle}', isDark),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // 2. Sahaba Tab
  Widget _buildSahabaTab(bool isDark, Color gold) {
    final list = MuslimBagService.sahaba.where((s) {
      if (_searchQuery.isEmpty) return true;
      return s.name.contains(_searchQuery) ||
          s.title.contains(_searchQuery) ||
          s.biography.contains(_searchQuery);
    }).toList();

    if (list.isEmpty) return _buildEmptyState('لا توجد نتائج مطابقة لقصص الصحابة');

    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: list.length,
      itemBuilder: (ctx, i) {
        final s = list[i];
        return Card(
          elevation: isDark ? 2 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: gold.withValues(alpha: 0.2)),
          ),
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _showSahabaDetailsModal(s, isDark, gold),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.teal.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.shield_rounded, color: Colors.teal, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.name,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.cairo(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: gold,
                              ),
                            ),
                            Text(
                              s.title,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.volume_up_rounded, color: Colors.teal),
                        tooltip: 'استماع صوتي للسيرة',
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          AzkarAudioService().speakSingleDhikr('${s.name}. ${s.title}. ${s.biography}');
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    s.biography,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textDirection: TextDirection.rtl,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : Colors.black54,
                      height: 1.5,
                    ),
                  ),
                  if (s.famousSaying.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: gold.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '💬 مقولته: "${s.famousSaying}"',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textDirection: TextDirection.rtl,
                        style: GoogleFonts.amiri(
                          fontSize: 12,
                          color: gold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // 3. Prophet's Wives Tab (أمهات المؤمنين)
  Widget _buildProphetWivesTab(bool isDark, Color gold) {
    final list = MuslimBagService.prophetWives.where((w) {
      if (_searchQuery.isEmpty) return true;
      return w.name.contains(_searchQuery) ||
          w.title.contains(_searchQuery) ||
          w.biography.contains(_searchQuery) ||
          w.wisdom.contains(_searchQuery);
    }).toList();

    if (list.isEmpty) return _buildEmptyState('لا توجد نتائج مطابقة لأمهات المؤمنين');

    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: list.length,
      itemBuilder: (ctx, i) {
        final w = list[i];
        return Card(
          elevation: isDark ? 2 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.pink.withValues(alpha: 0.25)),
          ),
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _showProphetWifeModal(w, isDark, gold),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.pink.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${w.order}',
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.bold,
                            color: Colors.pink,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              w.name,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.cairo(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: gold,
                              ),
                            ),
                            Text(
                              w.title,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.volume_up_rounded, color: Colors.pink),
                        tooltip: 'استماع صوتي للسيرة',
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          AzkarAudioService().speakSingleDhikr('${w.name}. ${w.title}. زواجه منها: ${w.marriageDate}. ${w.biography}. الحكمة: ${w.wisdom}');
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.pink.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 14, color: Colors.pink),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'تاريخ الزواج: ${w.marriageDate}',
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.pink.shade200 : Colors.pink.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    w.biography,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textDirection: TextDirection.rtl,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : Colors.black54,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '💡 الحكمة من الزواج: ${w.wisdom}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textDirection: TextDirection.rtl,
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      color: gold,
                      fontWeight: FontWeight.w600,
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

  // 4. Sahabiyat Tab (الصحابيات الجليلات)
  Widget _buildSahabiyatTab(bool isDark, Color gold) {
    final list = MuslimBagService.sahabiyat.where((s) {
      if (_searchQuery.isEmpty) return true;
      return s.name.contains(_searchQuery) ||
          s.title.contains(_searchQuery) ||
          s.biography.contains(_searchQuery);
    }).toList();

    if (list.isEmpty) return _buildEmptyState('لا توجد نتائج مطابقة لقصص الصحابيات');

    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: list.length,
      itemBuilder: (ctx, i) {
        final s = list[i];
        return Card(
          elevation: isDark ? 2 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.purple.withValues(alpha: 0.2)),
          ),
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _showSahabiyaDetailsModal(s, isDark, gold),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.purple.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.favorite_rounded, color: Colors.purple, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.name,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.cairo(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: gold,
                              ),
                            ),
                            Text(
                              s.title,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.volume_up_rounded, color: Colors.purple),
                        tooltip: 'استماع صوتي للسيرة',
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          AzkarAudioService().speakSingleDhikr('${s.name}. ${s.title}. ${s.biography}');
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    s.biography,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textDirection: TextDirection.rtl,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : Colors.black54,
                      height: 1.5,
                    ),
                  ),
                  if (s.role.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '🌺 الأثر والدور: ${s.role}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textDirection: TextDirection.rtl,
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.purple.shade200 : Colors.purple.shade700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // 5. Names of Allah (أسماء الله الحسنى الـ 99)
  Widget _buildNamesOfAllahTab(bool isDark, Color gold) {
    final list = MuslimBagService.namesOfAllah.where((n) {
      if (_searchQuery.isEmpty) return true;
      return n.name.contains(_searchQuery) ||
          n.meaning.contains(_searchQuery) ||
          n.proof.contains(_searchQuery);
    }).toList();

    if (list.isEmpty) return _buildEmptyState('لا توجد نتائج مطابقة لأسماء الله الحسنى');

    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: list.length,
      itemBuilder: (ctx, i) {
        final n = list[i];
        return Card(
          elevation: isDark ? 2 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: gold.withValues(alpha: 0.25)),
          ),
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _showNameOfAllahModal(n, isDark, gold),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: gold.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${n.id}',
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.bold,
                            color: gold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              n.name,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.amiri(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: gold,
                              ),
                            ),
                            Text(
                              n.meaning,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.volume_up_rounded, color: Colors.teal),
                        tooltip: 'استماع صوتي للاسم وشرحه',
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          AzkarAudioService().speakSingleDhikr('${n.name}. معناه: ${n.meaning}. والدليل من القرآن: ${n.proof}');
                        },
                      ),
                    ],
                  ),
                  if (n.proof.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: gold.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        n.proof,
                        textDirection: TextDirection.rtl,
                        style: GoogleFonts.amiri(
                          fontSize: 13,
                          color: gold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // 6. Hisn Al-Muslim Tab (حصن المسلم)
  Widget _buildHisnAlMuslimTab(bool isDark, Color gold) {
    final list = MuslimBagService.hisnChapters.where((c) {
      if (_searchQuery.isEmpty) return true;
      if (c.title.contains(_searchQuery)) return true;
      return c.hadiths.any((h) => h.text.contains(_searchQuery) || h.virtue.contains(_searchQuery));
    }).toList();

    if (list.isEmpty) return _buildEmptyState('لا توجد نتائج مطابقة في كتاب حصن المسلم');

    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: list.length,
      itemBuilder: (ctx, i) {
        final c = list[i];
        return Card(
          elevation: isDark ? 2 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.green.withValues(alpha: 0.3)),
          ),
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _showHisnChapterModal(c, isDark, gold),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.menu_book_rounded, color: Colors.green, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c.title,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.cairo(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: gold,
                              ),
                            ),
                            Text(
                              '${c.hadiths.length} أدعية وأحاديث مأثورة',
                              style: GoogleFonts.cairo(
                                fontSize: 11,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (c.hadiths.isNotEmpty)
                    Text(
                      c.hadiths.first.text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textDirection: TextDirection.rtl,
                      style: GoogleFonts.amiri(
                        fontSize: 15,
                        color: isDark ? Colors.white70 : Colors.black87,
                        height: 1.8,
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

  // 7. Quran Stories Tab
  Widget _buildQuranStoriesTab(bool isDark, Color gold) {
    final list = MuslimBagService.quranStories.where((q) {
      if (_searchQuery.isEmpty) return true;
      return q.title.contains(_searchQuery) ||
          q.surahReference.contains(_searchQuery) ||
          q.fullNarrative.contains(_searchQuery);
    }).toList();

    if (list.isEmpty) return _buildEmptyState('لا توجد نتائج مطابقة لقصص القرآن');

    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: list.length,
      itemBuilder: (ctx, i) {
        final q = list[i];
        return Card(
          elevation: isDark ? 2 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: gold.withValues(alpha: 0.2)),
          ),
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _showQuranStoryModal(q, isDark, gold),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: gold.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.auto_stories_rounded, color: Color(0xFFD4AF37), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              q.title,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.cairo(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: gold,
                              ),
                            ),
                            Text(
                              q.surahReference,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.volume_up_rounded, color: Colors.teal),
                        tooltip: 'استماع صوتي للقصة',
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          AzkarAudioService().speakSingleDhikr('${q.title}. ${q.surahReference}. ${q.fullNarrative}');
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    q.fullNarrative,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textDirection: TextDirection.rtl,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : Colors.black54,
                      height: 1.5,
                    ),
                  ),
                  if (q.spiritualLessons.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildChip('درس إيماني: ${q.spiritualLessons.first}', isDark),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // 8. Animals Tab
  Widget _buildAnimalsTab(bool isDark, Color gold) {
    final list = MuslimBagService.animalStories.where((a) {
      if (_searchQuery.isEmpty) return true;
      return a.animal.contains(_searchQuery) ||
          a.associatedProphet.contains(_searchQuery) ||
          a.story.contains(_searchQuery);
    }).toList();

    if (list.isEmpty) return _buildEmptyState('لا توجد نتائج مطابقة لقصص الحيوان في القرآن');

    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: list.length,
      itemBuilder: (ctx, i) {
        final a = list[i];
        return Card(
          elevation: isDark ? 2 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.amber.withValues(alpha: 0.2)),
          ),
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _showAnimalStoryModal(a, isDark, gold),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.pets_rounded, color: Colors.amber, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              a.animal,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.cairo(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: gold,
                              ),
                            ),
                            Text(
                              'مع ${a.associatedProphet}',
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.volume_up_rounded, color: Colors.amber),
                        tooltip: 'استماع صوتي للقصة',
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          AzkarAudioService().speakSingleDhikr('${a.animal} مع ${a.associatedProphet}. ${a.surahReference}. ${a.story}. الحكمة الإلهية: ${a.divineWisdom}');
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    a.story,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textDirection: TextDirection.rtl,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : Colors.black54,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '💡 الحكمة: ${a.divineWisdom}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textDirection: TextDirection.rtl,
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      color: gold,
                      fontWeight: FontWeight.w600,
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

  // 9. Surahs Insights Tab
  Widget _buildSurahsTab(bool isDark, Color gold) {
    final list = MuslimBagService.surahInsights.where((s) {
      if (_searchQuery.isEmpty) return true;
      return s.name.contains(_searchQuery) ||
          s.virtues.contains(_searchQuery) ||
          s.reasonOfNaming.contains(_searchQuery);
    }).toList();

    if (list.isEmpty) return _buildEmptyState('لا توجد نتائج مطابقة لفضائل ومعارف السور');

    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: list.length,
      itemBuilder: (ctx, i) {
        final s = list[i];
        return Card(
          elevation: isDark ? 2 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: gold.withValues(alpha: 0.2)),
          ),
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _showSurahDetailsModal(s, isDark, gold),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: gold.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${s.number}',
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.bold,
                            color: gold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'سورة ${s.name}',
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.amiri(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: gold,
                              ),
                            ),
                            Text(
                              '${s.revelationType} • آياتها ${s.ayahCount}',
                              style: GoogleFonts.cairo(
                                fontSize: 11,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.volume_up_rounded, color: Colors.teal),
                        tooltip: 'استماع صوتي لفضائل السورة',
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          AzkarAudioService().speakSingleDhikr('سورة ${s.name}. فضلها: ${s.virtues}. سبب التسمية: ${s.reasonOfNaming}');
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s.virtues,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textDirection: TextDirection.rtl,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : Colors.black54,
                      height: 1.5,
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

  // --- MODALS & DETAILS SHEETS ---

  void _showProphetDetailsModal(ProphetStory p, bool isDark, Color gold) {
    _showStoryModal(
      title: p.name,
      subtitle: '${p.title} • ${p.period}',
      content: p.fullStory,
      isDark: isDark,
      gold: gold,
      extraSections: [
        _buildInfoSection('المعجزة الكبرى', p.miracle, isDark, gold),
        if (p.quranVerses.isNotEmpty)
          _buildInfoSection(
            'من الآيات القرآنية الكريمة',
            p.quranVerses.map((v) => '﴿ $v ﴾').join('\n\n'),
            isDark,
            gold,
          ),
        if (p.lessons.isNotEmpty)
          _buildInfoSection(
            'الدروس والعبر المستفادة',
            p.lessons.map((l) => '• $l').join('\n'),
            isDark,
            gold,
          ),
      ],
    );
  }

  void _showSahabaDetailsModal(SahabaStory s, bool isDark, Color gold) {
    _showStoryModal(
      title: s.name,
      subtitle: s.title,
      content: s.biography,
      isDark: isDark,
      gold: gold,
      extraSections: [
        if (s.virtues.isNotEmpty) _buildInfoSection('الفضائل والمكانة', s.virtues, isDark, gold),
        if (s.famousSaying.isNotEmpty) _buildInfoSection('من أقواله الخالدة', '"${s.famousSaying}"', isDark, gold),
        if (s.keyEvents.isNotEmpty)
          _buildInfoSection(
            'محطات ومواقف بارزة',
            s.keyEvents.map((e) => '• $e').join('\n'),
            isDark,
            gold,
          ),
      ],
    );
  }

  void _showProphetWifeModal(ProphetWife w, bool isDark, Color gold) {
    _showStoryModal(
      title: w.name,
      subtitle: '${w.title} • الزوجة رقم ${w.order}',
      content: w.biography,
      isDark: isDark,
      gold: gold,
      extraSections: [
        _buildInfoSection('تاريخ الزواج المبارك', w.marriageDate, isDark, Colors.pink),
        _buildInfoSection('الحكمة الربانية والتشريعية من الزواج', w.wisdom, isDark, gold),
        _buildInfoSection('تاريخ ومكان الوفاة', w.death, isDark, isDark ? Colors.white60 : Colors.black54),
      ],
    );
  }

  void _showSahabiyaDetailsModal(SahabiyaStory s, bool isDark, Color gold) {
    _showStoryModal(
      title: s.name,
      subtitle: s.title,
      content: s.biography,
      isDark: isDark,
      gold: gold,
      extraSections: [
        if (s.role.isNotEmpty) _buildInfoSection('أثرها ودورها في الإسلام', s.role, isDark, Colors.purple),
        if (s.qualities.isNotEmpty)
          _buildInfoSection(
            'أبرز شمائلها وصفاتها',
            s.qualities.map((q) => '• $q').join('\n'),
            isDark,
            gold,
          ),
      ],
    );
  }

  void _showNameOfAllahModal(NameOfAllah n, bool isDark, Color gold) {
    _showStoryModal(
      title: n.name,
      subtitle: 'اسم من أسماء الله الحسنى (الرقم ${n.id})',
      content: n.meaning,
      isDark: isDark,
      gold: gold,
      extraSections: [
        if (n.proof.isNotEmpty) _buildInfoSection('الدليل والشاهد القرآني', n.proof, isDark, gold),
      ],
    );
  }

  void _showHisnChapterModal(HisnChapter c, bool isDark, Color gold) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.88,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF161F2E) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            AzkarAudioService().stop();
                            Navigator.pop(ctx);
                          },
                        ),
                        Expanded(
                          child: Text(
                            c.title,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: gold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.volume_up_rounded),
                          tooltip: 'استماع لجميع أدعية الباب',
                          onPressed: () {
                            final allText = c.hadiths.map((h) => h.text).join('. ');
                            AzkarAudioService().speakSingleDhikr(allText);
                          },
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: c.hadiths.length,
                      itemBuilder: (ctx, idx) {
                        final h = c.hadiths[idx];
                        final key = '${c.chapterId}_$idx';
                        final count = _hisnCounters[key] ?? 0;

                        return Card(
                          elevation: 1,
                          margin: const EdgeInsets.only(bottom: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: gold.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'دعاء ${idx + 1}',
                                        style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.bold, color: gold),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.volume_up_rounded, size: 20),
                                          onPressed: () => AzkarAudioService().speakSingleDhikr(h.text),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.copy_rounded, size: 18),
                                          onPressed: () {
                                            Clipboard.setData(ClipboardData(text: '${h.text}\n[${h.source}]'));
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('تم نسخ الدعاء')),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  h.text,
                                  textDirection: TextDirection.rtl,
                                  style: GoogleFonts.amiri(
                                    fontSize: _storyFontSize,
                                    height: 2.1,
                                    color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                if (h.virtue.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '✨ الفضل: ${h.virtue}',
                                      textDirection: TextDirection.rtl,
                                      style: GoogleFonts.cairo(fontSize: 11, color: Colors.green),
                                    ),
                                  ),
                                const SizedBox(height: 6),
                                Text(
                                  'المصدر: ${h.source}',
                                  textDirection: TextDirection.rtl,
                                  style: GoogleFonts.cairo(fontSize: 10, color: Colors.grey),
                                ),
                                const SizedBox(height: 10),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    setModalState(() {
                                      _hisnCounters[key] = count + 1;
                                    });
                                  },
                                  icon: const Icon(Icons.touch_app_rounded, size: 16),
                                  label: Text(
                                    'تسبيح (تكرار: $count)',
                                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: gold.withValues(alpha: 0.2),
                                    foregroundColor: gold,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showQuranStoryModal(QuranStoryItem q, bool isDark, Color gold) {
    _showStoryModal(
      title: q.title,
      subtitle: q.surahReference,
      content: q.fullNarrative,
      isDark: isDark,
      gold: gold,
      extraSections: [
        if (q.mainEvent.isNotEmpty) _buildInfoSection('الحدث والمنعطف المحوري', q.mainEvent, isDark, gold),
        if (q.spiritualLessons.isNotEmpty)
          _buildInfoSection(
            'العبر والدروس الإيمانية',
            q.spiritualLessons.map((l) => '• $l').join('\n'),
            isDark,
            gold,
          ),
      ],
    );
  }

  void _showAnimalStoryModal(AnimalStoryItem a, bool isDark, Color gold) {
    _showStoryModal(
      title: a.animal,
      subtitle: 'مع ${a.associatedProphet} • ${a.surahReference}',
      content: a.story,
      isDark: isDark,
      gold: gold,
      extraSections: [
        _buildInfoSection('الحكمة الإلهية من ذكر القصة', a.divineWisdom, isDark, gold),
      ],
    );
  }

  void _showSurahDetailsModal(SurahInsightItem s, bool isDark, Color gold) {
    _showStoryModal(
      title: 'سورة ${s.name}',
      subtitle: '${s.revelationType} • ${s.ayahCount} آية',
      content: s.virtues,
      isDark: isDark,
      gold: gold,
      extraSections: [
        _buildInfoSection('سبب التسمية والنزول', s.reasonOfNaming, isDark, gold),
        if (s.majorThemes.isNotEmpty)
          _buildInfoSection(
            'أبرز المحاور والمقاصد الكبرى للسورة',
            s.majorThemes.map((t) => '• $t').join('\n'),
            isDark,
            gold,
          ),
      ],
    );
  }

  void _showStoryModal({
    required String title,
    required String subtitle,
    required String content,
    required bool isDark,
    required Color gold,
    List<Widget> extraSections = const [],
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.88,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF161F2E) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  // Header Bar with Actions
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            AzkarAudioService().stop();
                            Navigator.pop(ctx);
                          },
                        ),
                        Expanded(
                          child: Text(
                            title,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.cairo(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: gold,
                            ),
                          ),
                        ),
                        // Listen Voice
                        IconButton(
                          icon: const Icon(Icons.volume_up_rounded),
                          tooltip: 'استماع صوتي للقراءة',
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            AzkarAudioService().speakSingleDhikr(content);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('جاري القراءة الصوتية...'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                        // Copy
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 20),
                          tooltip: 'نسخ المحتوى',
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: '$title\n\n$content'));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('تم نسخ القصة إلى الحافظة بنجاح'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  // Font Size Controls
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, size: 20),
                          onPressed: () {
                            if (_storyFontSize > 14) {
                              setModalState(() => _storyFontSize -= 1);
                              setState(() => _storyFontSize -= 1);
                            }
                          },
                        ),
                        Text(
                          'حجم الخط: ${_storyFontSize.toInt()}',
                          style: GoogleFonts.cairo(fontSize: 12),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, size: 20),
                          onPressed: () {
                            if (_storyFontSize < 34) {
                              setModalState(() => _storyFontSize += 1);
                              setState(() => _storyFontSize += 1);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // Content Scroll
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            subtitle,
                            textAlign: TextAlign.center,
                            textDirection: TextDirection.rtl,
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            content,
                            textAlign: TextAlign.right,
                            textDirection: TextDirection.rtl,
                            style: GoogleFonts.amiri(
                              fontSize: _storyFontSize,
                              height: 2.2,
                              fontWeight: FontWeight.w500,
                              color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                            ),
                          ),
                          ...extraSections,
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoSection(String heading, String body, bool isDark, Color gold) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: gold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: gold.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            heading,
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: gold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            textDirection: TextDirection.rtl,
            style: GoogleFonts.amiri(
              fontSize: _storyFontSize - 2,
              height: 1.9,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.cairo(
          fontSize: 10,
          color: isDark ? Colors.white70 : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              msg,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
