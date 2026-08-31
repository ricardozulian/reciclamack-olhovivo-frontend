import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'analysis_api.dart';
import 'design_tokens.dart';
import 'totem_scan_state.dart';
import 'totem_result_sequence.dart';
import 'totem_status.dart';
import 'widgets/annotated_image.dart';
import 'widgets/brand_app_bar.dart';
import 'widgets/shared_page_content.dart';
import 'widgets/totem_camera.dart';
import 'widgets/totem_hint_panel.dart';
import 'widgets/totem_pair_layout.dart';
import 'widgets/totem_result_panels.dart';

class TotemPage extends StatefulWidget {
  const TotemPage({super.key});

  @override
  State<TotemPage> createState() => _TotemPageState();
}

class _TotemPageState extends State<TotemPage> {
  static const int _scanIntervalMs = int.fromEnvironment(
    'TOTEM_SCAN_INTERVAL_MS',
    defaultValue: 1000,
  );
  static const int _defaultConfirmationFrames = int.fromEnvironment(
    'TOTEM_CONFIRM_FRAMES',
    defaultValue: 1,
  );
  static const int _actionableSeconds = int.fromEnvironment(
    'TOTEM_ACTIONABLE_SECONDS',
    defaultValue: 20,
  );
  static const int _closingSeconds = int.fromEnvironment(
    'TOTEM_CLOSING_SECONDS',
    defaultValue: 3,
  );
  static final double _jpegQuality = double.tryParse(
        const String.fromEnvironment(
          'TOTEM_CAPTURE_JPEG_QUALITY',
          defaultValue: '0.92',
        ),
      ) ??
      0.92;

  final AnalysisApi _api = AnalysisApi();
  late final bool _twoStep;
  late final TotemScanState _scanState;
  late final TotemResultSequence _resultSequence;
  Timer? _resultTimer;
  Map<String, dynamic>? _result;
  Uint8List? _confirmedBytes;
  TotemStatus _status = const TotemStatus(
    phase: TotemPhase.initializing,
    headline: 'Preparando a câmera',
    instruction: 'Aguarde enquanto o totem inicia a captura.',
  );

  @override
  void initState() {
    super.initState();
    _twoStep = _resolveTwoStep();
    _scanState = TotemScanState(confirmationFrames: _twoStep ? 2 : 1);
    _resultSequence = TotemResultSequence(
      actionableSeconds: _safeActionableSeconds,
      closingSeconds: _safeClosingSeconds,
    );
  }

  bool _resolveTwoStep() {
    final configured = Uri.base.queryParameters['two_step']?.toLowerCase();
    if (configured == 'true' || configured == '1') return true;
    if (configured == 'false' || configured == '0') return false;
    return _defaultConfirmationFrames > 1;
  }

  @override
  void dispose() {
    _resultTimer?.cancel();
    super.dispose();
  }

  void _setStatus(TotemStatus status) {
    if (!mounted || _confirmedBytes != null) return;
    setState(() => _status = status);
  }

  Future<bool> _processFrame(String filename, Uint8List bytes) async {
    _setStatus(
      const TotemStatus(
        phase: TotemPhase.analyzing,
        headline: 'Analisando o item',
        instruction: 'Mantenha o item no centro do quadrado.',
      ),
    );
    final probe = await _api.analyze(filename, bytes, persist: false);
    if (!mounted) return false;

    final probeDetections = detectionsFrom(probe);
    final wasWaitingForClear = _scanState.requiresClear;
    final decision = _scanState.recordDetections(probeDetections);
    final expectedClass = decision.confirmedClass;
    if (expectedClass == null) {
      if (wasWaitingForClear) {
        if (!_scanState.requiresClear) {
          _setStatus(
            const TotemStatus(
              phase: TotemPhase.scanning,
              headline: 'Pronto para o próximo item',
              instruction: 'Centralize o novo item no quadrado.',
            ),
          );
        } else {
          _setStatus(
            TotemStatus(
              phase: TotemPhase.waitingForClear,
              headline: 'Retire o item anterior',
              instruction: probeDetections.isEmpty
                  ? 'Verificando a área livre: ${_scanState.clearFrameCount} de ${_scanState.clearFrames}.'
                  : 'A próxima leitura começa quando a câmera estiver livre.',
            ),
          );
        }
      } else if (probeDetections.isEmpty) {
        _setStatus(
          const TotemStatus(
            phase: TotemPhase.scanning,
            headline: 'Procurando equipamento',
            instruction: 'Centralize o item no quadrado e mantenha-o imóvel.',
          ),
        );
      } else {
        _setStatus(
          const TotemStatus(
            phase: TotemPhase.candidate,
            headline: 'Item encontrado',
            instruction: 'Mantenha o item imóvel para a segunda leitura.',
          ),
        );
      }
      return true;
    }

    _setStatus(
      const TotemStatus(
        phase: TotemPhase.confirming,
        headline: 'Confirmando o resultado',
        instruction: 'A mesma imagem será guardada se a classe for confirmada.',
      ),
    );
    final confirmed = await _api.analyze(filename, bytes);
    if (!mounted) return false;
    final confirmedClass = _scanState.dominantClass(detectionsFrom(confirmed));
    if (confirmedClass != expectedClass) {
      _setStatus(
        const TotemStatus(
          phase: TotemPhase.scanning,
          headline: 'A confirmação mudou',
          instruction: 'Reposicione o item no centro do quadrado.',
        ),
      );
      return true;
    }

    setState(() {
      _confirmedBytes = bytes;
      _result = confirmed;
      _resultSequence.reset();
    });
    _startResultTimer();
    return false;
  }

