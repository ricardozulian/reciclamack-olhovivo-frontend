import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../design_tokens.dart';
import '../totem_camera_adapter.dart';
import '../totem_camera_adapter_types.dart';
import '../totem_scan_state.dart';
import '../totem_status.dart';

typedef TotemFrameCallback = Future<bool> Function(
  String filename,
  Uint8List bytes,
);

class TotemCamera extends StatefulWidget {
  const TotemCamera({
    required this.onFrame,
    required this.onStatusChanged,
    required this.scanInterval,
    required this.jpegQuality,
    super.key,
  });

  final TotemFrameCallback onFrame;
  final ValueChanged<TotemStatus> onStatusChanged;
  final Duration scanInterval;
  final double jpegQuality;

  @override
  State<TotemCamera> createState() => _TotemCameraState();
}

class _TotemCameraState extends State<TotemCamera> with WidgetsBindingObserver {
  TotemCameraAdapter? _adapter;
  String? _error;
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
    _scanTimer?.cancel();
    await _adapter?.dispose();
    final adapter = createTotemCameraAdapter();
    _adapter = adapter;
    if (mounted) {
      setState(() {
        _initializing = true;
        _error = null;
      });
      _emit(
        TotemPhase.initializing,
        'Preparando a câmera',
        'Aguarde enquanto o totem inicia a captura.',
      );
    }
    try {
      await adapter.initialize();
      if (!mounted || adapter != _adapter) {
        await adapter.dispose();
        return;
      }
      setState(() => _initializing = false);
      _emitScanning();
      _scheduleCapture(Duration.zero);
    } on TotemCameraAdapterException catch (error) {
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _error = _cameraMessage(error);
      });
      _emit(TotemPhase.cameraError, 'Câmera indisponível', _error!);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _error = 'Verifique a câmera e tente novamente.';
      });
      _emit(TotemPhase.cameraError, 'Câmera indisponível', _error!);
    }
  }

  String _cameraMessage(TotemCameraAdapterException error) {
    if (error.code == 'permission_denied') {
      return 'Autorize a câmera para este totem e tente novamente.';
    }
    if (error.code == 'not_found') {
      return 'Nenhuma câmera foi encontrada.';
    }
    return 'Verifique a conexão da câmera e tente novamente.';
  }

  void _emit(TotemPhase phase, String headline, String instruction) {
    widget.onStatusChanged(
      TotemStatus(
        phase: phase,
        headline: headline,
        instruction: instruction,
      ),
    );
  }

  void _emitScanning() {
    _emit(
      TotemPhase.scanning,
      'Procurando equipamento',
      'Centralize o item no quadrado e mantenha-o imóvel.',
    );
  }

  void _scheduleCapture(Duration delay) {
    _scanTimer?.cancel();
    if (!mounted || !_active) return;
    _scanTimer = Timer(delay, _capture);
  }

  Future<void> _capture() async {
    final adapter = _adapter;
    if (!_active || adapter == null || _initializing || _capturing) return;
    setState(() => _capturing = true);
    _emit(
      TotemPhase.capturing,
      'Capturando o item',
      'Mantenha o item no centro do quadrado.',
    );

    Duration? nextDelay;
    try {
      final bytes = await adapter.captureSquare(
        jpegQuality: widget.jpegQuality,
      );
      final continueScanning = await widget.onFrame(
        'totem-${DateTime.now().toUtc().microsecondsSinceEpoch}.jpg',
        bytes,
      );
      _retrySchedule.recordSuccess();
      if (continueScanning) nextDelay = widget.scanInterval;
    } on TotemCameraAdapterException catch (error) {
      nextDelay = _retrySchedule.recordFailure();
      _emit(
        TotemPhase.retrying,
        'Nova tentativa em ${nextDelay.inSeconds} s',
        error.message,
      );
    } catch (_) {
      nextDelay = _retrySchedule.recordFailure();
      _emit(
        TotemPhase.retrying,
        'Nova tentativa em ${nextDelay.inSeconds} s',
        'Ocorreu uma falha temporária durante a análise.',
      );
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
      _adapter?.dispose();
      _adapter = null;
    } else if (state == AppLifecycleState.resumed && _adapter == null) {
      _active = true;
      _initialize();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _active = false;
    _scanTimer?.cancel();
    _adapter?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adapter = _adapter;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ReciclaColors.bgDeep,
        border: Border.all(color: ReciclaColors.primary, width: 2),
        borderRadius: BorderRadius.circular(ReciclaRadii.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(ReciclaRadii.md - 2),
          child: ColoredBox(
            color: ReciclaColors.bgDeep,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (!_initializing && _error == null && adapter != null)
                  adapter.buildPreview(),
                if (_initializing)
                  const Center(child: CircularProgressIndicator()),
                if (_error != null)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(ReciclaSpacing.s6),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.videocam_off_outlined,
                            color: ReciclaColors.warning,
                            size: 64,
                          ),
                          const SizedBox(height: ReciclaSpacing.s4),
                          Text(_error!, textAlign: TextAlign.center),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
