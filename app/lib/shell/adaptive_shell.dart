/// app/lib/shell/adaptive_shell.dart
///
/// Adaptive navigation chrome: bottom NavigationBar on narrow layouts,
/// NavigationRail on wide layouts. Also:
///  * keeps the offline enrichment queue processor alive app-wide,
///  * shows the enrichment status in the toolbar (always discoverable, on
///    every tab),
///  * owns the app-wide shortcuts: Ctrl+N (add words), Ctrl+F (focus the
///    search bar, from any tab), Ctrl+/ (shortcut cheat sheet), and
///    Ctrl+1..6 (switch sections, top-row or numpad digits).
///
/// Owning shortcuts here (instead of inside individual screens) is what
/// makes them work consistently: the shell wraps every tab, the navigation
/// rail, and the app bar, so key events reach these bindings no matter
/// which widget currently has keyboard focus.
///
/// Adding words happens through the notebook tab's inline capture field or
/// the Ctrl+N quick-add dialog; there is deliberately no toolbar button
/// for it.
library;

import 'dart:async';

import 'package:core_design_system/core_design_system.dart';
import 'package:feature_enrich/feature_enrich.dart';
import 'package:feature_notebook/feature_notebook.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../router.dart';
import 'quick_add_dialog.dart';
import 'shortcut_cheatsheet_dialog.dart';

const double _kRailBreakpoint = 640;

class _Destination {
  const _Destination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// Order must match the branch order in app/lib/router.dart.
const List<_Destination> _destinations = [
  _Destination(
    label: 'Notebook',
    icon: Icons.auto_stories_outlined,
    selectedIcon: Icons.auto_stories,
  ),
  _Destination(
    label: 'Quiz',
    // fact_check reads as a checklist/exam sheet - clearly distinct
    // from the Help section's question-mark icon.
    icon: Icons.fact_check_outlined,
    selectedIcon: Icons.fact_check,
  ),
  _Destination(
    label: 'Favorites',
    icon: Icons.star_border,
    selectedIcon: Icons.star,
  ),
  _Destination(
    label: 'Help',
    icon: Icons.help_outline,
    selectedIcon: Icons.help,
  ),
  _Destination(
    label: 'About',
    icon: Icons.info_outline,
    selectedIcon: Icons.info,
  ),
  _Destination(
    label: 'Settings',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
  ),
];

/// Branch indexes (see [_destinations] order).
const int _kNotebookBranch = 0;

/// Branches that contain a word list with a search bar.
const Set<int> _kSearchableBranches = {0, 2};

/// Ctrl+1..6 tab switching: top-row digits AND numpad digits (desktop
/// keyboards report them as different logical keys). Position maps to
/// [_destinations] index.
const List<LogicalKeyboardKey> _digitKeys = [
  LogicalKeyboardKey.digit1,
  LogicalKeyboardKey.digit2,
  LogicalKeyboardKey.digit3,
  LogicalKeyboardKey.digit4,
  LogicalKeyboardKey.digit5,
  LogicalKeyboardKey.digit6,
];
const List<LogicalKeyboardKey> _numpadKeys = [
  LogicalKeyboardKey.numpad1,
  LogicalKeyboardKey.numpad2,
  LogicalKeyboardKey.numpad3,
  LogicalKeyboardKey.numpad4,
  LogicalKeyboardKey.numpad5,
  LogicalKeyboardKey.numpad6,
];

class AdaptiveShell extends ConsumerWidget {
  const AdaptiveShell({required this.shell, super.key});

  final StatefulNavigationShell shell;

  void _goBranch(int index) {
    shell.goBranch(index, initialLocation: index == shell.currentIndex);
    // Remember the last visited section across launches (restored via
    // createRouter's initialLocation in main.dart). Fire-and-forget:
    // navigation must never wait on disk.
    unawaited(
      SharedPreferences.getInstance().then(
        (prefs) => prefs.setString(kLastRouteKey, kShellRoutePaths[index]),
      ),
    );
  }

  /// App-wide Ctrl+F. The coordinator notifies whichever word list screen
  /// is visible; from a tab without a search bar we jump to the notebook
  /// first and focus its search field on the next frame.
  void _focusSearch(WidgetRef ref) {
    final coordinator = ref.read(searchFocusCoordinatorProvider);
    if (_kSearchableBranches.contains(shell.currentIndex)) {
      coordinator.requestSearchFocus();
    } else {
      _goBranch(_kNotebookBranch);
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => coordinator.requestSearchFocus(),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keep-alive: the queue processor retries pending AI enrichments in the
    // background regardless of which tab is visible.
    ref.watch(enrichmentQueueControllerProvider);

    final wide = MediaQuery.sizeOf(context).width >= _kRailBreakpoint;
    final current = _destinations[shell.currentIndex];

    final appBar = AppBar(
      title: Text(current.label),
      actions: const [
        Center(child: EnrichmentStatusChip()),
        SizedBox(width: VnSpacing.x4),
      ],
    );

    final scaffold = wide
        ? Scaffold(
            appBar: appBar,
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: shell.currentIndex,
                  onDestinationSelected: _goBranch,
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    for (final d in _destinations)
                      NavigationRailDestination(
                        icon: Icon(d.icon),
                        selectedIcon: Icon(d.selectedIcon),
                        label: Text(d.label),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: shell),
              ],
            ),
          )
        : Scaffold(
            appBar: appBar,
            body: shell,
            bottomNavigationBar: NavigationBar(
              selectedIndex: shell.currentIndex,
              onDestinationSelected: _goBranch,
              destinations: [
                for (final d in _destinations)
                  NavigationDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: d.label,
                  ),
              ],
            ),
          );

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): () =>
            showQuickAddWordDialog(context),
        const SingleActivator(LogicalKeyboardKey.keyF, control: true): () =>
            _focusSearch(ref),
        // Ctrl+/ - shortcut cheat sheet overlay (renders the same card the
        // Help section shows, so the two can never drift apart).
        const SingleActivator(LogicalKeyboardKey.slash, control: true): () =>
            showShortcutCheatsheetDialog(context),
        for (var i = 0; i < _destinations.length; i++) ...{
          SingleActivator(_digitKeys[i], control: true): () => _goBranch(i),
          SingleActivator(_numpadKeys[i], control: true): () => _goBranch(i),
        },
      },
      child: scaffold,
    );
  }
}
