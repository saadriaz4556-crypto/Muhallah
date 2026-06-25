class KalimatData {
  final int number;
  final String nameUrdu;
  final String nameEnglish;
  final String arabicText;
  final String transliteration;
  final String urduTranslation;
  final String englishTranslation;

  const KalimatData({
    required this.number,
    required this.nameUrdu,
    required this.nameEnglish,
    required this.arabicText,
    required this.transliteration,
    required this.urduTranslation,
    required this.englishTranslation,
  });
}

const List<KalimatData> allKalimat = [
  KalimatData(
    number: 1,
    nameUrdu: "کلمہ طیبہ (تہلیل)",
    nameEnglish: "Tayyaba (Tahlil)",
    arabicText: "لَا إِلٰهَ إِلَّا اللهُ مُحَمَّدٌ رَّسُولُ اللهِ",
    transliteration: "La ilaha illallahu Muhammadur Rasoolullah",
    urduTranslation: "اللہ کے سوا کوئی معبود نہیں، محمد اللہ کے رسول ہیں۔",
    englishTranslation: "There is no deity but Allah, Muhammad is the messenger of Allah.",
  ),
  KalimatData(
    number: 2,
    nameUrdu: "کلمہ شہادت (شہادت)",
    nameEnglish: "Shahadat (Testimony)",
    arabicText: "أَشْهَدُ أَنْ لَا إِلٰهَ إِلَّا اللهُ وَحْدَهُ لَا شَرِيكَ لَهُ وَأَشْهَدُ أَنَّ مُحَمَّدًا عَبْدُهُ وَرَسُولُهُ",
    transliteration: "Ash-hadu al-la ilaha illallahu Wahdahu La Shareeka Lahu Wa-Ash-hadu Anna Muhammadan 'Abduhu Wa Rasooluhu",
    urduTranslation: "میں گواہی دیتا ہوں کہ اللہ کے سوا کوئی معبود نہیں، وہ اکیلا ہے، اس کا کوئی شریک نہیں، اور میں گواہی دیتا ہوں کہ محمد اس کے بندے اور رسول ہیں۔",
    englishTranslation: "I bear witness that there is no deity but Allah, Who is unique and without partner, and I bear witness that Muhammad is His servant and His messenger.",
  ),
  KalimatData(
    number: 3,
    nameUrdu: "کلمہ تمجید (تسبیح)",
    nameEnglish: "Tamjeed (Tasbih)",
    arabicText: "سُبْحَانَ اللهِ وَالْحَمْدُ لِلهِ وَلَا إِلٰهَ إِلَّا اللهُ وَاللهُ أَكْبَرُ وَلَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللهِ الْعَلِيِّ الْعَظِيمِ",
    transliteration: "Subhanallahi Walhamdulillahi Wala ilaha illallahu Wallahu Akbar Wala Hawla Wala Quwwata illa billahil 'Aliyyil 'Adheem",
    urduTranslation: "اللہ پاک ہے، اور تمام تعریفیں اللہ ہی کے لیے ہیں، اور اللہ کے سوا کوئی معبود نہیں، اور اللہ سب سے بڑا ہے، اور گناہ سے بچنے کی طاقت اور نیکی کرنے کی قوت اللہ ہی کی طرف سے ہے جو عالی شان اور بڑا عظمت والا ہے۔",
    englishTranslation: "Glory be to Allah, and praise be to Allah, and there is no deity but Allah, and Allah is most great, and there is no power and no strength except with Allah, the Most High, the Most Supreme.",
  ),
  KalimatData(
    number: 4,
    nameUrdu: "کلمہ توحید (تمحید)",
    nameEnglish: "Tauheed (Tahmid)",
    arabicText: "لَا إِلٰهَ إِلَّا اللهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، يُحْيِي وَيُمِيتُ، وَهُوَ حَيٌّ لَا يَمُوتُ أَبَدًا أَبَدًا، ذُو الْجَلَالِ وَالْإِكْرَامِ، بِيَدِهِ الْخَيْرُ، وَهُوَ عَلَىٰ كُلِّ شَيْءٍ قَدِيرٌ",
    transliteration: "La ilaha illallahu Wahdahu La Shareeka Lahu Lahul Mulku Walahul Hamdu Yuhyi Wayumeetu Wahuwa Hayyul-La Yamootu Abadan Abada, Dhul Jalali Wal Ikram, Biyadihil Khair, Wahuwa 'Ala Kulli Shai'in Qadeer",
    urduTranslation: "اللہ کے سوا کوئی معبود نہیں، وہ اکیلا ہے، اس کا کوئی شریک نہیں، بادشاہی اسی کی ہے اور تعریف اسی کے لیے ہے، وہ جلاتا ہے اور مارتا ہے، اور وہ ہمیشہ زندہ ہے، کبھی نہیں مرے گا، وہ عظمت اور بزرگی والا ہے، بھلائی اسی کے ہاتھ میں ہے اور وہ ہر چیز پر قادر ہے۔",
    englishTranslation: "There is no deity but Allah, Who is unique and without partner, His is the sovereignty and His is the praise, He gives life and causes death, and He is ever-living, Who will never die. In His hands is all goodness, and He has power over all things.",
  ),
  KalimatData(
    number: 5,
    nameUrdu: "کلمہ استغفار (استغفار)",
    nameEnglish: "Astaghfar (Istighfar)",
    arabicText: "أَسْتَغْفِرُ اللهَ رَبِّي مِنْ كُلِّ ذَنْبٍ أَذْنَبْتُهُ عَمْدًا أَوْ خَطَأً سِرًّا أَوْ عَلَانِيَةً وَأَتُوبُ إِلَيْهِ مِنَ الذَّنْبِ الَّذِي أَعْلَمُ وَمِنَ الذَّنْبِ الَّذِي لَا أَعْلَمُ، إِنَّكَ أَنْتَ عَلَّامُ الْغُيُوبِ وَسَتَّارُ الْعُيُوبِ وَغَفَّارُ الذُّنُوبِ وَلَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللهِ الْعَلِيِّ الْعَظِيمِ",
    transliteration: "Astaghfirullaha Rabbi Min Kulli Dhambin Adhnabtuhu 'Amadan Aw Khata'an Sirran Aw 'Alaniyyatan Wa-Atoobu Ilaihi Minadh-Dhambil-Ladhi A'lamu Wa Minadh-Dhambil-Ladhi La A'lamu, Innaka Anta 'Allamul Ghuyoobi Wa Sattarul 'Uyoobi Wa Ghaffarudh-Dhunoobi Wala Hawla Wala Quwwata illa billahil 'Aliyyil 'Adheem",
    urduTranslation: "میں اللہ سے بخشش مانگتا ہوں جو میرا رب ہے، ہر اس گناہ سے جو میں نے جان بوجھ کر کیا یا بھول کر کیا، پوشیدہ کیا یا اعلانیہ، اور میں اس کے حضور توبہ کرتا ہوں اس گناہ سے جو مجھے معلوم ہے اور اس گناہ سے جو مجھے معلوم نہیں، بے شک تو پوشیدہ باتوں کو جاننے والا اور عیبوں کو چھپانے والا اور گناہوں کو بخشنے والا ہے، اور گناہ سے بچنے کی طاقت اور نیکی کرنے کی قوت اللہ ہی کی طرف سے ہے جو عالی شان اور بڑا عظمت والا ہے۔",
    englishTranslation: "I seek forgiveness from Allah, Who is my Lord, for every sin I committed knowingly or unknowingly, secretly or openly, and I turn in repentance to Him for the sin which I know and for the sin which I do not know. Truly, You are the Knower of all secrets, the Coverer of all faults, and the Forgiver of all sins, and there is no power and no strength except with Allah, the Most High, the Most Supreme.",
  ),
  KalimatData(
    number: 6,
    nameUrdu: "کلمہ رد کفر (تکبیر)",
    nameEnglish: "Rad-de-Kufr (Takbir)",
    arabicText: "اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنْ أَنْ أُشْرِكَ بِكَ شَيْئًا وَأَنَا أَعْلَمُ بِهِ، وَأَسْتَغْفِرُكَ لِمَا لَا أَعْلَمُ بِهِ، تُبْتُ عَنْهُ وَتَبَرَّأْتُ مِنَ الْكُفْرِ وَالشِّرْكِ وَالْكِذْبِ وَالْغِيبَةِ وَالْبِدْعَةِ وَالنَّمِيمَةِ وَالْفَوَاحِشِ وَالْبُهْتَانِ وَالْمَعَاصِي كُلِّهَا، وَأَسْلَمْتُ وَأَقُولُ لَا إِلٰهَ إِلَّا اللهُ مُحَمَّدٌ رَّسُولُ اللهِ",
    transliteration: "Allahumma Inni A'oodhu bika min an ushrika bika shai'an wa-ana a'lamu bihi, wa-astaghfiruka lima la a'lamu bihi, tubtu 'anhu wa-tabarra'tu minal kufri wash-shirki wal-kidhbi wal-gheebati wal-bid'ati wan-nameemati wal-fawahishi wal-buhtani wal-ma'asi kulliha, wa-aslamtu wa-aqoolu La ilaha illallahu Muhammadur Rasoolullah",
    urduTranslation: "اے اللہ! میں تیری پناہ مانگتا ہوں اس بات سے کہ میں کسی چیز کو تیرا شریک بناؤں جان بوجھ کر، اور میں تجھ سے معافی مانگتا ہوں اس گناہ سے جسے میں نہیں جانتا، میں نے اس سے توبہ کی اور میں بیزار ہوا کفر، شرک، جھوٹ، غیبت، بدعت، چغلی، بے حیائی کے کاموں، بہتان اور تمام گناہوں سے، اور میں اسلام لایا اور میں کہتا ہوں کہ اللہ کے سوا کوئی معبود نہیں، محمد اللہ کے رسول ہیں۔",
    englishTranslation: "O Allah! I seek refuge in You from associating anything with You knowingly, and I seek Your forgiveness for that which I do not know. I repent of it and I declare myself free of disbelief, polytheism, falsehood, backbiting, innovation, slander, lewdness, calumny, and all sins. I submit to Your will and I declare: There is no deity but Allah, Muhammad is the messenger of Allah.",
  ),
];
