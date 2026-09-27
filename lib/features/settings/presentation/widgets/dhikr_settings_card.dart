import 'package:dhikr_reminder/core/constants/app_colors.dart';
import 'package:dhikr_reminder/core/toast/app_toast.dart';
import 'package:dhikr_reminder/core/widgets/collapsible_card.dart';
import 'package:dhikr_reminder/features/settings/application/dhikr_controller.dart';
import 'package:dhikr_reminder/l10n/gen/app_localizations.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How tall the azkar list can grow before it scrolls instead of pushing the
/// rest of the settings page down — roughly four and a half rows.
const _listMaxHeight = 560.0;

class DhikrCard extends ConsumerStatefulWidget {
  const DhikrCard({super.key});

  @override
  ConsumerState<DhikrCard> createState() => _DhikrCardState();
}

class _DhikrCardState extends ConsumerState<DhikrCard> {
  List<DhikrEntry>? _local;
  int? _localInterval;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final settings = ref.watch(dhikrSettingsProvider);
    // The draft is seeded from the provider exactly once, and only once the
    // saved settings have actually come back from disk. Latching earlier
    // captured the seed defaults, and the Save button would then write those
    // straight back over the user's real entries and interval.
    if (settings.isLoaded) {
      _local ??= settings.entries;
      _localInterval ??= settings.intervalMinutes;
    }
    final local = _local ?? settings.entries;
    final interval = _localInterval ?? settings.intervalMinutes;

    void updateEntry(int index, DhikrEntry entry) {
      setState(() {
        _local = [...local]..[index] = entry;
      });
    }

    void deleteEntry(int index) {
      setState(() {
        _local = [...local]..removeAt(index);
      });
    }

    void addEntry() {
      final id = ref.read(dhikrSettingsProvider.notifier).allocateId();
      setState(() {
        _local = [...local, DhikrEntry(id: id, name: '')];
      });
    }

