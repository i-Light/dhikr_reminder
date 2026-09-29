import 'dart:math';

import 'package:dhikr_reminder/features/settings/application/dhikr_controller.dart';
import 'package:dhikr_reminder/features/settings/application/dhikr_reminder_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DhikrReminderScheduler.pickWeighted', () {
    test('never picks an entry muted to chance 0', () {
      final entries = [
        const DhikrEntry(id: 1, name: 'muted', chance: 0),
        const DhikrEntry(id: 2, name: 'loud', chance: 5),
      ];

      for (var seed = 0; seed < 50; seed++) {
        expect(
          DhikrReminderScheduler.pickWeighted(entries, Random(seed))?.id,
          2,
          reason: 'seed $seed picked a muted entry',
        );
      }
    });

    test('returns null when every entry is muted', () {
      final entries = [
        const DhikrEntry(id: 1, name: 'muted', chance: 0),
        const DhikrEntry(id: 2, name: 'also muted', chance: 0),
      ];

      expect(DhikrReminderScheduler.pickWeighted(entries, Random(1)), isNull);
    });

    test('returns null for an empty list', () {
      expect(DhikrReminderScheduler.pickWeighted([], Random(1)), isNull);
    });

    test('picks the only un-muted entry every time', () {
      final entries = [
        const DhikrEntry(id: 1, name: 'only one', chance: 1),
        const DhikrEntry(id: 2, name: 'muted', chance: 0),
      ];

      for (var seed = 0; seed < 50; seed++) {
        expect(
            DhikrReminderScheduler.pickWeighted(entries, Random(seed))?.id, 1);
      }
    });

    test('chance is a weight: 3x the chance lands roughly 3x as often', () {
      final entries = [
        const DhikrEntry(id: 1, name: 'light', chance: 1),
        const DhikrEntry(id: 2, name: 'heavy', chance: 3),
      ];

      final counts = <int, int>{1: 0, 2: 0};
      const rolls = 20000;
      for (var seed = 0; seed < rolls; seed++) {
        final picked =
            DhikrReminderScheduler.pickWeighted(entries, Random(seed));
        counts[picked!.id] = counts[picked.id]! + 1;
      }

      final ratio = counts[2]! / counts[1]!;
      // Loose enough that the fixed seed set can never make this flaky, tight
      // enough that a 50/50 pick would fail it.
      expect(ratio, inInclusiveRange(2.2, 3.8));
    });
  });

  group('DhikrReminderScheduler.pickReminder', () {
    final entries = [
      const DhikrEntry(id: 1, name: 'zero', chance: 0),
      const DhikrEntry(id: 2, name: 'low', chance: 1),
      const DhikrEntry(id: 3, name: 'max', chance: dhikrChanceMax),
    ];

    test('with chance off, every entry is equally likely, even chance 0', () {
      final counts = <int, int>{1: 0, 2: 0, 3: 0};
      for (var seed = 0; seed < 3000; seed++) {
        final picked = DhikrReminderScheduler.pickReminder(
          entries,
          Random(seed),
          useChance: false,
        );
        counts[picked!.id] = counts[picked.id]! + 1;
      }

      for (final count in counts.values) {
        expect(count, inInclusiveRange(800, 1200));
      }
    });

    test('with chance on, chance 0 is still never picked', () {
      for (var seed = 0; seed < 200; seed++) {
        expect(
          DhikrReminderScheduler.pickReminder(
            entries,
            Random(seed),
            useChance: true,
          )?.id,
          isNot(1),
        );
      }
    });

    test('with chance off and no entries, there is nothing to pick', () {
      expect(
        DhikrReminderScheduler.pickReminder([], Random(1), useChance: false),
        isNull,
      );
    });
  });

  group('ActiveDhikrReminder', () {
    test('counts up to the target and reports completion', () {
      const reminder = ActiveDhikrReminder(
        entry: DhikrEntry(id: 1, name: 'SubhanAllah', amount: 3),
      );
      expect(reminder.hasTarget, isTrue);
      expect(reminder.isComplete, isFalse);

      final done = reminder.copyWith(count: 3);
      expect(done.isComplete, isTrue);
    });

    test('an entry with no target counts up freely and never completes', () {
      const reminder = ActiveDhikrReminder(
        entry: DhikrEntry(id: 1, name: 'Allah', amount: 0),
      );
      expect(reminder.hasTarget, isFalse);
      expect(reminder.copyWith(count: 99).isComplete, isFalse);
    });
  });
}
