import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/prayer_times_service.dart';
import 'azkar_screen.dart';
import 'bookmarks_screen.dart';
import 'home_screen.dart';
import 'listen_only_screen.dart';
import 'prayer_times_screen.dart';
import 'settings_screen.dart';
import 'surahs_list_screen.dart';
import 'accessibility_hub_screen.dart';
import 'qibla_screen.dart';
import 'muslim_bag_screen.dart';
import 'names_of_allah_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  Timer? _dhikrTimer;
  Timer? _adhanCheckTimer;
  Map<String, String>? _currentFloatingDhikr;
  Timer? _autoDismissTimer;
  int _dhikrIndex = 0;
  String? _lastPromptedPrayerKey;

  static const _screens = [
    HomeScreen(),
    SurahsListScreen(),
    ListenOnlyScreen(),
    PrayerTimesScreen(),
    BookmarksScreen(),
    AzkarScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startInAppTimers();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startInAppTimers();
    } else {
      _dhikrTimer?.cancel();
      _adhanCheckTimer?.cancel();
      _autoDismissTimer?.cancel();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dhikrTimer?.cancel();
    _adhanCheckTimer?.cancel();
    _autoDismissTimer?.cancel();
    super.dispose();
  }

  void _startInAppTimers() {
    _dhikrTimer?.cancel();
    _adhanCheckTimer?.cancel();

    // In-App Dhikr Reminder every 5 minutes while user has app open
    _dhikrTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _triggerFloatingDhikr();
    });

    // Check for prayer adhan time every 15 seconds
    _adhanCheckTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _checkForAdhanPrompt();
    });
  }

  void _triggerFloatingDhikr() {
    final list = PrayerTimesService.dhikrList;
    if (list.isEmpty || !mounted) return;

    final dhikr = list[_dhikrIndex % list.length];
    _dhikrIndex++;

    setState(() {
      _currentFloatingDhikr = dhikr;
    });

    HapticFeedback.lightImpact();

    _autoDismissTimer?.cancel();
    _autoDismissTimer = Timer(const Duration(seconds: 14), () {
      if (mounted) {
        setState(() => _currentFloatingDhikr = null);
      }
    });
  }

  Future<void> _checkForAdhanPrompt() async {
    final isPrayerEnabled = await PrayerTimesService.notificationsEnabled;
    if (!isPrayerEnabled) return;

    final loc = await PrayerTimesService.getSavedLocation();
    if (loc == null) return;

    final now = DateTime.now();
    final times = await PrayerTimesService.calculateFor(loc, now);

    final prayers = [
      ('الفجر', times.fajr),
      ('الظهر', times.dhuhr),
      ('العصر', times.asr),
      ('المغرب', times.maghrib),
      ('العشاء', times.isha),
    ];

    for (final (name, pTime) in prayers) {
      final diff = now.difference(pTime).inSeconds;
      final key = '${now.year}-${now.month}-${now.day}-$name';
      if (diff >= 0 && diff < 30 && key != _lastPromptedPrayerKey) {
        _lastPromptedPrayerKey = key;
        if (mounted) {
          _showAdhanPromptDialog(name);
        }
        break;
      }
    }
  }

  void _showAdhanPromptDialog(String prayerName) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Text('🕌', style: TextStyle(fontSize: 26)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'حان موعد أذان $prayerName',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 17),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'الله أكبر، الله أكبر • حيّ على الصلاة، حيّ على الفلاح',
              style: GoogleFonts.amiri(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFD4AF37),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'هل ترغب في إيقاف صوت الأذان أم المتابعة؟',
              style: GoogleFonts.cairo(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'لا (متابعة الأذان)',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              PrayerTimesService.stopAdhan();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم إيقاف صوت الأذان')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'نعم (إيقاف الأذان)',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showMoreMenu(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final goldColor = const Color(0xFFD4AF37);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.76,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF141F2D) : Colors.white,
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  children: [
                    Icon(Icons.widgets_rounded, color: goldColor, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'أقسام وميزات نور القرآن',
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: goldColor,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildMoreMenuItem(
                      context: ctx,
                      icon: Icons.auto_awesome_rounded,
                      color: const Color(0xFFD4AF37),
                      title: 'أسماء الله الحسنى (99) ✨',
                      subtitle: 'جميع أسماء الله الـ 99 مع معانيها الدقيقة والشواهد القرآنية والاستماع الصوتي',
                      onTap: () {
                        Navigator.pop(ctx);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const NamesOfAllahScreen()));
                      },
                    ),
                    _buildMoreMenuItem(
                      context: ctx,
                      icon: Icons.auto_stories_rounded,
                      color: Colors.teal,
                      title: 'حقيبة المسلم الشاملة',
                      subtitle: 'قصص الأنبياء، الصحابة، أمهات المؤمنين، وحصن المسلم',
                      onTap: () {
                        Navigator.pop(ctx);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const MuslimBagScreen()));
                      },
                    ),
                    _buildMoreMenuItem(
                      context: ctx,
                      icon: Icons.explore_rounded,
                      color: Colors.amber.shade800,
                      title: 'بوصلة اتجاه القبلة 🕋',
                      subtitle: 'بوصلة حقيقية 100% بدون إنترنت مع استجابة واهتزاز لمسي',
                      onTap: () {
                        Navigator.pop(ctx);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const QiblaScreen()));
                      },
                    ),
                    _buildMoreMenuItem(
                      context: ctx,
                      icon: Icons.accessibility_new_rounded,
                      color: Colors.teal,
                      title: 'مركز التيسير وذوي الهمم 🤍',
                      subtitle: 'للأميين، كبار السن، المكفوفين، والصم والبكم (توجيه صوتي وبصري)',
                      onTap: () {
                        Navigator.pop(ctx);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const AccessibilityHubScreen()));
                      },
                    ),
                    _buildMoreMenuItem(
                      context: ctx,
                      icon: Icons.headphones_rounded,
                      color: const Color(0xFF0F5132),
                      title: 'الاستماع للقارئ',
                      subtitle: 'تلاوات خاشعة لجميع سور القرآن الكريم بصوت القارئ المختار',
                      onTap: () {
                        Navigator.pop(ctx);
                        setState(() => _selectedIndex = 2);
                      },
                    ),
                    _buildMoreMenuItem(
                      context: ctx,
                      icon: Icons.bookmark_rounded,
                      color: Colors.indigo,
                      title: 'المحفوظات والعلامات المرجعية',
                      subtitle: 'الانتقال المباشر للآيات المحفوظة ومتابعة القراءة من موضع التوقف',
                      onTap: () {
                        Navigator.pop(ctx);
                        setState(() => _selectedIndex = 4);
                      },
                    ),
                    _buildMoreMenuItem(
                      context: ctx,
                      icon: Icons.tune_rounded,
                      color: Colors.blueAccent,
                      title: 'الإعدادات والمظهر',
                      subtitle: 'الوضع الليلي والنهاري، تردد التذكير في منتصف الشاشة، وتخصيص التطبيق',
                      onTap: () {
                        Navigator.pop(ctx);
                        setState(() => _selectedIndex = 6);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMoreMenuItem({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B283A) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.cairo(
            fontSize: 11,
            color: isDark ? Colors.white60 : Colors.black54,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isTabletOrDesktop = constraints.maxWidth >= 700;
              final content = Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isTabletOrDesktop ? 1200 : double.infinity,
                  ),
                  child: IndexedStack(index: _selectedIndex, children: _screens),
                ),
              );

              if (!isTabletOrDesktop) return content;

              final useExtendedRail = constraints.maxWidth >= 1050;
              return Row(
                children: [
                  NavigationRail(
                    extended: useExtendedRail,
                    labelType: useExtendedRail
                        ? NavigationRailLabelType.none
                        : NavigationRailLabelType.all,
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: (index) =>
                        setState(() => _selectedIndex = index),
                    destinations: _railDestinations,
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: content),
                ],
              );
            },
          ),

          // In-App Centered Floating Dhikr Modal (Center of screen, instant tap dismiss)
          if (_currentFloatingDhikr != null)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _currentFloatingDhikr = null);
                },
                child: Container(
                  color: Colors.black.withValues(alpha: 0.5),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _currentFloatingDhikr = null);
                    },
                    child: Material(
                      elevation: 20,
                      borderRadius: BorderRadius.circular(28),
                      color: Colors.transparent,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 420),
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0F3B2C), Color(0xFF1B5E3C)],
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                          ),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: const Color(0xFFD4AF37), width: 2.2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
                              blurRadius: 24,
                              spreadRadius: 2,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.favorite_rounded, color: Color(0xFFD4AF37), size: 26),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _currentFloatingDhikr!['title'] ?? '🕊️ ذكر الله والصلاة على النبي ﷺ',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: const Color(0xFFD4AF37),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _currentFloatingDhikr!['body'] ?? '',
                              textAlign: TextAlign.center,
                              textDirection: TextDirection.rtl,
                              style: GoogleFonts.amiri(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                height: 1.8,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD4AF37).withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.5)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.touch_app_rounded, color: Colors.white, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    'المس لتختفي فوراً',
                                    style: GoogleFonts.cairo(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 700) {
            return const SizedBox.shrink();
          }

          int barIndex = 0;
          if (_selectedIndex == 0) {
            barIndex = 0;
          } else if (_selectedIndex == 1) {
            barIndex = 1;
          } else if (_selectedIndex == 3) {
            barIndex = 2;
          } else if (_selectedIndex == 5) {
            barIndex = 3;
          } else {
            barIndex = 4;
          }

          return NavigationBar(
            height: 64,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            selectedIndex: barIndex,
            onDestinationSelected: (idx) {
              if (idx == 0) {
                setState(() => _selectedIndex = 0);
              } else if (idx == 1) {
                setState(() => _selectedIndex = 1);
              } else if (idx == 2) {
                setState(() => _selectedIndex = 3);
              } else if (idx == 3) {
                setState(() => _selectedIndex = 5);
              } else if (idx == 4) {
                _showMoreMenu(context);
              }
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'الرئيسية',
              ),
              NavigationDestination(
                icon: Icon(Icons.menu_book_outlined),
                selectedIcon: Icon(Icons.menu_book_rounded),
                label: 'المصحف',
              ),
              NavigationDestination(
                icon: Icon(Icons.mosque_outlined),
                selectedIcon: Icon(Icons.mosque_rounded),
                label: 'المواقيت',
              ),
              NavigationDestination(
                icon: Icon(Icons.spa_outlined),
                selectedIcon: Icon(Icons.spa_rounded),
                label: 'الأذكار',
              ),
              NavigationDestination(
                icon: Icon(Icons.grid_view_rounded),
                selectedIcon: Icon(Icons.grid_view_rounded),
                label: 'المزيد',
              ),
            ],
          );
        },
      ),
    );
  }

  static const _railDestinations = [
    NavigationRailDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home_rounded),
      label: Text('الرئيسية'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.menu_book_outlined),
      selectedIcon: Icon(Icons.menu_book_rounded),
      label: Text('المصحف والسور'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.headphones_outlined),
      selectedIcon: Icon(Icons.headphones_rounded),
      label: Text('الاستماع'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.mosque_outlined),
      selectedIcon: Icon(Icons.mosque_rounded),
      label: Text('مواقيت الصلاة'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.bookmark_border_rounded),
      selectedIcon: Icon(Icons.bookmark_rounded),
      label: Text('المحفوظات'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.spa_outlined),
      selectedIcon: Icon(Icons.spa_rounded),
      label: Text('الأدعية والأذكار'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.tune_rounded),
      selectedIcon: Icon(Icons.tune_rounded),
      label: Text('الإعدادات'),
    ),
  ];
}
