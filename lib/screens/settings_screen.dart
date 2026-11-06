import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import '../services/prayer_times_service.dart';
import '../providers/theme_provider.dart';
import '../widgets/mini_player.dart';
import '../widgets/noor_logo.dart';
import 'secret_admin_screen.dart';
import 'accessibility_hub_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _secretTapCounter = 0;
  bool _dhikrEnabled = true;
  int _dhikrInterval = 5;

  @override
  void initState() {
    super.initState();
    _loadDhikrSettings();
  }

  Future<void> _loadDhikrSettings() async {
    final enabled = await PrayerTimesService.isDhikrRemindersEnabled();
    final interval = await PrayerTimesService.getDhikrIntervalMinutes();
    if (mounted) {
      setState(() {
        _dhikrEnabled = enabled;
        _dhikrInterval = interval;
      });
    }
  }

  void _showSecretPinDialog() {
    final pinController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.lock_outline_rounded, color: Color(0xFFD4AF37)),
            const SizedBox(width: 8),
            Text('المنطقة الإدارية السرية', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
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
                hintText: 'الرمز السري...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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

  void _onLogoTapped() {
    _secretTapCounter++;
    if (_secretTapCounter >= 5) {
      _secretTapCounter = 0;
      _showSecretPinDialog();
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final goldColor = const Color(0xFFD4AF37);
    final themeProv = Provider.of<ThemeProvider>(context);
    final isDark = themeProv.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'الإعدادات والمظهر',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.lock_rounded, size: 20),
            tooltip: 'إدارة',
            onPressed: _showSecretPinDialog,
          ),
        ],
      ),
      bottomNavigationBar: const MiniPlayer(),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            physics: const BouncingScrollPhysics(),
            children: [
              // Dedicated Accessibility & Inclusivity Center Card
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF1B382B), const Color(0xFF10241B)]
                        : [const Color(0xFF0F5132), const Color(0xFF1B6B4C)],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.12),
                      blurRadius: 14,
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
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: goldColor.withValues(alpha: 0.25),
                              shape: BoxShape.circle,
                              border: Border.all(color: goldColor, width: 1.5),
                            ),
                            child: const Text('🤍', style: TextStyle(fontSize: 24)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'مركز التيسير وذوي الهمم',
                                      style: GoogleFonts.cairo(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: goldColor.withValues(alpha: 0.25),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        'مميّز',
                                        style: GoogleFonts.cairo(
                                          color: goldColor,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'للأميين، كبار السن، المكفوفين، والصم والبكم (توجيه صوتي واهتزازي وتفسير بصري)',
                                  style: GoogleFonts.cairo(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Theme Switch Card
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: goldColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      themeProv.isDarkMode ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                      color: goldColor,
                    ),
                  ),
                  title: Text(
                    'المظهر (داكن / فاتح)',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: Text(
                    themeProv.isDarkMode ? 'الوضع الليلي الفاخر مفعّل' : 'الوضع النهاري مفعّل',
                    style: GoogleFonts.cairo(fontSize: 12),
                  ),
                  trailing: Switch.adaptive(
                    value: themeProv.isDarkMode,
                    activeColor: goldColor,
                    onChanged: (_) => themeProv.toggleTheme(),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Background Dhikr Reminders Settings Card
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: goldColor.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.notifications_active_rounded, color: goldColor),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'التذكير بذكر الله في منتصف الشاشة',
                                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                Text(
                                  'بطاقة تذكير عائمة تظهر بمنتصف شاشة الهاتف وتختفي فوراً بمجرد اللمس',
                                  style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: _dhikrEnabled,
                            activeColor: goldColor,
                            onChanged: (val) async {
                              setState(() => _dhikrEnabled = val);
                              await PrayerTimesService.setDhikrRemindersEnabled(val);
                            },
                          ),
                        ],
                      ),
                      if (_dhikrEnabled) ...[
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'معدل تكرار التذكير:',
                              style: GoogleFonts.cairo(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            DropdownButton<int>(
                              value: [5, 10, 15, 30, 60].contains(_dhikrInterval) ? _dhikrInterval : 5,
                              underline: const SizedBox(),
                              dropdownColor: isDark ? const Color(0xFF1A273A) : Colors.white,
                              style: GoogleFonts.cairo(
                                color: goldColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              items: const [
                                DropdownMenuItem(value: 5, child: Text('كل 5 دقائق (موصى به)')),
                                DropdownMenuItem(value: 10, child: Text('كل 10 دقائق')),
                                DropdownMenuItem(value: 15, child: Text('كل 15 دقيقة')),
                                DropdownMenuItem(value: 30, child: Text('كل 30 دقيقة')),
                                DropdownMenuItem(value: 60, child: Text('كل ساعة')),
                              ],
                              onChanged: (val) async {
                                if (val != null) {
                                  setState(() => _dhikrInterval = val);
                                  await PrayerTimesService.setDhikrIntervalMinutes(val);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('تم ضبط التذكير ليعمل كل $val دقيقة بنجاح'),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Quran Font Size Card
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.format_size_rounded, color: primaryColor),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'حجم الخط القرآني',
                                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                Text(
                                  'تحكم بحجم خط المصحف والتفسير (${themeProv.fontSize.round()})',
                                  style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Center(
                        child: Text(
                          'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
                          style: GoogleFonts.amiri(
                            fontSize: themeProv.fontSize,
                            fontWeight: FontWeight.bold,
                            color: goldColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: goldColor,
                          thumbColor: goldColor,
                        ),
                        child: Slider(
                          value: themeProv.fontSize,
                          min: 18.0,
                          max: 38.0,
                          divisions: 10,
                          label: themeProv.fontSize.round().toString(),
                          onChanged: (val) => themeProv.setFontSize(val),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Current Reciter Card
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.mic_external_on_rounded, color: Colors.blue),
                  ),
                  title: Text(
                    'القارئ الحالي للتطبيق',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: Text(
                    StorageService.reciterName,
                    style: GoogleFonts.cairo(fontSize: 13, color: goldColor, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // App Info & Secret Trigger Section
              Center(
                child: GestureDetector(
                  onTap: _onLogoTapped,
                  child: Column(
                    children: [
                      const NoorLogo(size: 68),
                      const SizedBox(height: 10),
                      Text(
                        'نور القرآن الكريم',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        'الإصدار 1.0.0 • صُنع لوجه الله تعالى',
                        style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
