import 'dart:math';

import 'package:dhikr_reminder/core/widgets/amount_stepper.dart';
import 'package:dhikr_reminder/features/settings/application/dhikr_controller.dart';
import 'package:dhikr_reminder/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';

/// Daily-goal shortcuts.
const dailyGoalShortcuts = [1, 10, 33, 100, 300, 500, 1000];

/// How much of the screen the editor takes, each way.
const _dialogScreenFraction = 0.9;

/// The widest the editor grows, so on a big window it is not a wall.
const _dialogMaxWidth = 720.0;

/// Shows a dhikr's text (which cannot be changed here: dhikr come from the
/// library) and asks for its repetitions, its daily goal and, when the weighted
/// option is on, how often it comes up. Resolves to the edited entry, or null
/// if cancelled.
Future<DhikrEntry?> showDhikrEditDialog(
  BuildContext context, {
  required DhikrEntry entry,
  required bool showFrequency,
}) {
  return showDialog<DhikrEntry>(
    context: context,
    builder: (_) => DhikrEditDialog(entry: entry, showFrequency: showFrequency),
  );
}

/// The editor: 90% of the screen high and wide (up to a limit), with the title
/// and the buttons held in place and the middle scrolling, so every control is
/// reachable on a small phone and nothing is cut off by the keyboard or the
/// screen's edge.
class DhikrEditDialog extends StatefulWidget {
  const DhikrEditDialog({
    super.key,
    required this.entry,
    required this.showFrequency,
  });

  final DhikrEntry entry;
  final bool showFrequency;

  @override
  State<DhikrEditDialog> createState() => _DhikrEditDialogState();
}

class _DhikrEditDialogState extends State<DhikrEditDialog> {
  late int _amount = widget.entry.amount;
  late int _chance = widget.entry.chance;
  late int _goal = widget.entry.dailyGoal;

  void _save() {
    Navigator.of(context).pop(
      widget.entry.copyWith(
        amount: _amount,
        chance: _chance,
        dailyGoal: _goal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final size = MediaQuery.sizeOf(context);
    final height = size.height * _dialogScreenFraction;
    final width = min(size.width * _dialogScreenFraction, _dialogMaxWidth);

    return Dialog(
      key: const ValueKey('dhikr-edit-dialog'),
      insetPadding: EdgeInsets.symmetric(
        horizontal: (size.width - width) / 2,
        vertical: (size.height - height) / 2,
      ),
      child: SizedBox(
        key: const ValueKey('dhikr-edit-box'),
        width: width,
        height: height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(24, 20, 24, 8),
              child: Text(
                l10n.notifEditTitle,
                style: theme.textTheme.headlineSmall,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                key: const ValueKey('dhikr-edit-scroll'),
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // The azkar are Arabic whatever the UI language is, so the
                    // text is pinned right-to-left.
                    Container(
                      key: const ValueKey('dhikr-name-preview'),
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.entry.name,
                        textDirection: TextDirection.rtl,
                        style: const TextStyle(
                          fontFamily: 'NotoSansArabic',
                          fontSize: 20,
                          height: 1.7,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      l10n.notifAmountLabel,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    AmountStepper(
                      value: _amount,
                      min: dhikrAmountMin,
                      max: dhikrAmountMax,
                      onChanged: (value) => setState(() => _amount = value),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      key: const ValueKey('dhikr-goal-switch'),
                      contentPadding: EdgeInsets.zero,
                      secondary: const Icon(Icons.flag_outlined),
                      title: Text(l10n.notifGoalTitle),
                      subtitle: Text(l10n.notifGoalSubtitle),
                      value: _goal > 0,
                      onChanged: (on) =>
                          setState(() => _goal = on ? dailyGoalDefault : 0),
                    ),
                    if (_goal > 0) ...[
                      Row(
                        children: [
                          IconButton.filledTonal(
                            onPressed: _goal > dailyGoalMin
                                ? () => setState(
                                      () => _goal = (_goal - 10).clamp(
                                        dailyGoalMin,
                                        dailyGoalMax,
                                      ),
                                    )
                                : null,
                            icon: const Icon(Icons.remove),
                          ),
                          Expanded(
                            child: Text(
                              l10n.notifGoalCount(_goal),
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                          IconButton.filledTonal(
                            onPressed: _goal < dailyGoalMax
                                ? () => setState(
                                      () => _goal = (_goal + 10).clamp(
                                        dailyGoalMin,
                                        dailyGoalMax,
                                      ),
                                    )
                                : null,
                            icon: const Icon(Icons.add),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        key: const ValueKey('goal-shortcuts'),
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          for (final shortcut in dailyGoalShortcuts)
                            ChoiceChip(
                              label: Text('$shortcut'),
                              selected: _goal == shortcut,
                              onSelected: (_) =>
                                  setState(() => _goal = shortcut),
                            ),
                        ],
                      ),
                    ],
                    if (widget.showFrequency) ...[
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.notifFrequencyLabel,
                              style: theme.textTheme.titleSmall,
                            ),
                          ),
                          Text(
                            _chance == 0
                                ? l10n.notifFrequencyNever
                                : l10n.notifFrequencyValue(_chance),
                            style: theme.textTheme.labelLarge,
                          ),
                        ],
                      ),
                      Slider(
                        value: _chance.toDouble(),
                        min: dhikrChanceMin.toDouble(),
                        max: dhikrChanceMax.toDouble(),
                        divisions: dhikrChanceMax - dhikrChanceMin,
                        onChanged: (value) =>
                            setState(() => _chance = value.round()),
                      ),
                      Text(
                        l10n.notifFrequencyHint,
                        style:
                            theme.textTheme.bodySmall?.copyWith(color: muted),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                spacing: 8,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.commonCancel),
                  ),
                  FilledButton(
                    onPressed: _save,
                    child: Text(l10n.commonSave),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
