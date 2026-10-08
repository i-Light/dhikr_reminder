import 'package:dhikr_reminder/core/theme/gradient_text.dart';
import 'package:flutter/material.dart';

/// A [Card] whose body can be folded away, with the title row as the control.
///
/// Taken from the gratovo project's card of the same name. Written rather than
/// reached for from Material's [ExpansionTile] for two reasons: the header can
/// carry its own controls without fighting the tile's tap target, and the
/// collapsed state can say something ([collapsedSummary]), because a card that
/// folds to nothing but its title gives no reason to open it.
///
/// The whole header is the toggle, not just the arrow: a 24-pixel target for
/// something that is opened and closed constantly is needless precision work.
class CollapsibleCard extends StatefulWidget {
  const CollapsibleCard({
    super.key,
    required this.title,
    required this.child,
    this.initiallyExpanded = true,
    this.subtitle,
    this.headerTrailing,
    this.collapsedSummary,
    this.leadingIcon,
  });

  final String title;

  /// Always visible, under the title: what the section is for.
  final String? subtitle;

  /// Controls that belong to the section and stay reachable in both states.
  /// Kept out of the tap target, so pressing one does not also fold the card.
  final Widget? headerTrailing;

  /// Shown INSTEAD of [child] while collapsed. The point of a collapsed card is
  /// to take less room, not to become opaque: a short answer here is what makes
  /// folding it a saving rather than a loss.
  final Widget? collapsedSummary;

  /// Shown at the start of the header, before the title.
  final Widget? leadingIcon;

  final Widget child;

  /// Cards that carry the page's main content start open; cards that are a
  /// tool you reach for start closed.
  final bool initiallyExpanded;

  @override
  State<CollapsibleCard> createState() => _CollapsibleCardState();
}

class _CollapsibleCardState extends State<CollapsibleCard> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  key: const ValueKey('collapsible-header'),
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Padding(
                    padding:
                        const EdgeInsetsDirectional.fromSTEB(12, 12, 8, 12),
                    child: Row(
                      children: [
                        // Turns rather than swapping icons, so the change reads
                        // as one thing opening. The arrow points along the
                        // reading direction when closed and down when open.
                        AnimatedRotation(
                          turns: _expanded ? (rtl ? -0.25 : 0.25) : 0,
                          duration: const Duration(milliseconds: 150),
                          child: Icon(
                            Icons.chevron_right,
                            textDirection: Directionality.of(context),
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (widget.leadingIcon != null) ...[
                          widget.leadingIcon!,
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GradientText(
                                widget.title,
                                style: theme.textTheme.titleMedium,
                              ),
                              if (widget.subtitle != null)
                                Text(
                                  widget.subtitle!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (widget.headerTrailing != null)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: widget.headerTrailing,
                ),
            ],
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 16, 16),
              child: widget.child,
            )
          else if (widget.collapsedSummary != null)
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 14),
              child: DefaultTextStyle.merge(
                style: theme.textTheme.bodySmall!.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                child: widget.collapsedSummary!,
              ),
            ),
        ],
      ),
    );
  }
}
