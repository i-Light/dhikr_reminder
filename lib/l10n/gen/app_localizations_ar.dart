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
}
