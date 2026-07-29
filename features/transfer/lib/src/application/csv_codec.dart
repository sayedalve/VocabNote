/// features/transfer/lib/src/application/csv_codec.dart
///
/// Minimal RFC-4180 CSV encoder/decoder. Pure functions, no I/O, unit
/// tested. Handles quoted fields, embedded commas, quotes, and newlines
/// (both LF and CRLF).
library;

String _encodeField(String field) {
  final needsQuoting = field.contains(',') ||
      field.contains('"') ||
      field.contains('\n') ||
      field.contains('\r');
  if (!needsQuoting) return field;
  return '"${field.replaceAll('"', '""')}"';
}

/// Encodes [rows] as CSV text with CRLF row terminators.
String encodeCsv(List<List<String>> rows) {
  final buffer = StringBuffer();
  for (final row in rows) {
    buffer
      ..writeAll(row.map(_encodeField), ',')
      ..write('\r\n');
  }
  return buffer.toString();
}

/// Decodes CSV [input] into rows of fields. Accepts LF or CRLF line
/// endings and a missing trailing newline.
List<List<String>> decodeCsv(String input) {
  final rows = <List<String>>[];
  var row = <String>[];
  final field = StringBuffer();
  var inQuotes = false;
  var i = 0;

  void endField() {
    row.add(field.toString());
    field.clear();
  }

  void endRow() {
    endField();
    rows.add(row);
    row = <String>[];
  }

  while (i < input.length) {
    final char = input[i];
    if (inQuotes) {
      if (char == '"') {
        if (i + 1 < input.length && input[i + 1] == '"') {
          field.write('"');
          i += 2;
        } else {
          inQuotes = false;
          i += 1;
        }
      } else {
        field.write(char);
        i += 1;
      }
    } else {
      switch (char) {
        case '"':
          inQuotes = true;
          i += 1;
        case ',':
          endField();
          i += 1;
        case '\r':
          if (i + 1 < input.length && input[i + 1] == '\n') {
            i += 1;
          }
          endRow();
          i += 1;
        case '\n':
          endRow();
          i += 1;
        default:
          field.write(char);
          i += 1;
      }
    }
  }

  // Flush the trailing field/row when the input has no final newline.
  if (field.isNotEmpty || row.isNotEmpty) {
    endRow();
  }
  return rows;
}
