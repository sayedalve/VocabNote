/// core/design_system/lib/src/card_style.dart
///
/// Reading-experience preferences for vocabulary cards: typography sizes,
/// spacing, corner radius, live card zoom, and pronunciation display.
///
/// This is a pure presentation model (no persistence, no Riverpod):
///  * feature_settings owns editing and storage of these values,
///  * the app layer injects the resolved style via [VnCardStyleScope],
///  * card widgets read it with `VnCardStyleScope.of(context)`.
///
/// Serialization is tolerant by contract: any `num` is accepted for a
/// double slot, unknown keys are ignored, and every value is clamped into
/// its allowed range, so a corrupt or older stored blob can never crash
/// the app (and no string-to-number radix parsing is ever involved).
library;

import 'package:flutter/widgets.dart';

@immutable
final class VnCardStyle {
  const VnCardStyle({
    this.bodyFontSize = defaultBodyFontSize,
    this.headwordFontSize = defaultHeadwordFontSize,
    this.definitionFontSize = defaultDefinitionFontSize,
    this.lineHeight = defaultLineHeight,
    this.cardPadding = defaultCardPadding,
    this.verticalSpacing = defaultVerticalSpacing,
    this.sectionSpacing = defaultSectionSpacing,
    this.cardRadius = defaultCardRadius,
    this.zoom = defaultZoom,
    this.simplifiedPronunciation = defaultSimplifiedPronunciation,
  });

  /// Base size for section labels, synonyms/antonyms, and secondary lines.
  final double bodyFontSize;

  /// Size of the headword - the card's primary visual focus.
  final double headwordFontSize;

  /// Size of the meaning/definition line.
  final double definitionFontSize;

  /// Line-height multiplier for card text.
  final double lineHeight;

  /// Inner vertical card padding. Horizontal padding is
  /// [horizontalCardPadding] (2x) so text never crowds the card edges.
  final double cardPadding;

  /// Left/right inner card padding: twice [cardPadding] (30 px at the
  /// default) for a balanced, readable card.
  double get horizontalCardPadding => cardPadding * 2;

  /// Vertical gap between cards in the list.
  final double verticalSpacing;

  /// Gap between sections inside one card.
  final double sectionSpacing;

  /// Card corner radius.
  final double cardRadius;

  /// Live zoom applied to card content only (fonts and inner spacing).
  /// Toolbar, sidebar, and menus are deliberately unaffected.
  final double zoom;

  /// When true, pronunciation renders as a readable respelling ("kat")
  /// instead of raw IPA ("/kaet/").
  final bool simplifiedPronunciation;

  // Allowed ranges. Sliders and [normalized] both derive from these so the
  // UI and the model can never disagree.
  static const double minBodyFontSize = 11;
  static const double maxBodyFontSize = 20;
  static const double defaultBodyFontSize = 14;

  static const double minHeadwordFontSize = 16;
  static const double maxHeadwordFontSize = 34;
  static const double defaultHeadwordFontSize = 22;

  static const double minDefinitionFontSize = 11;
  static const double maxDefinitionFontSize = 22;
  static const double defaultDefinitionFontSize = 15;

  static const double minLineHeight = 1.1;
  static const double maxLineHeight = 2.0;
  static const double defaultLineHeight = 1.4;

  static const double minCardPadding = 8;
  static const double maxCardPadding = 28;
  static const double defaultCardPadding = 15;

  static const double minVerticalSpacing = 2;
  static const double maxVerticalSpacing = 20;
  static const double defaultVerticalSpacing = 8;

  static const double minSectionSpacing = 2;
  static const double maxSectionSpacing = 20;
  static const double defaultSectionSpacing = 8;

  static const double minCardRadius = 0;
  static const double maxCardRadius = 24;
  static const double defaultCardRadius = 12;

  static const double minZoom = 0.8;
  static const double maxZoom = 1.6;
  static const double defaultZoom = 1.0;
  static const double zoomStep = 0.1;

  /// Simplified pronunciation ("kat") is the default experience; raw IPA
  /// ("/k\u00e6t/") stays available as an opt-in under Settings \u2192
  /// Typography.
  static const bool defaultSimplifiedPronunciation = true;

  /// Scales a card-content dimension by the live zoom factor.
  double zoomed(double value) => value * zoom;

  VnCardStyle copyWith({
    double? bodyFontSize,
    double? headwordFontSize,
    double? definitionFontSize,
    double? lineHeight,
    double? cardPadding,
    double? verticalSpacing,
    double? sectionSpacing,
    double? cardRadius,
    double? zoom,
    bool? simplifiedPronunciation,
  }) {
    return VnCardStyle(
      bodyFontSize: bodyFontSize ?? this.bodyFontSize,
      headwordFontSize: headwordFontSize ?? this.headwordFontSize,
      definitionFontSize: definitionFontSize ?? this.definitionFontSize,
      lineHeight: lineHeight ?? this.lineHeight,
      cardPadding: cardPadding ?? this.cardPadding,
      verticalSpacing: verticalSpacing ?? this.verticalSpacing,
      sectionSpacing: sectionSpacing ?? this.sectionSpacing,
      cardRadius: cardRadius ?? this.cardRadius,
      zoom: zoom ?? this.zoom,
      simplifiedPronunciation:
          simplifiedPronunciation ?? this.simplifiedPronunciation,
    );
  }

