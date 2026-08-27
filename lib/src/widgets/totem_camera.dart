import 'dart:async';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../design_tokens.dart';
import '../totem_scan_state.dart';

typedef TotemFrameCallback = Future<bool> Function(
  String filename,
  Uint8List bytes,
  void Function(String message) reportStatus,
);

class TotemCamera extends StatefulWidget {
  const TotemCamera({
    required this.onFrame,
    required this.scanInterval,
    super.key,
  });

  final TotemFrameCallback onFrame;
  final Duration scanInterval;

  @override
  State<TotemCamera> createState() => _TotemCameraState();
}

class _TotemCameraState extends State<TotemCamera> with WidgetsBindingObserver {
  CameraController? _controller;
  String? _error;
  String? _statusMessage;
  bool _initializing = true;
  bool _capturing = false;
  bool _active = true;
  Timer? _scanTimer;
  final TotemRetrySchedule _retrySchedule = TotemRetrySchedule();

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
      _scheduleCapture(Duration.zero);
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

  void _scheduleCapture(Duration delay) {
    _scanTimer?.cancel();
    if (!mounted || !_active) return;
    _scanTimer = Timer(delay, _capture);
  }

  void _reportStatus(String message) {
    if (!mounted) return;
    setState(() => _statusMessage = message);
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (!_active ||
        controller == null ||
        !controller.value.isInitialized ||
        _capturing) {
      return;
    }
    setState(() {
      _capturing = true;
      _statusMessage = 'Capturando imagem…';
    });
    Duration? nextDelay;
    try {
      final image = await controller.takePicture();
      final continueScanning = await widget.onFrame(
        image.name,
        await image.readAsBytes(),
        _reportStatus,
      );
      _retrySchedule.recordSuccess();
      if (continueScanning) nextDelay = widget.scanInterval;
    } on CameraException catch (error) {
      if (!mounted) return;
      setState(() => _error = _cameraMessage(error));
    } catch (_) {
      nextDelay = _retrySchedule.recordFailure();
      if (mounted) {
        setState(() {
          _statusMessage =
              'Falha temporária na análise. O totem tentará novamente.';
        });
      }
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
    if (nextDelay != null) _scheduleCapture(nextDelay);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _active = false;
      _scanTimer?.cancel();
      _controller?.dispose();
      _controller = null;
    } else if (state == AppLifecycleState.resumed && _controller == null) {
      _active = true;
      _initialize();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _active = false;
    _scanTimer?.cancel();
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
            child: Stack(
              fit: StackFit.expand,
              children: [
                CameraPreview(controller),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: ReciclaSpacing.s4,
                      vertical: ReciclaSpacing.s3,
                    ),
                    color: Colors.black.withValues(alpha: 0.78),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_capturing) ...[
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          ),
                          const SizedBox(width: ReciclaSpacing.s3),
                        ] else ...[
                          const Icon(
                            Icons.center_focus_strong,
                            color: ReciclaColors.primary,
                            size: 22,
                          ),
                          const SizedBox(width: ReciclaSpacing.s3),
                        ],
                        Flexible(
                          child: Text(
                            _statusMessage ?? 'Procurando equipamento…',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: ReciclaSpacing.s3),
        const Text(
          'Mantenha o item diante da câmera. O totem descarta as imagens de busca e guarda somente a imagem confirmada.',
          textAlign: TextAlign.center,
          style: TextStyle(color: ReciclaColors.fg2, fontSize: 13),
        ),
      ],
    );
  }
}
