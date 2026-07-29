import 'package:core_design_system/core_design_system.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VnCardStyle pronunciation default', () {
    test('simplified pronunciation is on by default', () {
      expect(VnCardStyle.defaultSimplifiedPronunciation, isTrue);
      expect(const VnCardStyle().simplifiedPronunciation, isTrue);
    });

    test('fromJson falls back to simplified when the key is absent', () {
      expect(
        VnCardStyle.fromJson(const {}).simplifiedPronunciation,
        isTrue,
      );
    });

    test('fromJson preserves an explicit user choice of IPA', () {
      expect(
        VnCardStyle.fromJson(const {'simplifiedPronunciation': false})
            .simplifiedPronunciation,
        isFalse,
      );
    });
  });

  group('VnCardStyle round trip', () {
    test('toJson/fromJson preserves every field', () {
      const style = VnCardStyle(zoom: 1.2, simplifiedPronunciation: false);
      expect(VnCardStyle.fromJson(style.toJson()), style);
    });
  });
}
