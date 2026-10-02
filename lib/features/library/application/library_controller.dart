import 'dart:async';
import 'dart:developer' as developer;

import 'package:dhikr_reminder/features/library/data/dhikr_library.dart';
import 'package:dhikr_reminder/features/library/domain/dhikr_item.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Bounds and step for the library's text size, in logical pixels — what the
/// quick-settings popup's increase/decrease buttons move between, and what
/// the number in the middle of it shows.
///
/// The floor keeps a long ayah legible; the ceiling is where a short dhikr
/// starts to look like a headline rather than as reading. The step is small
/// enough that the number is a fine control on its own — no slider needed.
const double dhikrLibraryFontMin = 16;
const double dhikrLibraryFontMax = 40;
const double dhikrLibraryFontStep = 2;
const double dhikrLibraryFontDefault = 24;

/// Persisted keys — the two quick-settings choices are remembered across
/// launches. The search box and the tag filter deliberately are not: a
/// library that reopened showing only yesterday's filtered subset, with no
/// obvious reason on screen, reads as a bug rather than as remembered state.
const _showTashkeelPrefsKey = 'dhikr_reminder.library.showTashkeel';
const _fontSizePrefsKey = 'dhikr_reminder.library.fontSize';

/// What the library screen is showing right now: the search text, the tags
/// selected in the filter popup, and the two quick settings.
@immutable
class DhikrLibraryView {
  const DhikrLibraryView({
    this.query = '',
    this.selectedTags = const <DhikrTag>{},
    this.showTashkeel = true,
    this.fontSize = dhikrLibraryFontDefault,
  });

  final String query;

  /// An empty set means "no tag filter" — every entry shows. Otherwise an
  /// entry shows if it shares at least one tag with this set (see
  /// [DhikrItem.matchesTags]): selecting more tags widens the list, which is
  /// what a gallery of buttons invites you to expect.
  final Set<DhikrTag> selectedTags;

  /// Whether the dhikr text is rendered vocalised or through [stripTashkeel].
  final bool showTashkeel;

  /// Logical pixels for the dhikr text itself; the card's other type scales
  /// with it (see `DhikrLibraryCard`).
  final double fontSize;

  bool get hasTagFilter => selectedTags.isNotEmpty;

  DhikrLibraryView copyWith({
    String? query,
    Set<DhikrTag>? selectedTags,
    bool? showTashkeel,
    double? fontSize,
  }) {
    return DhikrLibraryView(
      query: query ?? this.query,
      selectedTags: selectedTags ?? this.selectedTags,
      showTashkeel: showTashkeel ?? this.showTashkeel,
      fontSize: fontSize ?? this.fontSize,
    );
  }
}

/// Owns the library screen's view state and remembers the two quick settings.
///
/// A `Notifier` so the screen, the quick-settings popup and the filter popup
/// all read the same source of truth — a toggle flipped in a popup repaints
/// the list behind it without anything being handed between them.
class DhikrLibraryNotifier extends Notifier<DhikrLibraryView> {
  @override
  DhikrLibraryView build() {
    unawaited(_loadPersisted());
    return const DhikrLibraryView();
  }

  /// Reads the two remembered quick settings and publishes them in one write,
  /// so there is never a frame where the size is the user's but the tashkeel
  /// choice is not. A failed read leaves the defaults standing; unlike the
  /// settings list, nothing here blocks on loading, so there is no `isLoaded`
  /// flag to raise.
  Future<void> _loadPersisted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final showTashkeel =
          prefs.getBool(_showTashkeelPrefsKey) ?? state.showTashkeel;
      final stored = prefs.getDouble(_fontSizePrefsKey);
      state = state.copyWith(
        showTashkeel: showTashkeel,
        fontSize: stored == null ? state.fontSize : _clampFont(stored),
      );
    } catch (error, stackTrace) {
      developer.log(
        'Failed to load the library view settings; keeping defaults.',
        name: 'dhikr_reminder.library',
        level: 900,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  void updateQuery(String query) => state = state.copyWith(query: query);

  void clearQuery() => state = state.copyWith(query: '');

  /// Adds [tag] to the selection, or removes it if it was already in.
  void toggleTag(DhikrTag tag) {
    final next = Set<DhikrTag>.of(state.selectedTags);
    if (!next.add(tag)) next.remove(tag);
    state = state.copyWith(selectedTags: next);
  }

  /// Drops every tag filter, back to "show everything".
  void clearTags() => state = state.copyWith(selectedTags: const <DhikrTag>{});

  Future<void> toggleTashkeel() async {
    final next = !state.showTashkeel;
    state = state.copyWith(showTashkeel: next);
    await _persist((prefs) => prefs.setBool(_showTashkeelPrefsKey, next));
  }

  /// Moves the text size one step, clamped at both ends. [direction] is `1`
  /// to grow and `-1` to shrink.
  Future<void> stepFontSize(int direction) async {
    final next = _clampFont(state.fontSize + dhikrLibraryFontStep * direction);
    if (next == state.fontSize) return;
    state = state.copyWith(fontSize: next);
    await _persist((prefs) => prefs.setDouble(_fontSizePrefsKey, next));
  }

  double _clampFont(double value) =>
      value.clamp(dhikrLibraryFontMin, dhikrLibraryFontMax);

  Future<void> _persist(
    Future<void> Function(SharedPreferences prefs) write,
  ) async {
    try {
      await write(await SharedPreferences.getInstance());
    } catch (error, stackTrace) {
      developer.log(
        'Failed to persist the library view settings.',
        name: 'dhikr_reminder.library',
        level: 900,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}

final dhikrLibraryProvider =
    NotifierProvider<DhikrLibraryNotifier, DhikrLibraryView>(
  DhikrLibraryNotifier.new,
);

/// The entries the screen should list for the current [DhikrLibraryView] —
/// the whole library narrowed by the search text and the tag filter.
///
/// A provider rather than a method on the screen, so the filtering happens
/// once per change of the view state instead of on every rebuild of the list.
final filteredDhikrProvider = Provider<List<DhikrItem>>((ref) {
  final view = ref.watch(dhikrLibraryProvider);
  return dhikrLibrary
      .where((item) =>
          item.matchesTags(view.selectedTags) && item.matchesQuery(view.query))
      .toList(growable: false);
});

