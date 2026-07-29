/// features/settings/lib/src/presentation/card_zoom_control.dart
///
/// Toolbar control for live card zoom. Three ways to adjust:
///  * the +/- buttons step by [VnCardStyle.zoomStep],
///  * scrolling the mouse wheel anywhere over the control zooms smoothly
///    (proportional to scroll distance, so notched wheels and trackpads
///    both feel right); the scroll is claimed via the pointer-signal
///    resolver so the page behind never scrolls while zooming,
///  * clicking the percentage readout resets to 100%.
/// All paths clamp to [VnCardStyle.minZoom]..[VnCardStyle.maxZoom] and
/// persist through [CardStyleController.setZoom].
library;

import 'package:core_design_system/core_design_system.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/card_style_controller.dart';

/// Wheel-to-zoom sensitivity: one standard wheel notch (120 scroll units
/// on Windows) maps to two thirds of a button step, so wheel zooming is
/// smooth but never jumpy.
const double _kZoomPerScrollUnit = VnCardStyle.zoomStep / 180;

class CardZoomControl extends ConsumerWidget {
  const CardZoomControl({super.key});

  void _setZoom(WidgetRef ref, double zoom) {
    final clamped = zoom
        .clamp(VnCardStyle.minZoom, VnCardStyle.maxZoom)
        .toDouble();
    // Snap to whole percents so the readout and stored value stay clean.
    final snapped = (clamped * 100).roundToDouble() / 100;
    ref.read(cardStyleControllerProvider.notifier).setZoom(snapped);
  }

  void _handlePointerSignal(
    PointerSignalEvent event,
    WidgetRef ref,
    double zoom,
  ) {
    if (event is! PointerScrollEvent) return;
    // Claim the scroll through the signal resolver: if we win (we are the
    // innermost handler), no surrounding scrollable ever sees the event,
    // so the page cannot scroll while the pointer zooms over the control.
    GestureBinding.instance.pointerSignalResolver.register(event, (resolved) {
      final scroll = resolved as PointerScrollEvent;
      final delta = -scroll.scrollDelta.dy * _kZoomPerScrollUnit;
      if (delta == 0) return;
      _setZoom(ref, zoom + delta);
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = VnTheme.of(context).tokens;
    final textTheme = Theme.of(context).textTheme;
    final style =
        ref.watch(cardStyleControllerProvider).value ?? const VnCardStyle();
    final zoom = style.zoom;
    final pct = (zoom * 100).round();
    final canZoomOut = zoom > VnCardStyle.minZoom + 0.001;
    final canZoomIn = zoom < VnCardStyle.maxZoom - 0.001;

    return Listener(
      onPointerSignal: (event) => _handlePointerSignal(event, ref, zoom),
      child: Semantics(
        label: 'Card zoom',
        value: '$pct percent',
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: tokens.surfaceInput,
            border: Border.all(color: tokens.border),
            borderRadius: BorderRadius.circular(VnRadius.md),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Zoom out (Ctrl+-)',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.zoom_out, size: 18),
                color: canZoomOut ? tokens.textSecondary : tokens.textMuted,
                onPressed: canZoomOut
                    ? () => _setZoom(ref, zoom - VnCardStyle.zoomStep)
                    : null,
              ),
              Tooltip(
                message: 'Card zoom \u2014 scroll to adjust, '
                    'click to reset (Ctrl+0)',
                child: InkWell(
                  onTap: () => _setZoom(ref, VnCardStyle.defaultZoom),
                  borderRadius: BorderRadius.circular(VnRadius.sm),
                  child: SizedBox(
                    width: 44,
                    height: 28,
                    child: Center(
                      child: Text(
                        '$pct%',
                        style: textTheme.bodySmall?.copyWith(
                          color: tokens.textSecondary,
                          fontWeight: VnTypeScale.semiBold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Zoom in (Ctrl+=)',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.zoom_in, size: 18),
                color: canZoomIn ? tokens.textSecondary : tokens.textMuted,
                onPressed: canZoomIn
                    ? () => _setZoom(ref, zoom + VnCardStyle.zoomStep)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
