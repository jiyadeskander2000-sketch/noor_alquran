import 'dart:io';
import 'dart:math';
import 'package:adhan/adhan.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class PrayerTimesService {
  PrayerTimesService._();

  static const _adhanChannel = MethodChannel('noor_alquran/adhan');
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const _latitudeKey = 'prayer_latitude';
  static const _longitudeKey = 'prayer_longitude';
  static const _locationNameKey = 'prayer_location_name';
  static const _methodKey = 'prayer_calculation_method';
  static const _hanafiKey = 'prayer_hanafi_asr';
  static const _notificationsEnabledKey = 'prayer_notifications_enabled';
  static const _dhikrRemindersEnabledKey = 'dhikr_reminders_enabled';
  static const _dhikrIntervalMinutesKey = 'dhikr_interval_minutes';
  static const _customAdhanPathKey = 'custom_adhan_path';

  static const List<Map<String, String>> _dhikrList = [
    {
      'title': '🕊️ صَلِّ على الحبيب ﷺ',
      'body':
          'اللَّهُمَّ صَلِّ وَسَلِّمْ وَبَارِكْ عَلَى نَبِيِّنَا مُحَمَّدٍ وَعَلَى آلِهِ وَصَحْبِهِ أَجْمَعِينَ.',
    },
    {
      'title': '✨ تسبيح وتحميد',
      'body':
          'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ، سُبْحَانَ اللَّهِ الْعَظِيمِ (حبيبتان إلى الرحمن).',
    },
    {
      'title': '📿 ذكر وتوحيد',
      'body':
          'لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ.',
    },
    {
      'title': '🌿 استغفار وتوبة',
      'body':
          'أَسْتَغْفِرُ اللَّهَ الْعَظِيمَ الَّذِي لَا إِلَهَ إِلَّا هُوَ الْحَيَّ الْقَيُّومَ وَأَتُوبُ إِلَيْهِ.',
    },
    {
      'title': '💎 كنز من كنوز الجنة',
      'body':
          'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ الْعَلِيِّ الْعَظِيمِ.',
    },
    {
      'title': '🌸 دعاء واستغاثة',
      'body':
          'يَا حَيُّ يَا قَيُّومُ بِرَحْمَتِكَ أَسْتَغِيثُ، أَصْلِحْ لِي شَأْنِي كُلَّهُ وَلَا تَكِلْنِي إِلَى نَفْسِي طَرْفَةَ عَيْنٍ.',
    },
    {
      'title': '🤲 العفو والعافية',
      'body':
          'اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ فِي الدُّنْيَا وَالْآخِرَةِ.',
    },
    {
      'title': '🌟 الباقيات الصالحات',
      'body':
          'سُبْحَانَ اللَّهِ، وَالْحَمْدُ لِلَّهِ، وَلَا إِلَهَ إِلَّا اللَّهُ، وَاللَّهُ أَكْبَرُ.',
    },
    {
      'title': '☀️ كفاية وتوكل',
      'body':
          'حَسْبِيَ اللَّهُ لَا إِلَهَ إِلَّا هُوَ عَلَيْهِ تَوَكَّلْتُ وَهُوَ رَبُّ الْعَرْشِ الْعَظِيمِ.',
    },
    {
      'title': '🌙 تفريج الكرب',
      'body': 'لَا إِلَهَ إِلَّا أَنْتَ سُبْحَانَكَ إِنِّي كُنْتُ مِنَ الظَّالِمِينَ.',
    },
    {
      'title': '🌺 الصلاة الإبراهيمية',
      'body':
          'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ كَمَا صَلَّيْتَ عَلَى إِبْرَاهِيمَ وَعَلَى آلِ إِبْرَاهِيمَ.',
    },
    {
      'title': '💫 سيد الاستغفار',
      'body':
          'اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ.',
    },
  ];

  static List<Map<String, String>> get dhikrList => _dhikrList;

  static double calculateQiblaDirection(double lat, double lng) {
    const kaabaLat = 21.4225 * (pi / 180.0);
    const kaabaLng = 39.8262 * (pi / 180.0);
    final userLat = lat * (pi / 180.0);
    final userLng = lng * (pi / 180.0);

    final deltaLng = kaabaLng - userLng;
    final y = sin(deltaLng);
    final x = cos(userLat) * tan(kaabaLat) - sin(userLat) * cos(deltaLng);

    var qibla = atan2(y, x) * (180.0 / pi);
    return (qibla + 360.0) % 360.0;
  }

  static double calculateDistanceToKaabaKm(double lat, double lng) {
    const kaabaLat = 21.4225;
    const kaabaLng = 39.8262;
    return Geolocator.distanceBetween(lat, lng, kaabaLat, kaabaLng) / 1000.0;
  }

  static Future<void> initialize() async {
    tz_data.initializeTimeZones();
    try {
      tz.setLocalLocation(
        tz.getLocation(await FlutterTimezone.getLocalTimezone()),
      );
    } catch (_) {
      tz.setLocalLocation(tz.local);
    }

    const androidSettings = AndroidInitializationSettings(
      '@drawable/noor_launcher_icon',
    );
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _notifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      ),
      onDidReceiveNotificationResponse: (response) {
        if (response.actionId == 'stop_adhan') {
          stopAdhan();
        }
      },
    );

    // Create high importance notification channels on Android
    if (!kIsWeb && Platform.isAndroid) {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            'prayer_times',
            'مواقيت الصلاة والأذان',
            description: 'تنبيهات وأصوات الأذان عند دخول أوقات الصلاة مع خيار الإيقاف',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
          ),
        );
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            'dhikr_reminders',
            'تذكير الأذكار والصلاة على النبي',
            description: 'إشعارات دورية للتذكير بذكر الله والصلاة على رسول الله ﷺ',
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
          ),
        );
      }
    }
  }

  static Future<PrayerLocation?> getSavedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final latitude = prefs.getDouble(_latitudeKey);
    final longitude = prefs.getDouble(_longitudeKey);
    if (latitude == null || longitude == null) return null;
    return PrayerLocation(
      latitude: latitude,
      longitude: longitude,
      name: prefs.getString(_locationNameKey) ?? 'موقعي المحفوظ',
    );
  }

  static Future<void> saveLocation(PrayerLocation location) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_latitudeKey, location.latitude);
    await prefs.setDouble(_longitudeKey, location.longitude);
    await prefs.setString(_locationNameKey, location.name);
  }

  static Future<PrayerLocation> determineCurrentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('فعّل خدمة الموقع في إعدادات الجهاز ثم أعد المحاولة.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw Exception('لم يتم السماح للتطبيق باستخدام الموقع.');
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('إذن الموقع مرفوض نهائيًا. غيّره من إعدادات التطبيق.');
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 20),
      ),
    );
    final location = PrayerLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      name: 'الموقع الحالي',
    );
    await saveLocation(location);
    return location;
  }

  static Future<PrayerTimes> calculateFor(
    PrayerLocation location,
    DateTime date,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final methodIndex =
        prefs.getInt(_methodKey) ?? CalculationMethod.umm_al_qura.index;
    final method = CalculationMethod
        .values[methodIndex.clamp(0, CalculationMethod.values.length - 1)];
    final params = method.getParameters();
    params.madhab = (prefs.getBool(_hanafiKey) ?? false)
        ? Madhab.hanafi
        : Madhab.shafi;
    return PrayerTimes(
      Coordinates(location.latitude, location.longitude, validate: true),
      DateComponents.from(date),
      params,
    );
  }

  static Future<int> getCalculationMethodIndex() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_methodKey) ?? CalculationMethod.umm_al_qura.index;
  }

  static Future<void> setCalculationMethodIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_methodKey, index);
  }

  static Future<bool> get hanafiAsr async =>
      (await SharedPreferences.getInstance()).getBool(_hanafiKey) ?? false;

  static Future<void> setHanafiAsr(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hanafiKey, value);
  }

  static Future<bool> get notificationsEnabled async =>
      (await SharedPreferences.getInstance())
          .getBool(_notificationsEnabledKey) ??
      false;

  static Future<bool> get dhikrRemindersEnabled async =>
      (await SharedPreferences.getInstance())
          .getBool(_dhikrRemindersEnabledKey) ??
      false;

  static Future<bool> canScheduleExactAlarms() async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final result = await _adhanChannel.invokeMethod<bool>('canScheduleExactAlarms');
        return result ?? true;
      } catch (_) {}
    }
    return true;
  }

  static Future<void> requestExactAlarmPermission() async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        await _adhanChannel.invokeMethod('requestExactAlarmPermission');
      } catch (_) {}
    }
  }

  static Future<void> stopAdhan() async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        await _adhanChannel.invokeMethod('stopAdhan');
      } catch (_) {}
    }
  }

  static Future<void> schedulePrayerNotifications(
    PrayerLocation location,
  ) async {
    final android = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final granted = await android?.requestNotificationsPermission();
    final ios = _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    final iosGranted = await ios?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    if (granted == false || iosGranted == false) {
      throw Exception('إذن الإشعارات غير مفعّل، يُرجى تفعيله من الإعدادات.');
    }

    final prefs = await SharedPreferences.getInstance();
    final customPath = prefs.getString(_customAdhanPathKey);

    final now = DateTime.now();
    for (var id = 100; id < 150; id++) {
      await _notifications.cancel(id);
    }

    final prayers = <(String, DateTime Function(PrayerTimes))>[
      ('الفجر', (times) => times.fajr),
      ('الظهر', (times) => times.dhuhr),
      ('العصر', (times) => times.asr),
      ('المغرب', (times) => times.maghrib),
      ('العشاء', (times) => times.isha),
    ];

    final alarms = <Map<String, dynamic>>[];
    int alarmId = 0;

    for (var day = 0; day < 7; day++) {
      final date = DateTime(now.year, now.month, now.day + day);
      final times = await calculateFor(location, date);
      for (var prayerIndex = 0; prayerIndex < prayers.length; prayerIndex++) {
        final (name, getTime) = prayers[prayerIndex];
        final time = getTime(times);
        if (!time.isAfter(now)) continue;

        final notificationId = 100 + day * prayers.length + prayerIndex;

        alarms.add({
          'id': alarmId++,
          'timestamp': time.millisecondsSinceEpoch,
          'prayer': name,
        });

        // Backup local notification with stop action
        await _notifications.zonedSchedule(
          notificationId,
          '🕌 حان الآن وقت أذان $name',
          'الله أكبر، الله أكبر • حيّ على الصلاة، حيّ على الفلاح',
          tz.TZDateTime.from(time, tz.local),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'prayer_times',
              'مواقيت الصلاة والأذان',
              channelDescription: 'تنبيهات وأصوات الأذان عند دخول أوقات الصلاة',
              importance: Importance.max,
              priority: Priority.high,
              sound: RawResourceAndroidNotificationSound('adhan'),
              playSound: true,
              enableVibration: true,
              actions: [
                AndroidNotificationAction(
                  'stop_adhan',
                  'نعم (إيقاف الأذان)',
                  showsUserInterface: false,
                  cancelNotification: true,
                ),
                AndroidNotificationAction(
                  'continue_adhan',
                  'لا (متابعة الأذان)',
                  showsUserInterface: false,
                  cancelNotification: true,
                ),
              ],
            ),
            iOS: DarwinNotificationDetails(
              sound: 'default',
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    }

    // Schedule high-precision background Adhan Foreground Service on Android
    if (!kIsWeb && Platform.isAndroid) {
      try {
        await _adhanChannel.invokeMethod('schedule', {
          'filePath': customPath,
          'alarms': alarms,
        });
      } catch (e) {
        debugPrint('Adhan channel schedule error: $e');
      }
    }

    await prefs.setBool(_notificationsEnabledKey, true);
  }

  static Future<void> cancelPrayerNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, false);

    for (var id = 100; id < 150; id++) {
      await _notifications.cancel(id);
    }

    if (!kIsWeb && Platform.isAndroid) {
      try {
        await _adhanChannel.invokeMethod('cancel');
        await _adhanChannel.invokeMethod('stopAdhan');
      } catch (_) {}
    }
  }

  static Future<bool> isDhikrRemindersEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_dhikrRemindersEnabledKey) ?? true;
  }

  static Future<void> setDhikrRemindersEnabled(bool value) async {
    if (value) {
      final android = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final androidGranted = await android?.requestNotificationsPermission();
      final ios = _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      final iosGranted = await ios?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      if (androidGranted == false || iosGranted == false) {
        throw Exception('إذن الإشعارات غير مفعّل، يُرجى تفعيله في الإعدادات.');
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dhikrRemindersEnabledKey, value);

    if (value) {
      await scheduleBackgroundDhikrReminders();
    } else {
      await cancelDhikrReminders();
    }
  }

  static Future<int> getDhikrIntervalMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_dhikrIntervalMinutesKey) ?? 5;
  }

  static Future<void> setDhikrIntervalMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_dhikrIntervalMinutesKey, minutes);
    final enabled = prefs.getBool(_dhikrRemindersEnabledKey) ?? true;
    if (enabled) {
      await scheduleBackgroundDhikrReminders();
    }
  }

  static Future<void> scheduleBackgroundDhikrReminders() async {
    // Cancel old dhikr reminders
    for (var id = 2000; id < 2120; id++) {
      await _notifications.cancel(id);
    }

    final intervalMinutes = await getDhikrIntervalMinutes();
    final now = DateTime.now();
    int notificationId = 2000;
    int dhikrIndex = 0;

    // Schedule rolling reminders across the daytime (from 07:00 to 23:00) for next 2 days
    for (var day = 0; day < 2; day++) {
      final baseDay = DateTime(now.year, now.month, now.day + day);
      final startHour = (day == 0 && now.hour >= 7) ? now.hour : 7;
      final startMin = (day == 0 && now.hour == startHour)
          ? ((now.minute ~/ intervalMinutes) + 1) * intervalMinutes
          : 0;

      var reminderTime = DateTime(
        baseDay.year,
        baseDay.month,
        baseDay.day,
        startHour,
        startMin,
      );

      final endDayTime = DateTime(baseDay.year, baseDay.month, baseDay.day, 23, 15);

      while (reminderTime.isBefore(endDayTime) && notificationId < 2100) {
        if (reminderTime.isAfter(now)) {
          final dhikr = _dhikrList[dhikrIndex % _dhikrList.length];
          dhikrIndex++;

          await _notifications.zonedSchedule(
            notificationId++,
            dhikr['title']!,
            dhikr['body']!,
            tz.TZDateTime.from(reminderTime, tz.local),
            NotificationDetails(
              android: AndroidNotificationDetails(
                'dhikr_reminders',
                'تذكير الأذكار والصلاة على النبي',
                channelDescription: 'تذكير مستمر بذكر الله والصلاة على رسول الله ﷺ حتى خارج التطبيق',
                importance: Importance.high,
                priority: Priority.high,
                playSound: true,
                enableVibration: true,
                styleInformation: BigTextStyleInformation(
                  dhikr['body']!,
                  contentTitle: dhikr['title']!,
                  summaryText: 'ألا بذكر الله تطمئن القلوب',
                ),
                actions: const [
                  AndroidNotificationAction(
                    'dhikr_done',
                    'ذكرت الله 🤍',
                    showsUserInterface: false,
                    cancelNotification: true,
                  ),
                  AndroidNotificationAction(
                    'salawat_done',
                    'صلَّيت عليه ﷺ',
                    showsUserInterface: false,
                    cancelNotification: true,
                  ),
                ],
              ),
              iOS: const DarwinNotificationDetails(
                presentAlert: true,
                presentSound: true,
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          );
        }

        reminderTime = reminderTime.add(Duration(minutes: intervalMinutes));
      }
    }

    if (!kIsWeb && Platform.isAndroid) {
      try {
        await _adhanChannel.invokeMethod('startDhikrPopup');
      } catch (_) {}
    }
  }

  static Future<void> cancelDhikrReminders() async {
    for (var id = 2000; id < 2120; id++) {
      await _notifications.cancel(id);
    }
    if (!kIsWeb && Platform.isAndroid) {
      try {
        await _adhanChannel.invokeMethod('stopDhikrPopup');
      } catch (_) {}
    }
  }

  static Future<void> showDhikrReminder() async {
    final dhikr = _dhikrList[DateTime.now().minute % _dhikrList.length];
    await _notifications.show(
      1999,
      dhikr['title']!,
      dhikr['body']!,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'dhikr_reminders',
          'تذكير الأذكار والصلاة على النبي',
          channelDescription: 'تذكير بذكر الله والصلاة على النبي ﷺ',
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(''),
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  static Future<void> refreshNotificationsIfEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final prayerEnabled = prefs.getBool(_notificationsEnabledKey) ?? false;
    final dhikrEnabled = prefs.getBool(_dhikrRemindersEnabledKey) ?? false;

    if (prayerEnabled) {
      final location = await getSavedLocation();
      if (location != null) {
        try {
          await schedulePrayerNotifications(location);
        } catch (_) {}
      }
    }

    if (dhikrEnabled) {
      try {
        await scheduleBackgroundDhikrReminders();
      } catch (_) {}
    }
  }
}

class PrayerLocation {
  final double latitude;
  final double longitude;
  final String name;

  const PrayerLocation({
    required this.latitude,
    required this.longitude,
    required this.name,
  });
}
