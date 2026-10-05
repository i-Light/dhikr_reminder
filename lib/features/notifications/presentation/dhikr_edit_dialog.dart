import 'package:dhikr_reminder/features/settings/application/dhikr_controller.dart';
import 'package:dhikr_reminder/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';

/// Repetition counts offered as one-tap shortcuts; any other number is one
/// stepper press away.
const dhikrAmountShortcuts = [1, 3, 7, 10, 33, 100];

/// Daily-goal shortcuts.
const dailyGoalShortcuts = [33, 100, 300, 500, 1000];

/// Asks for a dhikr's text, repetitions and (when the weighted option is on)
/// how often it comes up. Resolves to the edited entry, or null if cancelled.
Future<DhikrEntry?> showDhikrEditDialog(
  BuildContext context, {
  required DhikrEntry entry,
  required bool isNew,
  required bool showFrequency,
}) {
  return showDialog<DhikrEntry>(
    context: context,
    builder: (_) => DhikrEditDialog(
      entry: entry,
      isNew: isNew,
      showFrequency: showFrequency,
    ),
  );
}

class DhikrEditDialog extends StatefulWidget {
  const DhikrEditDialog({
    super.key,
    required this.entry,
    required this.isNew,
    required this.showFrequency,
  });

  final DhikrEntry entry;
  final bool isNew;
  final bool showFrequency;

  @override
  State<DhikrEditDialog> createState() => _DhikrEditDialogState();
}

class _DhikrEditDialogState extends State<DhikrEditDialog> {
  late final _name = TextEditingController(text: widget.entry.name);
  late int _amount = widget.entry.amount;
  late int _chance = widget.entry.chance;
  late int _goal = widget.entry.dailyGoal;
  bool _showError = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _showError = true);
      return;
    }
    Navigator.of(context).pop(
      widget.entry.copyWith(
        name: name,
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

    return AlertDialog(
      title: Text(widget.isNew ? l10n.notifNewTitle : l10n.notifEditTitle),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // The azkar are Arabic whatever the UI language is, so the field
              // is pinned right-to-left.
              TextField(
                key: const ValueKey('dhikr-name-field'),
                controller: _name,
                autofocus: widget.isNew,
                minLines: 3,
                maxLines: 8,
                textDirection: TextDirection.rtl,
                style: const TextStyle(
                  fontFamily: 'AliMeshref',
                  fontSize: 22,
                  height: 1.7,
                ),
                decoration: InputDecoration(
                  labelText: l10n.notifNameLabel,
                  errorText: _showError ? l10n.notifNameRequired : null,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) {
                  if (_showError) setState(() => _showError = false);
                },
              ),
              const SizedBox(height: 20),
              Text(l10n.notifAmountLabel, style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton.filledTonal(
                    onPressed: _amount > dhikrAmountMin
                        ? () => setState(() => _amount--)
                        : null,
                    icon: const Icon(Icons.remove),
                  ),
                  Expanded(
                    child: Text(
                      l10n.notifRepeatCount(_amount),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: _amount < dhikrAmountMax
                        ? () => setState(() => _amount++)
                        : null,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final shortcut in dhikrAmountShortcuts)
                    ChoiceChip(
                      label: Text('$shortcut'),
                      selected: _amount == shortcut,
                      onSelected: (_) => setState(() => _amount = shortcut),
                    ),
                ],
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
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final shortcut in dailyGoalShortcuts)
                      ChoiceChip(
                        label: Text('$shortcut'),
                        selected: _goal == shortcut,
                        onSelected: (_) => setState(() => _goal = shortcut),
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
                  onChanged: (value) => setState(() => _chance = value.round()),
                ),
                Text(
                  l10n.notifFrequencyHint,
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(onPressed: _save, child: Text(l10n.commonSave)),
      ],
    );
  }
}
