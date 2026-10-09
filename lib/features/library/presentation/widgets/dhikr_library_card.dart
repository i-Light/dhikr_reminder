import 'package:dhikr_reminder/features/library/application/library_controller.dart';
import 'package:dhikr_reminder/features/library/data/dhikr_library.dart';
import 'package:dhikr_reminder/features/library/domain/dhikr_display.dart';
import 'package:dhikr_reminder/features/library/domain/dhikr_item.dart';
import 'package:dhikr_reminder/features/library/presentation/widgets/reminder_panel.dart';
import 'package:dhikr_reminder/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';

/// The face the dhikr itself renders in: the app's default Arabic font
/// (`assets/fonts/NotoSansArabic-Variable.ttf`, family `NotoSansArabic`), and the same one the
/// reminder card uses. A Naskh-style face is what makes an ayah read as
/// scripture rather than as UI text, which is the whole point of the library.
/// The entry's other type (subtitle, reference, description) stays on the
/// theme's face, so the dhikr is the only thing set apart.
const String _dhikrFontFamily = 'NotoSansArabic';

/// Line height for the dhikr text. Generous on purpose: tashkeel sits above
/// and below the letter shapes, and at Naskh's own leading the marks of one
/// line collide with the next. The taller line box is what keeps a vowelled
/// paragraph readable at every size the quick settings allow.
const double _dhikrLineHeight = 2.0;

/// The transliteration under the Arabic is this much of the Arabic's size, kept
/// between the two bounds so it stays readable at the smallest text size and
/// does not shout at the largest. Alone (the Arabic is switched off) it is the
/// dhikr itself and gets [_aloneRatio] of the size instead.
const double _transliterationRatio = 0.6;
const double _aloneRatio = 0.85;
const double _transliterationMin = 13;
const double _transliterationMax = 24;
const double _aloneMax = 34;

/// One entry in the library list: the optional lead-in, the dhikr, the
/// optional source reference and the optional note, in that order, as a
/// column, and under them the reminder button.
///
/// The button opens a panel that is hidden until it is pressed (see
/// [ReminderPanel]): choose how many times and add the dhikr to the reminders,
/// or, for one that is already there, see that it is and change or remove it.
/// Neither is there while [DhikrLibraryView.showAddUi] is off: the card is then
/// just the dhikr, and as compact as it can be.
///
/// A plain [StatelessWidget] taking its [view] as a parameter rather than a
/// [ConsumerWidget] reading the provider itself, so the whole list rebuilds
/// once per change of the text size or the tashkeel toggle instead of each row
/// subscribing on its own. Only the panel, which exists for one card at a
/// time, watches the saved reminders.
class DhikrLibraryCard extends StatelessWidget {
  const DhikrLibraryCard({
    super.key,
    required this.item,
    required this.view,
    this.showTransliteration = false,
    this.isAdded = false,
    this.onToggleReminder,
  });

  final DhikrItem item;
  final DhikrLibraryView view;

  /// Whether to put the dhikr's transliteration under its Arabic (see
  /// `showTransliterationProvider`). A plain parameter, like [view], so the
  /// list rebuilds once rather than each card subscribing on its own.
  final bool showTransliteration;

  /// Whether the dhikr is already in the person's reminders.
  final bool isAdded;

  /// Opens or closes the reminder panel. Null in places that only show the
  /// entry.
  final VoidCallback? onToggleReminder;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final addUi = view.showAddUi;
    final expanded = addUi && view.expandedId == item.id;
    final showRow = item.count > 1 ||
        (addUi &&
            (item.isRemindable || item.count > 0) &&
            onToggleReminder != null);

    // The tashkeel toggle is a formatting change only, see [stripTashkeel].
    final text = view.showTashkeel ? item.text : stripTashkeel(item.text);

    final display = resolveDhikrDisplay(
      arabic: text,
      transliteration: libraryTransliteration(item.id),
      showTransliteration: showTransliteration,
      showArabic: view.showArabic,
    );

    final dhikrStyle = TextStyle(
      fontFamily: _dhikrFontFamily,
      fontSize: view.fontSize,
      height: _dhikrLineHeight,
      color: colors.onSurface,
    );
    // Under the Arabic the transliteration is a note on it; alone it is the
    // dhikr, so it is bigger and in the full text color.
    final withArabic = display.hasArabic;
    final transliterationStyle = TextStyle(
      fontSize:
          (view.fontSize * (withArabic ? _transliterationRatio : _aloneRatio))
              .clamp(_transliterationMin,
                  withArabic ? _transliterationMax : _aloneMax),
      height: 1.5,
      color: withArabic ? colors.onSurfaceVariant : colors.onSurface,
    );

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (item.subtitle != null) ...[
              Text(
                item.subtitle!,
                // The lead-in is the one line that says *when* the dhikr is
                // said, so it is the one line allowed the brand color.
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
            ],
            if (display.hasArabic)
              Text(
                display.arabic!,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                style: dhikrStyle,
              ),
            if (display.hasTransliteration) ...[
              if (display.hasArabic) const SizedBox(height: 8),
              // Latin letters read left to right whatever the app's language,
              // and are left-aligned, so the two lines sit on opposite sides
              // of the card the way a bilingual page does.
              Text(
                display.transliteration!,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.left,
                style: transliterationStyle,
              ),
            ],
            if (item.hasReference) ...[
              const SizedBox(height: 8),
              Text(
                '[${item.reference}]',
                // Its own line and its own direction, so the square brackets
                // are the RTL pair rather than a mirrored one mid-paragraph.
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
            if (item.description != null) ...[
              const SizedBox(height: 16),
              Divider(height: 1, color: colors.outlineVariant),
              const SizedBox(height: 12),
              Text(
                item.description!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.7,
                ),
              ),
            ],
            if (showRow) const SizedBox(height: 10),
            if (showRow)
              Row(
                children: [
                  if (item.count > 1)
                    _CountChip(label: l10n.notifRepeatCount(item.count)),
                  const Spacer(),
                  if (addUi && item.isRemindable && onToggleReminder != null)
                    TextButton.icon(
                      key: ValueKey('reminder-button-${item.id}'),
                      onPressed: onToggleReminder,
                      icon: Icon(
                        isAdded
                            ? Icons.notifications_active
                            : Icons.add_alert_outlined,
                      ),
                      label: Text(
                        isAdded
                            ? l10n.libraryAddedButton
                            : l10n.libraryAddButton,
                      ),
                    )
                  else if (addUi && !item.isRemindable && item.count > 0)
                    Flexible(
                      child: Text(
                        l10n.libraryReadOnlyNote,
                        textAlign: TextAlign.end,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: expanded && item.isRemindable
                  ? Padding(
                      padding: const EdgeInsets.only(top: 6, bottom: 6),
                      child: ReminderPanel(
                        key: ValueKey('reminder-panel-${item.id}'),
                        item: item,
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}

/// The small pill that says how many times a dhikr is said.
class _CountChip extends StatelessWidget {
  const _CountChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 4,
          children: [
            Icon(
              Icons.repeat,
              size: 14,
              color: theme.colorScheme.onPrimaryContainer,
            ),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
