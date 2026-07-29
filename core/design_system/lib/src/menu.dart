/// core/design_system/lib/src/menu.dart
///
/// Accessible anchored menus shared by every dropdown and overflow menu in
/// the app, built on Material 3 [MenuAnchor]. One consistent behavior
/// contract everywhere:
///  * clicking anywhere outside an open menu dismisses it immediately, and
///    the outside click is consumed - so a stray click can never trigger
///    another control and only one menu can ever be open at a time,
///  * Esc closes the open menu and returns focus to its trigger,
///  * full keyboard support: the trigger is focusable, Enter/Space or
///    Arrow-Up/Down open the menu, arrow keys move through items (the
///    selected item is focused first), Enter activates,
///  * triggers expose button semantics, the expanded state, and the
///    current value to screen readers.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'motion.dart';
import 'theme.dart';
import 'tokens.dart';

/// One selectable option in a [VnSelect].
@immutable
class VnSelectOption<T> {
  const VnSelectOption({
    required this.value,
    required this.label,
    this.enabled = true,
  });

  final T value;
  final String label;
  final bool enabled;
}

/// Visual treatment of the [VnSelect] trigger.
enum VnSelectVariant {
  /// Looks like the app's input fields (fill, border, optional floating
  /// label). Use standalone in forms.
  field,

  /// Transparent trigger for embedding inside an existing styled
  /// container (e.g. the notebook picker's toolbar chip).
  bare,
}

/// A dropdown select with the standard desktop combo-box interaction
/// model. Replaces [DropdownButton]/[DropdownButtonFormField] app-wide so
/// dismissal, keyboard access, and styling can never drift per screen.
class VnSelect<T> extends StatefulWidget {
  const VnSelect({
    required this.options,
    required this.value,
    required this.onSelected,
    this.enabled = true,
    this.variant = VnSelectVariant.field,
    this.label,
    this.tooltip,
    this.semanticLabel,
    this.textStyle,
    this.dense = false,
    super.key,
  });

  final List<VnSelectOption<T>> options;

  /// Currently selected value (shown on the trigger with a check mark in
  /// the open menu).
  final T value;

  final ValueChanged<T> onSelected;
  final bool enabled;
  final VnSelectVariant variant;

  /// Floating label for the [VnSelectVariant.field] variant.
  final String? label;

  /// Hover tooltip for the trigger.
  final String? tooltip;

  /// Screen-reader label; falls back to [label] / [tooltip].
  final String? semanticLabel;

  /// Style for the selected-value text on the trigger.
  final TextStyle? textStyle;

  /// Compact paddings for dense form rows (field variant).
  final bool dense;

  @override
  State<VnSelect<T>> createState() => _VnSelectState<T>();
}

class _VnSelectState<T> extends State<VnSelect<T>> {
  final MenuController _menu = MenuController();
  final FocusNode _triggerFocus = FocusNode(debugLabel: 'VnSelect trigger');
  bool _focused = false;

