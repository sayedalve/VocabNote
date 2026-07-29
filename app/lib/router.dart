/// app/lib/router.dart
library;

import 'package:feature_quiz/feature_quiz.dart';
import 'package:go_router/go_router.dart';

import 'shell/about_tab.dart';
import 'shell/adaptive_shell.dart';
import 'shell/help_tab.dart';
import 'shell/notebook_tab.dart';
import 'shell/settings_tab.dart';

/// SharedPreferences key for the last visited shell section (persisted by
/// the shell, restored via [createRouter]'s initialLocation in main.dart).
const String kLastRouteKey = 'ui.last_route';

/// Valid shell destinations, in branch order (must match the destination
/// order in app/lib/shell/adaptive_shell.dart).
const List<String> kShellRoutePaths = [
  '/notebook',
  '/quiz',
  '/favorites',
  '/help',
  '/about',
  '/settings',
];

/// Builds the app router. [initialLocation] lets startup restore the last
/// visited section; callers must pass a value from [kShellRoutePaths].
GoRouter createRouter({String initialLocation = '/notebook'}) => GoRouter(
      initialLocation: initialLocation,
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => AdaptiveShell(shell: shell),
          // Branch order must match the destination order in
          // app/lib/shell/adaptive_shell.dart.
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/notebook',
                  pageBuilder: (context, state) => const NoTransitionPage(
                    child: NotebookTab(),
                  ),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/quiz',
                  pageBuilder: (context, state) => const NoTransitionPage(
                    child: QuizScreen(),
                  ),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/favorites',
                  pageBuilder: (context, state) => const NoTransitionPage(
                    child: NotebookTab(favoritesOnly: true),
                  ),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/help',
                  pageBuilder: (context, state) => const NoTransitionPage(
                    child: HelpTab(),
                  ),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/about',
                  pageBuilder: (context, state) => const NoTransitionPage(
                    child: AboutTab(),
                  ),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/settings',
                  pageBuilder: (context, state) => NoTransitionPage(
                    child: SettingsTab(
                      initialTab: switch (state.uri.queryParameters['tab']) {
                        'typography' => 1,
                        'data' => 2,
                        _ => 0,
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
