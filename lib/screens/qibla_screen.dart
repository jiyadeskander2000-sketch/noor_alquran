import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/compass_service.dart';
import '../services/prayer_times_service.dart';

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  PrayerLocation? _location;
  double _qiblaBearing = 0.0;
  double _distanceKm = 0.0;
  double _currentHeading = 0.0;
  bool _loading = true;
  bool _hapticEnabled = true;
  bool _wasFacingQibla = false;
  StreamSubscription<double>? _compassSubscription;

  @override
  void initState() {
    super.initState();
    _loadLocationAndCalculate();
    _startCompass();
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    super.dispose();
  }

  void _startCompass() {
    _compassSubscription = CompassService.headingStream.listen((heading) {
      if (!mounted) return;
      setState(() {
        _currentHeading = heading;
      });

      final isFacing = CompassService.isFacingQibla(_currentHeading, _qiblaBearing);
      if (isFacing && !_wasFacingQibla) {
        // Just aligned with Qibla
        if (_hapticEnabled) {
          HapticFeedback.heavyImpact();
        }
      }
      _wasFacingQibla = isFacing;
    });
  }

  Future<void> _loadLocationAndCalculate() async {
    setState(() => _loading = true);
    var loc = await PrayerTimesService.getSavedLocation();
    if (loc == null) {
      try {
        loc = await PrayerTimesService.determineCurrentLocation();
      } catch (_) {
        // Offline Default: Mecca
        loc = const PrayerLocation(
          latitude: 21.4225,
          longitude: 39.8262,
          name: 'مكة المكرمة',
        );
      }
    }

    final bearing = CompassService.calculateQibla(
      loc.latitude,
      loc.longitude,
    );
    final distance = CompassService.calculateDistanceKm(
      loc.latitude,
      loc.longitude,
    );

    if (mounted) {
      setState(() {
        _location = loc;
        _qiblaBearing = bearing;
        _distanceKm = distance;
        _loading = false;
      });
    }
  }

  void _showOfflineCityPicker() {
    final searchCtrl = TextEditingController();
    List<OfflineCity> filteredCities = List.from(CompassService.offlineCities);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final gold = const Color(0xFFD4AF37);

        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              height: MediaQuery.of(ctx).size.height * 0.75,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF141F2D) : Colors.white,
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
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Icon(Icons.location_city_rounded, color: gold, size: 24),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'اختر مدينتك (يعمل بدون إنترنت 100%)',
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TextField(
                      controller: searchCtrl,
                      decoration: InputDecoration(
                        hintText: 'ابحث عن اسم المدينة أو الدولة...',
                        hintStyle: GoogleFonts.cairo(fontSize: 13),
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: isDark ? Colors.white10 : Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (val) {
                        setModalState(() {
                          filteredCities = CompassService.offlineCities.where((c) {
                            return c.name.contains(val.trim()) ||
                                c.country.contains(val.trim());
                          }).toList();
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: filteredCities.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (ctx, idx) {
                        final city = filteredCities[idx];
                        final isSelected = _location?.name == city.name;
                        return ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: gold.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.place_rounded, color: gold, size: 20),
                          ),
                          title: Text(
                            city.name,
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: isSelected ? gold : null,
                            ),
                          ),
                          subtitle: Text(
                            city.country,
                            style: GoogleFonts.cairo(fontSize: 12),
                          ),
                          trailing: isSelected
                              ? Icon(Icons.check_circle_rounded, color: gold)
                              : const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                          onTap: () async {
                            final newLoc = PrayerLocation(
                              latitude: city.latitude,
                              longitude: city.longitude,
                              name: city.name,
                            );
                            await PrayerTimesService.saveLocation(newLoc);
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                            }
                            _loadLocationAndCalculate();
                          },
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

  String _getDirectionCardinal(double deg) {
    if (deg >= 337.5 || deg < 22.5) return 'شمال';
    if (deg >= 22.5 && deg < 67.5) return 'شمال شرق';
    if (deg >= 67.5 && deg < 112.5) return 'شرق';
    if (deg >= 112.5 && deg < 157.5) return 'جنوب شرق';
    if (deg >= 157.5 && deg < 202.5) return 'جنوب';
    if (deg >= 202.5 && deg < 247.5) return 'جنوب غرب';
    if (deg >= 247.5 && deg < 292.5) return 'غرب';
    return 'شمال غرب';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final goldColor = const Color(0xFFD4AF37);
    final primaryGreen = const Color(0xFF0F5132);

    final isFacing = CompassService.isFacingQibla(_currentHeading, _qiblaBearing);
    // Relative angle between current phone heading and Qibla
    final relativeAngle = (_qiblaBearing - _currentHeading + 360) % 360;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'بوصلة القبلة الحقيقية 🕋',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.location_city_rounded),
            tooltip: 'تحديد المدينة يدوياً (أوفلاين)',
            onPressed: _showOfflineCityPicker,
          ),
          IconButton(
            icon: const Icon(Icons.my_location_rounded),
            tooltip: 'تحديث الموقع عبر GPS',
            onPressed: () async {
              try {
                final loc = await PrayerTimesService.determineCurrentLocation();
                await PrayerTimesService.saveLocation(loc);
                await _loadLocationAndCalculate();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم تحديث الموقع بنجاح')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('تعذر تحديد الموقع: $e (يمكنك اختيار مدينتك أوفلاين)')),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Status banner
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 350),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isFacing
                                    ? [const Color(0xFF1B6B4C), const Color(0xFF0F5132)]
                                    : (isDark
                                        ? [const Color(0xFF152234), const Color(0xFF0E1724)]
                                        : [Colors.white, const Color(0xFFF8FAFC)]),
                                begin: Alignment.topRight,
                                end: Alignment.bottomLeft,
                              ),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: isFacing ? goldColor : (isDark ? Colors.white12 : Colors.grey.shade300),
                                width: isFacing ? 2.0 : 1.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isFacing
                                      ? goldColor.withValues(alpha: 0.3)
                                      : Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                                  blurRadius: isFacing ? 20 : 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: goldColor.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: goldColor, width: 1.5),
                                  ),
                                  child: Text(
                                    isFacing ? '✨' : '🕋',
                                    style: const TextStyle(fontSize: 22),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isFacing
                                            ? 'أنت الآن باتجاه القبلة مباشرة! 🕋'
                                            : 'موقعك: ${_location?.name ?? "مكة المكرمة"}',
                                        style: GoogleFonts.cairo(
                                          color: isFacing
                                              ? Colors.white
                                              : (isDark ? Colors.white : Colors.black87),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'المسافة إلى الكعبة المشرفة: ${_distanceKm.toStringAsFixed(0)} كم',
                                        style: GoogleFonts.cairo(
                                          color: isFacing ? const Color(0xFFF3C64F) : goldColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                OutlinedButton(
                                  onPressed: _showOfflineCityPicker,
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: goldColor),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  ),
                                  child: Text(
                                    'تغيير المدينة',
                                    style: GoogleFonts.cairo(
                                      color: isFacing ? Colors.white : (isDark ? goldColor : primaryGreen),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Compass Interactive Dial (Rotates in 60fps with device hardware sensors)
                          SizedBox(
                            width: 300,
                            height: 300,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Outer Rotating Dial (North indicator follows true Earth heading)
                                Transform.rotate(
                                  angle: -_currentHeading * (pi / 180.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isDark ? const Color(0xFF131D2C) : Colors.grey.shade50,
                                      border: Border.all(
                                        color: isFacing
                                            ? const Color(0xFF10B981)
                                            : goldColor.withValues(alpha: 0.6),
                                        width: isFacing ? 5 : 3.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: isFacing
                                              ? const Color(0xFF10B981).withValues(alpha: 0.35)
                                              : goldColor.withValues(alpha: 0.15),
                                          blurRadius: 32,
                                          spreadRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        // 360 degree ticks
                                        for (int i = 0; i < 360; i += 30)
                                          Transform.rotate(
                                            angle: i * (pi / 180.0),
                                            child: Align(
                                              alignment: Alignment.topCenter,
                                              child: Container(
                                                margin: const EdgeInsets.only(top: 8),
                                                width: i % 90 == 0 ? 3 : 1.5,
                                                height: i % 90 == 0 ? 12 : 6,
                                                color: i % 90 == 0
                                                    ? goldColor
                                                    : (isDark ? Colors.white24 : Colors.grey.shade400),
                                              ),
                                            ),
                                          ),

                                        // Cardinal directions
                                        Positioned(
                                          top: 22,
                                          child: Text(
                                            'شمال (N)',
                                            style: GoogleFonts.cairo(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: Colors.redAccent,
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 22,
                                          child: Text(
                                            'جنوب (S)',
                                            style: GoogleFonts.cairo(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: isDark ? Colors.white60 : Colors.black54,
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          right: 22,
                                          child: Text(
                                            'شرق (E)',
                                            style: GoogleFonts.cairo(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: isDark ? Colors.white60 : Colors.black54,
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          left: 22,
                                          child: Text(
                                            'غرب (W)',
                                            style: GoogleFonts.cairo(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: isDark ? Colors.white60 : Colors.black54,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Relative Qibla Pointer Arrow (Points to Kaaba relative to the phone)
                                Transform.rotate(
                                  angle: relativeAngle * (pi / 180.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Kaaba Icon at the tip
                                      AnimatedContainer(
                                        duration: const Duration(milliseconds: 300),
                                        padding: const EdgeInsets.all(7),
                                        decoration: BoxDecoration(
                                          color: isFacing
                                              ? const Color(0xFF10B981)
                                              : goldColor.withValues(alpha: 0.3),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isFacing ? Colors.white : goldColor,
                                            width: 2,
                                          ),
                                        ),
                                        child: const Text('🕋', style: TextStyle(fontSize: 24)),
                                      ),
                                      const SizedBox(height: 4),
                                      Icon(
                                        Icons.navigation_rounded,
                                        color: isFacing ? const Color(0xFF10B981) : primaryGreen,
                                        size: 75,
                                      ),
                                      const SizedBox(height: 75),
                                    ],
                                  ),
                                ),

                                // Center Pivot Core
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: isFacing
                                          ? [const Color(0xFF10B981), const Color(0xFF0F5132)]
                                          : [const Color(0xFFF3C64F), const Color(0xFFD4AF37)],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.3),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Icon(
                                      isFacing ? Icons.check_rounded : Icons.explore_rounded,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Realtime Telemetry Info Cards
                          Row(
                            children: [
                              Expanded(
                                child: _buildTelemetryCard(
                                  context: context,
                                  title: 'اتجاه القبلة',
                                  value: '${_qiblaBearing.toStringAsFixed(1)}°',
                                  subtitle: _getDirectionCardinal(_qiblaBearing),
                                  icon: Icons.my_location_rounded,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTelemetryCard(
                                  context: context,
                                  title: 'توجيه الهاتف',
                                  value: '${_currentHeading.toStringAsFixed(1)}°',
                                  subtitle: _getDirectionCardinal(_currentHeading),
                                  icon: Icons.phone_android_rounded,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Blind Accessibility & Offline Note Banner
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF131D2D) : Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isDark ? Colors.white12 : Colors.grey.shade200,
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.vibration_rounded, color: goldColor, size: 22),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'تنبيه اهتزازي للمكفوفين عند محاذاة القبلة',
                                        style: GoogleFonts.cairo(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    Switch.adaptive(
                                      value: _hapticEnabled,
                                      activeColor: goldColor,
                                      onChanged: (val) {
                                        setState(() => _hapticEnabled = val);
                                      },
                                    ),
                                  ],
                                ),
                                const Divider(height: 16),
                                Row(
                                  children: [
                                    const Icon(Icons.offline_bolt_rounded, color: Colors.green, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'حسابات البوصلة تعمل بالكامل محلياً (100% بدون إنترنت) عبر حساسات الهاتف الجيومغناطيسية.',
                                        style: GoogleFonts.cairo(
                                          fontSize: 11,
                                          color: isDark ? Colors.white60 : Colors.black54,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
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

  Widget _buildTelemetryCard({
    required BuildContext context,
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final goldColor = const Color(0xFFD4AF37);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D2D) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: goldColor, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    color: goldColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
