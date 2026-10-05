import 'package:dhikr_reminder/features/settings/application/dhikr_reminder_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReminderPauseNotifier', () {
    test('starts unpaused', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(reminderPauseProvider), isNull);
    });

    test('pauseFor sets a resume time about that far ahead', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(reminderPauseProvider.notifier)
          .pauseFor(const Duration(hours: 1));

      final until = container.read(reminderPauseProvider)!;
      final away = until.difference(DateTime.now());
      expect(away, greaterThan(const Duration(minutes: 59)));
      expect(away, lessThanOrEqualTo(const Duration(hours: 1)));
    });

    test('resume clears the pause', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(reminderPauseProvider.notifier)
        ..pauseFor(const Duration(hours: 1));

      notifier.resume();

      expect(container.read(reminderPauseProvider), isNull);
    });

    test('lifts itself once the time is up', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(reminderPauseProvider.notifier)
          .pauseFor(const Duration(milliseconds: 30));

      await Future<void>.delayed(const Duration(milliseconds: 80));

      expect(container.read(reminderPauseProvider), isNull);
    });
  });
}
