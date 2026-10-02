import 'package:dhikr_reminder/features/library/domain/dhikr_item.dart';

/// دعاء ختم القرآن الكريم وأدعية للميّت — the dua said on finishing the
/// Quran, and the ones said for someone who has died.
///
/// One section of `dhikrLibrary` (see `../dhikr_library.dart`). Kept
/// together because both are tied to an occasion rather than to a time of
/// day: one to a milestone in reading, one to a funeral.
const List<DhikrItem> deceasedKhatmAdhkar = <DhikrItem>[
  // ---- دعاء ختم القرآن الكريم --------------------------------------------
  DhikrItem(
    id: 'kh_khatm_rahma',
    text:
        'اللَّهُمَّ ارْحَمْنِي بِالْقُرْآنِ، وَاجْعَلْهُ لِي إِمَامًا وَنُورًا '
        'وَهُدًى وَرَحْمَةً، اللَّهُمَّ ذَكِّرْنِي مِنْهُ مَا نَسِيتُ، '
        'وَعَلِّمْنِي مِنْهُ مَا جَهِلْتُ، وَارْزُقْنِي تِلَاوَتَهُ آنَاءَ '
        'اللَّيْلِ وَأَطْرَافَ النَّهَارِ، وَاجْعَلْهُ لِي حُجَّةً يَا رَبَّ '
        'الْعَالَمِينَ',
    subtitle: 'دعاء ختم القرآن',
    tags: <DhikrTag>[DhikrTag.khatmQuran, DhikrTag.jawamiDuas],
  ),
  DhikrItem(
    id: 'kh_khatm_qulub',
    text:
        'اللَّهُمَّ أَصْلِحْ بِالْقُرْآنِ قُلُوبَنَا، وَأَذْهِبْ بِهِ أَحْزَانَنَا '
        'وَهُمُومَنَا، وَاجْعَلْهُ لَنَا فِي الدُّنْيَا قَائِدًا وَفِي '
        'الْآخِرَةِ شَفِيعًا',
    subtitle: 'دعاء ختم القرآن',
    description:
        'يُستحب الدعاء عند الختم؛ كان أنس رضي الله عنه يجمع أهله عند ختمه '
        'ويدعو.',
    tags: <DhikrTag>[DhikrTag.khatmQuran, DhikrTag.jawamiDuas],
  ),
  DhikrItem(
    id: 'kh_khatm_noor',
    text:
        'اللَّهُمَّ اجْعَلِ الْقُرْآنَ الْعَظِيمَ رَبِيعَ قُلُوبِنَا، وَنُورَ '
        'صُدُورِنَا، وَجَلَاءَ أَحْزَانِنَا، وَذَهَابَ هُمُومِنَا',
    subtitle: 'دعاء ختم القرآن',
    tags: <DhikrTag>[DhikrTag.khatmQuran, DhikrTag.jawamiDuas],
  ),
  // ---- أدعية للميّت ------------------------------------------------------
  DhikrItem(
    id: 'dec_janazah',
    text:
        'اللَّهُمَّ اغْفِرْ لَهُ، وَارْحَمْهُ، وَعَافِهِ، وَاعْفُ عَنْهُ، '
        'وَأَكْرِمْ مَنْزِلَهُ، وَوَسِّعْ مُدْخَلَهُ، وَاغْسِلْهُ بِالْمَاءِ '
        'وَالثَّلْجِ وَالْبَرَدِ، وَنَقِّهِ مِنَ الْخَطَايَا كَمَا يُنَقَّى '
        'الثَّوْبُ الْأَبْيَضُ مِنَ الدَّنَسِ',
    subtitle: 'يُقال في صلاة الجنازة',
    description: 'وهو أكمل ما يُدعى به للميّت، ويُبدَّل الضمير لمن تُصلي عليه.',
    tags: <DhikrTag>[DhikrTag.duasForDeceased, DhikrTag.propheticDuas],
  ),
  DhikrItem(
    id: 'dec_living_dead',
    text:
        'اللَّهُمَّ اغْفِرْ لِأَحْيَائِنَا وَأَمْوَاتِنَا، وَشَاهِدِنَا وَغَائِبِنَا، '
        'وَصَغِيرِنَا وَكَبِيرِنَا، وَذَكَرِنَا وَأُنْثَانَا',
    subtitle: 'يُقال في صلاة الجنازة',
    tags: <DhikrTag>[DhikrTag.duasForDeceased, DhikrTag.propheticDuas],
  ),
  DhikrItem(
    id: 'dec_la_tahrimna',
    text:
        'اللَّهُمَّ لَا تَحْرِمْنَا أَجْرَهُ، وَلَا تَفْتِنَّا بَعْدَهُ، وَاغْفِرْ '
        'لَنَا وَلَهُ',
    subtitle: 'يُقال عند التعزية',
    tags: <DhikrTag>[DhikrTag.duasForDeceased, DhikrTag.jawamiDuas],
  ),
  DhikrItem(
    id: 'dec_qabr',
    text:
        'اللَّهُمَّ اجْعَلْ قَبْرَهُ رَوْضَةً مِنْ رِيَاضِ الْجَنَّةِ، وَلَا '
        'تَجْعَلْهُ حُفْرَةً مِنْ حُفَرِ النِّيرَانِ',
    subtitle: 'دعاء للميّت',
    tags: <DhikrTag>[DhikrTag.duasForDeceased, DhikrTag.jawamiDuas],
  ),
];