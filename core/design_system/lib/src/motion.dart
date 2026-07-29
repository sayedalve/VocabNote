/// core/design_system/lib/src/motion.dart
///
/// Reduced-motion support. Wrap animation durations in [vnMotionDuration]
/// so users who enable "reduce motion" / "show animations: off" at the OS
/// level get instant transitions. Rendering is unchanged for everyone else.
library;

import 'package:flutter/widgets.dart';

/// Returns [base], or [Duration.zero] when the platform asks for animations
/// to be disabled (Windows "Animation effects", macOS "Reduce motion",
/// Android "Remove animations").
Duration vnMotionDuration(BuildContext context, Duration base) =>
    (MediaQuery.maybeDisableAnimationsOf(context) ?? false)
        ? Duration.zero
        : base;
