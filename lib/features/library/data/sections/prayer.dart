import 'package:dhikr_reminder/features/library/domain/dhikr_item.dart';

/// أذكار بعد الصلاة، وأذكار الصلاة، وأذكار الأذان والمسجد، وتسبيحات ما بعد
/// الصلاة — the prayer-adjacent adhkar.
///
/// One section of `dhikrLibrary` (see `../dhikr_library.dart`). The
/// after-prayer adhkar are the bulk of it; the two in-prayer duas and the
/// adhan/mosque entries share a file because they are all "at the prayer"
/// rather than "at home" or "in the morning".
const List<DhikrTag> _afterPrayer = <DhikrTag>[
  DhikrTag.afterPrayer,
  DhikrTag.prayer,
];
const List<DhikrTag> _afterPrayerNabawi = <DhikrTag>[
  ..._afterPrayer,
  DhikrTag.propheticDuas,
];

const List<DhikrItem> prayerAdhkar = <DhikrItem>[
  DhikrItem(
    id: 'p_istighfar_salam',
    text:
        'أَسْتَغْفِرُ اللَّهَ، أَسْتَغْفِرُ اللَّهَ، أَسْتَغْفِرُ اللَّهَ. '
        'اللَّهُمَّ أَنْتَ السَّلَامُ وَمِنْكَ السَّلَامُ، تَبَارَكْتَ يَا ذَا '
        'الْجَلَالِ وَالْإِكْرَامِ',
    subtitle: 'يُقال بعد السلام من الصلاة',
    description: 'كان النبي ﷺ إذا انصرف من صلاته استغفر ثلاثاً وقالها.',
    tags: _afterPrayer,
  ),
  DhikrItem(
    id: 'p_dhikr_shukr',
    text: 'اللَّهُمَّ أَعِنِّي عَلَى ذِكْرِكَ وَشُكْرِكَ وَحُسْنِ عِبَادَتِكَ',
    subtitle: 'يُقال بعد كل صلاة',
    description:
        'أوصى النبي ﷺ معاذاً ألّا يدعها دُبُر كل صلاة، وأخذ بيده فقال: يا معاذ، '
        'والله إني لأحبك.',
    tags: _afterPrayerNabawi,
  ),
  DhikrItem(
    id: 'p_tasabih_after',
    text: 'سُبْحَانَ اللَّهِ (٣٣)\nالْحَمْدُ لِلَّهِ (٣٣)\nاللَّهُ أَكْبَرُ (٣٣)',
    subtitle: 'ثلاثاً وثلاثين بعد كل صلاة',
    description:
        'من سبّح الله ثلاثاً وثلاثين، وحمِد الله ثلاثاً وثلاثين، وكبّر الله ثلاثاً '
        'وثلاثين، فذلك تسعة وتسعون، وقال تمام المئة: لا إله إلا الله وحده لا '
        'شريك له، له الملك وله الحمد وهو على كل شيء قدير — غُفرت خطاياه.',
    tags: <DhikrTag>[..._afterPrayer, DhikrTag.tasabih],
  ),
  DhikrItem(
    id: 'p_la_manea',
    text:
        'لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ '
        'الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ، اللَّهُمَّ لَا مَانِعَ لِمَا '
        'أَعْطَيْتَ، وَلَا مُعْطِيَ لِمَا مَنَعْتَ، وَلَا يَنْفَعُ ذَا الْجَدِّ '
        'مِنْكَ الْجَدُّ',
    subtitle: 'يُقال بعد السلام وقبل أن ينصرف',
    tags: _afterPrayer,
  ),
  DhikrItem(
    id: 'p_rabbana_atina',
    text:
        'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا '
        'عَذَابَ النَّارِ',
    subtitle: 'كان النبي ﷺ أكثر ما يدعو به في الصلاة',
    reference: 'البقرة: ٢٠١',
    tags: <DhikrTag>[
      ..._afterPrayer,
      DhikrTag.quranicDuas,
      DhikrTag.propheticDuas,
    ],
  ),
  DhikrItem(
    id: 'p_jubn_fitna',
    text:
        'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْجُبْنِ، وَأَعُوذُ بِكَ أَنْ أُرَدَّ '
        'إِلَى أَرْذَلِ الْعُمُرِ، وَأَعُوذُ بِكَ مِنْ فِتْنَةِ الدُّنْيَا، '
        'وَأَعُوذُ بِكَ مِنْ عَذَابِ الْقَبْرِ',
    subtitle: 'يُقال بعد الصلاة',
    tags: _afterPrayerNabawi,
  ),
  DhikrItem(
    id: 'p_istiftah',
    text:
        'سُبْحَانَكَ اللَّهُمَّ وَبِحَمْدِكَ، وَتَبَارَكَ اسْمُكَ، وَتَعَالَى '
        'جَدُّكَ، وَلَا إِلَٰهَ غَيْرُكَ',
    subtitle: 'دعاء الاستفتاح — يُقال في أول الصلاة',
    tags: <DhikrTag>[DhikrTag.prayer],
  ),
  DhikrItem(
    id: 'p_zalamt_nafsi',
    text:
        'اللَّهُمَّ إِنِّي ظَلَمْتُ نَفْسِي ظُلْمًا كَثِيرًا وَلَا يَغْفِرُ '
        'الذُّنُوبَ إِلَّا أَنْتَ، فَاغْفِرْ لِي مَغْفِرَةً مِنْ عِندِكَ '
        'وَارْحَمْنِي، إِنَّكَ أَنْتَ الْغَفُورُ الرَّحِيمُ',
    subtitle: 'دعاء أبي بكر — يُقال في التشهد قبل السلام',
    tags: <DhikrTag>[DhikrTag.prayer, DhikrTag.propheticDuas],
  ),
  DhikrItem(
    id: 'p_adhan_wasilah',
    text:
        'اللَّهُمَّ رَبَّ هَذِهِ الدَّعْوَةِ التَّامَّةِ، وَالصَّلَاةِ الْقَائِمَةِ، '
        'آتِ مُحَمَّدًا الْوَسِيلَةَ وَالْفَضِيلَةَ، وَابْعَثْهُ مَقَامًا '
        'مَحْمُودًا الَّذِي وَعَدْتَهُ',
    subtitle: 'يُقال بعد الأذان',
    description:
        'من قالها حين يسمع النداء حُلّت له شفاعتي يوم القيامة.',
    tags: <DhikrTag>[DhikrTag.adhan, DhikrTag.propheticDuas],
  ),
  DhikrItem(
    id: 'p_adhan_shahada',
    text:
        'وَأَنَا أَشْهَدُ أَنْ لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، '
        'وَأَنَّ مُحَمَّدًا عَبْدُهُ وَرَسُولُهُ، رَضِيتُ بِاللَّهِ رَبًّا، '
        'وَبِمُحَمَّدٍ رَسُولًا، وَبِالْإِسْلَامِ دِينًا',
    subtitle: 'يُقال عند سماع الأذان',
    description: 'من قالها حين يسمع المؤذن يقول «أشهد أن لا إله إلا الله» غُفر له ذنبه.',
    tags: <DhikrTag>[DhikrTag.adhan, DhikrTag.propheticDuas],
  ),
  DhikrItem(
    id: 'p_mosque_in',
    text:
        'أَعُوذُ بِاللَّهِ مِنَ الشَّيْطَانِ الرَّجِيمِ، اللَّهُمَّ افْتَحْ لِي '
        'أَبْوَابَ رَحْمَتِكَ',
    subtitle: 'يُقال عند دخول المسجد',
    tags: <DhikrTag>[DhikrTag.mosque],
  ),
  DhikrItem(
    id: 'p_mosque_out',
    text: 'اللَّهُمَّ إِنِّي أَسْأَلُكَ مِنْ فَضْلِكَ',
    subtitle: 'يُقال عند الخروج من المسجد',
    description: 'وتُقدَّم على الدعاء بالصلاة على النبي ﷺ.',
    tags: <DhikrTag>[DhikrTag.mosque, DhikrTag.propheticDuas],
  ),
];