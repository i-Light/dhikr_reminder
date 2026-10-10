import 'dart:async';

import 'package:dhikr_reminder/core/storage/storage_guard.dart';
import 'package:dhikr_reminder/features/library/data/dhikr_library.dart';
import 'package:dhikr_reminder/features/library/domain/dhikr_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const favouritesPrefsKey = 'dhikr_reminder.library.favourites';

/// The library entries the person starred, oldest star first. That order is
/// also "my wird": the list a session reads through, in the order it was made.
///
/// Read from disk only when something first asks for it (the library page, a
/// session), never at startup.
class FavouritesNotifier extends Notifier<List<String>> {
  /// A star pressed while the saved list is still being read waits for it.
  Future<void> _ready = Future<void>.value();

  @override
  List<String> build() {
    _ready = _load();
    return const [];
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!ref.mounted) return;
      final saved = prefs.getStringList(favouritesPrefsKey) ?? const [];
      // An id from another release is brought to the entry it became, and one
      // the library no longer has is dropped, so a star never points at nothing.
      final ids = <String>[];
      for (final id in saved) {
        final item = libraryItemById(id);
        if (item != null && !ids.contains(item.id)) ids.add(item.id);
      }
      state = ids;
    } catch (_) {
      // No stars is a fine answer.
    }
  }

  /// Stars the entry [id], or takes its star off.
  Future<void> toggle(String id) async {
    await _ready;
    if (!ref.mounted) return;
    state = state.contains(id)
        ? [
            for (final f in state)
              if (f != id) f,
          ]
        : [...state, id];
    if (!StorageGuard.canWrite) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(favouritesPrefsKey, state);
    } catch (_) {
      // A star that was not remembered costs one tap after a restart.
    }
  }
}

final favouritesProvider = NotifierProvider<FavouritesNotifier, List<String>>(
  FavouritesNotifier.new,
);

/// The starred entries as library items, in the order they were starred.
final favouriteItemsProvider = Provider<List<DhikrItem>>((ref) {
  return [
    for (final id in ref.watch(favouritesProvider))
      if (libraryItemById(id) != null) libraryItemById(id)!,
  ];
});
