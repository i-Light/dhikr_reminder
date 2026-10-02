import 'package:dhikr_reminder/features/library/domain/dhikr_item.dart';

/// أدعية الأنبياء — the supplications the prophets themselves made, as the
/// Quran records them.
///
/// One section of `dhikrLibrary` (see `../dhikr_library.dart`). Each entry
/// carries both [DhikrTag.prophetsDuas] and [DhikrTag.quranicDuas]: every one
/// of these is quoted from the Quran, and the two tags answer different
/// questions — "whose dua is this?" and "is this from the Quran?".
const List<DhikrTag> _prophetQuran = <DhikrTag>[
  DhikrTag.prophetsDuas,
  DhikrTag.quranicDuas,
];

const List<DhikrItem> prophetsAdhkar = <DhikrItem>[
  DhikrItem(
    id: 'pr_adam',
    text:
        'رَبَّنَا ظَلَمْنَا أَنفُسَنَا وَإِن لَّمْ تَغْفِرْ لَنَا وَتَرْحَمْنَا '
        'لَنَكُونَنَّ مِنَ الْخَاسِرِينَ',
    subtitle: 'دعاء آدم عليه السلام',
    reference: 'الأعراف: ٢٣',
    tags: _prophetQuran,
  ),
  DhikrItem(
    id: 'pr_nuh',
    text:
        'رَبِّ اغْفِرْ لِي وَلِوَالِدَيَّ وَلِمَن دَخَلَ بَيْتِيَ مُؤْمِنًا '
        'وَلِلْمُؤْمِنِينَ وَالْمُؤْمِنَاتِ',
    subtitle: 'دعاء نوح عليه السلام',
    reference: 'نوح: ٢٨',
    tags: _prophetQuran,
  ),
  DhikrItem(
    id: 'pr_ibrahim',
    text:
        'رَبِّ اجْعَلْنِي مُقِيمَ الصَّلَاةِ وَمِن ذُرِّيَّتِي، رَبَّنَا '
        'وَتَقَبَّلْ دُعَاءِ',
    subtitle: 'دعاء إبراهيم عليه السلام',
    reference: 'إبراهيم: ٤٠',
    tags: _prophetQuran,
  ),
  DhikrItem(
    id: 'pr_musa',
    text:
        'رَبِّ اشْرَحْ لِي صَدْرِي، وَيَسِّرْ لِي أَمْرِي، وَاحْلُلْ عُقْدَةً مِّن '
        'لِّسَانِي، يَفْقَهُوا قَوْلِي',
    subtitle: 'دعاء موسى عليه السلام',
    reference: 'طه: ٢٥-٢٨',
    tags: _prophetQuran,
  ),
  DhikrItem(
    id: 'pr_yunus',
    text:
        'لَا إِلَٰهَ إِلَّا أَنتَ سُبْحَانَكَ إِنِّي كُنتُ مِنَ الظَّالِمِينَ',
    subtitle: 'دعاء يونس عليه السلام — لا يدعو بها مسلم في شيء إلا استُجيب له',
    reference: 'الأنبياء: ٨٧',
    tags: _prophetQuran,
  ),
  DhikrItem(
    id: 'pr_ayyub',
    text: 'رَبِّ إِنِّي مَسَّنِيَ الضُّرُّ وَأَنتَ أَرْحَمُ الرَّاحِمِينَ',
    subtitle: 'دعاء أيوب عليه السلام',
    reference: 'الأنبياء: ٨٣',
    tags: _prophetQuran,
  ),
  DhikrItem(
    id: 'pr_zakariya',
    text: 'رَبِّ لَا تَذَرْنِي فَرْدًا وَأَنتَ خَيْرُ الْوَارِثِينَ',
    subtitle: 'دعاء زكريا عليه السلام',
    reference: 'الأنبياء: ٨٩',
    tags: _prophetQuran,
  ),
  DhikrItem(
    id: 'pr_isa',
    text:
        'اللَّهُمَّ رَبَّنَا أَنزِلْ عَلَيْنَا مَائِدَةً مِّنَ السَّمَاءِ تَكُونُ '
        'لَنَا عِيدًا لِّأَوَّلِنَا وَآخِرِنَا وَآيَةً مِّنكَ',
    subtitle: 'دعاء عيسى عليه السلام',
    reference: 'المائدة: ١١٤',
    tags: _prophetQuran,
  ),
];