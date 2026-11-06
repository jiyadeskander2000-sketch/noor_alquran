import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/theme_provider.dart';
import '../services/audio_manager.dart';
import '../services/quran_service.dart';
import 'qibla_screen.dart';
import 'listen_only_screen.dart';
import 'azkar_screen.dart';
import 'prayer_times_screen.dart';

class AccessibilityHubScreen extends StatefulWidget {
  const AccessibilityHubScreen({super.key});

  @override
  State<AccessibilityHubScreen> createState() => _AccessibilityHubScreenState();
}

class _AccessibilityHubScreenState extends State<AccessibilityHubScreen> {
  bool _hapticQibla = true;
  bool _hapticTasbeeh = true;
  bool _highContrast = false;
  bool _visualPrayerAlerts = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _hapticQibla = prefs.getBool('acc_haptic_qibla') ?? true;
      _hapticTasbeeh = prefs.getBool('acc_haptic_tasbeeh') ?? true;
      _highContrast = prefs.getBool('acc_high_contrast') ?? false;
      _visualPrayerAlerts = prefs.getBool('acc_visual_alerts') ?? true;
    });
  }

  Future<void> _savePreference(String key, bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, val);
  }

  void _triggerHapticDemo(String type) {
    switch (type) {
      case 'qibla':
        HapticFeedback.heavyImpact();
        Future.delayed(const Duration(milliseconds: 150), () => HapticFeedback.heavyImpact());
        Future.delayed(const Duration(milliseconds: 300), () => HapticFeedback.heavyImpact());
        break;
      case 'tasbeeh':
        HapticFeedback.mediumImpact();
        break;
      case 'tasbeeh33':
        HapticFeedback.heavyImpact();
        Future.delayed(const Duration(milliseconds: 180), () => HapticFeedback.heavyImpact());
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark || _highContrast;
    final goldColor = const Color(0xFFD4AF37);
    final primaryGreen = const Color(0xFF0F5132);
    final themeProv = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'مركز التيسير وذوي الهمم 🤍',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            physics: const BouncingScrollPhysics(),
            children: [
              // Welcome Banner
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF142436), const Color(0xFF0B1420)]
                        : [primaryGreen, const Color(0xFF1B6B4C)],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: goldColor.withValues(alpha: 0.22),
                        shape: BoxShape.circle,
                        border: Border.all(color: goldColor, width: 2),
                      ),
                      child: const Text('🌟', style: TextStyle(fontSize: 28)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'تطبيق متاح للجميع بفضل الله',
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'خصائص مصممة بعناية لكبار السن، الأميين، المكفوفين، والصم والبكم لتمكين كل مسلم من القرآن والذكر بسهولة تامة.',
                            style: GoogleFonts.cairo(
                              color: isDark ? Colors.white70 : Colors.white.withValues(alpha: 0.9),
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ================= SECTION 1: FOR THE ILLITERATE & ELDERLY =================
              _buildSectionHeader('📖 للأميين وكبار السن (الوضع البصري الصوتي)', Icons.record_voice_over_rounded, goldColor, isDark),
              const SizedBox(height: 12),
              Text(
                'بطاقات مرئية عملاقة وواضحة جداً؛ تتيح الاستماع المباشر للقرآن والأذكار دون الحاجة للقراءة:',
                style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 540;
                  return GridView.count(
                    crossAxisCount: isWide ? 2 : 1,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: isWide ? 2.3 : 2.5,
                    children: [
                      _buildSimpleTouchCard(
                        context: context,
                        iconText: '📖',
                        title: 'الاستماع للمصحف الشريف',
                        subtitle: 'اضغط هنا للاستماع المباشر بصوت الشيخ',
                        color: const Color(0xFF0F5132),
                        onTap: () {
                          final fatiha = QuranService.getSurahByNumber(1)!;
                          Provider.of<AudioManager>(context, listen: false).playSurah(fatiha);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ListenOnlyScreen()),
                          );
                        },
                      ),
                      _buildSimpleTouchCard(
                        context: context,
                        iconText: '🤲',
                        title: 'أذكار اليوم بالصوت',
                        subtitle: 'استمع لأذكار الصباح والمساء بلمسة واحدة',
                        color: const Color(0xFF1E3A8A),
                        onTap: () {
                          final hour = DateTime.now().hour;
                          final isMorning = hour >= 4 && hour < 15;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AzkarScreen(
                                initialCategory: isMorning ? 'أذكار الصباح' : 'أذكار المساء',
                              ),
                            ),
                          );
                        },
                      ),
                      _buildSimpleTouchCard(
                        context: context,
                        iconText: '🕋',
                        title: 'القبلة بالاهتزاز والصورة',
                        subtitle: 'توجيه فوري للكعبة دون قراءة درجات',
                        color: const Color(0xFFB45309),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const QiblaScreen()),
                          );
                        },
                      ),
                      _buildSimpleTouchCard(
                        context: context,
                        iconText: '🕌',
                        title: 'أوقات الصلوات والأذان',
                        subtitle: 'عرض أوقات الأذان والتنبيه بالألوان',
                        color: const Color(0xFF047857),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const PrayerTimesScreen()),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 28),

              // ================= SECTION 2: FOR THE BLIND & VISUALLY IMPAIRED =================
              _buildSectionHeader('🦯 للمكفوفين وضعاف البصر (توجيه لمسي واهتزازي)', Icons.visibility_off_rounded, goldColor, isDark),
              const SizedBox(height: 12),
              _buildSwitchCard(
                title: 'الاهتزاز اللمسي لتحديد القبلة (Haptic Compass)',
                subtitle: 'يهتز الهاتف ثلاث نبضات قوية فور توجيه الهاتف باتجاه الكعبة المشرفة دون الحاجة لرؤية الشاشة.',
                icon: Icons.vibration_rounded,
                value: _hapticQibla,
                goldColor: goldColor,
                isDark: isDark,
                onChanged: (val) {
                  setState(() => _hapticQibla = val);
                  _savePreference('acc_haptic_qibla', val);
                  if (val) _triggerHapticDemo('qibla');
                },
              ),
              const SizedBox(height: 10),
              _buildSwitchCard(
                title: 'اهتزاز السبحة اللمسية (Haptic Subha)',
                subtitle: 'نبضة خفيفة عند كل تسبيحة، ونبضتان عند بلوغ (33)، وثلاث نبضات عند بلوغ (100) تسبيحة.',
                icon: Icons.touch_app_rounded,
                value: _hapticTasbeeh,
                goldColor: goldColor,
                isDark: isDark,
                onChanged: (val) {
                  setState(() => _hapticTasbeeh = val);
                  _savePreference('acc_haptic_tasbeeh', val);
                  if (val) _triggerHapticDemo('tasbeeh33');
                },
              ),
              const SizedBox(height: 10),
              _buildSwitchCard(
                title: 'وضع التباين الأقصى والخطوط الكبيرة',
                subtitle: 'خلفية سوداء نقية مع نصوص ذهبية وصفراء ناصعة لراحة العين وضعاف البصر.',
                icon: Icons.contrast_rounded,
                value: _highContrast,
                goldColor: goldColor,
                isDark: isDark,
                onChanged: (val) {
                  setState(() => _highContrast = val);
                  _savePreference('acc_high_contrast', val);
                  if (val && themeProv.fontSize < 24) {
                    themeProv.setFontSize(26.0);
                  }
                },
              ),
              const SizedBox(height: 28),

              // ================= SECTION 3: FOR THE DEAF & HARD OF HEARING =================
              _buildSectionHeader('🧏 للصم والبكم (توجيه بصري متقن وتفسير كتابي)', Icons.hearing_disabled_rounded, goldColor, isDark),
              const SizedBox(height: 12),
              _buildSwitchCard(
                title: 'التنبيهات البصرية للأذان والصلوات',
                subtitle: 'وميض ناعم وشاشة ملونة مميزة تنبه عند حلول وقت الصلاة بدلاً من الاعتماد على الصوت وحده.',
                icon: Icons.flash_on_rounded,
                value: _visualPrayerAlerts,
                goldColor: goldColor,
                isDark: isDark,
                onChanged: (val) {
                  setState(() => _visualPrayerAlerts = val);
                  _savePreference('acc_visual_alerts', val);
                },
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF131D2D) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: goldColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.auto_stories_rounded, color: goldColor, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'المزامنة البصرية الحية للآيات مع التفسير المكتوب',
                            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'في شاشة "استماع وقراءة"، تضيء الآية الحالية بإطار ذهبي مشع يتنقل آلياً، مع توفر التفسير المكتوب لكل آية بضغطة زر واحدة.',
                            style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color gold, bool isDark) {
    return Row(
      children: [
        Icon(icon, color: gold, size: 22),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleTouchCard({
    required BuildContext context,
    required String iconText,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            HapticFeedback.mediumImpact();
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Text(iconText, style: const TextStyle(fontSize: 26)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cairo(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required Color goldColor,
    required bool isDark,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D2D) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: value ? goldColor.withValues(alpha: 0.5) : (isDark ? Colors.white12 : Colors.grey.shade200),
          width: value ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: goldColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: goldColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeColor: goldColor,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
