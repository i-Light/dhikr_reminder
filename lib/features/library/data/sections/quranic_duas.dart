import 'package:dhikr_reminder/features/library/domain/dhikr_item.dart';

/// الأدعية القرآنية — the supplications the Quran itself teaches, that are
/// not tied to one named prophet.
///
/// One section of `dhikrLibrary` (see `../dhikr_library.dart`). Every entry
/// is a quotation, so [DhikrItem.reference] is always set and the library
/// renders it in brackets after the text.
const List<DhikrItem> quranicDuas = <DhikrItem>[
  DhikrItem(
    id: 'q_rabbana_hasana',
    text:
        'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا '
        'عَذَابَ النَّارِ',
    reference: 'البقرة: ٢٠١',
    description: 'كان النبي ﷺ أكثر ما يدعو به.',
    tags: <DhikrTag>[DhikrTag.quranicDuas, DhikrTag.jawamiDuas],
  ),
  DhikrItem(
    id: 'q_la_tuzigh',
    text:
        'رَبَّنَا لَا تُزِغْ قُلُوبَنَا بَعْدَ إِذْ هَدَيْتَنَا وَهَبْ لَنَا مِن '
        'لَّدُنكَ رَحْمَةً إِنَّكَ أَنتَ الْوَهَّابُ',
    reference: 'آل عمران: ٨',
    tags: <DhikrTag>[DhikrTag.quranicDuas],
  ),
  DhikrItem(
    id: 'q_ghufranak',
    text:
        'رَبَّنَا إِنَّا آمَنَّا فَاغْفِرْ لَنَا ذُنُوبَنَا وَقِنَا عَذَابَ النَّارِ',
    reference: 'آل عمران: ١٦',
    tags: <DhikrTag>[DhikrTag.quranicDuas],
  ),
  DhikrItem(
    id: 'q_la_tuakhidhna',
    text:
        'رَبَّنَا لَا تُؤَاخِذْنَا إِن نَّسِينَا أَوْ أَخْطَأْنَا، رَبَّنَا وَلَا '
        'تَحْمِلْ عَلَيْنَا إِصْرًا كَمَا حَمَلْتَهُ عَلَى الَّذِينَ مِن '
        'قَبْلِنَا، رَبَّنَا وَلَا تُحَمِّلْنَا مَا لَا طَاقَةَ لَنَا بِهِ، '
        'وَاعْفُ عَنَّا وَاغْفِرْ لَنَا وَارْحَمْنَا، أَنتَ مَوْلَانَا '
        'فَانصُرْنَا عَلَى الْقَوْمِ الْكَافِرِينَ',
    reference: 'البقرة: ٢٨٦',
    tags: <DhikrTag>[DhikrTag.quranicDuas],
  ),
  DhikrItem(
    id: 'q_hasbunallah',
    text: 'حَسْبُنَا اللَّهُ وَنِعْمَ الْوَكِيلُ',
    reference: 'آل عمران: ١٧٣',
    tags: <DhikrTag>[DhikrTag.quranicDuas, DhikrTag.misc],
  ),
  DhikrItem(
    id: 'q_hasbuna_wa_kafa',
    text: 'وَنِعْمَ الْوَكِيلُ، نِعْمَ الْمَوْلَى وَنِعْمَ النَّصِيرُ',
    reference: 'الأنفال: ٤٠ والتحريم: ٤',
    tags: <DhikrTag>[DhikrTag.quranicDuas],
  ),
  DhikrItem(
    id: 'q_rabbana_atimim',
    text:
        'رَبَّنَا أَتْمِمْ لَنَا نُورَنَا وَاغْفِرْ لَنَا إِنَّكَ عَلَى كُلِّ شَيْءٍ '
        'قَدِيرٌ',
    reference: 'التحريم: ٨',
    tags: <DhikrTag>[DhikrTag.quranicDuas],
  ),
  DhikrItem(
    id: 'q_ali_imran_193',
    text:
        'رَبَّنَا إِنَّنَا سَمِعْنَا مُنَادِيًا يُنَادِي لِلْإِيمَانِ أَنْ آمِنُوا '
        'بِرَبِّكُمْ فَآمَنَّا، رَبَّنَا فَاغْفِرْ لَنَا ذُنُوبَنَا وَكَفِّرْ '
        'عَنَّا سَيِّئَاتِنَا وَتَوَفَّنَا مَعَ الْأَبْرَارِ',
    reference: 'آل عمران: ١٩٣',
    tags: <DhikrTag>[DhikrTag.quranicDuas],
  ),
  DhikrItem(
    id: 'q_rabbana_hab_lana',
    text:
        'رَبَّنَا هَبْ لَنَا مِنْ أَزْوَاجِنَا وَذُرِّيَّاتِنَا قُرَّةَ أَعْيُنٍ '
        'وَاجْعَلْنَا لِلْمُتَّقِينَ إِمَامًا',
    reference: 'الفرقان: ٧٤',
    tags: <DhikrTag>[DhikrTag.quranicDuas],
  ),
  DhikrItem(
    id: 'q_rabbana_hasana_sura',
    text:
        'رَبَّنَا لَا تَجْعَلْنَا ظَالِمِينَ، رَبِّ زِدْنِي عِلْمًا، رَّبِّ '
        'ارْحَمْهُمَا كَمَا رَبَّيَانِي صَغِيرًا',
    subtitle: 'آيات يدعو بها القرآن',
    reference: 'القصص والأنبياء والإسراء',
    tags: <DhikrTag>[DhikrTag.quranicDuas, DhikrTag.prophetsDuas],
  ),
  DhikrItem(
    id: 'q_rabbi_awzini',
    text:
        'رَبِّ أَوْزِعْنِي أَنْ أَشْكُرَ نِعْمَتَكَ الَّتِي أَنْعَمْتَ عَلَيَّ '
        'وَعَلَى وَالِدَيَّ وَأَنْ أَعْمَلَ صَالِحًا تَرْضَاهُ',
    reference: 'الأحقاف: ١٥',
    tags: <DhikrTag>[DhikrTag.quranicDuas, DhikrTag.jawamiDuas],
  ),
];