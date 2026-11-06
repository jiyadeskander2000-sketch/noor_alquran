const fs = require('fs');
const path = require('path');

async function downloadAndBuild() {
  console.log('Downloading Quran Uthmani...');
  const quranRes = await fetch('https://api.alquran.cloud/v1/quran/quran-uthmani');
  const quranData = await quranRes.json();

  console.log('Downloading Tafsir Al-Muyassar...');
  const tafsirRes = await fetch('https://api.alquran.cloud/v1/quran/ar.muyassar');
  const tafsirData = await tafsirRes.json();

  const outDir = path.join(__dirname, 'assets', 'data');
  if (!fs.existsSync(outDir)) {
    fs.mkdirSync(outDir, { recursive: true });
  }

  const surahsMeta = [];
  const surahsFull = {};

  const quranSurahs = quranData.data.surahs;
  const tafsirSurahs = tafsirData.data.surahs;

  for (let i = 0; i < quranSurahs.length; i++) {
    const qSurah = quranSurahs[i];
    const tSurah = tafsirSurahs[i];

    surahsMeta.push({
      number: qSurah.number,
      name: qSurah.name,
      englishName: qSurah.englishName,
      englishNameTranslation: qSurah.englishNameTranslation,
      revelationType: qSurah.revelationType, // Meccan or Medinan
      numberOfAyahs: qSurah.numberOfAyahs,
    });

    const ayahs = [];
    for (let j = 0; j < qSurah.ayahs.length; j++) {
      const qAyah = qSurah.ayahs[j];
      const tAyah = tSurah.ayahs[j];

      // Remove BOM if present in Uthmani text
      let text = qAyah.text.replace(/\uFEFF/g, '').trim();

      // In Surahs other than Al-Fatiha (1) and At-Tawbah (9), remove Bismillah prefix from first ayah if present
      // so we can display Bismillah beautifully in the header instead of duplicated in ayah 1
      if (qSurah.number !== 1 && qSurah.number !== 9 && j === 0) {
        const bismillahPrefix = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ';
        if (text.startsWith(bismillahPrefix)) {
          text = text.substring(bismillahPrefix.length).trim();
        }
      }

      ayahs.push({
        number: qAyah.number, // overall ayah number (1 to 6236)
        numberInSurah: qAyah.numberInSurah,
        text: text,
        juz: qAyah.juz,
        page: qAyah.page,
        tafsir: tAyah ? tAyah.text : ''
      });
    }

    surahsFull[qSurah.number] = {
      number: qSurah.number,
      name: qSurah.name,
      englishName: qSurah.englishName,
      revelationType: qSurah.revelationType,
      numberOfAyahs: qSurah.numberOfAyahs,
      ayahs: ayahs
    };
  }

  // Write surahs metadata
  fs.writeFileSync(
    path.join(outDir, 'surahs.json'),
    JSON.stringify(surahsMeta, null, 2),
    'utf-8'
  );
  console.log('Saved surahs.json successfully.');

  // Write full quran with tafsir
  fs.writeFileSync(
    path.join(outDir, 'quran.json'),
    JSON.stringify(surahsFull),
    'utf-8'
  );
  console.log('Saved quran.json successfully with full Tafsir.');

  // Write Azkar & Duas
  const azkar = [
    {
      category: "دعاء ختم القرآن الكريم",
      items: [
        {
          text: "اللَّهُمَّ ارْحَمْنِي بِالقُرْآنِ وَاجْعَلْهُ لِي إِمَاماً وَنُوراً وَهُدًى وَرَحْمَةً، اللَّهُمَّ ذَكِّرْنِي مِنْهُ مَا نَسِيتُ وَعَلِّمْنِي مِنْهُ مَا جَهِلْتُ وَارْزُقْنِي تِلاَوَتَهُ آنَاءَ اللَّيْلِ وَأَطْرَافَ النَّهَارِ وَاجْعَلْهُ لِي حُجَّةً يَا رَبَّ العَالَمِينَ.",
          count: 1
        },
        {
          text: "اللَّهُمَّ أَصْلِحْ لِي دِينِي الَّذِي هُوَ عِصْمَةُ أَمْرِي، وَأَصْلِحْ لِي دُنْيَايَ الَّتِي فِيهَا مَعَاشِي، وَأَصْلِحْ لِي آخِرَتِي الَّتِي فِيهَا مَعَادِي، وَاجْعَلِ الحَيَاةَ زِيَادَةً لِي فِي كُلِّ خَيْرٍ وَاجْعَلِ المَوْتَ رَاحَةً لِي مِنْ كُلِّ شَرٍّ.",
          count: 1
        },
        {
          text: "اللَّهُمَّ اجْعَلْ خَيْرَ عُمْرِي آخِرَهُ وَخَيْرَ عَمَلِي خَوَاتِمَهُ وَخَيْرَ أَيَّامِي يَوْمَ أَلْقَاكَ فِيهِ.",
          count: 1
        }
      ]
    },
    {
      category: "أذكار الصباح",
      items: [
        {
          text: "أَصْبَحْنَا وَأَصْبَحَ المُلْكُ لِلَّهِ وَالحَمْدُ لِلَّهِ، لاَ إِلَهَ إِلاَّ اللَّهُ وَحْدَهُ لاَ شَرِيكَ لَهُ، لَهُ المُلْكُ وَلَهُ الحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ.",
          count: 1
        },
        {
          text: "اللَّهُمَّ أَنْتَ رَبِّي لاَ إِلَهَ إِلاَّ أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوءُ بِذَنْبِي فَاغْفِرْ لِي فَإِنَّهُ لاَ يَغْفِرُ الذُّنُوبَ إِلاَّ أَنْتَ.",
          count: 1
        },
        {
          text: "بِسْمِ اللَّهِ الَّذِي لاَ يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الأَرْضِ وَلاَ فِي السَّمَاءِ وَهُوَ السَّمِيعُ العَلِيمُ.",
          count: 3
        },
        {
          text: "يَا حَيُّ يَا قَيُّومُ بِرَحْمَتِكَ أَسْتَغِيثُ، أَصْلِحْ لِي شَأْنِي كُلَّهُ، وَلاَ تَكِلْنِي إِلَى نَفْسِي طَرْفَةَ عَيْنٍ.",
          count: 1
        }
      ]
    },
    {
      category: "أذكار المساء",
      items: [
        {
          text: "أَمْسَيْنَا وَأَمْسَى المُلْكُ لِلَّهِ، وَالحَمْدُ لِلَّهِ، لاَ إِلَهَ إِلاَّ اللَّهُ وَحْدَهُ لاَ شَرِيكَ لَهُ، لَهُ المُلْكُ وَلَهُ الحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ.",
          count: 1
        },
        {
          text: "أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ.",
          count: 3
        },
        {
          text: "اللَّهُمَّ مَا أَمْسَى بِي مِنْ نِعْمَةٍ أَوْ بِأَحَدٍ مِنْ خَلْقِكَ فَمِنْكَ وَحْدَكَ لاَ شَرِيكَ لَكَ، فَلَكَ الحَمْدُ وَلَكَ الشُّكْرُ.",
          count: 1
        }
      ]
    },
    {
      category: "أدعية قرآنية جامعة",
      items: [
        {
          text: "رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ.",
          count: 1
        },
        {
          text: "رَبِّ اشْرَحْ لِي صَدْرِي وَيَسِّرْ لِي أَمْرِي وَاحْلُلْ عُقْدَةً مِّن لِّسَانِي يَفْقَهُوا قَوْلِي.",
          count: 1
        },
        {
          text: "رَبَّنَا لاَ تُزِغْ قُلُوبَنَا بَعْدَ إِذْ هَدَيْتَنَا وَهَبْ لَنَا مِن لَّدُنكَ رَحْمَةً إِنَّكَ أَنتَ الْوَهَّابُ.",
          count: 1
        }
      ]
    },
    {
      category: "أذكار بعد الصلاة",
      items: [
        { text: "أَسْتَغْفِرُ اللهَ.", count: 3 },
        { text: "اللَّهُمَّ أَنْتَ السَّلَامُ وَمِنْكَ السَّلَامُ، تَبَارَكْتَ يَا ذَا الْجَلَالِ وَالْإِكْرَامِ.", count: 1 },
        { text: "سُبْحَانَ اللهِ.", count: 33 },
        { text: "الْحَمْدُ لِلَّهِ.", count: 33 },
        { text: "اللهُ أَكْبَرُ.", count: 33 },
        { text: "لَا إِلَهَ إِلَّا اللهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ.", count: 1 }
      ]
    },
    {
      category: "أذكار النوم والاستيقاظ",
      items: [
        { text: "بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا.", count: 1 },
        { text: "اللَّهُمَّ قِنِي عَذَابَكَ يَوْمَ تَبْعَثُ عِبَادَكَ.", count: 1 },
        { text: "سُبْحَانَ اللهِ.", count: 33 },
        { text: "الْحَمْدُ لِلَّهِ.", count: 33 },
        { text: "اللهُ أَكْبَرُ.", count: 34 },
        { text: "الْحَمْدُ لِلَّهِ الَّذِي أَحْيَانَا بَعْدَ مَا أَمَاتَنَا وَإِلَيْهِ النُّشُورُ.", count: 1 }
      ]
    },
    {
      category: "أدعية من القرآن الكريم",
      items: [
        { text: "رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ.", count: 1 },
        { text: "رَبَّنَا لَا تُزِغْ قُلُوبَنَا بَعْدَ إِذْ هَدَيْتَنَا وَهَبْ لَنَا مِنْ لَدُنْكَ رَحْمَةً إِنَّكَ أَنْتَ الْوَهَّابُ.", count: 1 },
        { text: "رَبَّنَا ظَلَمْنَا أَنْفُسَنَا وَإِنْ لَمْ تَغْفِرْ لَنَا وَتَرْحَمْنَا لَنَكُونَنَّ مِنَ الْخَاسِرِينَ.", count: 1 },
        { text: "رَبِّ اشْرَحْ لِي صَدْرِي وَيَسِّرْ لِي أَمْرِي.", count: 1 },
        { text: "رَبِّ زِدْنِي عِلْمًا.", count: 1 },
        { text: "رَبَّنَا أَفْرِغْ عَلَيْنَا صَبْرًا وَتَوَفَّنَا مُسْلِمِينَ.", count: 1 },
        { text: "رَبَّنَا هَبْ لَنَا مِنْ أَزْوَاجِنَا وَذُرِّيَّاتِنَا قُرَّةَ أَعْيُنٍ وَاجْعَلْنَا لِلْمُتَّقِينَ إِمَامًا.", count: 1 },
        { text: "رَبَّنَا اغْفِرْ لَنَا وَلِإِخْوَانِنَا الَّذِينَ سَبَقُونَا بِالْإِيمَانِ وَلَا تَجْعَلْ فِي قُلُوبِنَا غِلًّا لِلَّذِينَ آمَنُوا رَبَّنَا إِنَّكَ رَءُوفٌ رَحِيمٌ.", count: 1 }
      ]
    },
    {
      category: "أدعية نبوية مأثورة",
      items: [
        { text: "اللَّهُمَّ إِنِّي أَسْأَلُكَ الْهُدَى وَالتُّقَى وَالْعَفَافَ وَالْغِنَى.", count: 1 },
        { text: "اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْهَمِّ وَالْحَزَنِ، وَالْعَجْزِ وَالْكَسَلِ، وَالْجُبْنِ وَالْبُخْلِ، وَضَلَعِ الدَّيْنِ وَغَلَبَةِ الرِّجَالِ.", count: 1 },
        { text: "يَا مُقَلِّبَ الْقُلُوبِ ثَبِّتْ قَلْبِي عَلَى دِينِكَ.", count: 1 },
        { text: "اللَّهُمَّ أَعِنِّي عَلَى ذِكْرِكَ وَشُكْرِكَ وَحُسْنِ عِبَادَتِكَ.", count: 1 },
        { text: "اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ فِي الدُّنْيَا وَالْآخِرَةِ.", count: 1 },
        { text: "اللَّهُمَّ اغْفِرْ لِي وَارْحَمْنِي وَاهْدِنِي وَعَافِنِي وَارْزُقْنِي.", count: 1 },
        { text: "اللَّهُمَّ إِنِّي أَسْأَلُكَ الْجَنَّةَ وَأَعُوذُ بِكَ مِنَ النَّارِ.", count: 1 }
      ]
    },
    {
      category: "الاستغفار والتسبيح",
      items: [
        { text: "أَسْتَغْفِرُ اللهَ وَأَتُوبُ إِلَيْهِ.", count: 100 },
        { text: "سُبْحَانَ اللهِ وَبِحَمْدِهِ.", count: 100 },
        { text: "لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللهِ.", count: 1 },
        { text: "لَا إِلَهَ إِلَّا اللهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ.", count: 100 },
        { text: "سُبْحَانَ اللهِ وَالْحَمْدُ لِلَّهِ وَلَا إِلَهَ إِلَّا اللهُ وَاللهُ أَكْبَرُ.", count: 1 }
      ]
    }
  ];

  fs.writeFileSync(
    path.join(outDir, 'azkar.json'),
    JSON.stringify(azkar, null, 2),
    'utf-8'
  );
  console.log('Saved azkar.json successfully.');
}

downloadAndBuild().catch(console.error);
