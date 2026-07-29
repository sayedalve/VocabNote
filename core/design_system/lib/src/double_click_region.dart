/// core/design_system/lib/src/double_click_region.dart
///
/// Raw-pointer double-click detection that can never lose clicks to other
/// gesture recognizers.
///
/// [Listener] observes pointer events directly and does not participate in
/// the gesture arena, so this region coexists with arena-based gestures in
/// its subtree (most importantly [SelectionArea]'s text-selection
/// gestures): single click + drag always selects text, and a double-click
/// always fires [VnDoubleClickRegion.onDoubleClick] -- neither interaction
/// can steal the other's clicks. A [GestureDetector.onDoubleTap] cannot
/// give this guarantee, because it competes (and often loses) in the
/// arena.
library;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Invokes [onDoubleClick] when two primary-button presses land within
/// [kDoubleTapTimeout] and [kDoubleTapSlop] of each other.
///
/// Fires on the second pointer *down* (not up), so the callback feels
/// instant and a tiny drag between press and release cannot cancel it.
class VnDoubleClickRegion extends StatefulWidget {
  const VnDoubleClickRegion({
    required this.onDoubleClick,
    required this.child,
    super.key,
  });

  /// Fired on the second press of a double-click. When null the region is
  /// inert and merely passes pointer events through.
  final VoidCallback? onDoubleClick;

  final Widget child;

  @override
  State<VnDoubleClickRegion> createState() => _VnDoubleClickRegionState();
}

class _VnDoubleClickRegionState extends State<VnDoubleClickRegion> {
  Duration? _lastDownTime;
  Offset? _lastDownPosition;

  void _handlePointerDown(PointerDownEvent event) {
    final onDoubleClick = widget.onDoubleClick;
    if (onDoubleClick == null) return;
    if (event.kind == PointerDeviceKind.mouse &&
        event.buttons != kPrimaryButton) {
      // Right/middle clicks never count toward a double-click.
      _lastDownTime = null;
      _lastDownPosition = null;
      return;
    }

    final lastTime = _lastDownTime;
    final lastPosition = _lastDownPosition;
    final isDoubleClick = lastTime != null &&
        lastPosition != null &&
        event.timeStamp - lastTime <= kDoubleTapTimeout &&
        (event.position - lastPosition).distance <= kDoubleTapSlop;

    if (isDoubleClick) {
      // Reset so a triple-click cannot fire the callback twice.
      _lastDownTime = null;
      _lastDownPosition = null;
      onDoubleClick();
    } else {
      _lastDownTime = event.timeStamp;
      _lastDownPosition = event.position;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _handlePointerDown,
      child: widget.child,
    );
  }
}
