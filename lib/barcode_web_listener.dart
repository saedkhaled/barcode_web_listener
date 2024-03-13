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
class BarcodeKeyboardWebListener extends StatefulWidget {
  /// Child widget to be displayed.
  final Widget child;

  /// Callback to be called when barcode is scanned.
  final BarcodeScannedCallback onBarcodeScanned;

  /// Maximum time between two key events.
  /// If time between two key events is longer than this value
  /// previous keys will be ignored.
  final Duration bufferDuration;

  /// When experiencing issueswith empty barcodes on Windows,
  /// set this value to true. Default value is `false`.
  final bool useKeyDownEvent;

  /// This widget will listen for raw PHYSICAL keyboard events
  /// even when other controls have primary focus.
  /// It will buffer all characters coming in specified `bufferDuration` time frame
  /// that end with line feed character and call callback function with result.
  /// Keep in mind this widget will listen for events even when not visible.
  const BarcodeKeyboardWebListener({
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
  State<BarcodeKeyboardWebListener> createState() =>
      _BarcodeKeyboardWebListenerState();
}

class _BarcodeKeyboardWebListenerState
    extends State<BarcodeKeyboardWebListener> {
  List<String> _scannedChars = [];
  late StreamSubscription<String?> _keyboardSubscription;

  final _controller = StreamController<String?>();

  Timer? _lastScannedCharCodeTimer;

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
    _lastScannedCharCodeTimer =
        Timer(widget.bufferDuration, submitScannedCharCode);
  }

  void resetScannedCharCodes() {
    _scannedChars = [];
  }

  void addScannedCharCode(String charCode) {
    _scannedChars.add(charCode);
  }

  void submitScannedCharCode() {
    // last char is being added as 'm' instead of line feed, so we need to check for 'm' if it is the last char
    // and call the callback and remove the last char which is 'm'
    if (_scannedChars.isNotEmpty && _scannedChars.last == 'm') {
      _scannedChars.removeLast();
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
