import 'package:hijri/digits_converter.dart';
import 'package:hijri/hijri_calendar.dart';

/// [date] as a Hijri date line, from the Umm al-Qura calendar:
/// "الأحد ٢٢ ربيع الآخر ١٤٤٨ هـ" in Arabic, "Sunday 22 Rabi' al-Thani 1448 AH"
/// in English.
///
/// Computed from the device's own date, nothing is fetched. The package keeps
/// its language in a static, so it is set and read back within this one
/// synchronous call.
String formatHijriDate(DateTime date, {required bool arabic}) {
  final previous = HijriCalendar.language;
  try {
    HijriCalendar.language = arabic ? 'ar' : 'en';
    final hijri = HijriCalendar.fromDate(date);
    final day = arabic
        ? DigitsConverter.convertWesternNumberToEastern(hijri.hDay)
        : '${hijri.hDay}';
    final year = arabic
        ? DigitsConverter.convertWesternNumberToEastern(hijri.hYear)
        : '${hijri.hYear}';
    return arabic
        ? '${hijri.dayWeName} $day ${hijri.longMonthName} $year هـ'
        : '${hijri.dayWeName} $day ${hijri.longMonthName} $year AH';
  } finally {
    HijriCalendar.language = previous;
  }
}
