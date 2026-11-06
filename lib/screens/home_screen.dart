import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/quran_service.dart';
import '../services/storage_service.dart';
import '../providers/theme_provider.dart';
import 'quran_read_screen.dart';
import 'listen_only_screen.dart';
import 'listen_read_screen.dart';
import 'bookmarks_screen.dart';
import 'settings_screen.dart';
import 'secret_admin_screen.dart';
import 'prayer_times_screen.dart';
import 'azkar_screen.dart';
import 'qibla_screen.dart';
import 'accessibility_hub_screen.dart';
import 'muslim_bag_screen.dart';
import 'names_of_allah_screen.dart';
import '../widgets/noor_logo.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _lastRead;
  int _dailyAyahIndex = 0;

  static const _inspirationalAyahs = [
    {
      'surah': 'سورة الشرح',
      'ayah': '6',
      'text': '﴿ فَإِنَّ مَعَ الْعُسْرِ يُسْرًا ۞ إِنَّ مَعَ الْعُسْرِ يُسْرًا ﴾',
      'tafsir': 'إن مع الضيق والشدة فرجاً وتيسيراً عظيماً من الله، فلن يغلب عسر يسرين.',
    },
    {
      'surah': 'سورة الرعد',
      'ayah': '28',
      'text': '﴿ الَّذِينَ آمَنُوا وَتَطْمَئِنُّ قُلُوبُهُمْ بِذِكْرِ اللَّهِ ۗ أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ ﴾',
      'tafsir': 'بذكر الله وحده تسكن النفوس وتطمئن القلوب وتذهب المخاوف والهموم.',
    },
    {
      'surah': 'سورة البقرة',
      'ayah': '186',
      'text': '﴿ وَإِذَا سَأَلَكَ عِبَادِي عَنِّي فَإِنِّي قَرِيبٌ ۖ أُجِيبُ دَعْوَةَ الدَّاعِ إِذَا دَعَانِ ﴾',
      'tafsir': 'الله سبحانه قريب من عباده يسمع دعاءهم ويجيب سؤالهم ولا يرد سائلاً أقبل عليه.',
    },
    {
      'surah': 'سورة الطلاق',
      'ayah': '2-3',
      'text': '﴿ وَمَنْ يَتَّقِ اللَّهَ يَجْعَلْ لَهُ مَخْرَجًا ۞ وَيَرْزُقْهُ مِنْ حَيْثُ لَا يَحْتَسِبُ ﴾',
      'tafsir': 'من راقب ربه واتقاه جعل له من كل ضيق مخرجاً ورزقه من حيث لا يحتسب.',
    },
    {
      'surah': 'سورة الطور',
      'ayah': '48',
      'text': '﴿ وَاصْبِرْ لِحُكْمِ رَبِّكَ فَإِنَّكَ بِأَعْيُنِنَا ۖ وَسَبِّحْ بِحَمْدِ رَبِّكَ حِينَ تَقُومُ ﴾',
      'tafsir': 'اصبر على قضاء ربك فإنك في حفظنا وعنايتنا التامة التي لا تغفل ولا تنام.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadLastRead();
  }

  void _loadLastRead() {
    setState(() {
      _lastRead = StorageService.getLastRead();
    });
  }

  void _showSecretPinDialog() {
    final pinController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.lock_rounded, color: Color(0xFFD4AF37)),
            const SizedBox(width: 8),
            Text(
              'المنطقة الإدارية السرية',
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'أدخل الرمز السري الخاص بك لإدارة أصوات القارئ:',
              style: GoogleFonts.cairo(fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'الرمز السري (الافتراضي 7777)...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء', style: GoogleFonts.cairo()),
          ),
          ElevatedButton(
            onPressed: () {
              if (pinController.text.trim() == StorageService.adminPin) {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SecretAdminScreen()),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: Colors.red,
                    content: Text('الرمز السري غير صحيح!'),
                  ),
                );
              }
            },
            child: Text('دخول', style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
  }

  void _openQuranSearch() {
    showSearch(context: context, delegate: QuranSearchDelegate());
  }

  @override
  Widget build(BuildContext context) {
    return _buildHomeDashboard(context);
  }

  Widget _buildHomeDashboard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final goldColor = const Color(0xFFD4AF37);
    final themeProv = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const NoorLogo(size: 36),
            const SizedBox(width: 10),
            Text(
              'نور القرآن الكريم',
              style: GoogleFonts.amiri(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: isDark ? goldColor : const Color(0xFF0F5132),
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: Icon(
            themeProv.isDarkMode
                ? Icons.wb_sunny_rounded
                : Icons.nightlight_round,
            color: goldColor,
            size: 22,
          ),
          tooltip: themeProv.isDarkMode ? 'الوضع النهاري' : 'الوضع الليلي',
          onPressed: () => themeProv.toggleTheme(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, size: 24),
            tooltip: 'بحث في القرآن',
            onPressed: _openQuranSearch,
          ),
          IconButton(
            icon: const Icon(Icons.shield_outlined, size: 22),
            tooltip: 'إدارة سرية',
            onPressed: _showSecretPinDialog,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadLastRead();
        },
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 840),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              physics: const BouncingScrollPhysics(),
              children: [
                // Spacious Reciter Master Banner
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 26,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF152238), const Color(0xFF0E1726)]
                          : [const Color(0xFF0F5132), const Color(0xFF1B4D3E)],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.35 : 0.12,
                        ),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: goldColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: goldColor.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                    Icon(
                                      Icons.mic_rounded,
                                      size: 16,
                                      color: goldColor,
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        'القارئ: ${StorageService.reciterName}',
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.cairo(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white12,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'مصحف أوفلاين',
                              style: GoogleFonts.cairo(
                                color: goldColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '﴿ أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ ﴾',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.amiri(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          height: 1.8,
                          color: const Color(0xFFF3C64F),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Last Read Section (Spacious & Clean)
                if (_lastRead != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF131D2D) : Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: goldColor.withValues(alpha: 0.3),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.2 : 0.04,
                          ),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: goldColor.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.bookmark_added_rounded,
                            color: goldColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'متابعة القراءة من آخر موضع',
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_lastRead!['surahName']} • الآية (${_lastRead!['ayahNumber']})',
                                style: GoogleFonts.cairo(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            final surah = QuranService.getSurahByNumber(
                              _lastRead!['surahNumber'],
                            );
                            if (surah != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => QuranReadScreen(
                                    initialSurah: surah,
                                    initialAyahIndex:
                                        _lastRead!['ayahNumber'] - 1,
                                  ),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 10,
                            ),
                          ),
                          child: Text(
                            'متابعة',
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Time-based Adhkar banner
                _buildTimeAdhkarCard(context),

                // Muslim Bag Banner
                _buildMuslimBagBanner(context),

                // Names of Allah 99 Banner
                _buildNamesOfAllahBanner(context),

                // Daily Ayah reflection card
                _buildDailyAyahCard(context),

                // Accessibility & Inclusivity Center Banner
                _buildAccessibilityHubBanner(context),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    'الوصول السريع',
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    int crossAxisCount = 2;
                    double childAspectRatio = 1.6;

                    if (constraints.maxWidth < 360) {
                      crossAxisCount = 2;
                      childAspectRatio = 1.35;
                    } else if (constraints.maxWidth >= 850) {
                      crossAxisCount = 4;
                      childAspectRatio = 1.8;
                    } else if (constraints.maxWidth >= 560) {
                      crossAxisCount = 3;
                      childAspectRatio = 1.7;
                    } else {
                      crossAxisCount = 2;
                      childAspectRatio = 1.6;
                    }

                    return GridView.count(
                      crossAxisCount: crossAxisCount,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: childAspectRatio,
                      children: [
                        _buildSimpleActionCard(
                          context: context,
                          icon: Icons.menu_book_rounded,
                          title: 'قراءة القرآن',
                          onTap: () {
                            final fatiha = QuranService.getSurahByNumber(1)!;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    QuranReadScreen(initialSurah: fatiha),
                              ),
                            );
                          },
                        ),
                        _buildSimpleActionCard(
                          context: context,
                          icon: Icons.headphones_rounded,
                          title: 'الاستماع',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ListenOnlyScreen(),
                            ),
                          ),
                        ),
                        _buildSimpleActionCard(
                          context: context,
                          icon: Icons.auto_mode_rounded,
                          title: 'قراءة واستماع',
                          onTap: () {
                            final fatiha = QuranService.getSurahByNumber(1)!;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ListenReadScreen(initialSurah: fatiha),
                              ),
                            );
                          },
                        ),
                        _buildSimpleActionCard(
                          context: context,
                          icon: Icons.mosque_rounded,
                          title: 'مواقيت الصلاة',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PrayerTimesScreen(),
                            ),
                          ),
                        ),
                        _buildSimpleActionCard(
                          context: context,
                          icon: Icons.auto_awesome_rounded,
                          title: 'أسماء الله الحسنى',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NamesOfAllahScreen(),
                            ),
                          ),
                        ),
                        _buildSimpleActionCard(
                          context: context,
                          icon: Icons.auto_stories_rounded,
                          title: 'حقيبة المسلم',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MuslimBagScreen(),
                            ),
                          ),
                        ),
                        _buildSimpleActionCard(
                          context: context,
                          icon: Icons.record_voice_over_rounded,
                          title: 'أذكار اليوم بالصوت',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AzkarScreen(initialCategory: 'أذكار الصباح'),
                            ),
                          ),
                        ),
                        _buildSimpleActionCard(
                          context: context,
                          icon: Icons.explore_rounded,
                          title: 'بوصلة القبلة',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const QiblaScreen(),
                            ),
                          ),
                        ),
                        _buildSimpleActionCard(
                          context: context,
                          icon: Icons.spa_rounded,
                          title: 'الأذكار والدعاء',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AzkarScreen(),
                            ),
                          ),
                        ),
                        _buildSimpleActionCard(
                          context: context,
                          icon: Icons.accessibility_new_rounded,
                          title: 'مركز التيسير',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AccessibilityHubScreen(),
                            ),
                          ),
                        ),
                        _buildSimpleActionCard(
                          context: context,
                          icon: Icons.bookmarks_rounded,
                          title: 'العلامات المرجعية',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const BookmarksScreen(),
                            ),
                          ),
                        ),
                        _buildSimpleActionCard(
                          context: context,
                          icon: Icons.tune_rounded,
                          title: 'الإعدادات والمظهر',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SettingsScreen(),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMuslimBagBanner(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final goldColor = const Color(0xFFD4AF37);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E3A2F), const Color(0xFF11261E)]
              : [const Color(0xFFE0F2F1), const Color(0xFFB2DFDB)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? goldColor.withValues(alpha: 0.35) : const Color(0xFF26A69A),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MuslimBagScreen()),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: goldColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.auto_stories_rounded, color: goldColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'حقيبة المسلم الشاملة',
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: goldColor.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'مكتبة الإيمان',
                              style: GoogleFonts.cairo(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: goldColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'قصص الأنبياء • الصحابة • الصحابيات • القرآن • الحيوان • فضائل السور',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNamesOfAllahBanner(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final goldColor = const Color(0xFFD4AF37);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141F2D) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: goldColor.withValues(alpha: isDark ? 0.35 : 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NamesOfAllahScreen()),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: goldColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.auto_awesome_rounded, color: goldColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'أسماء الله الحسنى (99)',
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: goldColor.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'من أحصاها دخل الجنة',
                              style: GoogleFonts.cairo(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: goldColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '٩٩ اسماً كاملاً مع شرح المعاني والشواهد القرآنية والاستماع الصوتي',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeAdhkarCard(BuildContext context) {
    final hour = DateTime.now().hour;
    final isMorning = hour >= 4 && hour < 15;
    final title = isMorning ? 'أذكار الصباح' : 'أذكار المساء';
    final subtitle = isMorning
        ? 'ابدأ يومك ببركة الذكر وحفظ الرحمن'
        : 'حصّن نفسك وأهلك بأذكار المساء المأثورة';
    final icon = isMorning ? Icons.wb_sunny_rounded : Icons.nightlight_round;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final goldColor = const Color(0xFFD4AF37);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E2C42), const Color(0xFF141F30)]
              : [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? goldColor.withValues(alpha: 0.3)
              : const Color(0xFF81C784),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AzkarScreen(initialCategory: title),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: goldColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: goldColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1B5E20),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: goldColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'الوقت الحالي',
                              style: GoogleFonts.cairo(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                  ? goldColor
                                  : const Color(0xFF2E7D32),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDailyAyahCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final goldColor = const Color(0xFFD4AF37);
    final currentAyah =
        _inspirationalAyahs[_dailyAyahIndex % _inspirationalAyahs.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D2D) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: goldColor.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.auto_stories_rounded, color: goldColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'آية اليوم وتدبّرها',
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: goldColor,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 20),
                tooltip: 'آية أخرى',
                onPressed: () {
                  setState(() {
                    _dailyAyahIndex =
                        (_dailyAyahIndex + 1) % _inspirationalAyahs.length;
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 18),
                tooltip: 'نسخ الآية وتفسيرها',
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(
                      text:
                          '${currentAyah['text']}\n${currentAyah['surah']} - آية ${currentAyah['ayah']}\nالتفسير الميسر: ${currentAyah['tafsir']}',
                    ),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      behavior: SnackBarBehavior.floating,
                      content: Text(
                        'تم نسخ الآية وتفسيرها بنجاح',
                        style: GoogleFonts.cairo(),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            currentAyah['text']!,
            textAlign: TextAlign.center,
            style: GoogleFonts.amiri(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              height: 1.9,
              color: isDark ? const Color(0xFFF3C64F) : const Color(0xFF0F5132),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${currentAyah['surah']} • الآية (${currentAyah['ayah']})',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? Colors.black26 : const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.grey.shade200,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline_rounded,
                  size: 18,
                  color: goldColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    currentAyah['tafsir']!,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      height: 1.6,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccessibilityHubBanner(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final goldColor = const Color(0xFFD4AF37);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E3A8A).withValues(alpha: 0.35), const Color(0xFF0F172A)]
              : [const Color(0xFFEFF6FF), const Color(0xFFDBEAFE)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF3B82F6).withValues(alpha: isDark ? 0.4 : 0.6),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AccessibilityHubScreen()),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Text('🤍', style: TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'مركز التيسير وذوي الهمم',
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: isDark ? Colors.white : const Color(0xFF1E3A8A),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: goldColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'متاح للجميع',
                              style: GoogleFonts.cairo(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: goldColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'للأميين، المكفوفين، والصم والبكم (توجيه صوتي وبصري واهتزازي)',
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSimpleActionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final goldColor = const Color(0xFFD4AF37);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D2D) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: goldColor, size: 20),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class QuranSearchDelegate extends SearchDelegate {
  @override
  String get searchFieldLabel => 'ابحث في آيات القرآن الكريم...';

  @override
  TextStyle? get searchFieldStyle => GoogleFonts.cairo(fontSize: 15);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear_rounded),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_forward_rounded),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    if (query.trim().isEmpty) {
      return Center(
        child: Text(
          'اكتب كلمة أو جملة للبحث في المصحف الشريف',
          style: GoogleFonts.cairo(color: Colors.grey),
        ),
      );
    }

    final results = QuranService.search(query);

    if (results.isEmpty) {
      return Center(
        child: Text(
          'لم يتم العثور على نتائج مطابقة لـ "$query"',
          style: GoogleFonts.cairo(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      itemBuilder: (context, idx) {
        final res = results[idx];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(
              res.ayah.text,
              style: GoogleFonts.amiri(fontSize: 18, height: 1.9),
              textAlign: TextAlign.right,
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '${res.surah.name} • الآية (${res.ayah.numberInSurah})',
                style: GoogleFonts.cairo(
                  color: const Color(0xFFD4AF37),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            onTap: () {
              close(context, null);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => QuranReadScreen(
                    initialSurah: res.surah,
                    initialAyahIndex: res.ayah.numberInSurah - 1,
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
