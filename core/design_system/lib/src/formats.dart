/// core/design_system/lib/src/formats.dart
///
/// Shared, dependency-free date/time formatting. Previously each feature
/// hand-rolled its own `_formatDate`, and the formats had diverged (the
/// quiz history used `DD/MM/YYYY h:mm AM`, the backup list used
/// `YYYY-MM-DD HH:mm`). Every screen now renders timestamps identically.
library;

const List<String> _monthAbbreviations = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _twoDigits(int value) => value.toString().padLeft(2, '0');

/// Formats a date as `15 Jan 2026` in the local time zone.
String formatVnDate(DateTime value) {
  final local = value.toLocal();
  return '${local.day} ${_monthAbbreviations[local.month - 1]} '
      '${local.year}';
}

/// Formats a timestamp as `15 Jan 2026, 14:30` in the local time zone.
String formatVnDateTime(DateTime value) {
  final local = value.toLocal();
  return '${formatVnDate(local)}, '
      '${_twoDigits(local.hour)}:${_twoDigits(local.minute)}';
}
