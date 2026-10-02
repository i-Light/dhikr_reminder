import 'package:dhikr_reminder/features/library/domain/dhikr_item.dart';

/// أذكار النوم وأذكار الاستيقاظ — what is said going to bed and on waking.
///
/// One section of `dhikrLibrary` (see `../dhikr_library.dart`).
const List<DhikrTag> _sleepNabawi = <DhikrTag>[
  DhikrTag.sleep,
  DhikrTag.propheticDuas,
];
const List<DhikrTag> _wakingNabawi = <DhikrTag>[
  DhikrTag.waking,
  DhikrTag.propheticDuas,
];

const List<DhikrItem> sleepWakingAdhkar = <DhikrItem>[
  DhikrItem(
    id: 's_bismillah_amut',
    text: 'بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا',
    subtitle: 'يُقال عند النوم',
    tags: _sleepNabawi,
  ),
  DhikrItem(
    id: 's_qini_adhabak',
    text: 'اللَّهُمَّ قِنِي عَذَابَكَ يَوْمَ تَبْعَثُ عِبَادَكَ',
    subtitle: 'تُقال ثلاث مرات عند النوم',
    description: 'كان النبي ﷺ يضع يده تحت خده ثم يقولها ثلاثاً.',
    tags: _sleepNabawi,
  ),
  DhikrItem(
    id: 's_tasabih_nawm',
    text:
        'سُبْحَانَ اللَّهِ (٣٣)\nالْحَمْدُ لِلَّهِ (٣٣)\nاللَّهُ أَكْبَرُ (٣٤)',
    subtitle: 'تسبيح فاطمة قبل النوم',
    description:
        'علّمها النبي ﷺ أن تكون خيراً لها من خادم تطلبه من الدنيا.',
    tags: <DhikrTag>[DhikrTag.sleep, DhikrTag.tasabih],
  ),
  DhikrItem(
    id: 's_aslamtu_nafsi',
    text:
        'اللَّهُمَّ أَسْلَمْتُ نَفْسِي إِلَيْكَ، وَوَجَّهْتُ وَجْهِي إِلَيْكَ، '
        'وَفَوَّضْتُ أَمْرِي إِلَيْكَ، وَأَلْجَأْتُ ظَهْرِي إِلَيْكَ، رَغْبَةً '
        'وَرَهْبَةً إِلَيْكَ، لَا مَلْجَأَ وَلَا مَنْجَا مِنْكَ إِلَّا إِلَيْكَ، '
        'آمَنْتُ بِكِتَابِكَ الَّذِي أَنْزَلْتَ، وَبِنَبِيِّكَ الَّذِي أَرْسَلْتَ',
    subtitle: 'يُقال عند النوم',
    description:
        'من قالها ومات من ليلته مات على الفطرة، ومن قالها فليجعلها آخر ما يقول.',
    tags: _sleepNabawi,
  ),
  DhikrItem(
    id: 's_bi_ismika_rabbi',
    text:
        'بِاسْمِكَ رَبِّي وَضَعْتُ جَنْبِي، وَبِكَ أَرْفَعُهُ، فَإِنْ أَمْسَكْتَ '
        'نَفْسِي فَارْحَمْهَا، وَإِنْ أَرْسَلْتَهَا فَاحْفَظْهَا بِمَا تَحْفَظُ بِهِ '
        'عِبَادَكَ الصَّالِحِينَ',
    subtitle: 'يُقال عند النوم',
    tags: _sleepNabawi,
  ),
  DhikrItem(
    id: 's_khalaqta_nafsi',
    text:
        'اللَّهُمَّ إِنَّكَ خَلَقْتَ نَفْسِي وَأَنْتَ تَوَفَّاهَا، لَكَ مَمَاتُهَا '
        'وَمَحْيَاهَا، إِنْ أَحْيَيْتَهَا فَاحْفَظْهَا، وَإِنْ أَمَتَّهَا '
        'فَاغْفِرْ لَهَا، اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَافِيَةَ',
    subtitle: 'يُقال عند النوم',
    tags: _sleepNabawi,
  ),
  DhikrItem(
    id: 's_atamana_waqana',
    text:
        'الْحَمْدُ لِلَّهِ الَّذِي أَطْعَمَنَا وَسَقَانَا وَكَفَانَا وَآوَانَا، '
        'فَكَمْ مِمَّنْ لَا كَافِيَ لَهُ وَلَا مُؤْوِيَ',
    subtitle: 'يُقال عند النوم',
    tags: <DhikrTag>[DhikrTag.sleep, DhikrTag.virtueOfDhikr],
  ),
  // ---- أذكار الاستيقاظ ---------------------------------------------------
  DhikrItem(
    id: 'w_alhamdulillah_ahya',
    text:
        'الْحَمْدُ لِلَّهِ الَّذِي أَحْيَانَا بَعْدَ مَا أَمَاتَنَا وَإِلَيْهِ '
        'النُّشُورُ',
    subtitle: 'يُقال عند الاستيقاظ',
    tags: _wakingNabawi,
  ),
  DhikrItem(
    id: 'w_alhamdulillah_rada',
    text:
        'الْحَمْدُ لِلَّهِ الَّذِي رَدَّ عَلَيَّ رُوحِي وَعَافَانِي فِي جَسَدِي '
        'وَأَذِنَ لِي بِذِكْرِهِ',
    subtitle: 'يُقال عند الاستيقاظ',
    tags: _wakingNabawi,
  ),
  DhikrItem(
    id: 'w_taarra',
    text:
        'لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ '
        'الْحَمْدُ، وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ، سُبْحَانَ اللَّهِ، '
        'وَالْحَمْدُ لِلَّهِ، وَلَا إِلَٰهَ إِلَّا اللَّهُ، وَاللَّهُ أَكْبَرُ، '
        'وَلَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ الْعَلِيِّ الْعَظِيمِ',
    subtitle: 'من تعارّ من الليل',
    description:
        'ثم قال: اللهم اغفر لي — أو دعا، استُجيب له، فإن توضأ وصلى قُبلت صلاته.',
    tags: _wakingNabawi,
  ),
];