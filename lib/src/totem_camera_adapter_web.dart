import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

import 'square_crop_geometry.dart';
import 'totem_camera_adapter_types.dart';

TotemCameraAdapter createTotemCameraAdapter() => _WebTotemCameraAdapter();

class _WebTotemCameraAdapter implements TotemCameraAdapter {
  static int _nextViewId = 0;

  final web.HTMLVideoElement _video = web.HTMLVideoElement();
  web.MediaStream? _stream;
  late final String _viewType;
  bool _registered = false;

  @override
  Future<void> initialize() async {
    await dispose();
    _configureVideoElement();
    _registerPreview();

    final mediaDevices = web.window.navigator.mediaDevices;
    try {
      if (mediaDevices.getSupportedConstraints().resizeMode) {
        try {
          _stream = await mediaDevices
              .getUserMedia(_constraints(exactResizeMode: true))
              .toDart;
        } on web.DOMException catch (error) {
          if (!_isConstraintError(error)) rethrow;
        }
      }
      _stream ??= await mediaDevices
          .getUserMedia(_constraints(exactResizeMode: false))
          .toDart;
      _video.srcObject = _stream;
      await _waitForMetadata();
      await _video.play().toDart;
    } on web.DOMException catch (error) {
      await dispose();
      throw _cameraException(error);
    } catch (error) {
      await dispose();
      if (error is TotemCameraAdapterException) rethrow;
      throw TotemCameraAdapterException('camera_error', '$error');
    }
  }

  web.MediaStreamConstraints _constraints({required bool exactResizeMode}) {
    final resizeMode = exactResizeMode
        ? <String, Object>{'exact': 'crop-and-scale'}
        : 'crop-and-scale';
    final videoConstraints = <String, Object>{
      'width': <String, Object>{'ideal': 720},
      'height': <String, Object>{'ideal': 720},
      'aspectRatio': <String, Object>{'ideal': 1.0},
      'resizeMode': resizeMode,
      'facingMode': <String, Object>{'ideal': 'environment'},
    }.jsify();
    return web.MediaStreamConstraints(
      audio: false.toJS,
      video: videoConstraints!,
    );
  }

  bool _isConstraintError(web.DOMException error) {
    return error.name == 'OverconstrainedError' ||
        error.name == 'ConstraintNotSatisfiedError';
  }

  TotemCameraAdapterException _cameraException(web.DOMException error) {
    switch (error.name) {
      case 'NotAllowedError':
      case 'PermissionDeniedError':
        return const TotemCameraAdapterException(
          'permission_denied',
          'Acesso à câmera negado.',
        );
      case 'NotFoundError':
      case 'DevicesNotFoundError':
        return const TotemCameraAdapterException(
          'not_found',
          'Nenhuma câmera foi encontrada.',
        );
      case 'NotReadableError':
      case 'TrackStartError':
        return const TotemCameraAdapterException(
          'not_readable',
          'A câmera está conectada, mas não pode ser usada.',
        );
      default:
        return TotemCameraAdapterException(error.name, error.message);
    }
  }

  void _configureVideoElement() {
    _video
      ..autoplay = true
      ..muted = true
      ..playsInline = true;
    _video.style
      ..width = '100%'
      ..height = '100%'
      ..objectFit = 'cover'
      ..transform = 'scaleX(-1)'
      ..backgroundColor = 'black';
  }

  void _registerPreview() {
    if (_registered) return;
    _viewType = 'reciclamack-totem-camera-${_nextViewId++}';
    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int _) => _video,
    );
    _registered = true;
  }

  Future<void> _waitForMetadata() async {
    if (_video.videoWidth > 0 && _video.videoHeight > 0) return;
    final completer = Completer<void>();
    _video.onloadedmetadata = ((web.Event _) {
      if (!completer.isCompleted) completer.complete();
    }).toJS;
    _video.onerror = ((web.Event _) {
      if (!completer.isCompleted) {
        completer.completeError(
          const TotemCameraAdapterException(
            'video_error',
            'Não foi possível mostrar a câmera.',
          ),
        );
      }
    }).toJS;
    await completer.future.timeout(const Duration(seconds: 10));
  }

  @override
  Widget buildPreview() => HtmlElementView(viewType: _viewType);

  @override
  Future<Uint8List> captureSquare({required double jpegQuality}) async {
    final width = _video.videoWidth;
    final height = _video.videoHeight;
    if (width <= 0 || height <= 0 || _stream?.active != true) {
      throw const TotemCameraAdapterException(
        'camera_inactive',
        'A câmera não forneceu uma imagem.',
      );
    }

    final crop = SquareCropRect.centered(width, height);
    final canvas = web.HTMLCanvasElement()
      ..width = crop.side
      ..height = crop.side;
    final context = canvas.getContext('2d') as web.CanvasRenderingContext2D?;
    if (context == null) {
      throw const TotemCameraAdapterException(
        'canvas_unavailable',
        'O navegador não forneceu o canvas da câmera.',
      );
    }
    context
      ..translate(crop.side, 0)
      ..scale(-1, 1);
    context.drawImage(
      _video,
      crop.x,
      crop.y,
      crop.side,
      crop.side,
      0,
      0,
      crop.side,
      crop.side,
    );

    final blobCompleter = Completer<web.Blob>();
    canvas.toBlob(
      ((web.Blob? blob) {
        if (blob == null) {
          blobCompleter.completeError(
            const TotemCameraAdapterException(
              'jpeg_error',
              'O navegador não codificou a imagem.',
            ),
          );
        } else {
          blobCompleter.complete(blob);
        }
      }).toJS,
      'image/jpeg',
      jpegQuality.toJS,
    );
    final blob = await blobCompleter.future;
    final buffer = await blob.arrayBuffer().toDart;
    return buffer.toDart.asUint8List();
  }

  @override
  Future<void> dispose() async {
    final stream = _stream;
    if (stream != null) {
      for (final track in stream.getTracks().toDart) {
        track.stop();
      }
    }
    _stream = null;
    _video
      ..pause()
      ..srcObject = null;
  }
}
