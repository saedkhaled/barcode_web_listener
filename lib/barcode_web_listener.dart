library barcode_web_listener;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

//Callback function signature
typedef BarcodeScannedCallback = void Function(String barcode);

/// This widget will listen for raw PHYSICAL keyboard events
/// even when other controls have primary focus.
/// It will buffer all characters coming in specifed `bufferDuration` time frame
/// that end with line feed character and call callback function with result.
/// Keep in mind this widget will listen for events even when not visible.
/// Windows seems to be using the [KeyDownEvent] instead of the
/// [KeyUpEvent], this behaviour can be managed by setting [useKeyDownEvent].
class BarcodeWebListener extends StatefulWidget {
  /// Child widget to be displayed.
  final Widget child;

  /// Callback to be called when barcode is scanned.
  final BarcodeScannedCallback onBarcodeScanned;

  /// Maximum time between two key events.
  /// If time between two key events is longer than this value
  /// previous keys will be ignored.
  final Duration bufferDuration;

  /// When experiencing issues with empty barcodes on Windows,
  /// set this value to true. Default value is `false`.
  final bool useKeyDownEvent;

  /// This widget will listen for raw PHYSICAL keyboard events
  /// even when other controls have primary focus.
  /// It will buffer all characters coming in specified `bufferDuration` time frame
  /// that end with line feed character and call callback function with result.
  /// Keep in mind this widget will listen for events even when not visible.
  const BarcodeWebListener({
    /// Child widget to be displayed.
    required this.child,

    /// Callback to be called when barcode is scanned.
    required this.onBarcodeScanned,

    /// When experiencing issues with empty barcodes on Windows,
    /// set this value to true. Default value is `false`.
    this.useKeyDownEvent = false,

    /// Maximum time between two key events.
    /// If time between two key events is longer than this value
    /// previous keys will be ignored.
    this.bufferDuration = const Duration(milliseconds: 100),
    super.key,
  });

  @override
  State<BarcodeWebListener> createState() =>
      _BarcodeWebListenerState();
}

class _BarcodeWebListenerState
    extends State<BarcodeWebListener> {
  List<String> _scannedChars = [];
  late StreamSubscription<String?> _keyboardSubscription;

  final _controller = StreamController<String?>();

  Timer? _lastScannedCharCodeTimer;

  DateTime? _lastScannedTime;

  @override
  void initState() {
    HardwareKeyboard.instance.addHandler(_keyBoardCallback);
    _keyboardSubscription =
        _controller.stream.where((char) => char != null).listen(onKeyEvent);
    super.initState();
  }

  void onKeyEvent(String? char) {
    _scannedChars.add(char!);
    if (_lastScannedCharCodeTimer != null) {
      _lastScannedCharCodeTimer!.cancel();
    }
    final newTime = DateTime.now();
    if (_lastScannedTime != null) {
      final diff = newTime.difference(_lastScannedTime!);
      if (diff.inMilliseconds > widget.bufferDuration.inMilliseconds) {
        resetScannedCharCodes();
      }
    }
    _lastScannedCharCodeTimer =
        Timer(widget.bufferDuration, submitScannedCharCode);
  }

  void resetScannedCharCodes() {
    _scannedChars = [];
  }

  void submitScannedCharCode() {
    if (_scannedChars.length > 3) {
      widget.onBarcodeScanned.call(_scannedChars.join());
      resetScannedCharCodes();
    }
  }

  bool _keyBoardCallback(KeyEvent keyEvent) {
    if (keyEvent.logicalKey.keyId > 255) {
      return false;
    }
    if ((widget.useKeyDownEvent && keyEvent is KeyUpEvent) ||
        (!widget.useKeyDownEvent && keyEvent is KeyDownEvent)) {
      _controller.sink.add(keyEvent.character);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  void dispose() {
    _keyboardSubscription.cancel();
    _controller.close();
    HardwareKeyboard.instance.removeHandler(_keyBoardCallback);
    super.dispose();
  }
}
