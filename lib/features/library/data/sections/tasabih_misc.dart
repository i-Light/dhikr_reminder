import 'package:dhikr_reminder/features/library/domain/dhikr_item.dart';

/// تسابيح وأذكار متفرقة — the counting formulas, and the everyday adhkar
/// that have no single occasion attached to them.
///
/// One section of `dhikrLibrary` (see `../dhikr_library.dart`). The two tags
/// are kept distinct on purpose: [DhikrTag.tasabih] is for the counting
/// wordings, [DhikrTag.misc] for a dua that simply has no better home.
const List<DhikrItem> tasabihMiscAdhkar = <DhikrItem>[
  DhikrItem(
    id: 't_subhanallah_bihamdih',
    text: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ، سُبْحَانَ اللَّهِ الْعَظِيمِ',
    subtitle: 'كلمتان خفيفتان على اللسان',
    description:
        'كلمتان خفيفتان على اللسان، ثقيلتان في الميزان، حبيبتان إلى الرحمن.',
    tags: <DhikrTag>[DhikrTag.tasabih, DhikrTag.virtueOfDhikr],
  ),
  DhikrItem(
    id: 't_la_hawla',
    text: 'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ',
    subtitle: 'كنز من كنوز الجنة',
    tags: <DhikrTag>[DhikrTag.tasabih, DhikrTag.misc],
  ),
  DhikrItem(
    id: 't_subhanallah_adad',
    text:
        'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ، عَدَدَ خَلْقِهِ، وَرِضَا نَفْسِهِ، وَزِنَةَ '
        'عَرْشِهِ، وَمِدَادَ كَلِمَاتِهِ',
    subtitle: 'تُقال مرة واحدة وتعدل ذكراً كثيراً',
    description:
        'قالتها جويرية للنبي ﷺ فعدلت له أضعاف ما قاله من الفجر إلى ذلك الوقت.',
    tags: <DhikrTag>[DhikrTag.tasabih],
  ),
  DhikrItem(
    id: 't_bakiyat_salihat',
    text:
        'سُبْحَانَ اللَّهِ، وَالْحَمْدُ لِلَّهِ، وَلَا إِلَٰهَ إِلَّا اللَّهُ، '
        'وَاللَّهُ أَكْبَرُ',
    subtitle: 'الباقيات الصالحات — أحبُّ الكلام إلى الله',
    tags: <DhikrTag>[DhikrTag.tasabih, DhikrTag.virtueOfDhikr],
  ),
  DhikrItem(
    id: 't_ibrahimiya',
    text:
        'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ، كَمَا صَلَّيْتَ '
        'عَلَى إِبْرَاهِيمَ وَعَلَى آلِ إِبْرَاهِيمَ، إِنَّكَ حَمِيدٌ مَجِيدٌ، '
        'اللَّهُمَّ بَارِكْ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ، كَمَا بَارَكْتَ '
        'عَلَى إِبْرَاهِيمَ وَعَلَى آلِ إِبْرَاهِيمَ، إِنَّكَ حَمِيدٌ مَجِيدٌ',
    subtitle: 'الصلاة الإبراهيمية',
    description: 'أفضلها ما علّمه النبي ﷺ أصحابه حين سألوه كيف نصلي عليه.',
    tags: <DhikrTag>[
      DhikrTag.tasabih,
      DhikrTag.propheticDuas,
      DhikrTag.virtueOfDhikr,
    ],
  ),
  DhikrItem(
    id: 't_lailaha_ashr',
    text:
        'لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ '
        'الْحَمْدُ، وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
    subtitle: 'تُقال عشر مرات في اليوم',
    description:
        'من قالها عشر مرات كانت له عدل عشر رقاب، وكُتب له مئة حسنة، ومُحيت عنه '
        'مئة سيئة.',
    tags: <DhikrTag>[DhikrTag.tasabih, DhikrTag.misc],
  ),
  DhikrItem(
    id: 't_jannah_nar',
    text: 'اللَّهُمَّ إِنِّي أَسْأَلُكَ الْجَنَّةَ وَأَعُوذُ بِكَ مِنَ النَّارِ',
    subtitle: 'دعاء جامع يُكثر منه',
    tags: <DhikrTag>[DhikrTag.misc, DhikrTag.jawamiDuas],
  ),
  DhikrItem(
    id: 't_hasan_aqibah',
    text:
        'اللَّهُمَّ أَحْسِنْ عَاقِبَتَنَا فِي الْأُمُورِ كُلِّهَا، وَأَجِرْنَا مِنْ '
        'خِزْيِ الدُّنْيَا وَعَذَابِ الْآخِرَةِ',
    subtitle: 'دعاء جامع',
    tags: <DhikrTag>[DhikrTag.misc, DhikrTag.jawamiDuas],
  ),
];