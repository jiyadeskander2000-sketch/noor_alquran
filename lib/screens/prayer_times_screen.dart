import 'dart:async';
import 'dart:io';

import 'package:adhan/adhan.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/prayer_times_service.dart';
import '../widgets/mini_player.dart';
import 'qibla_screen.dart';

class PrayerTimesScreen extends StatefulWidget {
  const PrayerTimesScreen({super.key});

  @override
  State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen>
    with WidgetsBindingObserver {
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _locationNameController = TextEditingController();
  final AudioPlayer _adhanPlayer = AudioPlayer();
  Timer? _adhanCheckTimer;
  Timer? _countdownTimer;
  PrayerLocation? _location;
  PrayerTimes? _times;
  int _methodIndex = CalculationMethod.umm_al_qura.index;
  bool _hanafiAsr = false;
  bool _loading = true;
  bool _busy = false;
  bool _notificationsEnabled = false;
  bool _dhikrRemindersEnabled = false;
  bool _appIsResumed = true;
  bool _isPlayingAdhan = false;
  String? _adhanPath;
  String? _lastPlayedPrayerKey;

  static const _methodLabels = {
    CalculationMethod.muslim_world_league: 'رابطة العالم الإسلامي',
    CalculationMethod.egyptian: 'الهيئة المصرية العامة للمساحة',
    CalculationMethod.karachi: 'جامعة العلوم الإسلامية - كراتشي',
    CalculationMethod.umm_al_qura: 'أم القرى - مكة المكرمة',
    CalculationMethod.dubai: 'دبي',
    CalculationMethod.moon_sighting_committee: 'لجنة تحري الهلال',
    CalculationMethod.north_america: 'أمريكا الشمالية',
    CalculationMethod.kuwait: 'الكويت',
    CalculationMethod.qatar: 'قطر',
    CalculationMethod.singapore: 'سنغافورة',
    CalculationMethod.turkey: 'تركيا',
    CalculationMethod.tehran: 'طهران',
    CalculationMethod.other: 'مخصص',
  };

  static const _cityLocations = <String, PrayerLocation>{
    'مكة المكرمة': PrayerLocation(
      latitude: 21.4225,
      longitude: 39.8262,
      name: 'مكة المكرمة',
    ),
    'المدينة المنورة': PrayerLocation(
      latitude: 24.4672,
      longitude: 39.6111,
      name: 'المدينة المنورة',
    ),
    'الرياض': PrayerLocation(
      latitude: 24.7136,
      longitude: 46.6753,
      name: 'الرياض',
    ),
    'القدس الشريف': PrayerLocation(
      latitude: 31.7683,
      longitude: 35.2137,
      name: 'القدس الشريف',
    ),
    'القاهرة': PrayerLocation(
      latitude: 30.0444,
      longitude: 31.2357,
      name: 'القاهرة',
    ),
    'صنعاء': PrayerLocation(
      latitude: 15.3694,
      longitude: 44.1910,
      name: 'صنعاء',
    ),
    'عدن': PrayerLocation(latitude: 12.7855, longitude: 45.0187, name: 'عدن'),
    'تعز': PrayerLocation(latitude: 13.5795, longitude: 44.0209, name: 'تعز'),
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _adhanPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlayingAdhan = state == PlayerState.playing;
        });
      }
    });
    _load();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appIsResumed = state == AppLifecycleState.resumed;
    if (state == AppLifecycleState.resumed) {
      PrayerTimesService.refreshNotificationsIfEnabled();
      _refreshTimes();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _latitudeController.dispose();
    _longitudeController.dispose();
    _locationNameController.dispose();
    _adhanCheckTimer?.cancel();
    _countdownTimer?.cancel();
    _adhanPlayer.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      await PrayerTimesService.initialize();
      final location = await PrayerTimesService.getSavedLocation();
      final method = await PrayerTimesService.getCalculationMethodIndex();
      final hanafi = await PrayerTimesService.hanafiAsr;
      final prefs = await SharedPreferences.getInstance();
      final adhanPath = prefs.getString('custom_adhan_path');
      final notificationsEnabled = await PrayerTimesService.notificationsEnabled;
      final dhikrRemindersEnabled = await PrayerTimesService.dhikrRemindersEnabled;

      if (location != null) {
        _latitudeController.text = location.latitude.toStringAsFixed(5);
        _longitudeController.text = location.longitude.toStringAsFixed(5);
        _locationNameController.text = location.name;
      }

      final times = location == null
          ? null
          : await PrayerTimesService.calculateFor(location, DateTime.now());

      if (!mounted) return;
      setState(() {
        _location = location;
        _times = times;
        _methodIndex = method;
        _hanafiAsr = hanafi;
        _adhanPath = adhanPath;
        _notificationsEnabled = notificationsEnabled;
        _dhikrRemindersEnabled = dhikrRemindersEnabled;
        _loading = false;
      });

      _adhanCheckTimer ??= Timer.periodic(
        const Duration(seconds: 10),
        (_) => _checkForPrayerAdhan(),
      );

      _countdownTimer ??= Timer.periodic(
        const Duration(seconds: 30),
        (_) {
          if (mounted) setState(() {});
        },
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showMessage('تعذر تجهيز مواقيت الصلاة: $error');
    }
  }

  Future<void> _useDeviceLocation() async {
    setState(() => _busy = true);
    try {
      final location = await PrayerTimesService.determineCurrentLocation();
      await _updateLocation(location);
      _showMessage('تم تحديد وتحديث موقعك بنجاح.');
    } catch (error) {
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveManualLocation() async {
    final latitude = double.tryParse(_latitudeController.text.trim());
    final longitude = double.tryParse(_longitudeController.text.trim());
    if (latitude == null ||
        longitude == null ||
        latitude.abs() > 90 ||
        longitude.abs() > 180) {
      _showMessage(
        'أدخل إحداثيات صحيحة: خط العرض من -90 إلى 90 والطول من -180 إلى 180.',
      );
      return;
    }
    final location = PrayerLocation(
      latitude: latitude,
      longitude: longitude,
      name: _locationNameController.text.trim().isEmpty
          ? 'موقع يدوي'
          : _locationNameController.text.trim(),
    );
    await _updateLocation(location);
    _showMessage('تم حفظ الموقع اليدوي بنجاح.');
  }

  Future<void> _updateLocation(PrayerLocation location) async {
    await PrayerTimesService.saveLocation(location);
    final times = await PrayerTimesService.calculateFor(
      location,
      DateTime.now(),
    );
    if (!mounted) return;
    setState(() {
      _location = location;
      _times = times;
      _latitudeController.text = location.latitude.toStringAsFixed(5);
      _longitudeController.text = location.longitude.toStringAsFixed(5);
      _locationNameController.text = location.name;
    });
    if (_notificationsEnabled) {
      await PrayerTimesService.schedulePrayerNotifications(location);
    }
  }

  Future<void> _saveMethod(int? index) async {
    if (index == null) return;
    await PrayerTimesService.setCalculationMethodIndex(index);
    setState(() => _methodIndex = index);
    await _refreshTimes();
    if (_notificationsEnabled && _location != null) {
      await PrayerTimesService.schedulePrayerNotifications(_location!);
    }
  }

  Future<void> _setMadhab(bool value) async {
    await PrayerTimesService.setHanafiAsr(value);
    setState(() => _hanafiAsr = value);
    await _refreshTimes();
    if (_notificationsEnabled && _location != null) {
      await PrayerTimesService.schedulePrayerNotifications(_location!);
    }
  }

  Future<void> _refreshTimes() async {
    if (_location == null) return;
    final times = await PrayerTimesService.calculateFor(
      _location!,
      DateTime.now(),
    );
    if (mounted) setState(() => _times = times);
  }

  Future<void> _togglePrayerNotifications(bool enable) async {
    if (enable) {
      if (_location == null) {
        _showMessage('حدّد موقعك أولًا لحساب مواقيت الصلاة بدقة.');
        return;
      }

      setState(() => _busy = true);
      try {
        final canExact = await PrayerTimesService.canScheduleExactAlarms();
        if (!canExact) {
          final grant = await _showExactAlarmDialog();
          if (grant == true) {
            await PrayerTimesService.requestExactAlarmPermission();
          }
        }

        await PrayerTimesService.schedulePrayerNotifications(_location!);
        if (mounted) setState(() => _notificationsEnabled = true);
        _showMessage('تم تفعيل أذان الصلوات وتنبيهات الخلفية بنجاح.');
      } catch (error) {
        _showMessage(error.toString().replaceFirst('Exception: ', ''));
      } finally {
        if (mounted) setState(() => _busy = false);
      }
    } else {
      setState(() => _busy = true);
      try {
        await PrayerTimesService.cancelPrayerNotifications();
        if (mounted) setState(() => _notificationsEnabled = false);
        _showMessage('تم إيقاف تنبيهات وأذان الصلاة.');
      } catch (error) {
        _showMessage('حدث خطأ أثناء الإلغاء: $error');
      } finally {
        if (mounted) setState(() => _busy = false);
      }
    }
  }

  Future<bool?> _showExactAlarmDialog() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'إذن التنبيه الدقيق للأذان',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'ليتمكن التطبيق من رفع الأذان في الوقت المضبوط تماماً حتى لو كان الهاتف مقفلاً أو في وضع السكون، يرجى تفعيل إذن "المنبهات والتذكيرات" في إعدادات النظام.',
          style: GoogleFonts.cairo(fontSize: 13, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('تخطي', style: GoogleFonts.cairo()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: Text('فتح الإعدادات', style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
  }

  Future<void> _setDhikrReminders(bool enabled) async {
    setState(() => _busy = true);
    try {
      await PrayerTimesService.setDhikrRemindersEnabled(enabled);
      if (!mounted) return;
      setState(() => _dhikrRemindersEnabled = enabled);
      _showMessage(
        enabled
            ? 'تم تفعيل التذكير بذكر الله والصلاة على النبي ﷺ في الخلفية.'
            : 'تم إيقاف تذكيرات الأذكار.',
      );
    } catch (error) {
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _testDhikrReminder() async {
    try {
      await PrayerTimesService.showDhikrReminder();
      _showMessage('تم إرسال إشعار تذكير تجريبي الآن.');
    } catch (e) {
      _showMessage('تعذر إرسال الإشعار: $e');
    }
  }

  Future<void> _stopAllAdhan() async {
    try {
      await _adhanPlayer.stop();
      await PrayerTimesService.stopAdhan();
      if (mounted) setState(() => _isPlayingAdhan = false);
      _showMessage('تم إيقاف صوت الأذان.');
    } catch (e) {
      debugPrint('Error stopping adhan: $e');
    }
  }

  Future<void> _pickAdhan() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'm4a', 'wav', 'aac', 'ogg'],
      );
      if (result == null || result.files.single.path == null) return;
      var savedPath = result.files.single.path!;
      if (!kIsWeb) {
        final directory = await getApplicationDocumentsDirectory();
        final extension = path.extension(savedPath).isEmpty
            ? '.mp3'
            : path.extension(savedPath);
        final destination = File(
          path.join(directory.path, 'custom_adhan$extension'),
        );
        await File(savedPath).copy(destination.path);
        savedPath = destination.path;
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('custom_adhan_path', savedPath);
      if (!mounted) return;
      setState(() => _adhanPath = savedPath);
      _showMessage('تم حفظ ملف الأذان المخصص بنجاح.');
      if (_notificationsEnabled && _location != null) {
        await PrayerTimesService.schedulePrayerNotifications(_location!);
      }
    } catch (error) {
      _showMessage('تعذر استيراد الملف: $error');
    }
  }

  Future<void> _resetToDefaultAdhan() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('custom_adhan_path');
    setState(() => _adhanPath = null);
    _showMessage('تمت العودة إلى الأذان الافتراضي المدمج.');
    if (_notificationsEnabled && _location != null) {
      await PrayerTimesService.schedulePrayerNotifications(_location!);
    }
  }

  Future<void> _previewAdhan() async {
    if (_isPlayingAdhan) {
      await _stopAllAdhan();
      return;
    }

    try {
      if (_adhanPath != null && _adhanPath!.isNotEmpty) {
        if (kIsWeb) {
          await _adhanPlayer.play(UrlSource(_adhanPath!));
        } else {
          await _adhanPlayer.play(DeviceFileSource(_adhanPath!));
        }
      } else {
        await _adhanPlayer.play(AssetSource('audio/adhan.mp3'));
      }
      setState(() => _isPlayingAdhan = true);
    } catch (error) {
      _showMessage('تعذر تشغيل ملف الأذان: $error');
    }
  }

  Future<void> _checkForPrayerAdhan() async {
    if (!_appIsResumed ||
        !_notificationsEnabled ||
        _times == null) {
      return;
    }

    final now = DateTime.now();
    for (final prayer in _prayerList(_times!)) {
      if (prayer.$1 == 'الشروق') continue;
      final difference = now.difference(prayer.$2).inSeconds;
      final key = '${now.year}-${now.month}-${now.day}-${prayer.$1}';
      if (difference >= 0 && difference < 20 && key != _lastPlayedPrayerKey) {
        _lastPlayedPrayerKey = key;
        try {
          if (_adhanPath != null && _adhanPath!.isNotEmpty) {
            if (kIsWeb) {
              await _adhanPlayer.play(UrlSource(_adhanPath!));
            } else if (await File(_adhanPath!).exists()) {
              await _adhanPlayer.play(DeviceFileSource(_adhanPath!));
            }
          } else {
            await _adhanPlayer.play(AssetSource('audio/adhan.mp3'));
          }
          setState(() => _isPlayingAdhan = true);
          _showInAppAdhanPrompt(prayer.$1);
        } catch (error) {
          debugPrint('Foreground adhan play error: $error');
        }
        return;
      }
    }
  }

  void _showInAppAdhanPrompt(String prayerName) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            const Text('🕌', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'حان أذان $prayerName',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 17),
              ),
            ),
          ],
        ),
        content: Text(
          'يرتفع الآن أذان صلاة $prayerName المبارك.\nهل تريد إيقاف صوت الأذان؟',
          style: GoogleFonts.cairo(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('لا (متابعة الأذان)', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _stopAllAdhan();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            child: Text('نعم (إيقاف الأذان)', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.cairo(fontSize: 13)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _formatTime(DateTime dateTime) => MaterialLocalizations.of(
    context,
  ).formatTimeOfDay(TimeOfDay.fromDateTime(dateTime));

  List<(String, DateTime)> _prayerList(PrayerTimes times) => [
    ('الفجر', times.fajr),
    ('الشروق', times.sunrise),
    ('الظهر', times.dhuhr),
    ('العصر', times.asr),
    ('المغرب', times.maghrib),
    ('العشاء', times.isha),
  ];

  (String, Duration)? _getNextPrayerInfo(List<(String, DateTime)> prayers) {
    final now = DateTime.now();
    for (final prayer in prayers) {
      if (prayer.$1 != 'الشروق' && prayer.$2.isAfter(now)) {
        return (prayer.$1, prayer.$2.difference(now));
      }
    }
    // If all passed today, next is Fajr tomorrow
    if (prayers.isNotEmpty) {
      final tomorrowFajr = prayers.first.$2.add(const Duration(days: 1));
      return ('الفجر', tomorrowFajr.difference(now));
    }
    return null;
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    if (hours > 0) {
      return '$hours ساعة و $minutes دقيقة';
    } else {
      return '$minutes دقيقة';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final green = Theme.of(context).colorScheme.primary;
    final gold = Theme.of(context).colorScheme.secondary;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'مواقيت الصلاة والأذان',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.explore_outlined),
            tooltip: 'بوصلة القبلة',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const QiblaScreen()),
            ),
          ),
          if (_isPlayingAdhan)
            TextButton.icon(
              onPressed: _stopAllAdhan,
              icon: const Icon(Icons.stop_circle_rounded, color: Colors.redAccent),
              label: Text(
                'إيقاف الأذان',
                style: GoogleFonts.cairo(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: const MiniPlayer(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 760;
                final main = _buildMainContent(isDark, green, gold);
                final settings = _buildSettings(isDark, green, gold);

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1120),
                    child: wide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.all(16),
                                  child: main,
                                ),
                              ),
                              SizedBox(
                                width: 380,
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.all(16),
                                  child: settings,
                                ),
                              ),
                            ],
                          )
                        : ListView(
                            padding: const EdgeInsets.all(16),
                            physics: const BouncingScrollPhysics(),
                            children: [main, settings],
                          ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildMainContent(bool isDark, Color green, Color gold) {
    final times = _times;
    final prayers = times == null ? <(String, DateTime)>[] : _prayerList(times);
    final nextPrayerInfo = times != null ? _getNextPrayerInfo(prayers) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Adhan Floating Stop Banner if currently sounding
        if (_isPlayingAdhan)
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.red, width: 1.5),
            ),
            child: Row(
              children: [
                const Icon(Icons.volume_up_rounded, color: Colors.red, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'صوت الأذان يرتفع الآن...',
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'اضغط على الزر لإسكات الصوت فوراً',
                        style: GoogleFonts.cairo(fontSize: 11),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _stopAllAdhan,
                  icon: const Icon(Icons.stop_rounded, size: 18),
                  label: Text('إيقاف', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  ),
                ),
              ],
            ),
          ),

        // Main Islamic Banner with Next Prayer Countdown
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF132B25), const Color(0xFF0C1916)]
                  : [const Color(0xFF0F5132), const Color(0xFF1B6B4C)],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.15),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded, color: gold, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _location?.name ?? 'حدّد الموقع لعرض المواقيت',
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  if (_notificationsEnabled)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: gold.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: gold.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.notifications_active_rounded, color: gold, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'الأذان مفعل',
                            style: GoogleFonts.cairo(
                              color: gold,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              if (nextPrayerInfo != null) ...[
                Text(
                  'الصلاة القادمة: صلاة ${nextPrayerInfo.$1}',
                  style: GoogleFonts.cairo(
                    color: gold,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'بقي على الأذان: ${_formatDuration(nextPrayerInfo.$2)}',
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ] else ...[
                Text(
                  MaterialLocalizations.of(context).formatFullDate(DateTime.now()),
                  style: GoogleFonts.cairo(color: Colors.white70, fontSize: 13),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (times == null)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'استخدم موقع الجهاز أو اختر مدينتك لحساب مواقيت الصلاة بدقة.',
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(fontSize: 15),
              ),
            ),
          )
        else
          ...prayers.map((prayer) {
            final isNext = nextPrayerInfo != null && prayer.$1 == nextPrayerInfo.$1;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: isNext
                    ? green.withValues(alpha: isDark ? 0.28 : 0.08)
                    : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isNext
                      ? green.withValues(alpha: 0.6)
                      : (isDark ? Colors.white12 : Colors.black12),
                  width: isNext ? 1.5 : 1,
                ),
              ),
              child: ListTile(
                leading: Icon(
                  _prayerIcon(prayer.$1),
                  color: isNext ? green : gold,
                ),
                title: Text(
                  prayer.$1,
                  style: GoogleFonts.cairo(
                    fontWeight: isNext ? FontWeight.bold : FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                trailing: Text(
                  _formatTime(prayer.$2),
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isNext ? green : null,
                  ),
                ),
              ),
            );
          }),

        const SizedBox(height: 12),

        // Quick Toggle Action Button for Adhan
        FilledButton.icon(
          onPressed: _busy ? null : () => _togglePrayerNotifications(!_notificationsEnabled),
          icon: Icon(
            _notificationsEnabled
                ? Icons.notifications_off_outlined
                : Icons.notifications_active_rounded,
          ),
          label: Text(
            _notificationsEnabled
                ? 'إيقاف تنبيهات وأذان الصلاة'
                : 'تفعيل أذان الصلوات وتنبيهات الخلفية',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: _notificationsEnabled ? Colors.red.shade700 : const Color(0xFF0F5132),
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ],
    );
  }

  IconData _prayerIcon(String name) => switch (name) {
    'الفجر' => Icons.wb_twilight_rounded,
    'الشروق' => Icons.wb_sunny_outlined,
    'الظهر' => Icons.light_mode_outlined,
    'العصر' => Icons.sunny_snowing,
    'المغرب' => Icons.nights_stay_outlined,
    _ => Icons.nightlight_round,
  };

  Widget _buildSettings(bool isDark, Color green, Color gold) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'تخصيص الأذان والإشعارات',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        const SizedBox(height: 12),

        // Adhan sound box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.5) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.volume_up_rounded, color: gold, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'صوت الأذان المبارك',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _adhanPath == null
                    ? 'الأذان الافتراضي المبارك (مدمج بجودة عالية)'
                    : 'ملف مخصص: ${path.basename(_adhanPath!)}',
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickAdhan,
                      icon: const Icon(Icons.upload_file_rounded, size: 18),
                      label: Text('اختيار ملف صوتي', style: GoogleFonts.cairo(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: _previewAdhan,
                    tooltip: _isPlayingAdhan ? 'إيقاف' : 'تجربة الأذان',
                    icon: Icon(_isPlayingAdhan ? Icons.stop_rounded : Icons.play_arrow_rounded),
                  ),
                ],
              ),
              if (_adhanPath != null)
                TextButton(
                  onPressed: _resetToDefaultAdhan,
                  child: Text('العودة للأذان الافتراضي', style: GoogleFonts.cairo(fontSize: 12)),
                ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Dhikr Reminders Switch Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.5) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'تذكير بذكر الله والصلاة على النبي ﷺ',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: Text(
                  'إشعارات دورية حتى لو كان التطبيق مغلقاً أو في الخلفية',
                  style: GoogleFonts.cairo(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
                ),
                value: _dhikrRemindersEnabled,
                activeColor: green,
                onChanged: _setDhikrReminders,
              ),
              if (_dhikrRemindersEnabled) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _testDhikrReminder,
                  icon: const Icon(Icons.notifications_active_outlined, size: 18),
                  label: Text('إرسال تذكير تجريبي الآن', style: GoogleFonts.cairo(fontSize: 12)),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 20),
        Text(
          'إعدادات الموقع والحساب',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 10),

        OutlinedButton.icon(
          onPressed: _busy ? null : _useDeviceLocation,
          icon: const Icon(Icons.my_location_rounded),
          label: Text(
            _busy ? 'جارٍ تحديد الموقع...' : 'استخدام موقع الجهاز التلقائي',
            style: GoogleFonts.cairo(),
          ),
        ),
        const SizedBox(height: 8),

        DropdownButtonFormField<String>(
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'اختر مدينة سريعة'),
          items: [
            for (final city in _cityLocations.keys)
              DropdownMenuItem(value: city, child: Text(city, style: GoogleFonts.cairo())),
          ],
          onChanged: (city) {
            final location = _cityLocations[city];
            if (location != null) _updateLocation(location);
          },
        ),
        const SizedBox(height: 8),

        TextField(
          controller: _locationNameController,
          decoration: const InputDecoration(labelText: 'اسم المدينة (اختياري)'),
        ),
        const SizedBox(height: 8),

        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _latitudeController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                decoration: const InputDecoration(labelText: 'خط العرض'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _longitudeController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                decoration: const InputDecoration(labelText: 'خط الطول'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        OutlinedButton.icon(
          onPressed: _saveManualLocation,
          icon: const Icon(Icons.save_outlined),
          label: Text('حفظ الإحداثيات يدويًا', style: GoogleFonts.cairo()),
        ),
        const SizedBox(height: 12),

        DropdownButtonFormField<int>(
          value: _methodIndex,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'طريقة الحساب الفقهية'),
          items: [
            for (var i = 0; i < CalculationMethod.values.length; i++)
              DropdownMenuItem(
                value: i,
                child: Text(
                  _methodLabels[CalculationMethod.values[i]]!,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(fontSize: 13),
                ),
              ),
          ],
          onChanged: _saveMethod,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('العصر على المذهب الحنفي', style: GoogleFonts.cairo(fontSize: 14)),
          value: _hanafiAsr,
          activeColor: green,
          onChanged: _setMadhab,
        ),
      ],
    );
  }
}
