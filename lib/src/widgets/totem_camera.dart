import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../design_tokens.dart';

typedef TotemCaptureCallback = Future<void> Function(
  String filename,
  Uint8List bytes,
);

class TotemCamera extends StatefulWidget {
  const TotemCamera({required this.onCapture, super.key});

  final TotemCaptureCallback onCapture;

  @override
  State<TotemCamera> createState() => _TotemCameraState();
}

class _TotemCameraState extends State<TotemCamera> with WidgetsBindingObserver {
  CameraController? _controller;
  String? _error;
  bool _initializing = true;
  bool _capturing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  Future<void> _initialize() async {
    await _controller?.dispose();
    if (mounted) {
      setState(() {
        _controller = null;
        _initializing = true;
        _error = null;
      });
    }
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw CameraException(
          'CameraUnavailable',
          'Nenhuma câmera encontrada.',
        );
      }
      final controller = CameraController(
        _chooseCamera(cameras),
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _initializing = false;
      });
    } on CameraException catch (error) {
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _error = _cameraMessage(error);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _error = 'Não foi possível iniciar a câmera conectada.';
      });
    }
  }

  CameraDescription _chooseCamera(List<CameraDescription> cameras) {
    for (final camera in cameras) {
      if (camera.lensDirection == CameraLensDirection.external) return camera;
    }
    for (final camera in cameras) {
      if (camera.lensDirection == CameraLensDirection.back) return camera;
    }
    return cameras.first;
  }

  String _cameraMessage(CameraException error) {
    if (error.code.toLowerCase().contains('denied')) {
      return 'Acesso à câmera negado. Autorize a câmera para este totem e tente novamente.';
    }
    return 'Câmera indisponível. Verifique a conexão USB e tente novamente.';
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _capturing) {
      return;
    }
    setState(() => _capturing = true);
    try {
      final image = await controller.takePicture();
      await widget.onCapture(image.name, await image.readAsBytes());
    } on CameraException catch (error) {
      if (!mounted) return;
      setState(() => _error = _cameraMessage(error));
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _controller?.dispose();
      _controller = null;
    } else if (state == AppLifecycleState.resumed && _controller == null) {
      _initialize();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (_initializing) {
      return const AspectRatio(
        aspectRatio: 4 / 3,
        child: ColoredBox(
          color: ReciclaColors.bgDeep,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: ReciclaSpacing.s3),
                Text('Preparando a câmera…'),
              ],
            ),
          ),
        ),
      );
    }

    if (_error != null ||
        controller == null ||
        !controller.value.isInitialized) {
      return AspectRatio(
        aspectRatio: 4 / 3,
        child: ColoredBox(
          color: ReciclaColors.bgDeep,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(ReciclaSpacing.s6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.videocam_off_outlined,
                    color: ReciclaColors.warning,
                    size: 48,
                  ),
                  const SizedBox(height: ReciclaSpacing.s3),
                  Text(
                    _error ?? 'Câmera indisponível.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: ReciclaSpacing.s4),
                  OutlinedButton.icon(
                    onPressed: _initialize,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tentar novamente'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(ReciclaRadii.md),
          child: AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: CameraPreview(controller),
          ),
        ),
        const SizedBox(height: ReciclaSpacing.s4),
        ElevatedButton.icon(
          key: const Key('totem-capture'),
          onPressed: _capturing ? null : _capture,
          icon: const Icon(Icons.camera_alt),
          label: Text(_capturing ? 'Capturando…' : 'Analisar este item'),
        ),
        const SizedBox(height: ReciclaSpacing.s2),
        const Text(
          'A câmera é processada localmente. Apenas a foto capturada é analisada.',
          textAlign: TextAlign.center,
          style: TextStyle(color: ReciclaColors.fg2, fontSize: 13),
        ),
      ],
    );
  }
}
