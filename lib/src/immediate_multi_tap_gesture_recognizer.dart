import 'dart:async';
import 'dart:ui';

import 'package:flutter/gestures.dart';

/// Custom [TapGestureRecognizer] that allows for immediate triggers of singleTap events even in the case of actual double taps
class ImmediateMultiTapGestureRecognizer extends TapGestureRecognizer {
  VoidCallback? onSingleTap;
  VoidCallback? onDoubleTap;

  final int numberOfTaps;
  final Duration tapTimeout;

  ImmediateMultiTapGestureRecognizer({
    required this.numberOfTaps,
    required this.tapTimeout,
    super.debugOwner,
  });

  int _tapCount = 0;
  Timer? _timer;

  @override
  void handleTapDown({required PointerDownEvent down}) {
    onSingleTap?.call();

    // Start the timer
    _timer = Timer(tapTimeout, () {
      _tapCount = 0;
      _timer = null;
    });

    // Increment the tap count
    _tapCount++;

    // Consume the tap event
    resolve(GestureDisposition.accepted);

    super.handleTapDown(down: down);
  }

  @override
  void handleTapUp(
      {required PointerDownEvent down, required PointerUpEvent up}) {
    // Check if it's a double tap
    if (_tapCount == numberOfTaps) {
      // Handle double tap
      onDoubleTap?.call();

      // Reset tap count
      _tapCount = 0;

      // Stop the timer
      if (_timer != null) {
        _timer!.cancel();
        _timer = null;
      }
    }

    resolve(GestureDisposition.accepted);

    super.handleTapUp(down: down, up: up);
  }

  @override
  void handleTapCancel(
      {PointerCancelEvent? cancel,
      required PointerDownEvent down,
      String? reason}) {
    _tapCount = 0;
    _timer?.cancel();

    super.handleTapCancel(cancel: cancel, down: down, reason: reason ?? "");
  }

  @override
  bool isPointerAllowed(PointerDownEvent event) {
    return true;
  }
}
