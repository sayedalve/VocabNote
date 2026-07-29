/// app/lib/shell/settings_tab.dart
///
/// App-level composition of the Settings branch: AI provider configuration
/// (feature_settings), typography & spacing (feature_settings), and data
/// transfer (feature_transfer) as three tabs. Lives in the app layer
/// because features never import each other.
library;

import 'package:feature_settings/feature_settings.dart';
import 'package:feature_transfer/feature_transfer.dart';
import 'package:flutter/material.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({this.initialTab = 0, super.key});

  /// 0 = AI Provider, 1 = Typography, 2 = Data. Deep links use
  /// /settings?tab=typography and /settings?tab=data (e.g. the empty-state
  /// “Import existing vocabulary” action).
  final int initialTab;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      // Keyed so navigating to a different ?tab= re-applies initialIndex.
      key: ValueKey('settings-tab-$initialTab'),
      length: 3,
      initialIndex: initialTab < 0 || initialTab > 2 ? 0 : initialTab,
      child: const Column(
        children: [
          TabBar(
            tabs: [
              Tab(text: 'AI Provider'),
              Tab(text: 'Typography'),
              Tab(text: 'Data'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                SettingsScreen(),
                TypographySettingsScreen(),
                TransferScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
