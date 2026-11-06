class Ayah {
  final int number; // Overall ayah index in quran (1-6236)
  final int numberInSurah;
  final String text;
  final int juz;
  final int page;
  final String tafsir;

  Ayah({
    required this.number,
    required this.numberInSurah,
    required this.text,
    required this.juz,
    required this.page,
    required this.tafsir,
  });

  factory Ayah.fromJson(Map<String, dynamic> json) {
    return Ayah(
      number: json['number'] as int,
      numberInSurah: json['numberInSurah'] as int,
      text: json['text'] as String,
      juz: json['juz'] as int? ?? 1,
      page: json['page'] as int? ?? 1,
      tafsir: json['tafsir'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'number': number,
    'numberInSurah': numberInSurah,
    'text': text,
    'juz': juz,
    'page': page,
    'tafsir': tafsir,
  };
}

class SurahDetail {
  final int number;
  final String name;
  final String englishName;
  final String revelationType;
  final int numberOfAyahs;
  final List<Ayah> ayahs;

  SurahDetail({
    required this.number,
    required this.name,
    required this.englishName,
    required this.revelationType,
    required this.numberOfAyahs,
    required this.ayahs,
  });

  factory SurahDetail.fromJson(Map<String, dynamic> json) {
    var ayahsJson = json['ayahs'] as List<dynamic>? ?? [];
    List<Ayah> ayahsList = ayahsJson.map((a) => Ayah.fromJson(a as Map<String, dynamic>)).toList();

    return SurahDetail(
      number: json['number'] as int,
      name: json['name'] as String,
      englishName: json['englishName'] as String,
      revelationType: json['revelationType'] ?? 'Meccan',
      numberOfAyahs: json['numberOfAyahs'] as int? ?? ayahsList.length,
      ayahs: ayahsList,
    );
  }

  bool get isMeccan => revelationType.toLowerCase().contains('meccan');
  String get typeArabic => isMeccan ? 'مكية' : 'مدنية';
}
