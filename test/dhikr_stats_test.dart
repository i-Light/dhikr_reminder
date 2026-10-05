import 'package:dhikr_reminder/features/settings/application/dhikr_controller.dart';
import 'package:dhikr_reminder/features/stats/dhikr_stats.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

ProviderContainer _container(DateTime Function() clock) {
  final container = ProviderContainer(overrides: [
    dhikrStatsClockProvider.overrideWithValue(clock),
  ]);
  addTearDown(container.dispose);
  return container;
}

Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  test('dhikrDayKey is a sortable yyyy-mm-dd', () {
    expect(dhikrDayKey(DateTime(2026, 3, 7)), '2026-03-07');
  });

  test('every tap adds to the session and to that dhikr for today', () {
    SharedPreferences.setMockInitialValues({});
    final container = _container(() => DateTime(2026, 10, 5, 9));
    container.read(dhikrStatsProvider.notifier)
      ..recordTap(1)
      ..recordTap(1)
      ..recordTap(2);

    final stats = container.read(dhikrStatsProvider);
    expect(stats.session, 3);
    expect(stats.todayFor(1), 2);
    expect(stats.todayFor(2), 1);
    expect(stats.todayFor(99), 0);
    expect(stats.today, 3);
  });

  test("today's counts are remembered across a restart, the session's is not",
      () async {
    SharedPreferences.setMockInitialValues({});
    final first = _container(() => DateTime(2026, 10, 5, 9));
    first.read(dhikrStatsProvider.notifier)
      ..recordTap(1)
      ..recordTap(1)
      ..recordTap(2);
    await _settle();

    final second = _container(() => DateTime(2026, 10, 5, 18));
    second.read(dhikrStatsProvider);
    await _settle();

    final stats = second.read(dhikrStatsProvider);
    expect(stats.session, 0);
    expect(stats.todayFor(1), 2);
    expect(stats.todayFor(2), 1);
  });

  test('a new day starts the daily counts over', () async {
    SharedPreferences.setMockInitialValues({
      'dhikr_reminder.stats.day': '2026-10-04',
      'dhikr_reminder.stats.todayByDhikr': '{"1":40}',
    });
    final container = _container(() => DateTime(2026, 10, 5, 9));
    container.read(dhikrStatsProvider);
    await _settle();

    expect(container.read(dhikrStatsProvider).today, 0);
  });

  test('midnight passing while the app is open rolls the day over', () {
    SharedPreferences.setMockInitialValues({});
    var now = DateTime(2026, 10, 5, 23, 59);
    final container = _container(() => now);
    final notifier = container.read(dhikrStatsProvider.notifier)..recordTap(1);

    now = DateTime(2026, 10, 6, 0, 1);
    notifier.recordTap(1);

    final stats = container.read(dhikrStatsProvider);
    expect(stats.session, 2);
    expect(stats.todayFor(1), 1);
  });

  group('DhikrEntry.dailyGoal', () {
    test('is off by default', () {
      expect(const DhikrEntry(id: 1, name: 'x').dailyGoal, 0);
    });

    test('survives being saved and loaded', () {
      const entry = DhikrEntry(id: 1, name: 'x', dailyGoal: 300);

      final loaded = DhikrEntry.fromJson(entry.toJson());

      expect(loaded.dailyGoal, 300);
    });

    test('an entry saved before goals existed loads with no goal', () {
      final loaded = DhikrEntry.fromJson({'id': 1, 'name': 'x', 'amount': 3});

      expect(loaded.dailyGoal, 0);
    });

    test('is clamped on load and kept by copyWith', () {
      final loaded = DhikrEntry.fromJson(
        {'id': 1, 'name': 'x', 'dailyGoal': dailyGoalMax * 5},
      );

      expect(loaded.dailyGoal, dailyGoalMax);
      expect(loaded.copyWith(name: 'y').dailyGoal, dailyGoalMax);
      expect(loaded.copyWith(dailyGoal: 0).dailyGoal, 0);
    });
  });
}
