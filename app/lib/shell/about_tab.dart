/// app/lib/shell/about_tab.dart
///
/// The About page: app identity, version, developer and project links,
/// update check, license, and credits. Links render as selectable text
/// with one-click copy \u2014 the app deliberately has no URL-launcher
/// dependency, keeping the Melos workspace pubspecs untouched.
library;

import 'package:core_design_system/core_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_info.dart';

class AboutTab extends StatelessWidget {
  const AboutTab({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final tokens = VnTheme.of(context).tokens;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: ListView(
          padding: const EdgeInsets.all(VnSpacing.x6),
          children: [
            const SizedBox(height: VnSpacing.x4),
            const Center(child: _AppMark()),
            const SizedBox(height: VnSpacing.x4),
            Center(
              child: Text(AppInfo.name, style: textTheme.headlineMedium),
            ),
            const SizedBox(height: VnSpacing.x2),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: VnSpacing.x3,
                  vertical: VnSpacing.x1,
                ),
                decoration: BoxDecoration(
                  color: tokens.surfaceRaised,
                  borderRadius: BorderRadius.circular(VnRadius.pill),
                  border: Border.all(color: tokens.border),
                ),
                child: Text(
                  'Version ${AppInfo.version} (build ${AppInfo.build})',
                  style: textTheme.labelMedium
                      ?.copyWith(color: tokens.textSecondary),
                ),
              ),
            ),
            const SizedBox(height: VnSpacing.x4),
            Text(
              AppInfo.description,
              textAlign: TextAlign.center,
              style:
                  textTheme.bodyMedium?.copyWith(color: tokens.textSecondary),
            ),
            const SizedBox(height: VnSpacing.x6),
            _AboutCard(
              title: 'Developer',
              children: [
                _InfoRow(
                  icon: Icons.person_outline,
                  label: 'Developed by',
                  value: AppInfo.developer,
                ),
                const SizedBox(height: VnSpacing.x3),
                const _InfoRow(
                  icon: Icons.account_balance_outlined,
                  label: 'Institution',
                  value: AppInfo.institution,
                ),
                const SizedBox(height: VnSpacing.x3),
                const _InfoRow(
                  icon: Icons.school_outlined,
                  label: 'Department',
                  value: AppInfo.department,
                ),
                const SizedBox(height: VnSpacing.x3),
                const _LinkRow(
                  icon: Icons.facebook_outlined,
                  label: 'Facebook',
                  url: AppInfo.facebookUrl,
                ),
                const SizedBox(height: VnSpacing.x3),
                const _LinkRow(
                  icon: Icons.code,
                  label: 'GitHub repository',
                  url: AppInfo.repositoryUrl,
                ),
              ],
            ),
            const SizedBox(height: VnSpacing.x4),
            _AboutCard(
              title: 'Updates',
              children: [
                Text(
                  'New versions are published on the GitHub releases page. '
                  'Compare the latest release there with the version shown '
                  'above.',
                  style: textTheme.bodySmall
                      ?.copyWith(color: tokens.textSecondary),
                ),
                const SizedBox(height: VnSpacing.x3),
                const _LinkRow(
                  icon: Icons.system_update_alt,
                  label: 'Check for updates',
                  url: AppInfo.releasesUrl,
                ),
              ],
            ),
            const SizedBox(height: VnSpacing.x4),
            _AboutCard(
              title: 'License',
              children: [
                Text(AppInfo.copyright, style: textTheme.bodyMedium),
                const SizedBox(height: VnSpacing.x1),
                Text(
                  'VocabNote is distributed as-is, without warranty of any '
                  'kind.',
                  style: textTheme.bodySmall
                      ?.copyWith(color: tokens.textSecondary),
                ),
                const SizedBox(height: VnSpacing.x3),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: () => showLicensePage(
                      context: context,
                      applicationName: AppInfo.name,
                      applicationVersion: AppInfo.version,
                      applicationLegalese: AppInfo.copyright,
                    ),
                    icon: const Icon(Icons.description_outlined, size: 18),
                    label: const Text('View open-source licenses'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: VnSpacing.x4),
            _AboutCard(
              title: 'Credits & acknowledgements',
              children: [
                Text(
                  'Built with Flutter and Dart, standing on the shoulders '
                  'of these open-source projects:',
                  style: textTheme.bodySmall
                      ?.copyWith(color: tokens.textSecondary),
                ),
                const SizedBox(height: VnSpacing.x2),
                const _CreditLine('Riverpod \u2014 state management'),
                const _CreditLine('Drift + SQLite \u2014 local database'),
                const _CreditLine('Freezed \u2014 immutable data classes'),
                const _CreditLine('go_router \u2014 navigation'),
                const _CreditLine(
                  'Inter & Noto Sans Bengali \u2014 typefaces',
                ),
              ],
            ),
            const SizedBox(height: VnSpacing.x8),
          ],
        ),
      ),
    );
  }
}

