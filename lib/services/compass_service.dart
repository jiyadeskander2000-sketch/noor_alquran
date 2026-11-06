import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class OfflineCity {
  final String name;
  final String country;
  final double latitude;
  final double longitude;

  const OfflineCity({
    required this.name,
    required this.country,
    required this.latitude,
    required this.longitude,
  });
}

class CompassService {
  CompassService._();

  static const _compassChannel = EventChannel('noor_alquran/compass');
  static const double kaabaLat = 21.4225;
  static const double kaabaLng = 39.8262;

  // Stream of smoothed compass heading in degrees (0..360, 0 = North)
  static Stream<double>? _headingStream;
  static double _lastHeading = 0.0;

  static Stream<double> get headingStream {
    _headingStream ??= _compassChannel
        .receiveBroadcastStream()
        .map<double>((dynamic event) {
          final raw = (event as num).toDouble();
          // Low-pass filter for smooth motion
          _lastHeading = _smoothAngle(_lastHeading, raw, 0.25);
          return _lastHeading;
        })
        .handleError((dynamic error) {
          debugPrint('Compass stream error: $error');
          return 0.0;
        });
    return _headingStream!;
  }

  // Smooth angle interpolation avoiding 360/0 jump glitch
  static double _smoothAngle(double current, double target, double factor) {
    double diff = (target - current) % 360;
    if (diff > 180) diff -= 360;
    if (diff < -180) diff += 360;
    double result = (current + diff * factor) % 360;
    return result < 0 ? result + 360 : result;
  }

  // Great-Circle accurate mathematical Qibla bearing
  static double calculateQibla(double lat, double lng) {
    final phi1 = lat * (pi / 180.0);
    final phi2 = kaabaLat * (pi / 180.0);
    final deltaLambda = (kaabaLng - lng) * (pi / 180.0);

    final y = sin(deltaLambda);
    final x = cos(phi1) * tan(phi2) - sin(phi1) * cos(deltaLambda);
    final bearingRad = atan2(y, x);
    final bearingDeg = (bearingRad * (180.0 / pi) + 360.0) % 360.0;
    return bearingDeg;
  }

