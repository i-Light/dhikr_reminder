import 'package:dhikr_reminder/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';

/// Repetition counts offered as one-tap shortcuts; any other number is one
/// stepper press away.
const dhikrAmountShortcuts = [1, 3, 7, 10, 33, 100];

/// A repetition count with minus and plus buttons around it and, below, the
/// usual counts as chips. Used wherever someone says how many times a dhikr is
/// said: when adding it from the library and when editing it.
class AmountStepper extends StatelessWidget {
  const AmountStepper({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.shortcuts = dhikrAmountShortcuts,
  });

  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final List<int> shortcuts;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            IconButton.filledTonal(
              onPressed: value > min ? () => onChanged(value - 1) : null,
              icon: const Icon(Icons.remove),
            ),
            Expanded(
              child: Text(
                l10n.notifRepeatCount(value),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
            ),
            IconButton.filledTonal(
              onPressed: value < max ? () => onChanged(value + 1) : null,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final shortcut in shortcuts)
              if (shortcut >= min && shortcut <= max)
                ChoiceChip(
                  label: Text('$shortcut'),
                  selected: value == shortcut,
                  onSelected: (_) => onChanged(shortcut),
                ),
          ],
        ),
      ],
    );
  }
}
