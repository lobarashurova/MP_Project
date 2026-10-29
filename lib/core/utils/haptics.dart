import 'package:flutter/services.dart';

/// Centralised haptic feedback so taps feel consistent across the app.
///
/// Every call is fire-and-forget: on platforms or devices without a haptic
/// engine the platform channel simply does nothing, so callers never need to
/// guard these.
class Haptics {
  Haptics._();

  /// Standard feedback for a button, card or icon tap.
  static void tap() => HapticFeedback.lightImpact();

  /// Moving between tabs, chips or any segmented choice.
  static void selection() => HapticFeedback.selectionClick();

  /// A value changed meaningfully — quantity steppers, toggles.
  static void change() => HapticFeedback.mediumImpact();

  /// A flow completed: order placed, item added to the basket.
  static void success() => HapticFeedback.mediumImpact();

  /// Destructive or blocked action: clear all, remove, validation failure.
  static void warning() => HapticFeedback.heavyImpact();
}
