import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import 'design_tokens.dart';
import 'totem_scan_state.dart';
import 'widgets/annotated_image.dart';
import 'widgets/brand_app_bar.dart';
import 'widgets/result_panel.dart';
import 'widgets/totem_camera.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const int _maxUploadBytes = 10 * 1024 * 1024;
  static const String _defaultApiBaseUrl = 'http://localhost:8000';
  static const String _apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: _defaultApiBaseUrl,
  );
  static const String _appMode = String.fromEnvironment(
    'APP_MODE',
    defaultValue: 'web',
  );
  static const int _totemResetSeconds = int.fromEnvironment(
    'TOTEM_RESET_SECONDS',
    defaultValue: 45,
  );
  static const int _totemScanIntervalMs = int.fromEnvironment(
    'TOTEM_SCAN_INTERVAL_MS',
    defaultValue: 1000,
  );
  static const int _totemConfirmationFrames = int.fromEnvironment(
    'TOTEM_CONFIRM_FRAMES',
    defaultValue: 2,
  );

  final ImagePicker _picker = ImagePicker();
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _result;
  Uint8List? _selectedBytes;
  String? _selectedName;
  Timer? _resetTimer;
  late final bool _cameraSecureContext;
  late final TotemScanState _totemScanState;

  bool get _isTotem => _appMode.toLowerCase() == 'totem';

  @override
  void initState() {
    super.initState();
    _cameraSecureContext = _isSecureCameraContext();
    _totemScanState = TotemScanState(
      confirmationFrames:
          _totemConfirmationFrames > 0 ? _totemConfirmationFrames : 2,
    );
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  bool _isSecureCameraContext() {
    if (!kIsWeb) return true;
    final host = Uri.base.host.toLowerCase();
    final loopback = host == 'localhost' || host == '127.0.0.1';
    return Uri.base.scheme == 'https' || loopback;
  }

  Future<void> _pickAndAnalyze(ImageSource source) async {
    if (source == ImageSource.camera && !_cameraSecureContext) {
      setState(() {
        _error =
            'Captura pela câmera no navegador requer HTTPS. Use "Selecionar foto" no HTTP.';
      });
      return;
    }
    try {
      final image = await _picker.pickImage(source: source, imageQuality: 92);
      if (image == null) return;
      await _analyzeBytes(image.name, await image.readAsBytes());
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Falha ao abrir a imagem. Tente novamente.');
    }
  }

  Future<void> _analyzeBytes(String filename, Uint8List bytes) async {
    _resetTimer?.cancel();
    if (bytes.length > _maxUploadBytes) {
      setState(() {
        _error = 'Imagem acima do limite de 10 MB. Escolha uma imagem menor.';
        _loading = false;
      });
      return;
    }
    setState(() {
      _selectedBytes = bytes;
      _selectedName = filename;
      _loading = true;
      _error = null;
      _result = null;
    });

    try {
      final analyzed = await _sendWithRetry(filename, bytes);
      if (!mounted) return;
      setState(() {
        _result = analyzed;
        _loading = false;
      });
      _scheduleTotemReset();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error =
            'Falha ao analisar a imagem. Verifique o sistema e tente novamente.';
        _loading = false;
      });
      _scheduleTotemReset();
    }
  }

  Future<bool> _processTotemFrame(
    String filename,
    Uint8List bytes,
    void Function(String message) reportStatus,
  ) async {
    reportStatus('Analisando imagem…');
    final probe = await _sendAnalyzeRequest(filename, bytes, persist: false);
    if (!mounted) return false;

    final probeDetections = _detectionsFrom(probe);
    final wasWaitingForClear = _totemScanState.requiresClear;
    final decision = _totemScanState.recordDetections(
      probeDetections,
    );
    final expectedClass = decision.confirmedClass;
    if (expectedClass == null) {
      if (wasWaitingForClear) {
        reportStatus(
          !_totemScanState.requiresClear
              ? 'Pronto para o próximo item.'
              : probeDetections.isEmpty
                  ? 'Área livre: verificação ${_totemScanState.clearFrameCount} de ${_totemScanState.clearFrames}.'
                  : 'Retire o item anterior para continuar.',
        );
      } else if (probeDetections.isEmpty) {
        reportStatus('Nenhum item identificado. Continuando a busca…');
      } else {
        reportStatus(
          'Item encontrado. Mantenha-o na posição para confirmar.',
        );
      }
      return true;
    }

    reportStatus('Item confirmado. Processando resultado…');
    final confirmed = await _sendAnalyzeRequest(filename, bytes);
    if (!mounted) return false;
    final confirmedClass = _totemScanState.dominantClass(
      _detectionsFrom(confirmed),
    );
    if (confirmedClass != expectedClass) {
      reportStatus('A confirmação mudou. Continuando a busca…');
      return true;
    }

    reportStatus('Resultado pronto.');
    _resetTimer?.cancel();
    setState(() {
      _selectedBytes = bytes;
      _selectedName = filename;
      _result = confirmed;
      _error = null;
      _loading = false;
    });
    _scheduleTotemReset();
    return false;
  }

  void _scheduleTotemReset() {
    if (!_isTotem || _totemResetSeconds <= 0) return;
    _resetTimer?.cancel();
    _resetTimer = Timer(
      const Duration(seconds: _totemResetSeconds),
      _resetSession,
    );
  }

  void _resetSession() {
    _resetTimer?.cancel();
    if (!mounted) return;
    if (_isTotem) _totemScanState.requireClear();
    setState(() {
      _selectedBytes = null;
      _selectedName = null;
      _result = null;
      _error = null;
      _loading = false;
    });
  }

  Future<void> _retryAnalysis() async {
    final bytes = _selectedBytes;
    final name = _selectedName;
    if (bytes != null && name != null) {
      await _analyzeBytes(name, bytes);
    }
  }

  Future<Map<String, dynamic>> _sendWithRetry(
    String filename,
    Uint8List bytes,
  ) async {
    Exception? lastError;
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        return await _sendAnalyzeRequest(filename, bytes);
      } catch (error) {
        lastError = Exception(error.toString());
        if (attempt == 0) {
          await Future<void>.delayed(const Duration(milliseconds: 450));
        }
      }
    }
    throw lastError ?? Exception('Erro desconhecido');
  }

  Future<Map<String, dynamic>> _sendAnalyzeRequest(
    String filename,
    Uint8List bytes, {
    bool persist = true,
  }) async {
    var uri = _apiUri('/v1/analyze-image');
    if (!persist) {
      uri = uri.replace(
        queryParameters: {...uri.queryParameters, 'persist': 'false'},
      );
    }
    final request = http.MultipartRequest('POST', uri)
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: filename,
          contentType: _mediaTypeForFilename(filename),
        ),
      );
    final streamed = await request.send().timeout(const Duration(seconds: 25));
    final body = await streamed.stream.bytesToString();
    final decoded = jsonDecode(body) as Map<String, dynamic>;
    if (streamed.statusCode >= 400) {
      throw Exception(decoded['detail'] ?? 'Erro da API');
    }
    return decoded;
  }

  MediaType _mediaTypeForFilename(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return MediaType('image', 'png');
    if (lower.endsWith('.webp')) return MediaType('image', 'webp');
    if (lower.endsWith('.gif')) return MediaType('image', 'gif');
    return MediaType('image', 'jpeg');
  }

  Uri _apiUri(String path) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final base = _effectiveApiBaseUrl();
    if (base.isEmpty || base == '/') return Uri.parse(normalizedPath);
    return Uri.parse(
      '${base.replaceAll(RegExp(r'/+$'), '')}$normalizedPath',
    );
  }

  String _effectiveApiBaseUrl() {
    final configured = _apiBaseUrl.trim();
    if (!kIsWeb || configured != _defaultApiBaseUrl) return configured;
    if (Uri.base.scheme == 'https') return '/';
    final host = Uri.base.host;
    if (host.isEmpty || host == 'localhost' || host == '127.0.0.1') {
      return configured;
    }
    return 'http://$host:8000';
  }

  List<Map<String, dynamic>> _detections() {
    final result = _result;
    if (result == null) return const [];
    return _detectionsFrom(result);
  }

  List<Map<String, dynamic>> _detectionsFrom(Map<String, dynamic> result) {
    final value = result['detections'];
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList();
  }

  int _responseDimension(String key) {
    return (_result?[key] as num?)?.toInt() ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bytes = _selectedBytes;
    return Scaffold(
      appBar: const BrandAppBar(),
      body: Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(ReciclaSpacing.s4),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: _isTotem ? 960 : 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHero(theme),
                const SizedBox(height: ReciclaSpacing.s6),
                if (_isTotem && bytes == null)
                  TotemCamera(
                    onFrame: _processTotemFrame,
                    scanInterval: const Duration(
                      milliseconds: _totemScanIntervalMs > 0
                          ? _totemScanIntervalMs
                          : 1000,
                    ),
                  )
                else if (!_isTotem)
                  _buildWebActions(),
                if (!_isTotem && !_cameraSecureContext) ...[
                  const SizedBox(height: ReciclaSpacing.s3),
                  _buildToast(
                    icon: Icons.warning_amber_rounded,
                    text:
                        'Câmera web exige contexto seguro (HTTPS). Em HTTP, envie uma imagem da galeria.',
                    color: ReciclaColors.warning,
                    bgColor: ReciclaColors.warningSurface,
                  ),
                ],
                if (bytes != null) ...[
                  const SizedBox(height: ReciclaSpacing.s4),
                  GestureDetector(
                    onTapDown: (_) => _scheduleTotemReset(),
                    child: AnnotatedImage(
                      bytes: bytes,
                      imageWidth: _responseDimension('image_width'),
                      imageHeight: _responseDimension('image_height'),
                      detections: _detections(),
                      loading: _loading,
                    ),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: ReciclaSpacing.s3),
                  _buildToast(
                    icon: Icons.error_outline,
                    text: _error!,
                    color: ReciclaColors.error,
                    bgColor: ReciclaColors.errorSurface,
                  ),
                  if (bytes != null)
                    Padding(
                      padding: const EdgeInsets.only(top: ReciclaSpacing.s3),
                      child: Wrap(
                        spacing: ReciclaSpacing.s3,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _loading ? null : _retryAnalysis,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Tentar análise novamente'),
                          ),
                          if (_isTotem)
                            TextButton(
                              onPressed: _resetSession,
                              child: const Text('Voltar para a câmera'),
                            ),
                        ],
                      ),
                    ),
                ],
                if (_result != null) ...[
                  const SizedBox(height: ReciclaSpacing.s6),
                  const Divider(),
                  const SizedBox(height: ReciclaSpacing.s4),
                  GestureDetector(
                    onTapDown: (_) => _scheduleTotemReset(),
                    child: ResultPanel(result: _result!),
                  ),
                  if (_isTotem) ...[
                    const SizedBox(height: ReciclaSpacing.s4),
                    Center(
                      child: ElevatedButton.icon(
                        key: const Key('totem-reset'),
                        onPressed: _resetSession,
                        icon: const Icon(Icons.replay),
                        label: const Text('Analisar outro item'),
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: ReciclaSpacing.s6),
                Text(
                  'Aviso:\n'
                  '• Este sistema utiliza inteligência artificial e pode apresentar erros.\n'
                  '• As informações são educacionais e não substituem orientação técnica, legal ou jurídica.\n'
                  '• Imagens eventualmente retidas e previsões automáticas não constituem dados auditados.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: ReciclaSpacing.s8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHero(ThemeData theme) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: ReciclaSpacing.s4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: ReciclaColors.primarySurface,
              border: Border.all(color: ReciclaColors.primaryBorder),
              borderRadius: BorderRadius.circular(ReciclaRadii.pill),
            ),
            child:
                Text('EDUCAÇÃO EM E-LIXO', style: theme.textTheme.labelMedium),
          ),
          const SizedBox(height: ReciclaSpacing.s4),
          Text(
            _isTotem
                ? 'Mostre seu eletrônico para a câmera'
                : 'Identifique e descarte seus eletrônicos corretamente',
            style: theme.textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: ReciclaSpacing.s3),
          Text(
            _isTotem
                ? 'Aproxime o item. O totem identifica o equipamento automaticamente.'
                : 'Envie uma foto de aparelho eletrônico para receber orientações de descarte.',
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWebActions() {
    return Center(
      child: Wrap(
        spacing: ReciclaSpacing.s3,
        runSpacing: ReciclaSpacing.s3,
        alignment: WrapAlignment.center,
        children: [
          ElevatedButton.icon(
            onPressed:
                _loading ? null : () => _pickAndAnalyze(ImageSource.gallery),
            icon: const Icon(Icons.upload_file),
            label: const Text('Selecionar foto'),
          ),
          OutlinedButton.icon(
            onPressed: (_loading || !_cameraSecureContext)
                ? null
                : () => _pickAndAnalyze(ImageSource.camera),
            icon: const Icon(Icons.camera_alt),
            label: const Text('Capturar câmera'),
          ),
        ],
      ),
    );
  }

  Widget _buildToast({
    required IconData icon,
    required String text,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: color.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(ReciclaRadii.sm),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
