import 'package:dhikr_reminder/features/library/domain/dhikr_item.dart';

/// أذكار الوضوء والمنزل والخلاء والطعام — the everyday, off-the-prayer-mat
/// adhkar: what is said at the wash basin, at the front door, in the
/// washroom and at the table.
///
/// One section of `dhikrLibrary` (see `../dhikr_library.dart`).
const List<DhikrItem> dailyLifeAdhkar = <DhikrItem>[
  DhikrItem(
    id: 'd_wudu_shahada',
    text:
        'أَشْهَدُ أَنْ لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، '
        'وَأَشْهَدُ أَنَّ مُحَمَّدًا عَبْدُهُ وَرَسُولُهُ',
    subtitle: 'يُقال بعد الوضوء',
    description:
        'من توضأ فأحسن الوضوء ثم قالها فُتحت له أبواب الجنة الثمانية يدخل من '
        'أيها شاء.',
    tags: <DhikrTag>[DhikrTag.wudu, DhikrTag.propheticDuas],
  ),
  DhikrItem(
    id: 'd_wudu_tawwabin',
    text: 'اللَّهُمَّ اجْعَلْنِي مِنَ التَّوَّابِينَ، وَاجْعَلْنِي مِنَ الْمُتَطَهِّرِينَ',
    subtitle: 'يُقال بعد الوضوء',
    tags: <DhikrTag>[DhikrTag.wudu, DhikrTag.propheticDuas],
  ),
  DhikrItem(
    id: 'd_home_in',
    text:
        'بِسْمِ اللَّهِ وَلَجْنَا، وَبِسْمِ اللَّهِ خَرَجْنَا، وَعَلَى رَبِّنَا '
        'تَوَكَّلْنَا، ثُمَّ يُسَلِّمُ عَلَى أَهْلِهِ',
    subtitle: 'يُقال عند دخول المنزل',
    description:
        'من دخله يذكر الله عند دخوله وعند طعامه لم يستطع الشيطان أن يبيت عنده ولا '
        'أن يأكل من طعامه.',
    tags: <DhikrTag>[DhikrTag.home, DhikrTag.propheticDuas],
  ),
  DhikrItem(
    id: 'd_home_out',
    text:
        'بِسْمِ اللَّهِ، تَوَكَّلْتُ عَلَى اللَّهِ، وَلَا حَوْلَ وَلَا قُوَّةَ '
        'إِلَّا بِاللَّهِ',
    subtitle: 'يُقال عند الخروج من المنزل',
    description:
        'يُقال لها: هُديتَ وكُفيتَ ووُقيتَ، وتنحّى عنه الشيطان. وعن التَّوَكُّل '
        'على الله في مهمّات اليوم كلها.',
    tags: <DhikrTag>[
      DhikrTag.home,
      DhikrTag.misc,
      DhikrTag.propheticDuas,
    ],
  ),
  DhikrItem(
    id: 'd_khalaa_in',
    text: 'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْخُبْثِ وَالْخَبَائِثِ',
    subtitle: 'يُقال عند دخول الخلاء',
    tags: <DhikrTag>[DhikrTag.khalaa],
  ),
  DhikrItem(
    id: 'd_khalaa_out',
    text: 'غُفْرَانَكَ',
    subtitle: 'يُقال عند الخروج من الخلاء',
    description: 'وفي لفظ: غُفرانك يا رب.',
    tags: <DhikrTag>[DhikrTag.khalaa],
  ),
  DhikrItem(
    id: 'd_food_before',
    text: 'بِسْمِ اللَّهِ',
    subtitle: 'يُقال قبل الطعام',
    description:
        'وإذا نسي في أوله فليقل: بسم الله في أوله وآخره.',
    tags: <DhikrTag>[DhikrTag.food],
  ),
  DhikrItem(
    id: 'd_food_after',
    text:
        'الْحَمْدُ لِلَّهِ الَّذِي أَطْعَمَنِي هَذَا وَرَزَقَنِيهِ مِنْ غَيْرِ حَوْلٍ '
        'مِنِّي وَلَا قُوَّةٍ',
    subtitle: 'يُقال بعد الطعام',
    description: 'من قالها غُفر له ما تقدم من ذنبه.',
    tags: <DhikrTag>[DhikrTag.food, DhikrTag.virtueOfDhikr],
  ),
];