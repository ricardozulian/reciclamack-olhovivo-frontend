import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'totem_camera_adapter_types.dart';

TotemCameraAdapter createTotemCameraAdapter() => _UnsupportedCameraAdapter();

class _UnsupportedCameraAdapter implements TotemCameraAdapter {
  @override
  Future<Uint8List> captureSquare({required double jpegQuality}) {
    throw const TotemCameraAdapterException(
      'unsupported',
      'The totem camera requires a web browser.',
    );
  }

  @override
  Widget buildPreview() => const ColoredBox(color: Colors.black);

  @override
  Future<void> dispose() async {}

  @override
  Future<void> initialize() => captureSquare(jpegQuality: 0.92);
}
