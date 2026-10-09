import 'package:dhikr_reminder/core/date/hijri_date.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 1 Muharram 1447 AH began on 26 June 2025 (Umm al-Qura).
  final newYear = DateTime(2025, 6, 26);

  test('formats an Arabic Hijri date with Eastern digits', () {
    final text = formatHijriDate(newYear, arabic: true);
    expect(text, contains('١٤٤٧'));
    expect(text, contains('محرم'));
    expect(text, endsWith('هـ'));
  });

  test('formats an English Hijri date', () {
    final text = formatHijriDate(newYear, arabic: false);
    expect(text, contains('1447'));
    expect(text, endsWith('AH'));
  });

  test('does not leave the package language switched', () {
    formatHijriDate(newYear, arabic: true);
    expect(formatHijriDate(newYear, arabic: false), isNot(contains('محرم')));
  });

  test('gives an empty line, not an error, for a date the calendar lacks', () {
    expect(formatHijriDate(DateTime(1100), arabic: true), isEmpty);
    expect(formatHijriDate(DateTime(3000), arabic: false), isEmpty);
    // And the language is still put back.
    expect(formatHijriDate(newYear, arabic: false), isNot(contains('محرم')));
  });
}