  int get _safeActionableSeconds =>
      _actionableSeconds > 0 ? _actionableSeconds : 20;
  int get _safeClosingSeconds => _closingSeconds > 0 ? _closingSeconds : 3;

  void _startResultTimer() {
    _resultTimer?.cancel();
    _resultTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_resultSequence.tick()) {
        _resetSession();
      } else {
        setState(() {});
      }
    });
  }

  void _showClosingPage() {
    if (!mounted) return;
    setState(_resultSequence.showClosing);
  }

  void _resetSession() {
    _resultTimer?.cancel();
    if (!mounted) return;
    _scanState.requireClear();
    setState(() {
      _confirmedBytes = null;
      _result = null;
      _resultSequence.reset();
      _status = const TotemStatus(
        phase: TotemPhase.waitingForClear,
        headline: 'Retire o item anterior',
        instruction: 'A próxima leitura começa quando a câmera estiver livre.',
      );
    });
  }

  int _responseDimension(String key) => (_result?[key] as num?)?.toInt() ?? 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bytes = _confirmedBytes;
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: const TextScaler.linear(1.5),
      ),
      child: Scaffold(
        appBar: const BrandAppBar(),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              ReciclaSpacing.s4,
              ReciclaSpacing.s3,
              ReciclaSpacing.s4,
              ReciclaSpacing.s4,
            ),
            child: Column(
              children: [
                _buildHeader(theme, showingResult: bytes != null),
                const SizedBox(height: ReciclaSpacing.s3),
                Expanded(
                  child: bytes == null
                      ? TotemPairLayout(
                          first: TotemCamera(
                            onFrame: _processFrame,
                            onStatusChanged: _setStatus,
                            scanInterval: const Duration(
                              milliseconds:
                                  _scanIntervalMs > 0 ? _scanIntervalMs : 1000,
                            ),
                            jpegQuality: _jpegQuality > 0 && _jpegQuality <= 1
                                ? _jpegQuality
                                : 0.92,
                          ),
                          second: TotemHintPanel(status: _status),
                        )
                      : _buildResultPair(bytes),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, {required bool showingResult}) {
    return Column(
      children: [
        buildEducationBadge(theme),
        const SizedBox(height: ReciclaSpacing.s2),
        Text(
          showingResult
              ? _resultSequence.stage == TotemResultStage.actionable
                  ? 'Veja como descartar este equipamento'
                  : 'Prepare a próxima leitura'
              : 'Mostre seu eletrônico para a câmera',
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildResultPair(Uint8List bytes) {
    if (_resultSequence.stage == TotemResultStage.closing) {
      return TotemPairLayout(
        first: TotemRemoveItemPanel(
          remainingSeconds: _resultSequence.remainingSeconds,
        ),
        second: const TotemLegalPanel(),
      );
    }
    return TotemPairLayout(
      first: AnnotatedImage(
        bytes: bytes,
        imageWidth: _responseDimension('image_width'),
        imageHeight: _responseDimension('image_height'),
        detections: detectionsFrom(_result),
        loading: false,
      ),
      second: TotemActionablePanel(
        result: _result!,
        remainingSeconds: _resultSequence.remainingSeconds,
        totalSeconds: _safeActionableSeconds,
        onFinishNow: _showClosingPage,
      ),
    );
  }
}