/// The in-app rendition of the application mark. The PNG icon artwork is
/// used for the Windows executable icon and is not bundled as a Flutter
/// asset (the pubspec stays untouched), so the mark is drawn here with the
/// same accent palette.
class _AppMark extends StatelessWidget {
  const _AppMark();

  @override
  Widget build(BuildContext context) {
    // The bundled artwork is the same file the Windows executable icon is
    // generated from (see flutter_launcher_icons in pubspec.yaml), so the
    // About page always matches the real application icon.
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Image.asset(
        'assets/icon/app_icon.png',
        width: 96,
        height: 96,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        semanticLabel: '${AppInfo.name} application icon',
        errorBuilder: (context, error, stackTrace) => const _FallbackMark(),
      ),
    );
  }
}

/// Legacy drawn mark, kept only as a fallback if the icon asset ever
/// fails to decode.
class _FallbackMark extends StatelessWidget {
  const _FallbackMark();

  @override
  Widget build(BuildContext context) {
    final tokens = VnTheme.of(context).tokens;
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tokens.accentHover, tokens.accent],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Icon(
        Icons.menu_book_rounded,
        size: 48,
        color: Colors.white,
      ),
    );
  }
}

/// Consistent card surface for About sections.
class _AboutCard extends StatelessWidget {
  const _AboutCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final tokens = VnTheme.of(context).tokens;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(VnSpacing.x4),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(VnRadius.md),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(), style: textTheme.labelSmall),
          const SizedBox(height: VnSpacing.x3),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final tokens = VnTheme.of(context).tokens;
    return Row(
      children: [
        Icon(icon, size: 18, color: tokens.textMuted),
        const SizedBox(width: VnSpacing.x3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style:
                    textTheme.bodySmall?.copyWith(color: tokens.textMuted),
              ),
              Text(value, style: textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

/// A labeled, selectable link with a one-click copy button.
class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.icon,
    required this.label,
    required this.url,
  });

  final IconData icon;
  final String label;
  final String url;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('$label link copied.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final tokens = VnTheme.of(context).tokens;
    return Row(
      children: [
        Icon(icon, size: 18, color: tokens.textMuted),
        const SizedBox(width: VnSpacing.x3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style:
                    textTheme.bodySmall?.copyWith(color: tokens.textMuted),
              ),
              SelectableText(
                url,
                style: textTheme.bodyMedium?.copyWith(color: tokens.accent),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Copy link',
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.copy, size: 16),
          onPressed: () => _copy(context),
        ),
      ],
    );
  }
}

class _CreditLine extends StatelessWidget {
  const _CreditLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final tokens = VnTheme.of(context).tokens;
    return Padding(
      padding: const EdgeInsets.only(bottom: VnSpacing.x1),
      child: Text(
        '\u2022  $text',
        style: textTheme.bodySmall?.copyWith(color: tokens.textSecondary),
      ),
    );
  }
}