  // Great-Circle accurate distance to Kaaba in kilometers
  static double calculateDistanceKm(double lat, double lng) {
    const r = 6371.0; // Earth radius in km
    final dLat = (kaabaLat - lat) * (pi / 180.0);
    final dLng = (kaabaLng - lng) * (pi / 180.0);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat * (pi / 180.0)) *
            cos(kaabaLat * (pi / 180.0)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  // Check if current phone heading is aligned with Qibla within tolerance
  static bool isFacingQibla(double heading, double qiblaBearing, {double tolerance = 3.5}) {
    double diff = (heading - qiblaBearing).abs();
    if (diff > 180) diff = 360 - diff;
    return diff <= tolerance;
  }

  // 100% Offline database of Islamic and Arab cities
  static const List<OfflineCity> offlineCities = [
    // السعودية
    OfflineCity(name: 'مكة المكرمة', country: 'السعودية', latitude: 21.4225, longitude: 39.8262),
    OfflineCity(name: 'المدينة المنورة', country: 'السعودية', latitude: 24.4672, longitude: 39.6111),
    OfflineCity(name: 'الرياض', country: 'السعودية', latitude: 24.7136, longitude: 46.6753),
    OfflineCity(name: 'جدة', country: 'السعودية', latitude: 21.5433, longitude: 39.1728),
    OfflineCity(name: 'الدمام', country: 'السعودية', latitude: 26.4207, longitude: 50.0888),
    OfflineCity(name: 'أبها', country: 'السعودية', latitude: 18.2164, longitude: 42.5053),
    OfflineCity(name: 'تبوك', country: 'السعودية', latitude: 28.3835, longitude: 36.5662),

    // اليمن
    OfflineCity(name: 'صنعاء', country: 'اليمن', latitude: 15.3694, longitude: 44.1910),
    OfflineCity(name: 'عدن', country: 'اليمن', latitude: 12.7855, longitude: 45.0187),
    OfflineCity(name: 'تعز', country: 'اليمن', latitude: 13.5776, longitude: 44.0175),
    OfflineCity(name: 'الحديدة', country: 'اليمن', latitude: 14.7978, longitude: 42.9545),
    OfflineCity(name: 'إب', country: 'اليمن', latitude: 13.9667, longitude: 44.1667),
    OfflineCity(name: 'المكلا (حضرموت)', country: 'اليمن', latitude: 14.5425, longitude: 49.1242),
    OfflineCity(name: 'ذمار', country: 'اليمن', latitude: 14.5427, longitude: 44.4051),

    // مصر
    OfflineCity(name: 'القاهرة', country: 'مصر', latitude: 30.0444, longitude: 31.2357),
    OfflineCity(name: 'الإسكندرية', country: 'مصر', latitude: 31.2001, longitude: 29.9187),
    OfflineCity(name: 'طنطا', country: 'مصر', latitude: 30.7865, longitude: 31.0004),
    OfflineCity(name: 'أسوان', country: 'مصر', latitude: 24.0889, longitude: 32.8998),

    // الشام وفلسطين
    OfflineCity(name: 'القدس الشريف', country: 'فلسطين', latitude: 31.7683, longitude: 35.2137),
    OfflineCity(name: 'غزة', country: 'فلسطين', latitude: 31.5017, longitude: 34.4668),
    OfflineCity(name: 'دمشق', country: 'سوريا', latitude: 33.5138, longitude: 36.2765),
    OfflineCity(name: 'حلب', country: 'سوريا', latitude: 36.2021, longitude: 37.1343),
    OfflineCity(name: 'عَمّان', country: 'الأردن', latitude: 31.9454, longitude: 35.9284),
    OfflineCity(name: 'بيروت', country: 'لبنان', latitude: 33.8938, longitude: 35.5018),

    // الخليج العربي
    OfflineCity(name: 'دبي', country: 'الإمارات', latitude: 25.2048, longitude: 55.2708),
    OfflineCity(name: 'أبوظبي', country: 'الإمارات', latitude: 24.4539, longitude: 54.3773),
    OfflineCity(name: 'الكويت', country: 'الكويت', latitude: 29.3759, longitude: 47.9774),
    OfflineCity(name: 'الدوحة', country: 'قطر', latitude: 25.2854, longitude: 51.5310),
    OfflineCity(name: 'المنامة', country: 'البحرين', latitude: 26.2285, longitude: 50.5860),
    OfflineCity(name: 'مسقط', country: 'عُمان', latitude: 23.5880, longitude: 58.3829),

    // العراق
    OfflineCity(name: 'بغداد', country: 'العراق', latitude: 33.3152, longitude: 44.3661),
    OfflineCity(name: 'البصرة', country: 'العراق', latitude: 30.5081, longitude: 47.7835),
    OfflineCity(name: 'أربيل', country: 'العراق', latitude: 36.1901, longitude: 44.0091),

    // المغرب العربي
    OfflineCity(name: 'طرابلس', country: 'ليبيا', latitude: 32.8872, longitude: 13.1913),
    OfflineCity(name: 'بنغازي', country: 'ليبيا', latitude: 32.1167, longitude: 20.0667),
    OfflineCity(name: 'تونس', country: 'تونس', latitude: 36.8065, longitude: 10.1815),
    OfflineCity(name: 'الجزائر العاصمة', country: 'الجزائر', latitude: 36.7538, longitude: 3.0588),
    OfflineCity(name: 'وهران', country: 'الجزائر', latitude: 35.6987, longitude: -0.6349),
    OfflineCity(name: 'الرباط', country: 'المغرب', latitude: 34.0209, longitude: -6.8416),
    OfflineCity(name: 'الدار البيضاء', country: 'المغرب', latitude: 33.5731, longitude: -7.5898),
    OfflineCity(name: 'مراكش', country: 'المغرب', latitude: 31.6295, longitude: -7.9811),

    // بلدان عربية وإسلامية أخرى
    OfflineCity(name: 'الخرطوم', country: 'السودان', latitude: 15.5007, longitude: 32.5599),
    OfflineCity(name: 'مقديشو', country: 'الصومال', latitude: 2.0469, longitude: 45.3182),
    OfflineCity(name: 'نواكشوط', country: 'موريتانيا', latitude: 18.0735, longitude: -15.9582),
    OfflineCity(name: 'إسطنبول', country: 'تركيا', latitude: 41.0082, longitude: 28.9784),
    OfflineCity(name: 'كوالالمبور', country: 'ماليزيا', latitude: 3.1390, longitude: 101.6869),
    OfflineCity(name: 'جاكرتا', country: 'إندونيسيا', latitude: -6.2088, longitude: 106.8456),
  ];
}