    final headerStyle = theme.textTheme.labelLarge?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return CollapsibleCard(
      title: l10n.settingsDhikrTitle,
      subtitle: l10n.settingsDhikrSubtitle,
      gradientBackground: true,
      child: Column(
        spacing: 24,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            spacing: 16,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(width: 24),
              Icon(Icons.timer_outlined, color: headerStyle?.color),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.settingsDhikrIntervalLabel,
                      style: theme.textTheme.bodyMedium,
                    ),
                    Text(
                      l10n.settingsDhikrIntervalSubtitle,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              _CounterField(
                value: interval,
                min: dhikrReminderIntervalMin,
                max: dhikrReminderIntervalMax,
                semanticsLabel: l10n.settingsDhikrIntervalLabel,
                onChanged: (value) => setState(() => _localInterval = value),
              ),
            ],
          ),
          const Divider(),
          Row(
            children: [
              const SizedBox(width: 44),
              Expanded(
                child: Row(
                  spacing: 16,
                  children: [
                    Icon(Icons.message, color: headerStyle?.color),
                    Text(
                      '${l10n.settingsDhikrNameColumn}  -------',
                      style: headerStyle,
                      textAlign: TextAlign.center,
                    )
                  ],
                ),
              ),
              SizedBox(
                width: 150,
                child: Row(spacing: 16, children: [
                  Icon(Icons.numbers, color: headerStyle?.color),
                  Text(
                    l10n.settingsDhikrAmountColumn,
                    style: headerStyle,
                    textAlign: TextAlign.center,
                  )
                ]),
              ),
              SizedBox(
                width: 150,
                child: Row(spacing: 16, children: [
                  // A scale icon, not a percent sign: the number is a weight
                  // relative to the other entries, and a "%" was quietly
                  // promising a probability this has never computed.
                  Icon(Icons.balance, color: headerStyle?.color),
                  Text(
                    l10n.settingsDhikrChanceColumn,
                    style: headerStyle,
                    textAlign: TextAlign.center,
                  )
                ]),
              ),
            ],
          ),
          // Spelled out rather than left to the column header, because
          // "chance" reads as a percentage to everyone who has not been told
          // otherwise, and the difference shows up the first time someone sets
          // one entry to 1 and wonders why it still appears constantly.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              const SizedBox(width: 32),
              Icon(
                Icons.info_outline,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              Expanded(
                child: Text(
                  l10n.settingsDhikrChanceExplainer,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: _listMaxHeight),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: local.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _DhikrRow(
                key: ValueKey(local[i].id),
                entry: local[i],
                onChanged: (entry) => updateEntry(i, entry),
                onDelete: () => deleteEntry(i),
              ),
            ),
          ),
          Row(
            spacing: 20,
            mainAxisSize: MainAxisSize.max,
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: addEntry,
                  icon: const Icon(Icons.add),
                  label: Text(l10n.commonAdd),
                ),
              ),
              Expanded(
                child: FilledButton.icon(
                  // Disabled until the saved settings are in hand, so there
                  // is no window where Save would persist the seed defaults.
                  onPressed: settings.isLoaded
                      ? () async {
                          final notifier =
                              ref.read(dhikrSettingsProvider.notifier);
                          await notifier.updateEntries(local);
                          await notifier.updateInterval(interval);
                          if (!context.mounted) return;
                          AppToast.success(context, l10n.settingsDhikrSaved);
                        }
                      : null,
                  icon: const Icon(Icons.save),
                  label: Text(l10n.commonSave),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DhikrRow extends StatelessWidget {
  const _DhikrRow({
    super.key,
    required this.entry,
    required this.onChanged,
    required this.onDelete,
  });

  final DhikrEntry entry;
  final ValueChanged<DhikrEntry> onChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Chance 0 means this dhikr is excluded from the reminder rotation
    // entirely (see DhikrReminderScheduler.pickWeighted) — dimming the name
    // and amount reads that back at a glance, without needing to check the
    // number itself. The chance field and delete button stay at full
    // opacity: they're exactly what someone would reach for to turn it back
    // on or remove it.
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.close),
          color: AppColors.accent,
          tooltip: l10n.commonDelete,
          visualDensity: VisualDensity.compact,
          onPressed: onDelete,
        ),
        Expanded(
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: entry.chance == 0 ? 0.45 : 1,
            child: Row(
              children: [
                Expanded(
                  child: _DhikrNameField(
                    name: entry.name,
                    onChanged: (name) => onChanged(entry.copyWith(name: name)),
                  ),
                ),
                const SizedBox(width: 12),
                _CounterField(
                  value: entry.amount,
                  min: dhikrAmountMin,
                  max: dhikrAmountMax,
                  semanticsLabel: '${entry.name} amount',
                  onChanged: (value) =>
                      onChanged(entry.copyWith(amount: value)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        _CounterField(
          value: entry.chance,
          min: dhikrChanceMin,
          max: dhikrChanceMax,
          semanticsLabel: '${entry.name} chance',
          onChanged: (value) => onChanged(entry.copyWith(chance: value)),
        ),
      ],
    );
  }
}

/// The dhikr's name, editable in place. Keeps its own controller in sync
/// with [name] the same way `_CounterField` does — only overwritten when the
/// incoming value actually differs from what's typed, so a live edit is
/// never clobbered mid-keystroke by the row's own `onChanged` round-trip.
class _DhikrNameField extends StatefulWidget {
  const _DhikrNameField({required this.name, required this.onChanged});

  final String name;
  final ValueChanged<String> onChanged;

  @override
  State<_DhikrNameField> createState() => _DhikrNameFieldState();
}

class _DhikrNameFieldState extends State<_DhikrNameField> {
  late final _controller = TextEditingController(text: widget.name);

  @override
  void didUpdateWidget(_DhikrNameField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.name != widget.name && _controller.text != widget.name) {
      _controller.text = widget.name;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      // Pinned RTL rather than left to resolve from the app's locale: the
      // azkar are Arabic whatever language the UI is set to (the seed list
      // says as much), so an English UI would otherwise put the caret on the
      // wrong side of the one field on this page that is never English.
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.right,
      decoration: const InputDecoration(
        isDense: true,
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      ),
    );
  }
}

/// A single-number counter box: typed like a text field, spun like a wheel —
/// same interaction model as `TimecodeField`'s segments (mouse wheel and
/// arrow keys bump the value, wrapping at both ends), generalized to one
/// value with an arbitrary `[min, max]` range instead of three fixed-width
/// h:mm:ss segments.
class _CounterField extends StatefulWidget {
  const _CounterField({
    required this.value,
    required this.max,
    this.min = 0,
    required this.semanticsLabel,
    required this.onChanged,
  });

  final int value;
  final int min;
  final int max;
  final String semanticsLabel;
  final ValueChanged<int> onChanged;

  @override
  State<_CounterField> createState() => _CounterFieldState();
}

class _CounterFieldState extends State<_CounterField> {
  late final _controller = TextEditingController(text: '${widget.value}');
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(_CounterField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value &&
        int.tryParse(_controller.text) != widget.value) {
      _controller.text = '${widget.value}';
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) return;
    // Left blank or unparsable on blur: settle back to the last known value
    // rather than saving a hole in the field.
    final parsed = int.tryParse(_controller.text);
    if (parsed == null) {
      _controller.text = '${widget.value}';
      return;
    }
    _commit(parsed);
  }

  void _commit(int value) {
    final clamped = value.clamp(widget.min, widget.max);
    if (_controller.text != '$clamped') _controller.text = '$clamped';
    if (clamped != widget.value) widget.onChanged(clamped);
  }

  void _bump(int delta) {
    final current = int.tryParse(_controller.text) ?? widget.value;
    final span = widget.max - widget.min + 1;
    final next = (current - widget.min + delta) % span;
    _commit((next < 0 ? next + span : next) + widget.min);
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    final dy = event.scrollDelta.dy;
    if (dy == 0) return;
    GestureBinding.instance.pointerSignalResolver.register(
      event,
      (_) => _bump(dy < 0 ? 1 : -1),
    );
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      _bump(1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _bump(-1);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Listener(
        onPointerSignal: _onPointerSignal,
        child: Focus(
          onKeyEvent: _onKey,
          canRequestFocus: false,
          skipTraversal: true,
          child: Semantics(
            label: widget.semanticsLabel,
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _MaxValueFormatter(widget.max),
              ],
              onTap: () => _controller.selection = TextSelection(
                baseOffset: 0,
                extentOffset: _controller.text.length,
              ),
              onSubmitted: (value) => _commit(int.tryParse(value) ?? 0),
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 4, vertical: 12),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Rejects a keystroke that would push the field's value above [max], same
/// "never let something out of range land in the box" rule as
/// `TimecodeField`'s `_SegmentFormatter`.
class _MaxValueFormatter extends TextInputFormatter {
  const _MaxValueFormatter(this.max);

  final int max;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;
    final parsed = int.tryParse(text);
    if (parsed == null) return oldValue;
    return parsed > max ? oldValue : newValue;
  }
}
