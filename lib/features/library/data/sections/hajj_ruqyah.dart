import 'package:dhikr_reminder/features/library/domain/dhikr_item.dart';

/// أذكار الحج والعمرة والرُّقية الشرعية — the talbiyah and the sanctuary
/// duas, alongside the Quranic ruqyah a person recites over themselves or
/// another.
///
/// One section of `dhikrLibrary` (see `../dhikr_library.dart`). The ruqyah
/// entries are the same surahs the morning/evening adhkar use, tagged
/// [DhikrTag.ruqyah] as well so they surface here in their own right — the
/// point of a library is that one text can be found from either direction.
const List<DhikrItem> hajjRuqyahAdhkar = <DhikrItem>[
  DhikrItem(
    id: 'h_talbiyah',
    text:
        'لَبَّيْكَ اللَّهُمَّ لَبَّيْكَ، لَبَّيْكَ لَا شَرِيكَ لَكَ لَبَّيْكَ، '
        'إِنَّ الْحَمْدَ وَالنِّعْمَةَ لَكَ وَالْمُلْكَ، لَا شَرِيكَ لَكَ',
    subtitle: 'التلبية — تُرفع بها الصوت في الحج والعمرة',
    tags: <DhikrTag>[DhikrTag.hajjUmrah, DhikrTag.propheticDuas],
  ),
  DhikrItem(
    id: 'h_labbayk_wa_sadayk',
    text:
        'لَبَّيْكَ وَسَعْدَيْكَ، وَالْخَيْرُ بِيَدَيْكَ، وَالشَّرُّ لَيْسَ إِلَيْكَ، '
        'لَبَّيْكَ وَالرَّغْبَاءُ إِلَيْكَ وَالْعَمَلُ',
    subtitle: 'من التلبية',
    tags: <DhikrTag>[DhikrTag.hajjUmrah],
  ),
  DhikrItem(
    id: 'h_safa_marwa',
    text:
        'إِنَّ الصَّفَا وَالْمَرْوَةَ مِن شَعَائِرِ اللَّهِ، أَبْدَأُ بِمَا بَدَأَ '
        'اللَّهُ بِهِ',
    subtitle: 'يُقال عند الصفا',
    reference: 'البقرة: ١٥٨',
    tags: <DhikrTag>[
      DhikrTag.hajjUmrah,
      DhikrTag.quranicDuas,
      DhikrTag.misc,
    ],
  ),
  DhikrItem(
    id: 'h_arafah',
    text:
        'لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ '
        'الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
    subtitle: 'أفضل الدعاء يوم عرفة',
    description: 'وهو دعاء الوقوف بعرفة — وخير ما قاله الأنبياء قبله.',
    tags: <DhikrTag>[DhikrTag.hajjUmrah, DhikrTag.virtueOfDhikr],
  ),
  DhikrItem(
    id: 'r_fatiha',
    text:
        'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ ۝ الْحَمْدُ لِلَّهِ رَبِّ '
        'الْعَالَمِينَ ۝ الرَّحْمَٰنِ الرَّحِيمِ ۝ مَالِكِ يَوْمِ الدِّينِ ۝ '
        'إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ ۝ اهْدِنَا الصِّرَاطَ '
        'الْمُسْتَقِيمَ ۝ صِرَاطَ الَّذِينَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ '
        'الْمَغْضُوبِ عَلَيْهِمْ وَلَا الضَّالِّينَ',
    subtitle: 'تُقرأ في الرُّقية',
    reference: 'الفاتحة',
    description: 'الفاتحة رقية — تُقرأ على المريض وعلى النفس.',
    tags: <DhikrTag>[
      DhikrTag.ruqyah,
      DhikrTag.quranicDuas,
      DhikrTag.virtueOfSuras,
    ],
  ),
  DhikrItem(
    id: 'r_ayat_kursi',
    text:
        'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ '
        'وَلَا نَوْمٌ ۚ لَهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ',
    subtitle: 'تُقرأ في الرُّقية قبل النوم',
    reference: 'البقرة: ٢٥٥',
    description:
        'من قرأها حين يأوي إلى فراشه لم يزل عليه من الله حافظ، ولا يقربه شيطان '
        'حتى يصبح.',
    tags: <DhikrTag>[
      DhikrTag.ruqyah,
      DhikrTag.quranicDuas,
      DhikrTag.virtueOfSuras,
    ],
  ),
  DhikrItem(
    id: 'r_muawwidhat',
    text:
        'قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ…\n'
        'قُلْ أَعُوذُ بِرَبِّ النَّاسِ…\n'
        'قُلْ هُوَ اللَّهُ أَحَدٌ…',
    subtitle: 'المعوذات — تُقرأ ثلاثاً وتُنفث في الكفين',
    reference: 'الفلق والناس والإخلاص',
    description:
        'كان النبي ﷺ إذا أوى إلى فراشه يجمع كفيه ثم ينفث فيهما ويقرؤهما، ثم '
        'يمسح بهما ما استطاع من جسده.',
    tags: <DhikrTag>[
      DhikrTag.ruqyah,
      DhikrTag.quranicDuas,
      DhikrTag.virtueOfSuras,
    ],
  ),
  DhikrItem(
    id: 'r_aoodhu_bik',
    text:
        'أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ',
    subtitle: 'ثلاث مرات — لمن خاف موضعاً أو ألماً',
    description:
        'الذي ينزل منزلاً فليقلها ثلاثاً، فلا يضره شيء حتى يرتحل منه.',
    tags: <DhikrTag>[DhikrTag.ruqyah, DhikrTag.propheticDuas],
  ),
];