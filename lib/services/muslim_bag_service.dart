import 'dart:convert';
import 'package:flutter/services.dart';

class ProphetStory {
  final String name;
  final String title;
  final String period;
  final String people;
  final String miracle;
  final List<String> quranVerses;
  final String fullStory;
  final List<String> lessons;

  ProphetStory({
    required this.name,
    required this.title,
    required this.period,
    required this.people,
    required this.miracle,
    required this.quranVerses,
    required this.fullStory,
    required this.lessons,
  });

  factory ProphetStory.fromJson(Map<String, dynamic> json) {
    return ProphetStory(
      name: json['name'] ?? '',
      title: json['title'] ?? '',
      period: json['period'] ?? '',
      people: json['people'] ?? '',
      miracle: json['miracle'] ?? '',
      quranVerses: List<String>.from(json['quranVerses'] ?? []),
      fullStory: json['fullStory'] ?? '',
      lessons: List<String>.from(json['lessons'] ?? []),
    );
  }
}

class SahabaStory {
  final String name;
  final String title;
  final String virtues;
  final String biography;
  final List<String> keyEvents;
  final String famousSaying;

  SahabaStory({
    required this.name,
    required this.title,
    required this.virtues,
    required this.biography,
    required this.keyEvents,
    required this.famousSaying,
  });

  factory SahabaStory.fromJson(Map<String, dynamic> json) {
    return SahabaStory(
      name: json['name'] ?? '',
      title: json['title'] ?? '',
      virtues: json['virtues'] ?? '',
      biography: json['biography'] ?? json['story'] ?? '',
      keyEvents: json['keyEvents'] != null
          ? List<String>.from(json['keyEvents'])
          : [],
      famousSaying: json['famousSaying'] ?? json['sayings'] ?? json['saying'] ?? '',
    );
  }
}

class SahabiyaStory {
  final String name;
  final String title;
  final String role;
  final String biography;
  final List<String> qualities;

  SahabiyaStory({
    required this.name,
    required this.title,
    required this.role,
    required this.biography,
    required this.qualities,
  });

  factory SahabiyaStory.fromJson(Map<String, dynamic> json) {
    return SahabiyaStory(
      name: json['name'] ?? '',
      title: json['title'] ?? '',
      role: json['role'] ?? json['virtues'] ?? '',
      biography: json['biography'] ?? json['story'] ?? '',
      qualities: json['qualities'] != null
          ? List<String>.from(json['qualities'])
          : [],
    );
  }
}

class ProphetWife {
  final int order;
  final String name;
  final String title;
  final String marriageDate;
  final String biography;
  final String wisdom;
  final String death;

  ProphetWife({
    required this.order,
    required this.name,
    required this.title,
    required this.marriageDate,
    required this.biography,
    required this.wisdom,
    required this.death,
  });

  factory ProphetWife.fromJson(Map<String, dynamic> json) {
    return ProphetWife(
      order: json['order'] ?? 0,
      name: json['name'] ?? '',
      title: json['title'] ?? '',
      marriageDate: json['marriageDate'] ?? '',
      biography: json['biography'] ?? '',
      wisdom: json['wisdom'] ?? '',
      death: json['death'] ?? '',
    );
  }
}

class NameOfAllah {
  final int id;
  final String name;
  final String meaning;
  final String proof;

  NameOfAllah({
    required this.id,
    required this.name,
    required this.meaning,
    required this.proof,
  });

  factory NameOfAllah.fromJson(Map<String, dynamic> json) {
    return NameOfAllah(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      meaning: json['meaning'] ?? '',
      proof: json['proof'] ?? '',
    );
  }
}

class HisnHadith {
  final String text;
  final String source;
  final String virtue;

  HisnHadith({
    required this.text,
    required this.source,
    required this.virtue,
  });

  factory HisnHadith.fromJson(Map<String, dynamic> json) {
    return HisnHadith(
      text: json['text'] ?? '',
      source: json['source'] ?? '',
      virtue: json['virtue'] ?? '',
    );
  }
}

class HisnChapter {
  final int chapterId;
  final String title;
  final List<HisnHadith> hadiths;

  HisnChapter({
    required this.chapterId,
    required this.title,
    required this.hadiths,
  });

  factory HisnChapter.fromJson(Map<String, dynamic> json) {
    return HisnChapter(
      chapterId: json['chapterId'] ?? 0,
      title: json['title'] ?? '',
      hadiths: (json['hadiths'] as List? ?? [])
          .map((h) => HisnHadith.fromJson(h as Map<String, dynamic>))
          .toList(),
    );
  }
}

class QuranStoryItem {
  final String title;
  final String surahReference;
  final String mainEvent;
  final String fullNarrative;
  final List<String> spiritualLessons;

  QuranStoryItem({
    required this.title,
    required this.surahReference,
    required this.mainEvent,
    required this.fullNarrative,
    required this.spiritualLessons,
  });