  /// Returns a copy with every value clamped into its allowed range.
  VnCardStyle normalized() {
    return VnCardStyle(
      bodyFontSize:
          bodyFontSize.clamp(minBodyFontSize, maxBodyFontSize).toDouble(),
      headwordFontSize: headwordFontSize
          .clamp(minHeadwordFontSize, maxHeadwordFontSize)
          .toDouble(),
      definitionFontSize: definitionFontSize
          .clamp(minDefinitionFontSize, maxDefinitionFontSize)
          .toDouble(),
      lineHeight: lineHeight.clamp(minLineHeight, maxLineHeight).toDouble(),
      cardPadding:
          cardPadding.clamp(minCardPadding, maxCardPadding).toDouble(),
      verticalSpacing: verticalSpacing
          .clamp(minVerticalSpacing, maxVerticalSpacing)
          .toDouble(),
      sectionSpacing: sectionSpacing
          .clamp(minSectionSpacing, maxSectionSpacing)
          .toDouble(),
      cardRadius: cardRadius.clamp(minCardRadius, maxCardRadius).toDouble(),
      zoom: zoom.clamp(minZoom, maxZoom).toDouble(),
      simplifiedPronunciation: simplifiedPronunciation,
    );
  }

  Map<String, Object> toJson() => <String, Object>{
        'bodyFontSize': bodyFontSize,
        'headwordFontSize': headwordFontSize,
        'definitionFontSize': definitionFontSize,
        'lineHeight': lineHeight,
        'cardPadding': cardPadding,
        'verticalSpacing': verticalSpacing,
        'sectionSpacing': sectionSpacing,
        'cardRadius': cardRadius,
        'zoom': zoom,
        'simplifiedPronunciation': simplifiedPronunciation,
      };

  /// Tolerant deserialization: missing or malformed entries fall back to
  /// defaults, and the result is always [normalized].
  static VnCardStyle fromJson(Map<String, Object?> json) {
    double readDouble(String key, double fallback) {
      final value = json[key];
      return value is num ? value.toDouble() : fallback;
    }

    bool readBool(String key, {required bool fallback}) {
      final value = json[key];
      return value is bool ? value : fallback;
    }

    return VnCardStyle(
      bodyFontSize: readDouble('bodyFontSize', defaultBodyFontSize),
      headwordFontSize:
          readDouble('headwordFontSize', defaultHeadwordFontSize),
      definitionFontSize:
          readDouble('definitionFontSize', defaultDefinitionFontSize),
      lineHeight: readDouble('lineHeight', defaultLineHeight),
      cardPadding: readDouble('cardPadding', defaultCardPadding),
      verticalSpacing: readDouble('verticalSpacing', defaultVerticalSpacing),
      sectionSpacing: readDouble('sectionSpacing', defaultSectionSpacing),
      cardRadius: readDouble('cardRadius', defaultCardRadius),
      zoom: readDouble('zoom', defaultZoom),
      simplifiedPronunciation: readBool(
        'simplifiedPronunciation',
        fallback: defaultSimplifiedPronunciation,
      ),
    ).normalized();
  }

  @override
  bool operator ==(Object other) {
    return other is VnCardStyle &&
        other.bodyFontSize == bodyFontSize &&
        other.headwordFontSize == headwordFontSize &&
        other.definitionFontSize == definitionFontSize &&
        other.lineHeight == lineHeight &&
        other.cardPadding == cardPadding &&
        other.verticalSpacing == verticalSpacing &&
        other.sectionSpacing == sectionSpacing &&
        other.cardRadius == cardRadius &&
        other.zoom == zoom &&
        other.simplifiedPronunciation == simplifiedPronunciation;
  }

  @override
  int get hashCode => Object.hash(
        bodyFontSize,
        headwordFontSize,
        definitionFontSize,
        lineHeight,
        cardPadding,
        verticalSpacing,
        sectionSpacing,
        cardRadius,
        zoom,
        simplifiedPronunciation,
      );
}

/// Injects the resolved [VnCardStyle] into the widget tree. The app layer
/// owns exactly one of these (wired to the persisted settings controller);
/// card widgets and the settings live preview read it via [of].
final class VnCardStyleScope extends InheritedWidget {
  const VnCardStyleScope({
    required this.style,
    required super.child,
    super.key,
  });

  final VnCardStyle style;

  /// The nearest injected style, or defaults when no scope is present
  /// (tests, previews).
  static VnCardStyle of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<VnCardStyleScope>();
    return scope?.style ?? const VnCardStyle();
  }

  @override
  bool updateShouldNotify(VnCardStyleScope oldWidget) =>
      style != oldWidget.style;
}
