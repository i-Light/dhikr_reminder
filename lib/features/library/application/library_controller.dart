import 'dart:async';
import 'dart:developer' as developer;

import 'package:dhikr_reminder/features/library/data/dhikr_library.dart';
import 'package:dhikr_reminder/features/library/domain/dhikr_item.dart';
import 'package:dhikr_reminder/features/settings/application/dhikr_controller.dart';
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
const _showArabicPrefsKey = 'dhikr_reminder.library.showArabic';
const _fontSizePrefsKey = 'dhikr_reminder.library.fontSize';
const _hideAddedPrefsKey = 'dhikr_reminder.library.hideAdded';

/// What the library screen is showing right now: the search text, the tags
/// selected in the filter popup, the quick settings, and whether the cards
/// offer to add a dhikr to the reminders.
@immutable
class DhikrLibraryView {
  const DhikrLibraryView({
    this.query = '',
    this.selectedTags = const <DhikrTag>{},
    this.showTashkeel = true,
    this.showArabic = true,
    this.fontSize = dhikrLibraryFontDefault,
    this.expandedId,
    this.showAddHint = false,
    this.hideAdded = false,
    this.showAddUi = false,
    this.addUiFromHint = false,
  });

  final String query;

  /// An empty set means "no tag filter" — every entry shows. Otherwise an
  /// entry shows if it shares at least one tag with this set (see
  /// [DhikrItem.matchesTags]): selecting more tags widens the list, which is
  /// what a gallery of buttons invites you to expect.
  final Set<DhikrTag> selectedTags;

  /// Whether the dhikr text is rendered vocalised or through [stripTashkeel].
  final bool showTashkeel;

  /// Whether the Arabic text is shown on the library cards. Off, a card shows
  /// only its transliteration (a dhikr that has none keeps its Arabic). The
  /// reminder cards have a switch of their own, on the notifications page.
  final bool showArabic;

  /// Logical pixels for the dhikr text itself; the card's other type scales
  /// with it (see `DhikrLibraryCard`).
  final double fontSize;

  /// The entry whose reminder panel is open, if any. One at a time, so the
  /// list stays calm.
  final String? expandedId;

  /// Whether to show the "pick the dhikr you want to add" banner: set when the
  /// notifications page sends the person here to add one.
  final bool showAddHint;

  /// Leave out the dhikr that are already in the person's reminders.
  final bool hideAdded;

  /// Whether each card offers its "add to reminders" button and panel. Off,
  /// the cards stay compact: the library is then only being read. Turned on
  /// with the bell in the header, or by the notifications page sending the
  /// person here to add one.
  final bool showAddUi;

  /// Whether [showAddUi] was switched on by that visit (and so goes off with
  /// it) rather than by the person's own press of the bell.
  final bool addUiFromHint;

  bool get hasTagFilter => selectedTags.isNotEmpty;

  /// How many filters narrow the list: the groups picked, and the one that
  /// hides what is already added.
  int get activeFilterCount => selectedTags.length + (hideAdded ? 1 : 0);

  DhikrLibraryView copyWith({
    String? query,
    Set<DhikrTag>? selectedTags,
    bool? showTashkeel,
    bool? showArabic,
    double? fontSize,
    String? expandedId,
    bool clearExpanded = false,
    bool? showAddHint,
    bool? hideAdded,
    bool? showAddUi,
    bool? addUiFromHint,
  }) {
    return DhikrLibraryView(
      query: query ?? this.query,
      selectedTags: selectedTags ?? this.selectedTags,
      showTashkeel: showTashkeel ?? this.showTashkeel,
      showArabic: showArabic ?? this.showArabic,
      fontSize: fontSize ?? this.fontSize,
      expandedId: clearExpanded ? null : (expandedId ?? this.expandedId),
      showAddHint: showAddHint ?? this.showAddHint,
      hideAdded: hideAdded ?? this.hideAdded,
      showAddUi: showAddUi ?? this.showAddUi,
      addUiFromHint: addUiFromHint ?? this.addUiFromHint,
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

  /// Reads the remembered quick settings and publishes them in one write, so
  /// there is never a frame where the size is the user's but the tashkeel
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
        showArabic: prefs.getBool(_showArabicPrefsKey) ?? state.showArabic,
        fontSize: stored == null ? state.fontSize : _clampFont(stored),
        hideAdded: prefs.getBool(_hideAddedPrefsKey) ?? state.hideAdded,
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

  /// Opens the reminder panel of the entry [id], or closes it if it is open.
  void toggleExpanded(String id) {
    state = state.expandedId == id
        ? state.copyWith(clearExpanded: true)
        : state.copyWith(expandedId: id);
  }

  /// Shows or hides the "pick the dhikr you want to add" banner. Showing it
  /// also switches the add buttons on, for as long as the visit lasts (see
  /// [endVisit]); hiding it only takes the banner away, so closing the banner
  /// does not take the buttons it was about away from under the person.
  void setAddHint(bool show) {
    if (show) {
      state = state.copyWith(
        showAddHint: true,
        showAddUi: true,
        addUiFromHint: !state.showAddUi || state.addUiFromHint,
      );
    } else if (state.showAddHint) {
      state = state.copyWith(showAddHint: false);
    }
  }

  /// The person has left the library: the banner goes, and so do the add
  /// buttons if only the visit had switched them on.
  void endVisit() {
    state = state.copyWith(
      showAddHint: false,
      showAddUi: state.showAddUi && !state.addUiFromHint,
      addUiFromHint: false,
      clearExpanded: state.addUiFromHint,
    );
  }

  /// The bell: show the add buttons, or put them away and keep the cards compact.
  void toggleAddUi() {
    final next = !state.showAddUi;
    state = state.copyWith(
      showAddUi: next,
      addUiFromHint: false,
      clearExpanded: !next,
    );
  }

  Future<void> toggleHideAdded() async {
    final next = !state.hideAdded;
    state = state.copyWith(hideAdded: next);
    await _persist((prefs) => prefs.setBool(_hideAddedPrefsKey, next));
  }

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

  Future<void> toggleArabic() async {
    final next = !state.showArabic;
    state = state.copyWith(showArabic: next);
    await _persist((prefs) => prefs.setBool(_showArabicPrefsKey, next));
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
/// the whole library narrowed by the search text, the tag filter and, when it
/// is on, the one that leaves out what is already in the reminders.
///
/// A provider rather than a method on the screen, so the filtering happens
/// once per change of the view state instead of on every rebuild of the list.
final filteredDhikrProvider = Provider<List<DhikrItem>>((ref) {
  final view = ref.watch(dhikrLibraryProvider);
  // Only watched while it matters, so adding a dhikr does not refilter a list
  // that is not hiding anything.
  final added =
      view.hideAdded ? ref.watch(addedLibraryIdsProvider) : const <String>{};
  return dhikrLibrary
      .where((item) =>
          !added.contains(item.id) &&
          item.matchesTags(view.selectedTags) &&
          item.matchesQuery(view.query))
      .toList(growable: false);
});
