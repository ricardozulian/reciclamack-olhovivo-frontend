import 'dart:typed_data';

import 'package:flutter/widgets.dart';

class TotemCameraAdapterException implements Exception {
  const TotemCameraAdapterException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => '$code: $message';
}

abstract class TotemCameraAdapter {
  Future<void> initialize();

  Widget buildPreview();

  Future<Uint8List> captureSquare({required double jpegQuality});

  Future<void> dispose();
}
