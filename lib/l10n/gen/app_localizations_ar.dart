// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'تذكير الأذكار';

  @override
  String get splashDescription =>
      'تذكير بالأذكار بيعيش في الـ tray وبيفكّرك بذكر الله.';

  @override
  String get homeSubtitle =>
      'هيطلع ذكر كل شوية دقايق — عدّه بضغطة وارجع لشغلك.';

  @override
  String get commonTestReminder => 'اظهار التذكير دلوقتي';

  @override
  String get settingsDhikrTitle => 'تعديل الأذكار';

  @override
  String get settingsDhikrSubtitle =>
      'غير كمية تكرار الأذكار، والعدد، وضيف، وشيل أذكار';

  @override
  String get settingsDhikrIntervalLabel => 'الفاصل الزمني للتذكير';

  @override
  String get settingsDhikrIntervalSubtitle =>
      'كل قد ايه يظهر تذكير الذكر، بالدقايق';

  @override
  String get settingsDhikrSoundLabel => 'الصوت';

  @override
  String get settingsDhikrSoundSubtitle => 'تشغيل صوت لما يظهر التذكير';

  @override
  String get settingsDhikrUseChanceLabel => 'نسبة الظهور';

  @override
  String get settingsDhikrUseChanceSubtitle =>
      'مقفول: كل الأذكار فرصتها واحدة. مفتوح: حدد كل ذكر يظهر قد ايه';

  @override
  String get settingsDhikrNameColumn => 'الذكر';

  @override
  String get settingsDhikrAmountColumn => 'العدد';

  @override
  String get settingsDhikrChanceColumn => 'نسبة الظهور';

  @override
  String get settingsDhikrChanceExplainer =>
      'الاحتمال هنا وزن وليس نسبة مئوية. الذكر عند 6 يظهر ضعف ما يظهر عند 3 — لا أكثر. إذا تساوت الأرقام تساوت الفرص، والصفر يعني أنه لن يظهر أبداً. ذكر واحد عند 1 مع إسكات البقية سيظهر في كل مرة، لأنه لا يوجد غيره للمقارنة.';

  @override
  String get settingsDhikrSaved => 'التغييرات الى اتعملت للأذكار اتحفظت.';

  @override
  String get commonAdd => 'إضافة';

  @override
  String get commonDelete => 'حذف';

  @override
  String get commonSave => 'حفظ';

  @override
  String get dhikrReminderTitle => 'تذكير باللَّه';

  @override
  String get dhikrReminderTouchEverywhereTip => 'أضغط فى اى مكان للعد';

  @override
  String get trayOpenApp => 'فتح التطبيق';

  @override
  String get trayNextDhikr => 'الذكر الجاي';

  @override
  String trayNextDhikrIn(String time) {
    return 'بعد $time';
  }

  @override
  String get trayNextDhikrPending => 'مستني الإعدادات';

  @override
  String get traySoundOn => 'الصوت شغال';

  @override
  String get traySoundOff => 'الصوت مقفول';

  @override
  String get trayQuit => 'إغلاق التطبيق';

  @override
  String get updateTitle => 'التحديثات';

  @override
  String get updateSubtitle => 'خلّي تذكير الأذكار محدّث دايماً';

  @override
  String updateVersion(String version) {
    return 'الإصدار $version';
  }

  @override
  String get updateNeverChecked => 'لسه ما اتفحصش';

  @override
  String get updateChecking => 'بيدوّر على تحديثات…';

  @override
  String get updateUpToDate => 'التطبيق محدّث';

  @override
  String updateLastChecked(String time) {
    return 'آخر فحص $time';
  }

  @override
  String updateAvailable(String version) {
    return 'الإصدار $version متاح';
  }

  @override
  String get updateAvailableManual =>
      'النسخة دي مش متسطّبة بالمثبّت، فمش هتقدر تحدّث نفسها. نزّل المثبّت الجديد من صفحة الإصدارات.';

  @override
  String get updateAvailableAutoOff =>
      'التحديث التلقائي مقفول. اضغط حدّث دلوقتي علشان تسطّبه.';

  @override
  String updateDownloading(String version) {
    return 'بينزّل الإصدار $version…';
  }

  @override
  String updateReady(String version) {
    return 'الإصدار $version جاهز للتسطيب';
  }

  @override
  String get updateReadyHint =>
      'هيتسطّب لوحده أول ما تقفل الشاشة دي ومايكونش فيه تذكير ظاهر.';

  @override
  String updateInstalling(String version) {
    return 'بيسطّب الإصدار $version…';
  }

  @override
  String get updateFailed => 'ماقدرناش نفحص التحديثات';

  @override
  String get updateFailedHint => 'اتأكد من الإنترنت. هيحاول تاني بعد شوية.';

  @override
  String get updateCheckButton => 'افحص التحديثات';

  @override
  String get updateInstallButton => 'حدّث دلوقتي';

  @override
  String get updateRestartButton => 'أعد التشغيل وحدّث';

  @override
  String get updateDownloadPageButton => 'افتح صفحة التنزيل';

  @override
  String get updateAutoLabel => 'التحديث التلقائي';

  @override
  String get updateAutoSubtitle =>
      'نزّل الإصدارات الجديدة فى الخلفية وسطّبها لما التطبيق يكون فاضى';

  @override
  String get navSettings => 'الإعدادات';

  @override
  String get navLibrary => 'موسوعة الأذكار';

  @override
  String get libraryTitle => 'موسوعة الأذكار';

  @override
  String get librarySubtitle =>
      'ابحث في كل الأذكار والأدعية وصفّيها بالمجموعة.';

  @override
  String get librarySearchHint => 'ابحث في الأذكار والأدعية…';

  @override
  String get librarySearchClear => 'مسح البحث';

  @override
  String libraryResultsCount(int count) {
    return '$count ذكر';
  }

  @override
  String get libraryEmptyTitle => 'مفيش حاجة تطابق بحثك';

  @override
  String get libraryEmptyHint => 'جرّب كلمة تانية، أو امسح الفلاتر.';

  @override
  String get libraryEmptyAction => 'امسح الفلاتر';

  @override
  String get libraryQuickSettings => 'إعدادات سريعة';

  @override
  String get libraryTashkeelLabel => 'إظهار التشكيل';

  @override
  String get libraryTashkeelSubtitle => 'عرض الحركات على الحروف';

  @override
  String get libraryFontSizeLabel => 'حجم الخط';

  @override
  String get libraryFontIncrease => 'تكبير الخط';

  @override
  String get libraryFontDecrease => 'تصغير الخط';

  @override
  String libraryFontValue(int size) {
    return '$size بكسل';
  }

  @override
  String get libraryClose => 'قفل';

  @override
  String get libraryFilterTitle => 'تصفية بالمجموعة';

  @override
  String get libraryFilterSubtitle =>
      'اختر مجموعة أو أكتر، ولما تسيب الكل بيظهر';

  @override
  String get libraryFilterAll => 'الكل';

  @override
  String get libraryFilterClear => 'امسح الفلاتر';

  @override
  String libraryFilterCount(int count) {
    return '$count مختارة';
  }

  @override
  String get tagMorning => 'أذكار الصباح';

  @override
  String get tagEvening => 'أذكار المساء';

  @override
  String get tagAfterPrayer => 'أذكار بعد الصلاة';

  @override
  String get tagTasabih => 'تسابيح';

  @override
  String get tagSleep => 'أذكار النوم';

  @override
  String get tagWaking => 'أذكار الاستيقاظ';

  @override
  String get tagPrayer => 'أذكار الصلاة';

  @override
  String get tagJawamiDuas => 'جوامع الدعاء';

  @override
  String get tagPropheticDuas => 'أدعية نبوية';

  @override
  String get tagQuranicDuas => 'الأدعية القرآنية';

  @override
  String get tagProphetsDuas => 'أدعية الأنبياء';

  @override
  String get tagMisc => 'أذكار متفرقة';

  @override
  String get tagAdhan => 'أذكار الآذان';

  @override
  String get tagMosque => 'أذكار المسجد';

  @override
  String get tagWudu => 'أذكار الوضوء';

  @override
  String get tagHome => 'أذكار المنزل';

  @override
  String get tagKhalaa => 'أذكار الخلاء';

  @override
  String get tagFood => 'أذكار الطعام';

  @override
  String get tagHajjUmrah => 'أذكار الحج والعمرة';

  @override
  String get tagKhatmQuran => 'دعاء ختم القرآن الكريم';

  @override
  String get tagVirtueOfDua => 'فضل الدعاء';

  @override
  String get tagVirtueOfDhikr => 'فضل الذكر';

  @override
  String get tagVirtueOfSuras => 'فضل السور';

  @override
  String get tagVirtueOfQuran => 'فضل القرآن';

  @override
  String get tagAsmaAllah => 'أسماء الله الحسنى';

  @override
  String get tagDuasForDeceased => 'أدعية للميّت';

  @override
  String get tagRuqyah => 'الرُّقية الشرعية';
}
