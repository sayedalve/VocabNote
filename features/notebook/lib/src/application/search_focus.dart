/// features/notebook/lib/src/application/search_focus.dart
///
/// App-wide "focus the search bar" coordination. The shell owns the global
/// Ctrl+F shortcut (so it works no matter which widget has keyboard focus)
/// and broadcasts a request through this coordinator; whichever word list
/// screen is currently visible responds by focusing its search field.
///
/// A plain [ChangeNotifier] behind a Riverpod [Provider] keeps this fully
/// decoupled: the shell never needs a reference to screen state, and
/// screens never need to know about the shell.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Broadcasts search-focus requests to listening word list screens.
class SearchFocusCoordinator extends ChangeNotifier {
  /// Asks the currently visible word list to focus its search field.
  void requestSearchFocus() => notifyListeners();
}

final Provider<SearchFocusCoordinator> searchFocusCoordinatorProvider =
    Provider<SearchFocusCoordinator>((ref) {
  final coordinator = SearchFocusCoordinator();
  ref.onDispose(coordinator.dispose);
  return coordinator;
});
