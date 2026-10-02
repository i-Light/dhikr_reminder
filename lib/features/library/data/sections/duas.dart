import 'package:dhikr_reminder/features/library/domain/dhikr_item.dart';

/// جوامع الدعاء والأدعية النبوية — the all-encompassing duas, and the ones
/// the Prophet ﷺ himself taught.
///
/// One section of `dhikrLibrary` (see `../dhikr_library.dart`). «جوامع
/// الدعاء» is the hadith's own term for a short wording that gathers many
/// requests at once, which is why these read as summaries rather than as
/// single, narrow asks.
const List<DhikrTag> _jawamiNabawi = <DhikrTag>[
  DhikrTag.jawamiDuas,
  DhikrTag.propheticDuas,
];

const List<DhikrItem> duasAdhkar = <DhikrItem>[
  DhikrItem(
    id: 'j_khayr_masala',
    text:
        'اللَّهُمَّ إِنِّي أَسْأَلُكَ مِنْ خَيْرِ مَا سَأَلَكَ مِنْهُ نَبِيُّكَ '
        'مُحَمَّدٌ ﷺ، وَأَعُوذُ بِكَ مِنْ شَرِّ مَا اسْتَعَاذَكَ مِنْهُ نَبِيُّكَ '
        'مُحَمَّدٌ ﷺ',
    subtitle: 'يجمع خير الدنيا والآخرة',
    description: 'قاله النبي ﷺ لعائشة رضي الله عنها وعلّمها أن تدعو به.',
    tags: _jawamiNabawi,
  ),
  DhikrItem(
    id: 'j_aslih_dini',
    text:
        'اللَّهُمَّ أَصْلِحْ لِي دِينِي الَّذِي هُوَ عِصْمَةُ أَمْرِي، وَأَصْلِحْ '
        'لِي دُنْيَايَ الَّتِي فِيهَا مَعَاشِي، وَأَصْلِحْ لِي آخِرَتِي الَّتِي '
        'فِيهَا مَعَادِي، وَاجْعَلِ الْحَيَاةَ زِيَادَةً لِي فِي كُلِّ خَيْرٍ، '
        'وَاجْعَلِ الْمَوْتَ رَاحَةً لِي مِنْ كُلِّ شَرٍّ',
    subtitle: 'من جوامع الدعاء',
    tags: <DhikrTag>[DhikrTag.jawamiDuas],
  ),
  DhikrItem(
    id: 'j_la_sahla',
    text:
        'اللَّهُمَّ لَا سَهْلَ إِلَّا مَا جَعَلْتَهُ سَهْلًا، وَأَنْتَ تَجْعَلُ '
        'الْحَزْنَ إِذَا شِئْتَ سَهْلًا',
    subtitle: 'يُقال عند تعسّر أمر',
    tags: <DhikrTag>[DhikrTag.jawamiDuas, DhikrTag.misc],
  ),
  DhikrItem(
    id: 'j_ya_muqallib',
    text: 'يَا مُقَلِّبَ الْقُلُوبِ ثَبِّتْ قَلْبِي عَلَى دِينِكَ',
    subtitle: 'من أكثر ما كان النبي ﷺ يدعو به',
    tags: _jawamiNabawi,
  ),
  DhikrItem(
    id: 'j_khayr_kullih',
    text:
        'اللَّهُمَّ إِنِّي أَسْأَلُكَ مِنَ الْخَيْرِ كُلِّهِ، عَاجِلِهِ وَآجِلِهِ، '
        'مَا عَلِمْتُ مِنْهُ وَمَا لَمْ أَعْلَمْ، وَأَعُوذُ بِكَ مِنَ الشَّرِّ '
        'كُلِّهِ، عَاجِلِهِ وَآجِلِهِ، مَا عَلِمْتُ مِنْهُ وَمَا لَمْ أَعْلَمْ',
    subtitle: 'من جوامع الدعاء',
    tags: <DhikrTag>[DhikrTag.jawamiDuas],
  ),
  DhikrItem(
    id: 'n_huda_taqa',
    text: 'اللَّهُمَّ إِنِّي أَسْأَلُكَ الْهُدَى وَالتُّقَى وَالْعَفَافَ وَالْغِنَى',
    subtitle: 'دعاء نبوي جامع',
    tags: _jawamiNabawi,
  ),
  DhikrItem(
    id: 'n_ghfirli_dhambi',
    text:
        'اللَّهُمَّ اغْفِرْ لِي ذَنْبِي كُلَّهُ، دِقَّهُ وَجِلَّهُ، وَأَوَّلَهُ '
        'وَآخِرَهُ، وَعَلَانِيَتَهُ وَسِرَّهُ',
    subtitle: 'دعاء نبوي',
    tags: <DhikrTag>[DhikrTag.propheticDuas],
  ),
  DhikrItem(
    id: 'n_aoodhu_arbaa',
    text:
        'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنْ عِلْمٍ لَا يَنْفَعُ، وَمِنْ قَلْبٍ '
        'لَا يَخْشَعُ، وَمِنْ نَفْسٍ لَا تَشْبَعُ، وَمِنْ دَعْوَةٍ لَا '
        'يُسْتَجَابُ لَهَا',
    subtitle: 'دعاء نبوي',
    tags: <DhikrTag>[DhikrTag.propheticDuas],
  ),
];