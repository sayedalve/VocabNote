/// core/ai/test/provider_config_test.dart
///
/// Unit tests for the HTTPS-everywhere-except-loopback security contract and
/// provider preset lookup.
library;

import 'package:core_ai/core_ai.dart';
import 'package:test/test.dart';

void main() {
  group('isBaseUrlAllowed', () {
    test('allows any https URL', () {
      expect(isBaseUrlAllowed('https://api.example.com'), isTrue);
    });

    test('allows plain http for loopback hosts', () {
      expect(isBaseUrlAllowed('http://localhost:11434/v1'), isTrue);
      expect(isBaseUrlAllowed('http://127.0.0.1:8080'), isTrue);
    });

    test('rejects plain http for non-loopback hosts', () {
      expect(isBaseUrlAllowed('http://api.example.com'), isFalse);
    });

    test('rejects non-http(s) schemes', () {
      expect(isBaseUrlAllowed('ftp://api.example.com'), isFalse);
    });

    test('rejects unparsable input', () {
      expect(isBaseUrlAllowed('not a url'), isFalse);
    });
  });

  group('presetById', () {
    test('finds a known preset by id', () {
      expect(presetById('groq').label, 'Groq');
    });

    test('falls back to the first preset for an unknown id', () {
      expect(presetById('does-not-exist'), kProviderPresets.first);
    });
  });
}
