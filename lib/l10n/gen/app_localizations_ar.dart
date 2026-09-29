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
}
