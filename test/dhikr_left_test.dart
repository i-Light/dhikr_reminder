import 'package:dhikr_reminder/features/settings/application/dhikr_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('how many are left', () {
    test('a round counts down, and starts again once it is said', () {
      const entry = DhikrEntry(id: 1, name: 'x', amount: 33);
      expect(entry.left(0), 33);
      expect(entry.left(1), 32);
      expect(entry.left(32), 1);
      expect(entry.left(33), 33);
      expect(entry.left(36), 30);
    });

    test('a dhikr said once always has one left to say', () {
      const entry = DhikrEntry(id: 1, name: 'x');
      expect(entry.left(0), 1);
      expect(entry.left(7), 1);
    });

    test('a daily goal counts down to zero and stays there', () {
      const entry = DhikrEntry(id: 1, name: 'x', amount: 33, dailyGoal: 100);
      expect(entry.left(0), 100);
      expect(entry.left(42), 58);
      expect(entry.left(100), 0);
      expect(entry.left(140), 0);
    });
  });

  group('the short name', () {
    test('is the Arabic unless the app shows transliterations', () {
      const entry = DhikrEntry(id: 1, name: 'سبحان الله', libraryId: 'nope');
      expect(entry.shortName(transliterated: false), 'سبحان الله');
      // No transliteration to show: the Arabic stays.
      expect(entry.shortName(transliterated: true), 'سبحان الله');
    });
  });
}
