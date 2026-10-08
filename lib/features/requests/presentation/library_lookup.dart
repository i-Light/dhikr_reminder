import 'package:dhikr_reminder/core/navigation/shell_tab.dart';
import 'package:dhikr_reminder/features/library/application/library_controller.dart';
import 'package:dhikr_reminder/features/library/domain/arabic_text.dart';
import 'package:dhikr_reminder/features/library/domain/dhikr_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Brings the person to [item] in the library: the library page in front, the
/// search set to the first words of the dhikr, and its reminder panel open
/// when the dhikr can be a reminder.
///
/// Used by "Show it in the library" wherever a request leads to an entry.
void showInLibrary(WidgetRef ref, DhikrItem item) {
  final words = normalizeArabic(item.text).split(' ').take(5).join(' ');
  final library = ref.read(dhikrLibraryProvider.notifier)
    ..clearTags()
    ..updateQuery(words);
  if (item.isRemindable &&
      ref.read(dhikrLibraryProvider).expandedId != item.id) {
    library.toggleExpanded(item.id);
  }
  ref.read(shellTabProvider.notifier).show(ShellTab.library);
}
