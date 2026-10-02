import 'package:dhikr_reminder/features/library/domain/dhikr_item.dart';

/// فضل الذكر وفضل الدعاء وفضل القرآن وفضل السور وأسماء الله الحسنى — the
/// library's reference half: what the texts above are worth, and the names
/// of Allah.
///
/// One section of `dhikrLibrary` (see `../dhikr_library.dart`). Entries here
/// keep [DhikrItem.text] short — a hasan hadith's wording, a name, a surah's
/// opening — and put the explanation in [DhikrItem.description], because the
/// point of this section is the *reason* a dhikr is said, not the wording.
const List<DhikrTag> _virtueDhikrQuran = <DhikrTag>[
  DhikrTag.virtueOfDhikr,
  DhikrTag.virtueOfQuran,
];

const List<DhikrItem> virtueAdhkar = <DhikrItem>[
  // ---- فضل الدعاء --------------------------------------------------------
  DhikrItem(
    id: 'v_dua_ibadah',
    text: 'وَإِذَا سَأَلَكَ عِبَادِي عَنِّي فَإِنِّي قَرِيبٌ',
    subtitle: 'فضل الدعاء',
    reference: 'البقرة: ١٨٦',
    description:
        'الدعاء هو العبادة — وقال ﷺ: «إِنَّ الدُّعَاءَ هُوَ الْعِبَادَةُ»، ثم قرأ '
        'هذه الآية.',
    tags: <DhikrTag>[DhikrTag.virtueOfDua, DhikrTag.virtueOfQuran],
  ),
  DhikrItem(
    id: 'v_dua_mustajaab',
    text: 'وَقَالَ رَبُّكُمُ ادْعُونِي أَسْتَجِبْ لَكُمْ',
    subtitle: 'فضل الدعاء',
    reference: 'غافر: ٦٠',
    description:
        'أمر بالدعاء ووعد بالإجابة — فمن لم يسأل فقد ترك خيراً كثيراً، وقال ﷺ: '
        '«مَنْ لَمْ يَسْأَلِ اللَّهَ يَغْضَبْ عَلَيْهِ».',
    tags: <DhikrTag>[DhikrTag.virtueOfDua, DhikrTag.virtueOfQuran],
  ),
  DhikrItem(
    id: 'v_dua_alayka',
    text: 'وَقَالَ ﷺ: «الدُّعَاءُ يَنْفَعُ لِمَا نَزَلَ وَلِمَا لَمْ يَنْزِلْ»',
    subtitle: 'فضل الدعاء',
    description:
        'فالدعاء يدفع البلاء قبل نزوله وبعد نزوله، فليُكثر منه في الرخاء والشدة.',
    tags: <DhikrTag>[DhikrTag.virtueOfDua],
  ),
  // ---- فضل الذكر ---------------------------------------------------------
  DhikrItem(
    id: 'v_dhikr_ahbab',
    text: '…فَاذْكُرُونِي أَذْكُرْكُمْ وَاشْكُرُوا لِي وَلَا تَكْفُرُونِ',
    subtitle: 'فضل الذكر',
    reference: 'البقرة: ١٥٢',
    description: 'أحبُّ الكلام إلى الله أربع: سبحان الله، والحمد لله، ولا إله إلا الله، والله أكبر.',
    tags: _virtueDhikrQuran,
  ),
  DhikrItem(
    id: 'v_dhikr_ghafil',
    text: 'الذِّكْرُ حَيَاةُ الْقُلُوبِ',
    subtitle: 'فضل الذكر',
    description:
        'ومثل الذي يذكر ربه والذي لا يذكره كمثل الحي والميت؛ وقال ﷺ: «لا يزال '
        'لسانك رطباً بذكر الله».',
    tags: <DhikrTag>[DhikrTag.virtueOfDhikr],
  ),
  DhikrItem(
    id: 'v_dhikr_mizaan',
    text: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
    subtitle: 'فضل الذكر',
    description:
        'من قالها في يوم مئة مرة حُطّت خطاياه وإن كانت مثل زبد البحر.',
    tags: <DhikrTag>[DhikrTag.virtueOfDhikr, DhikrTag.tasabih],
  ),
  DhikrItem(
    id: 'v_dhikr_salatayn',
    text: 'سُبْحَانَ اللَّهِ وَالْحَمْدُ لِلَّهِ وَلَا إِلَٰهَ إِلَّا اللَّهُ وَاللَّهُ أَكْبَرُ',
    subtitle: 'فضل الذكر',
    description:
        'أحبُّ الكلام إلى الله، وأربعٌ هنّ أحبُّ إليّ من الدنيا وما فيها.',
    tags: <DhikrTag>[DhikrTag.virtueOfDhikr, DhikrTag.tasabih],
  ),
  // ---- فضل القرآن وفضل السور ---------------------------------------------
  DhikrItem(
    id: 'v_quran_khayrukum',
    text:
        'خَيْرُكُمْ مَنْ تَعَلَّمَ الْقُرْآنَ وَعَلَّمَهُ',
    subtitle: 'فضل القرآن',
    description:
        'وقال ﷺ: «اقرؤوا القرآن فإنه يأتي يوم القيامة شفيعاً لأصحابه»، و«الذي '
        'يقرأ القرآن وهو حافظ له مع السفرة الكرام البررة».',
    tags: <DhikrTag>[DhikrTag.virtueOfQuran],
  ),
  DhikrItem(
    id: 'v_quran_juz_huruf',
    text: 'مَنْ قَرَأَ حَرْفًا مِنْ كِتَابِ اللَّهِ فَلَهُ بِهِ حَسَنَةٌ',
    subtitle: 'فضل القرآن',
    description:
        'والحسنة عشر أمثالها — لا أقول «الم» حرف، ولكن ألف حرف ولام حرف وميم حرف.',
    tags: <DhikrTag>[DhikrTag.virtueOfQuran],
  ),
  DhikrItem(
    id: 'v_sura_fatiha',
    text: 'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ',
    subtitle: 'فضل سورة الفاتحة',
    reference: 'الفاتحة: ٢',
    description:
        'أم الكتاب والسبع المثاني — هي نور، ما أنزل الله مثلها في التوراة ولا '
        'الإنجيل.',
    tags: <DhikrTag>[DhikrTag.virtueOfSuras, DhikrTag.virtueOfQuran],
  ),
  DhikrItem(
    id: 'v_sura_kahf',
    text: 'مَنْ قَرَأَ سُورَةَ الْكَهْفِ يَوْمَ الْجُمُعَةِ',
    subtitle: 'فضل سورة الكهف',
    description:
        'أضاء له من النور ما بين الجمعتين — وسورة الكهف هي نور لمن قرأها.',
    tags: <DhikrTag>[DhikrTag.virtueOfSuras, DhikrTag.virtueOfQuran],
  ),
  DhikrItem(
    id: 'v_sura_ikhlas',
    text: 'قُلْ هُوَ اللَّهُ أَحَدٌ',
    subtitle: 'فضل سورة الإخلاص',
    reference: 'الإخلاص',
    description:
        'تعدل ثلث القرآن — ومن قرأها عشر مرات بنى الله له بيتاً في الجنة.',
    tags: <DhikrTag>[DhikrTag.virtueOfSuras, DhikrTag.virtueOfQuran],
  ),
  DhikrItem(
    id: 'v_sura_mulk',
    text: 'تَبَارَكَ الَّذِي بِيَدِهِ الْمُلْكُ',
    subtitle: 'فضل سورة الملك',
    description:
        'المانعة من عذاب القبر — كان النبي ﷺ لا ينام حتى يقرأها.',
    tags: <DhikrTag>[DhikrTag.virtueOfSuras, DhikrTag.virtueOfQuran],
  ),
  DhikrItem(
    id: 'v_sura_kursi',
    text: 'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ',
    subtitle: 'فضل آية الكرسي',
    description:
        'سيدة آي القرآن — من قرأها دُبر كل صلاة لم يمنعه من دخول الجنة إلا '
        'الموت.',
    tags: <DhikrTag>[DhikrTag.virtueOfSuras, DhikrTag.virtueOfQuran],
  ),
];