  factory QuranStoryItem.fromJson(Map<String, dynamic> json) {
    return QuranStoryItem(
      title: json['title'] ?? '',
      surahReference: json['surahReference'] ?? json['surah'] ?? '',
      mainEvent: json['mainEvent'] ?? '',
      fullNarrative: json['fullNarrative'] ?? json['story'] ?? '',
      spiritualLessons: json['spiritualLessons'] != null
          ? List<String>.from(json['spiritualLessons'])
          : (json['lessons'] != null
              ? (json['lessons'] is List
                  ? List<String>.from(json['lessons'])
                  : [json['lessons'].toString()])
              : []),
    );
  }
}

class AnimalStoryItem {
  final String animal;
  final String associatedProphet;
  final String surahReference;
  final String story;
  final String divineWisdom;

  AnimalStoryItem({
    required this.animal,
    required this.associatedProphet,
    required this.surahReference,
    required this.story,
    required this.divineWisdom,
  });

  factory AnimalStoryItem.fromJson(Map<String, dynamic> json) {
    return AnimalStoryItem(
      animal: json['animal'] ?? '',
      associatedProphet: json['associatedProphet'] ?? json['prophetOrStory'] ?? '',
      surahReference: json['surahReference'] ?? json['verse'] ?? '',
      story: json['story'] ?? json['fullStory'] ?? '',
      divineWisdom: json['divineWisdom'] ?? json['wisdom'] ?? '',
    );
  }
}

class SurahInsightItem {
  final int number;
  final String name;
  final String englishName;
  final String revelationType;
  final int ayahCount;
  final String virtues;
  final List<String> majorThemes;
  final String reasonOfNaming;

  SurahInsightItem({
    required this.number,
    required this.name,
    required this.englishName,
    required this.revelationType,
    required this.ayahCount,
    required this.virtues,
    required this.majorThemes,
    required this.reasonOfNaming,
  });

  factory SurahInsightItem.fromJson(Map<String, dynamic> json) {
    return SurahInsightItem(
      number: json['number'] ?? 0,
      name: json['name'] ?? '',
      englishName: json['englishName'] ??
          (json['names'] != null && (json['names'] as List).isNotEmpty
              ? json['names'][0].toString()
              : ''),
      revelationType: json['revelationType'] ?? json['type'] ?? '',
      ayahCount: json['ayahCount'] ?? json['verses'] ?? 0,
      virtues: json['virtues'] ?? '',
      majorThemes: json['majorThemes'] != null
          ? List<String>.from(json['majorThemes'])
          : (json['themes'] != null
              ? (json['themes'] is List
                  ? List<String>.from(json['themes'])
                  : [json['themes'].toString()])
              : []),
      reasonOfNaming: json['reasonOfNaming'] ?? json['reason'] ?? '',
    );
  }
}

class MuslimBagService {
  static List<ProphetStory> prophets = [];
  static List<SahabaStory> sahaba = [];
  static List<ProphetWife> prophetWives = [];
  static List<SahabiyaStory> sahabiyat = [];
  static List<NameOfAllah> namesOfAllah = [];
  static List<HisnChapter> hisnChapters = [];
  static List<QuranStoryItem> quranStories = [];
  static List<AnimalStoryItem> animalStories = [];
  static List<SurahInsightItem> surahInsights = [];

  static bool isLoaded = false;

  static Future<void> loadAll() async {
    if (isLoaded) return;
    try {
      final pStr = await rootBundle.loadString('assets/data/prophets_stories.json');
      prophets = (jsonDecode(pStr) as List).map((j) => ProphetStory.fromJson(j)).toList();

      final sStr = await rootBundle.loadString('assets/data/sahaba_stories.json');
      sahaba = (jsonDecode(sStr) as List).map((j) => SahabaStory.fromJson(j)).toList();

      final wStr = await rootBundle.loadString('assets/data/prophet_wives.json');
      prophetWives = (jsonDecode(wStr) as List).map((j) => ProphetWife.fromJson(j)).toList();

      final syStr = await rootBundle.loadString('assets/data/sahabiyat_stories.json');
      sahabiyat = (jsonDecode(syStr) as List).map((j) => SahabiyaStory.fromJson(j)).toList();

      final nStr = await rootBundle.loadString('assets/data/names_of_allah.json');
      namesOfAllah = (jsonDecode(nStr) as List).map((j) => NameOfAllah.fromJson(j)).toList();

      final hStr = await rootBundle.loadString('assets/data/hisn_almuslim.json');
      hisnChapters = (jsonDecode(hStr) as List).map((j) => HisnChapter.fromJson(j)).toList();

      final qStr = await rootBundle.loadString('assets/data/quran_stories.json');
      quranStories = (jsonDecode(qStr) as List).map((j) => QuranStoryItem.fromJson(j)).toList();

      final aStr = await rootBundle.loadString('assets/data/animal_stories.json');
      animalStories = (jsonDecode(aStr) as List).map((j) => AnimalStoryItem.fromJson(j)).toList();

      final siStr = await rootBundle.loadString('assets/data/surah_insights.json');
      surahInsights = (jsonDecode(siStr) as List).map((j) => SurahInsightItem.fromJson(j)).toList();

      isLoaded = true;
    } catch (e) {
      // Silently handle fallback
    }
  }
}