  @override
  void dispose() {
    _triggerFocus.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_menu.isOpen) {
      _menu.close();
    } else {
      _menu.open();
    }
  }

  void _openMenu() {
    if (widget.enabled && !_menu.isOpen) _menu.open();
  }

  VnSelectOption<T>? get _selected {
    for (final option in widget.options) {
      if (option.value == widget.value) return option;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = VnTheme.of(context).tokens;
    final textTheme = Theme.of(context).textTheme;
    final selected = _selected;
    final valueStyle = widget.textStyle ??
        textTheme.bodyMedium?.copyWith(
          color: widget.enabled ? tokens.textPrimary : tokens.textMuted,
        );

    return MenuAnchor(
      controller: _menu,
      // Outside clicks close the menu AND are consumed, so they can never
      // trigger whatever sits underneath (and no second menu can open
      // while this one is up). Esc dismissal is built into the menu.
      consumeOutsideTap: true,
      crossAxisUnconstrained: false,
      onOpen: () {
        if (mounted) setState(() {});
      },
      onClose: () {
        if (!mounted) return;
        setState(() {});
        // Keyboard users keep their place: focus returns to the trigger.
        _triggerFocus.requestFocus();
      },
      menuChildren: [
        for (final option in widget.options)
          MenuItemButton(
            // Arrow-key traversal starts from the current selection.
            autofocus: option.value == widget.value,
            onPressed: option.enabled
                ? () => widget.onSelected(option.value)
                : null,
            trailingIcon: option.value == widget.value
                ? Icon(Icons.check, size: 16, color: tokens.accent)
                : null,
            child: Text(option.label, overflow: TextOverflow.ellipsis),
          ),
      ],
      builder: (context, controller, child) =>
          _buildTrigger(context, controller.isOpen, selected, valueStyle),
    );
  }

  Widget _buildTrigger(
    BuildContext context,
    bool isOpen,
    VnSelectOption<T>? selected,
    TextStyle? valueStyle,
  ) {
    final tokens = VnTheme.of(context).tokens;

    final row = Row(
      children: [
        Expanded(
          child: Text(
            selected?.label ?? '',
            style: valueStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        AnimatedRotation(
          turns: isOpen ? 0.5 : 0,
          duration: vnMotionDuration(context, VnMotion.fast),
          child: Icon(
            Icons.arrow_drop_down,
            size: 20,
            color: widget.enabled ? tokens.textSecondary : tokens.textMuted,
          ),
        ),
      ],
    );

    Widget trigger;
    switch (widget.variant) {
      case VnSelectVariant.bare:
        trigger = InkWell(
          focusNode: _triggerFocus,
          canRequestFocus: widget.enabled,
          onTap: widget.enabled ? _toggle : null,
          onFocusChange: (focused) => setState(() => _focused = focused),
          borderRadius: BorderRadius.circular(VnRadius.sm),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: VnSpacing.x1,
              vertical: VnSpacing.x1,
            ),
            child: row,
          ),
        );
      case VnSelectVariant.field:
        trigger = InkWell(
          focusNode: _triggerFocus,
          canRequestFocus: widget.enabled,
          onTap: widget.enabled ? _toggle : null,
          onFocusChange: (focused) => setState(() => _focused = focused),
          borderRadius: BorderRadius.circular(VnRadius.md),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: widget.label,
              enabled: widget.enabled,
              isDense: widget.dense,
              contentPadding: widget.dense
                  ? const EdgeInsets.symmetric(
                      horizontal: VnSpacing.x3,
                      vertical: VnSpacing.x2,
                    )
                  : null,
            ),
            isFocused: _focused || isOpen,
            isEmpty: selected == null,
            child: row,
          ),
        );
    }

    trigger = Semantics(
      button: true,
      enabled: widget.enabled,
      expanded: isOpen,
      label: widget.semanticLabel ?? widget.label ?? widget.tooltip,
      value: selected?.label,
      onTap: widget.enabled ? _toggle : null,
      child: trigger,
    );

    if (widget.tooltip case final tooltip?) {
      trigger = Tooltip(message: tooltip, child: trigger);
    }

    // Standard combo-box keys: Arrow-Up/Down (and Alt+Down) open the menu
    // from the focused trigger. Enter/Space activation comes from InkWell.
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.arrowDown): _openMenu,
        const SingleActivator(LogicalKeyboardKey.arrowUp): _openMenu,
        const SingleActivator(LogicalKeyboardKey.arrowDown, alt: true):
            _openMenu,
      },
      child: trigger,
    );
  }
}

/// One action in a [VnOverflowMenuButton].
@immutable
class VnMenuAction {
  const VnMenuAction({
    required this.label,
    required this.onSelected,
    this.icon,
    this.enabled = true,
    this.destructive = false,
  });

  final String label;
  final VoidCallback onSelected;
  final IconData? icon;
  final bool enabled;

  /// Renders in the danger color (delete-style actions).
  final bool destructive;
}

/// Icon-button overflow menu (the "three-dot" menu). Replaces
/// [PopupMenuButton] so overflow menus share the [VnSelect] behavior
/// contract: outside-click dismissal (consumed), Esc, keyboard traversal,
/// and focus restoration to the trigger.
class VnOverflowMenuButton extends StatefulWidget {
  const VnOverflowMenuButton({
    required this.tooltip,
    required this.actions,
    this.icon = Icons.more_vert,
    this.iconSize = 20,
    this.iconColor,
    this.dense = false,
    super.key,
  });

  final String tooltip;
  final List<VnMenuAction> actions;
  final IconData icon;
  final double iconSize;
  final Color? iconColor;

  /// Compact hit target for tight toolbar rows.
  final bool dense;

  @override
  State<VnOverflowMenuButton> createState() => _VnOverflowMenuButtonState();
}

class _VnOverflowMenuButtonState extends State<VnOverflowMenuButton> {
  final MenuController _menu = MenuController();
  final FocusNode _buttonFocus =
      FocusNode(debugLabel: 'VnOverflowMenuButton');

  @override
  void dispose() {
    _buttonFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = VnTheme.of(context).tokens;
    return MenuAnchor(
      controller: _menu,
      consumeOutsideTap: true,
      onClose: () {
        if (mounted) _buttonFocus.requestFocus();
      },
      menuChildren: [
        for (final action in widget.actions)
          MenuItemButton(
            onPressed: action.enabled ? action.onSelected : null,
            leadingIcon: action.icon == null
                ? null
                : Icon(
                    action.icon,
                    size: 18,
                    color: !action.enabled
                        ? tokens.textMuted
                        : action.destructive
                            ? tokens.danger
                            : tokens.textSecondary,
                  ),
            child: Text(
              action.label,
              style: action.destructive && action.enabled
                  ? TextStyle(color: tokens.danger)
                  : null,
            ),
          ),
      ],
      builder: (context, controller, child) => IconButton(
        focusNode: _buttonFocus,
        tooltip: widget.tooltip,
        visualDensity: widget.dense ? VisualDensity.compact : null,
        constraints: widget.dense
            ? const BoxConstraints(minWidth: 32, minHeight: 32)
            : null,
        padding: widget.dense ? EdgeInsets.zero : null,
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
        icon: Icon(
          widget.icon,
          size: widget.iconSize,
          color: widget.iconColor ?? tokens.textMuted,
        ),
      ),
    );
  }
}
