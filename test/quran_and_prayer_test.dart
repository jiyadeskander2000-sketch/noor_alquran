import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:noor_alquran/models/ayah.dart';
import 'package:noor_alquran/models/azkar.dart';
import 'package:noor_alquran/models/surah.dart';
import 'package:noor_alquran/services/prayer_times_service.dart';
import 'package:noor_alquran/services/quran_service.dart';
import 'package:noor_alquran/services/compass_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});

    final quranString = File('assets/data/quran.json').readAsStringSync();
    final Map<String, dynamic> quranJson = jsonDecode(quranString);
    final detailMap = quranJson.map(
      (key, value) => MapEntry(
        int.parse(key),
        SurahDetail.fromJson(value as Map<String, dynamic>),
      ),
    );

    final surahsString = File('assets/data/surahs.json').readAsStringSync();
    final List<dynamic> surahsJson = jsonDecode(surahsString);
    final surahs = surahsJson.map((item) {
      final json = item as Map<String, dynamic>;
      final detail = detailMap[json['number'] as int];
      return Surah.fromJson({
        ...json,
        'numberOfAyahs': json['numberOfAyahs'] ?? detail?.ayahs.length ?? 0,
      });
    }).toList();

    final azkarString = File('assets/data/azkar.json').readAsStringSync();
    final List<dynamic> azkarJson = jsonDecode(azkarString);
    final azkarList = azkarJson
        .map((a) => AzkarCategory.fromJson(a as Map<String, dynamic>))
        .toList();

    QuranService.setMockData(
      surahs: surahs,
      surahsDetailMap: detailMap,
      azkarList: azkarList,
    );
  });

  test('bundled Quran includes all surahs, ayahs, and tafsir entries', () {
    expect(QuranService.surahs, hasLength(114));

    for (var surahNumber = 1; surahNumber <= 114; surahNumber++) {
      final detail = QuranService.getSurahDetail(surahNumber);
      expect(detail, isNotNull, reason: 'Surah $surahNumber should have detail');
      expect(detail!.ayahs, isNotEmpty, reason: 'Surah $surahNumber should contain ayahs');

      for (final ayah in detail.ayahs) {
        expect(ayah.text.trim(), isNotEmpty);
        expect(ayah.tafsir.trim(), isNotEmpty);
      }
    }
  });

  test('surah metadata includes Meccan and Medinan classifications', () {
    final fatiha = QuranService.getSurahByNumber(1);
    final baqarah = QuranService.getSurahByNumber(2);

    expect(fatiha?.revelationType, 'Meccan');
    expect(baqarah?.revelationType, 'Medinan');
  });

  test('Arabic search finds a known ayah in Surah Al-Ikhlas', () {
    final results = QuranService.search('الصمد');
    expect(results, isNotEmpty);
    expect(results.first.surah.number, 112);
    expect(results.first.ayah.numberInSurah, 2);
  });

  test('prayer calculation returns the six daily solar times in order', () async {
    const mecca = PrayerLocation(
      latitude: 21.4225,
      longitude: 39.8262,
      name: 'مكة المكرمة',
    );
    final times = await PrayerTimesService.calculateFor(
      mecca,
      DateTime(2026, 1, 1),
    );

    expect(times.fajr.isBefore(times.sunrise), isTrue);
    expect(times.sunrise.isBefore(times.dhuhr), isTrue);
    expect(times.dhuhr.isBefore(times.asr), isTrue);
    expect(times.asr.isBefore(times.maghrib), isTrue);
    expect(times.maghrib.isBefore(times.isha), isTrue);
  });

  test('bundled azkar include Quran completion supplications', () {
    expect(QuranService.azkarList, isNotEmpty);
    expect(
      QuranService.azkarList.any((category) => category.category.contains('ختم القرآن')),
      isTrue,
    );
  });

  test('bundled azkar include expanded prayer and dua collections', () {
    expect(QuranService.azkarList.length, greaterThanOrEqualTo(9));
    final itemCount = QuranService.azkarList.fold<int>(
      0,
      (total, category) => total + category.items.length,
    );
    expect(itemCount, greaterThanOrEqualTo(40));
    expect(
      QuranService.azkarList.any(
        (category) => category.category.contains('القرآن'),
      ),
      isTrue,
    );
    expect(
      QuranService.azkarList.any(
        (category) => category.category.contains('النبوي') || category.category.contains('النبي'),
      ),
      isTrue,
    );
  });

  test('offline compass calculations and city dataset are valid', () {
    expect(CompassService.offlineCities, isNotEmpty);
    expect(CompassService.offlineCities.length, greaterThanOrEqualTo(30));

    // From Medina (24.4672, 39.6111) to Mecca, Qibla direction is roughly South (around 170°-185°)
    final qiblaFromMedina = CompassService.calculateQibla(24.4672, 39.6111);
    expect(qiblaFromMedina, inInclusiveRange(170.0, 185.0));

    // Distance from Medina to Mecca is ~330-360 km
    final distMedinaToMecca = CompassService.calculateDistanceKm(24.4672, 39.6111);
    expect(distMedinaToMecca, inInclusiveRange(320.0, 370.0));

    // Facing Qibla tolerance check
    expect(CompassService.isFacingQibla(qiblaFromMedina, qiblaFromMedina), isTrue);
    expect(CompassService.isFacingQibla(0.0, 180.0), isFalse);
  });

  test('azkar dataset includes simplified meanings for comprehension', () {
    final morning = QuranService.azkarList.firstWhere(
      (c) => c.category.contains('الصباح'),
    );
    expect(morning.items, isNotEmpty);
    expect(morning.items.any((item) => item.meaning != null && item.meaning!.isNotEmpty), isTrue);
  });

  test('morning and evening adhkar collections are complete and authentic', () {
    final morning = QuranService.azkarList.firstWhere((c) => c.category.contains('الصباح'));
    final evening = QuranService.azkarList.firstWhere((c) => c.category.contains('المساء'));

    expect(morning.items.length, greaterThanOrEqualTo(20));
    expect(evening.items.length, greaterThanOrEqualTo(20));

    // Verify presence of Sayyid al-Istighfar in both
    expect(morning.items.any((i) => i.fadl != null && i.fadl!.contains('سيد الاستغفار')), isTrue);
    expect(evening.items.any((i) => i.fadl != null && i.fadl!.contains('سيد الاستغفار')), isTrue);
  });

  test('Muslim Bag collections are complete across all six Islamic domains', () {
    final pData = jsonDecode(File('assets/data/prophets_stories.json').readAsStringSync()) as List;
    final sData = jsonDecode(File('assets/data/sahaba_stories.json').readAsStringSync()) as List;
    final syData = jsonDecode(File('assets/data/sahabiyat_stories.json').readAsStringSync()) as List;
    final qData = jsonDecode(File('assets/data/quran_stories.json').readAsStringSync()) as List;
    final aData = jsonDecode(File('assets/data/animal_stories.json').readAsStringSync()) as List;
    final siData = jsonDecode(File('assets/data/surah_insights.json').readAsStringSync()) as List;

    expect(pData.length, greaterThanOrEqualTo(10));
    expect(sData.length, greaterThanOrEqualTo(5));
    expect(syData.length, greaterThanOrEqualTo(4));
    expect(qData.length, greaterThanOrEqualTo(4));
    expect(aData.length, greaterThanOrEqualTo(5));
    expect(siData.length, greaterThanOrEqualTo(6));
  });
}
