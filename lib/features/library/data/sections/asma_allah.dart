import 'package:dhikr_reminder/features/library/domain/dhikr_item.dart';

/// أسماء الله الحسنى — the 99 names.
///
/// One section of `dhikrLibrary` (see `../dhikr_library.dart`). Grouped ten
/// to an entry rather than one entry each: a library row is a block of text,
/// and ninety-nine one-line rows would be a wall to scroll rather than a
/// list to read. Search still finds an individual name — [DhikrItem.matches-
/// Query] matches anywhere in the text, not just at the start — so typing
/// «اللطيف» lands on the entry holding it.
const List<DhikrTag> _asma = <DhikrTag>[DhikrTag.asmaAllah];

const List<DhikrItem> asmaAllahAdhkar = <DhikrItem>[
  DhikrItem(
    id: 'as_intro',
    text:
        'وَلِلَّهِ الْأَسْمَاءُ الْحُسْنَىٰ فَادْعُوهُ بِهَا',
    subtitle: 'فضل أسماء الله الحسنى',
    reference: 'الأعراف: ١٨٠',
    description:
        'قال ﷺ: «إِنَّ لِلَّهِ تِسْعَةً وَتِسْعِينَ اسْمًا، مِائَةً إِلَّا '
        'وَاحِدًا، مَنْ أَحْصَاهَا دَخَلَ الْجَنَّةَ». وإحصاؤها: حفظها والعمل '
        'بمقتضاها والدعاء بها.',
    tags: <DhikrTag>[DhikrTag.asmaAllah, DhikrTag.virtueOfDua],
  ),
  DhikrItem(
    id: 'as_1',
    text:
        'الرَّحْمَٰنُ\nالرَّحِيمُ\nالْمَلِكُ\nالْقُدُّوسُ\nالسَّلَامُ\n'
        'الْمُؤْمِنُ\nالْمُهَيْمِنُ\nالْعَزِيزُ\nالْجَبَّارُ\nالْمُتَكَبِّرُ',
    subtitle: 'الأسماء الحسنى (١ – ١٠)',
    tags: _asma,
  ),
  DhikrItem(
    id: 'as_2',
    text:
        'الْخَالِقُ\nالْبَارِئُ\nالْمُصَوِّرُ\nالْغَفَّارُ\nالْقَهَّارُ\n'
        'الْوَهَّابُ\nالرَّزَّاقُ\nالْفَتَّاحُ\nالْعَلِيمُ\nالْقَابِضُ',
    subtitle: 'الأسماء الحسنى (١١ – ٢٠)',
    tags: _asma,
  ),
  DhikrItem(
    id: 'as_3',
    text:
        'الْبَاسِطُ\nالْخَافِضُ\nالرَّافِعُ\nالْمُعِزُّ\nالْمُذِلُّ\n'
        'السَّمِيعُ\nالْبَصِيرُ\nالْحَكَمُ\nالْعَدْلُ\nاللَّطِيفُ',
    subtitle: 'الأسماء الحسنى (٢١ – ٣٠)',
    tags: _asma,
  ),
  DhikrItem(
    id: 'as_4',
    text:
        'الْخَبِيرُ\nالْحَلِيمُ\nالْعَظِيمُ\nالْغَفُورُ\nالشَّكُورُ\n'
        'الْعَلِيُّ\nالْكَبِيرُ\nالْحَفِيظُ\nالْمُقِيتُ\nالْحَسِيبُ',
    subtitle: 'الأسماء الحسنى (٣١ – ٤٠)',
    tags: _asma,
  ),
  DhikrItem(
    id: 'as_5',
    text:
        'الْجَلِيلُ\nالْكَرِيمُ\nالرَّقِيبُ\nالْمُجِيبُ\nالْوَاسِعُ\n'
        'الْحَكِيمُ\nالْوَدُودُ\nالْمَجِيدُ\nالْبَاعِثُ\nالشَّهِيدُ',
    subtitle: 'الأسماء الحسنى (٤١ – ٥٠)',
    tags: _asma,
  ),
  DhikrItem(
    id: 'as_6',
    text:
        'الْحَقُّ\nالْوَكِيلُ\nالْقَوِيُّ\nالْمَتِينُ\nالْوَلِيُّ\n'
        'الْحَمِيدُ\nالْمُحْصِي\nالْمُبْدِئُ\nالْمُعِيدُ\nالْمُحْيِي',
    subtitle: 'الأسماء الحسنى (٥١ – ٦٠)',
    tags: _asma,
  ),
  DhikrItem(
    id: 'as_7',
    text:
        'الْمُمِيتُ\nالْحَيُّ\nالْقَيُّومُ\nالْوَاجِدُ\nالْمَاجِدُ\n'
        'الْوَاحِدُ\nالْأَحَدُ\nالصَّمَدُ\nالْقَادِرُ\nالْمُقْتَدِرُ',
    subtitle: 'الأسماء الحسنى (٦١ – ٧٠)',
    tags: _asma,
  ),
  DhikrItem(
    id: 'as_8',
    text:
        'الْمُقَدِّمُ\nالْمُؤَخِّرُ\nالْأَوَّلُ\nالْآخِرُ\nالظَّاهِرُ\n'
        'الْبَاطِنُ\nالْوَالِي\nالْمُتَعَالِي\nالْبَرُّ\nالتَّوَّابُ',
    subtitle: 'الأسماء الحسنى (٧١ – ٨٠)',
    tags: _asma,
  ),
  DhikrItem(
    id: 'as_9',
    text:
        'الْمُنْتَقِمُ\nالْعَفُوُّ\nالرَّءُوفُ\nمَالِكُ الْمُلْكِ\n'
        'ذُو الْجَلَالِ وَالْإِكْرَامِ\nالْمُقْسِطُ\nالْجَامِعُ\nالْغَنِيُّ\n'
        'الْمُغْنِي\nالْمَانِعُ',
    subtitle: 'الأسماء الحسنى (٨١ – ٩٠)',
    tags: _asma,
  ),
  DhikrItem(
    id: 'as_10',
    text:
        'الضَّارُّ\nالنَّافِعُ\nالنُّورُ\nالْهَادِي\nالْبَدِيعُ\n'
        'الْبَاقِي\nالْوَارِثُ\nالرَّشِيدُ\nالصَّبُورُ',
    subtitle: 'الأسماء الحسنى (٩١ – ٩٩)',
    description:
        'وسُئل ﷺ عن أسماء الله فذكرها، وقال: «مَنْ أَحْصَاهَا دَخَلَ الْجَنَّةَ». '
        'وزاد العلماء من كتاب الله أسماءً مثل: الرَّبُّ، وَالْإِلَٰهُ، '
        'وَالْأَعْلَى، وَنَحْوِهَا.',
    tags: _asma,
  ),
];