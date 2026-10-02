import 'package:dhikr_reminder/features/library/application/library_controller.dart';
import 'package:dhikr_reminder/features/library/domain/dhikr_item.dart';
import 'package:flutter/material.dart';

/// The face the dhikr itself renders in — the one Arabic font this app ships
/// (`assets/fonts/PanoramaNaskhMobile-Regular.otf`, family `Naksh`), and the
/// same one the reminder card uses. A Naskh face is what makes a vocalised
/// ayah read as scripture rather than as UI text, which is the whole point of
/// the library. The entry's other type (subtitle, reference, description)
/// stays on the theme's face, so the dhikr is the only thing set apart.
const String _dhikrFontFamily = 'Naksh';

/// Line height for the dhikr text. Generous on purpose: tashkeel sits above
/// and below the letter shapes, and at Naskh's own leading the marks of one
/// line collide with the next — the taller line box is what keeps a
/// vocalised paragraph readable at every size the quick settings allow.
const double _dhikrLineHeight = 2.0;

/// One entry in the library list: the optional lead-in, the dhikr, the
/// optional source reference and the optional note — in that order, as a
/// column.
///
/// A plain [StatelessWidget] taking its [view] as a parameter rather than a
/// [ConsumerWidget] reading the provider itself, so the whole list rebuilds
/// once per change of the text size or the tashkeel toggle instead of each row
/// subscribing on its own.
class DhikrLibraryCard extends StatelessWidget {
  const DhikrLibraryCard({super.key, required this.item, required this.view});

  final DhikrItem item;
  final DhikrLibraryView view;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    // The tashkeel toggle is a formatting change only — see [stripTashkeel].
    final text = view.showTashkeel ? item.text : stripTashkeel(item.text);

    final dhikrStyle = TextStyle(
      fontFamily: _dhikrFontFamily,
      fontSize: view.fontSize,
      height: _dhikrLineHeight,
      color: colors.onSurface,
    );

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
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
            Text(
              text,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              style: dhikrStyle,
            ),
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
          ],
        ),
      ),
    );
  }
}