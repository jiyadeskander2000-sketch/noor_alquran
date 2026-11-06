import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/azkar.dart';
import '../services/quran_service.dart';
import '../services/azkar_audio_service.dart';
import '../providers/theme_provider.dart';
import '../widgets/mini_player.dart';

class AzkarScreen extends StatefulWidget {
  final String? initialCategory;
  const AzkarScreen({super.key, this.initialCategory});

  @override
  State<AzkarScreen> createState() => _AzkarScreenState();
}

class _AzkarScreenState extends State<AzkarScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<AzkarCategory> _categories = QuranService.azkarList;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  double _fontSize = 19.0;

  // Digital Subha state
  int _subhaCount = 0;
  String _selectedSubhaDhikr = 'سُبْحَانَ اللَّهِ';
  final List<String> _subhaPresets = [
    'سُبْحَانَ اللَّهِ',
    'الْحَمْدُ لِلَّهِ',
    'لَا إِلَهَ إِلَّا اللَّهُ',
    'اللَّهُ أَكْبَرُ',
    'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ',
    'أَسْتَغْفِرُ اللَّهَ وَأَتُوبُ إِلَيْهِ',
    'اللَّهُمَّ صَلِّ عَلَى نَبِيِّنَا مُحَمَّدٍ',
    'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ سُبْحَانَ اللَّهِ الْعَظِيمِ',
  ];

  int? _activeCategoryIndex;

  @override
  void initState() {
    super.initState();
    int initialIdx = 0;
    if (widget.initialCategory != null) {
      final found = _categories.indexWhere(
        (c) => c.category.contains(widget.initialCategory!),
      );
      if (found != -1) {
        initialIdx = found;
        _activeCategoryIndex = found;
      }
    }
    _tabController = TabController(
      length: _categories.length,
      initialIndex: initialIdx,
      vsync: this,
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging && _activeCategoryIndex != _tabController.index) {
        setState(() => _activeCategoryIndex = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    AzkarAudioService().stop();
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _openDigitalSubhaModal(BuildContext context, bool isDark, Color gold) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.72,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF161F2E) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'المسبحة الإلكترونية',
                          style: GoogleFonts.cairo(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: gold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh_rounded),
                          tooltip: 'تصفير العداد',
                          onPressed: () {
                            setModalState(() => _subhaCount = 0);
                            setState(() => _subhaCount = 0);
                          },
                        ),
                      ],
                    ),
                  ),
                  // Dropdown to pick preset
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: DropdownButtonFormField<String>(
                      value: _selectedSubhaDhikr,
                      isExpanded: true,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      items: _subhaPresets.map((d) {
                        return DropdownMenuItem(
                          value: d,
                          child: Text(
                            d,
                            style: GoogleFonts.amiri(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() {
                            _selectedSubhaDhikr = val;
                            _subhaCount = 0;
                          });
                          setState(() {
                            _selectedSubhaDhikr = val;
                            _subhaCount = 0;
                          });
                        }
                      },
                    ),
                  ),
                  const Spacer(),
                  // Counter Display & Big Button
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setModalState(() => _subhaCount++);
                      setState(() => _subhaCount++);
                    },
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: isDark
                              ? [const Color(0xFF1A362C), const Color(0xFF0F5132)]
                              : [const Color(0xFF0F5132), const Color(0xFF1B6B4C)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: gold.withValues(alpha: 0.35),
                            blurRadius: 28,
                            spreadRadius: 2,
                          ),
                        ],
                        border: Border.all(color: gold, width: 3),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$_subhaCount',
                            style: GoogleFonts.cairo(
                              fontSize: 54,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'اضغط للتسبيح',
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              color: gold,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Text(
                      '«سُبْحَانَ اللَّهِ وَبِحَمْدِهِ عَدَدَ خَلْقِهِ وَرِضَا نَفْسِهِ وَزِنَةَ عَرْشِهِ وَمِدَادَ كَلِمَاتِهِ»',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.amiri(
                        fontSize: 14,
                        color: isDark ? Colors.white70 : Colors.black87,
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

  void _showFontSizeDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text(
                'حجم خط الأذكار والدعاء',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                    style: GoogleFonts.amiri(fontSize: _fontSize, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Slider(
                    value: _fontSize,
                    min: 15.0,
                    max: 30.0,
                    divisions: 15,
                    label: _fontSize.toInt().toString(),
                    onChanged: (val) {
                      setDialogState(() => _fontSize = val);
                      setState(() => _fontSize = val);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('تم', style: GoogleFonts.cairo()),
                ),
              ],
            );
          },
        );
      },
    );
  }

  IconData _getCategoryIcon(String category) {
    if (category.contains('الصباح')) return Icons.wb_sunny_rounded;
    if (category.contains('المساء')) return Icons.nightlight_round;
    if (category.contains('النوم') || category.contains('الأرق')) return Icons.bedtime_rounded;
    if (category.contains('الاستيقاظ')) return Icons.alarm_rounded;
    if (category.contains('الصلاة') || category.contains('الأذان')) return Icons.mosque_rounded;
    if (category.contains('المسجد')) return Icons.account_balance_rounded;
    if (category.contains('الوضوء') || category.contains('المنزل')) return Icons.home_rounded;
    if (category.contains('الكرب') || category.contains('الهم')) return Icons.healing_rounded;
    if (category.contains('الاستخارة') || category.contains('التوبة')) return Icons.favorite_rounded;
    if (category.contains('السفر')) return Icons.flight_takeoff_rounded;
    if (category.contains('الرقية') || category.contains('الشفاء')) return Icons.shield_rounded;
    if (category.contains('الأنبياء')) return Icons.stars_rounded;
    if (category.contains('القرآن الكريم')) return Icons.menu_book_rounded;
    if (category.contains('السنة النبوية')) return Icons.auto_stories_rounded;
    if (category.contains('الوالدين')) return Icons.family_restroom_rounded;
    if (category.contains('الرزق')) return Icons.paid_rounded;
    if (category.contains('المطر')) return Icons.water_drop_rounded;
    if (category.contains('الطعام')) return Icons.restaurant_rounded;
    if (category.contains('ختم القرآن')) return Icons.bookmark_added_rounded;
    if (category.contains('النبي')) return Icons.star_rounded;
    if (category.contains('تسابيح')) return Icons.touch_app_rounded;
    return Icons.menu_book_rounded;
  }

  Color _getCategoryColor(String category) {
    if (category.contains('الصباح')) return Colors.orange;
    if (category.contains('المساء')) return Colors.indigo;
    if (category.contains('النوم')) return Colors.deepPurple;
    if (category.contains('الصلاة')) return Colors.teal;
    if (category.contains('الرقية')) return Colors.green;
    if (category.contains('الأنبياء')) return Colors.amber;
    if (category.contains('القرآن')) return Colors.teal;
    if (category.contains('ختم القرآن')) return Colors.purple;
    return const Color(0xFF0F5132);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final goldColor = const Color(0xFFD4AF37);
    final themeProv = Provider.of<ThemeProvider>(context);

    final isInsideCategory = _activeCategoryIndex != null;
    final currentCat = isInsideCategory ? _categories[_activeCategoryIndex!] : null;
    final currentTitle = currentCat != null ? currentCat.category : 'الأدعية والأذكار الجامعة';

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
                  tooltip: 'العودة لأقسام الأذكار',
                  onPressed: () {
                    setState(() {
                      _activeCategoryIndex = null;
                      _searchQuery = '';
                      _searchController.clear();
                    });
                  },
                )
              : null,
          title: Text(
            currentTitle,
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.format_size_rounded),
              tooltip: 'حجم الخط',
              onPressed: _showFontSizeDialog,
            ),
            IconButton(
              icon: const Icon(Icons.circle_outlined),
              tooltip: 'المسبحة الإلكترونية',
              onPressed: () => _openDigitalSubhaModal(context, isDark, goldColor),
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
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(isInsideCategory ? 98 : 60),
            child: Column(
              children: [
                // Search input
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: SizedBox(
                    height: 44,
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val.trim();
                        });
                      },
                      decoration: InputDecoration(
                        hintText: isInsideCategory
                            ? 'ابحث داخل $currentTitle...'
                            : 'ابحث في كافة الأدعية والأذكار...',
                        hintStyle: GoogleFonts.cairo(fontSize: 13),
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: isDark ? Colors.white24 : Colors.grey.shade300,
                          ),
                        ),
                        filled: true,
                        fillColor: isDark ? Colors.black26 : Colors.grey.shade50,
                      ),
                    ),
                  ),
                ),
                // Horizontal category switcher when inside category
                if (isInsideCategory)
                  SizedBox(
                    height: 42,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (ctx, i) {
                        final cat = _categories[i];
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
                                  _getCategoryIcon(cat.category),
                                  size: 15,
                                  color: isSelected
                                      ? (isDark ? Colors.black87 : Colors.white)
                                      : (isDark ? Colors.white70 : Colors.black87),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  cat.category,
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
        bottomNavigationBar: const MiniPlayer(),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: const Color(0xFF0F5132),
          foregroundColor: Colors.white,
          icon: const Icon(Icons.touch_app_outlined),
          label: Text('المسبحة ($_subhaCount)', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          onPressed: () => _openDigitalSubhaModal(context, isDark, goldColor),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth >= 720;

            if (_searchQuery.isNotEmpty) {
              return _buildSearchResultsView(isDark, goldColor, isTablet);
            }

            if (!isInsideCategory) {
              return _buildCategoryHub(isDark, goldColor);
            }

            return _buildCategoryItemsList(
              _categories[_activeCategoryIndex!],
              isDark,
              goldColor,
              isTablet,
            );
          },
        ),
      ),
    );
  }

  /// Hub of distinct, prominent buttons for all Adhkar categories
  Widget _buildCategoryHub(bool isDark, Color goldColor) {
    final audio = AzkarAudioService();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      children: [
        // Instant Audio Player Card for Today's Adhkar (مشاري العفاسي بدون إنترنت)
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: goldColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.headphones_rounded, color: goldColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'الاستماع الصوتي المباشر (بدون إنترنت)',
                          style: GoogleFonts.cairo(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: goldColor,
                          ),
                        ),
                        Text(
                          'أذكار الصباح والمساء كاملة مسجلة مدمجة في التطبيق',
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
              const SizedBox(height: 14),
              // Fast Play Buttons for Sabah and Masa
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.play_circle_fill_rounded, size: 20),
                      label: Text('أذكار الصباح ☀️', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13)),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        audio.playFullRecordedAudio(isSabah: true);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('جاري تشغيل أذكار الصباح كاملة بصوت عذب ندي')),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.play_circle_fill_rounded, size: 20),
                      label: Text('أذكار المساء 🌙', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13)),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        audio.playFullRecordedAudio(isSabah: false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('جاري تشغيل أذكار المساء كاملة بصوت عذب ندي')),
                        );
                      },
                    ),
                  ),
                ],
              ),
              // Audio status banner if currently playing
              AnimatedBuilder(
                animation: Listenable.merge([audio.isPlayingNotifier, audio.statusMessageNotifier]),
                builder: (ctx, _) {
                  if (!audio.isPlayingNotifier.value) return const SizedBox.shrink();
                  return Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.graphic_eq_rounded, color: Colors.green, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            audio.statusMessageNotifier.value.isNotEmpty
                                ? audio.statusMessageNotifier.value
                                : 'الصوت يعمل الآن...',
                            style: GoogleFonts.cairo(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.stop_circle_rounded, color: Colors.amber, size: 20),
                          tooltip: 'إيقاف',
                          onPressed: () => audio.stop(),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'أقسام الأذكار والأدعية (اضغط على أي قسم للدخول):',
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: goldColor,
            ),
          ),
        ),
        const SizedBox(height: 12),
        // 22 Prominent Category Buttons (بوتنات واضحة مريحة وغير مزدحمة)
        ...List.generate(_categories.length, (index) {
          final cat = _categories[index];
          final catIcon = _getCategoryIcon(cat.category);
          final catColor = _getCategoryColor(cat.category);

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
                      // Icon Box
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: catColor.withValues(alpha: isDark ? 0.2 : 0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: catColor.withValues(alpha: 0.35)),
                        ),
                        child: Icon(catIcon, color: catColor, size: 26),
                      ),
                      const SizedBox(width: 14),
                      // Title & Supplications Count
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cat.category,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.cairo(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'يحتوي على ${cat.items.length} ذكراً ودعاءً مأثوراً',
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Count Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: goldColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${cat.items.length}',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: goldColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 15,
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

  Widget _buildSearchResultsView(bool isDark, Color goldColor, bool isTablet) {
    final query = _searchQuery.toLowerCase();
    final List<(String, AzkarItem)> matched = [];

    for (final cat in _categories) {
      for (final item in cat.items) {
        if (item.text.contains(query) ||
            (item.meaning != null && item.meaning!.contains(query)) ||
            (item.fadl != null && item.fadl!.contains(query)) ||
            (item.source != null && item.source!.contains(query)) ||
            cat.category.contains(query)) {
          matched.add((cat.category, item));
        }
      }
    }

    if (matched.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off_rounded, size: 56, color: goldColor.withValues(alpha: 0.6)),
              const SizedBox(height: 12),
              Text(
                'لم يتم العثور على أذكار أو أدعية تطابق "$_searchQuery"',
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          physics: const BouncingScrollPhysics(),
          itemCount: matched.length,
          itemBuilder: (context, idx) {
            final (catName, item) = matched[idx];
            return _buildAzkarCard(item, catName, isDark, goldColor, isTablet);
          },
        ),
      ),
    );
  }

  Widget _buildCategoryItemsList(
    AzkarCategory cat,
    bool isDark,
    Color goldColor,
    bool isTablet,
  ) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: Column(
          children: [
            _buildAudioControlBar(cat, isDark, goldColor),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                physics: const BouncingScrollPhysics(),
                itemCount: cat.items.length,
                itemBuilder: (context, idx) {
                  final item = cat.items[idx];
                  return _buildAzkarCard(item, cat.category, isDark, goldColor, isTablet, itemIndex: idx);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioControlBar(AzkarCategory cat, bool isDark, Color goldColor) {
    final audio = AzkarAudioService();
    final isSabah = cat.category.contains('الصباح');
    final isMasa = cat.category.contains('المساء');

    return AnimatedBuilder(
      animation: Listenable.merge([
        audio.isPlayingNotifier,
        audio.currentIndexNotifier,
        audio.currentRepeatNotifier,
        audio.statusMessageNotifier,
        audio.isFullContinuousNotifier,
        audio.positionNotifier,
        audio.durationNotifier,
      ]),
      builder: (context, _) {
        final isPlaying = audio.isPlayingNotifier.value;
        final currentIdx = audio.currentIndexNotifier.value;
        final statusMsg = audio.statusMessageNotifier.value;
        final isFullContinuous = audio.isFullContinuousNotifier.value;
        final pos = audio.positionNotifier.value;
        final dur = audio.durationNotifier.value;

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
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
            border: Border.all(
              color: isPlaying ? Colors.green : goldColor.withValues(alpha: 0.3),
              width: isPlaying ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      if (isPlaying) {
                        audio.stop();
                      } else {
                        if (isSabah) {
                          audio.playFullRecordedAudio(isSabah: true);
                        } else if (isMasa) {
                          audio.playFullRecordedAudio(isSabah: false);
                        } else {
                          audio.playSequence(cat.items);
                        }
                      }
                    },
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: isPlaying ? Colors.green : goldColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isPlaying ? 'جاري الاستماع الصوتي 🔊' : 'استماع صوتي للأذكار (بدون نت)',
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: isPlaying ? Colors.green : goldColor,
                          ),
                        ),
                        Text(
                          isPlaying
                              ? (statusMsg.isNotEmpty
                                  ? statusMsg
                                  : 'الذكر ${currentIdx + 1} من ${cat.items.length}')
                              : (isSabah || isMasa
                                  ? 'تشغيل بصوت الشيخ العذب أو قراءة متتابعة'
                                  : 'تشغيل كامل أذكار ${cat.category} بالصوت'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isPlaying && !isFullContinuous) ...[
                    IconButton(
                      icon: const Icon(Icons.skip_previous_rounded, size: 22),
                      tooltip: 'الذكر السابق',
                      onPressed: () => audio.previousDhikr(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next_rounded, size: 22),
                      tooltip: 'الذكر التالي',
                      onPressed: () => audio.nextDhikr(),
                    ),
                  ],
                ],
              ),
              // Position Progress Bar if full audio track is playing
              if (isPlaying && isFullContinuous && dur.inSeconds > 0) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '${pos.inMinutes}:${(pos.inSeconds % 60).toString().padLeft(2, '0')}',
                      style: GoogleFonts.cairo(fontSize: 11, color: goldColor),
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 3,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        ),
                        child: Slider(
                          value: pos.inSeconds.toDouble().clamp(0.0, dur.inSeconds.toDouble()),
                          max: dur.inSeconds.toDouble(),
                          activeColor: goldColor,
                          inactiveColor: Colors.grey.withValues(alpha: 0.3),
                          onChanged: (val) {
                            audio.seek(Duration(seconds: val.toInt()));
                          },
                        ),
                      ),
                    ),
                    Text(
                      '${dur.inMinutes}:${(dur.inSeconds % 60).toString().padLeft(2, '0')}',
                      style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ],
              // Action buttons if not playing
              if (!isPlaying) ...[
                const SizedBox(height: 10),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (isSabah || isMasa)
                      FilledButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          audio.playFullRecordedAudio(isSabah: isSabah);
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: goldColor,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          visualDensity: VisualDensity.compact,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.headphones_rounded, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              isSabah ? 'التسجيل الكامل لأذكار الصباح 🎧' : 'التسجيل الكامل لأذكار المساء 🎧',
                              style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    FilledButton.tonal(
                      onPressed: () => audio.playSequence(cat.items),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        visualDensity: VisualDensity.compact,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.playlist_play_rounded, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'تشغيل متتابع ذكر بذكر 🔊',
                            style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildAzkarCard(
    AzkarItem item,
    String categoryName,
    bool isDark,
    Color goldColor,
    bool isTablet, {
    int itemIndex = -1,
  }) {
    final isFinished = item.currentCount >= item.count;
    final isCurrentlySpeaking = AzkarAudioService().currentIndexNotifier.value == itemIndex &&
        AzkarAudioService().isPlayingNotifier.value;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: isCurrentlySpeaking ? 4 : (isDark ? 2 : 1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isCurrentlySpeaking
              ? goldColor
              : (isFinished
                  ? Colors.green.withValues(alpha: 0.6)
                  : (isDark ? Colors.white12 : Colors.grey.shade200)),
          width: isCurrentlySpeaking ? 2.0 : (isFinished ? 1.5 : 1),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          if (item.currentCount < item.count) {
            HapticFeedback.lightImpact();
            setState(() {
              item.currentCount++;
            });
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Tag (Category and Copy/Share/Speak) - Fully Expanded & Non-crowded
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: goldColor.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          categoryName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: goldColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Audio Voice Button
                      IconButton(
                        icon: Icon(
                          isCurrentlySpeaking ? Icons.volume_up_rounded : Icons.volume_down_rounded,
                          size: 20,
                          color: isCurrentlySpeaking ? goldColor : null,
                        ),
                        tooltip: 'استماع صوتي للذكر',
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          AzkarAudioService().speakSingleDhikr(item.text, itemIndex: itemIndex);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        tooltip: 'نسخ الذكر',
                        onPressed: () {
                          final copyText = StringBuffer(item.text);
                          if (item.meaning != null) {
                            copyText.write('\nالمعنى الميسر: ${item.meaning!}');
                          }
                          if (item.fadl != null) {
                            copyText.write('\nالفضل: ${item.fadl!}');
                          }
                          if (item.source != null) {
                            copyText.write('\nالمصدر: ${item.source!}');
                          }
                          Clipboard.setData(ClipboardData(
                            text: copyText.toString(),
                          ));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تم نسخ الذكر المبارك وشرحه إلى الحافظة'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Main Text
              Text(
                item.text,
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                style: GoogleFonts.amiri(
                  fontSize: _fontSize,
                  height: 2.1,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF1E293B),
                ),
              ),

              // Meaning & Explanation (المعنى والشرح الميسر)
              if (item.meaning != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F261E) : const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF81C784).withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.menu_book_rounded, size: 16, color: Color(0xFF2E7D32)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'المعنى الميسر: ${item.meaning!}',
                          textDirection: TextDirection.rtl,
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            height: 1.5,
                            color: isDark ? const Color(0xFFC8E6C9) : const Color(0xFF1B5E20),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Virtue (الفضل)
              if (item.fadl != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E293B).withValues(alpha: 0.6)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lightbulb_outline_rounded, size: 16, color: Color(0xFFD4AF37)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.fadl!,
                          textDirection: TextDirection.rtl,
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            height: 1.5,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Source (المصدر)
              if (item.source != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'المصدر: ${item.source!}',
                    textDirection: TextDirection.rtl,
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      color: isDark ? Colors.white38 : Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 14),

              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: item.count > 0 ? (item.currentCount / item.count).clamp(0.0, 1.0) : 0.0,
                  backgroundColor: isDark ? Colors.white10 : Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isFinished ? Colors.green : goldColor,
                  ),
                  minHeight: 4,
                ),
              ),

              const SizedBox(height: 12),

              // Interactive Footer Counter Pill & Reset
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    tooltip: 'إعادة العداد',
                    onPressed: () {
                      setState(() {
                        item.currentCount = 0;
                      });
                    },
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isFinished
                          ? Colors.green.withValues(alpha: 0.2)
                          : goldColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isFinished ? Colors.green : goldColor,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isFinished ? Icons.check_circle_rounded : Icons.touch_app_rounded,
                          size: 16,
                          color: isFinished ? Colors.green : goldColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${item.currentCount} / ${item.count}',
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isFinished ? Colors.green : goldColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
