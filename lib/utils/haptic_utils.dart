import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Haptic feedback utility class
class HapticUtils {
  /// Light impact - for button taps
  static void lightImpact() {
    HapticFeedback.lightImpact();
  }

  /// Medium impact - for selections and toggles
  static void mediumImpact() {
    HapticFeedback.mediumImpact();
  }

  /// Heavy impact - for important actions
  static void heavyImpact() {
    HapticFeedback.heavyImpact();
  }

  /// Selection click - for list item selections
  static void selectionClick() {
    HapticFeedback.selectionClick();
  }

  /// Vibrate pattern - for errors or warnings
  static void vibrate() {
    HapticFeedback.vibrate();
  }
}

/// Extension to add haptic feedback to any widget
extension HapticWidget on Widget {
  /// Wrap widget with haptic feedback on tap
  Widget withHapticFeedback({
    HapticType type = HapticType.light,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: () {
        switch (type) {
          case HapticType.light:
            HapticUtils.lightImpact();
            break;
          case HapticType.medium:
            HapticUtils.mediumImpact();
            break;
          case HapticType.heavy:
            HapticUtils.heavyImpact();
            break;
          case HapticType.selection:
            HapticUtils.selectionClick();
            break;
        }
        onTap?.call();
      },
      child: this,
    );
  }
}

enum HapticType {
  light,
  medium,
  heavy,
  selection,
}

/// Button with built-in haptic feedback
class HapticButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;
  final HapticType hapticType;
  final ButtonStyle? style;

  const HapticButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.hapticType = HapticType.light,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        switch (hapticType) {
          case HapticType.light:
            HapticUtils.lightImpact();
            break;
          case HapticType.medium:
            HapticUtils.mediumImpact();
            break;
          case HapticType.heavy:
            HapticUtils.heavyImpact();
            break;
          case HapticType.selection:
            HapticUtils.selectionClick();
            break;
        }
        onPressed();
      },
      style: style,
      child: child,
    );
  }
}

/// IconButton with built-in haptic feedback
class HapticIconButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget icon;
  final HapticType hapticType;
  final String? tooltip;
  final Color? color;

  const HapticIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.hapticType = HapticType.selection,
    this.tooltip,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        switch (hapticType) {
          case HapticType.light:
            HapticUtils.lightImpact();
            break;
          case HapticType.medium:
            HapticUtils.mediumImpact();
            break;
          case HapticType.heavy:
            HapticUtils.heavyImpact();
            break;
          case HapticType.selection:
            HapticUtils.selectionClick();
            break;
        }
        onPressed();
      },
      icon: icon,
      tooltip: tooltip,
      color: color,
    );
  }
}
