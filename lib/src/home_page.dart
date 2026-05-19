import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import 'design_tokens.dart';
import 'widgets/brand_app_bar.dart';
import 'widgets/result_panel.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const int _maxUploadBytes = 10 * 1024 * 1024;
  static const String _apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  final ImagePicker _picker = ImagePicker();
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _result;
  late final bool _cameraSecureContext;

  @override
  void initState() {
    super.initState();
    _cameraSecureContext = _isSecureCameraContext();
  }

  bool _isSecureCameraContext() {
    if (!kIsWeb) {
      return true;
    }
    final host = Uri.base.host.toLowerCase();
    final secureHost = host == 'localhost' || host == '127.0.0.1';
    return Uri.base.scheme == 'https' || secureHost;
  }

  Future<void> _analyze(ImageSource source) async {
    if (source == ImageSource.camera && !_cameraSecureContext) {
      setState(() {
        _error = 'Captura pela câmera no navegador requer HTTPS. Use "Selecionar foto" no HTTP.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });

    try {
      final image = await _picker.pickImage(source: source, imageQuality: 92);
      if (image == null) {
        setState(() => _loading = false);
        return;
      }
      final bytes = await image.readAsBytes();
      if (bytes.length > _maxUploadBytes) {
        setState(() {
          _error = 'Imagem acima do limite de 10 MB. Escolha uma imagem menor.';
          _loading = false;
        });
        return;
      }
      final analyzed = await _sendWithRetry(image.name, bytes);
      setState(() {
        _result = analyzed;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _error = 'Falha ao processar a imagem. Tente novamente.';
        _loading = false;
      });
    }
  }

  Future<Map<String, dynamic>> _sendWithRetry(String filename, Uint8List bytes) async {
    Exception? lastError;
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        return await _sendAnalyzeRequest(filename, bytes);
      } catch (e) {
        lastError = Exception(e.toString());
        await Future<void>.delayed(const Duration(milliseconds: 450));
      }
    }
    throw lastError ?? Exception('Erro desconhecido');
  }

  Future<Map<String, dynamic>> _sendAnalyzeRequest(String filename, Uint8List bytes) async {
    final uri = _apiUri('/v1/analyze-image');
    final mediaType = _mediaTypeForFilename(filename);
    final req = http.MultipartRequest('POST', uri)
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: filename,
          contentType: mediaType,
        ),
      );
    final streamed = await req.send().timeout(const Duration(seconds: 25));
    final body = await streamed.stream.bytesToString();
    final decoded = jsonDecode(body) as Map<String, dynamic>;
    if (streamed.statusCode >= 400) {
      throw Exception(decoded['detail'] ?? 'Erro da API');
    }
    return decoded;
  }

  MediaType _mediaTypeForFilename(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) {
      return MediaType('image', 'png');
    }
    if (lower.endsWith('.webp')) {
      return MediaType('image', 'webp');
    }
    if (lower.endsWith('.gif')) {
      return MediaType('image', 'gif');
    }
    return MediaType('image', 'jpeg');
  }

  Uri _apiUri(String path) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final base = _effectiveApiBaseUrl();
    if (base.isEmpty || base == '/') {
      return Uri.parse(normalizedPath);
    }
    return Uri.parse('${base.replaceAll(RegExp(r'/+$'), '')}$normalizedPath');
  }

  String _effectiveApiBaseUrl() {
    final configured = _apiBaseUrl.trim();
    if (!kIsWeb || configured != 'http://localhost:8000') {
      return configured;
    }
    final host = Uri.base.host;
    if (host.isEmpty || host == 'localhost' || host == '127.0.0.1') {
      return configured;
    }
    return 'http://$host:8000';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: const BrandAppBar(),
      body: Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(ReciclaSpacing.s4),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Hero Section ──
                Center(
                  child: Column(
                    children: [
                      const SizedBox(height: ReciclaSpacing.s4),
                      // Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: ReciclaColors.primarySurface,
                          border: Border.all(color: ReciclaColors.primaryBorder),
                          borderRadius: BorderRadius.circular(ReciclaRadii.pill),
                        ),
                        child: Text(
                          'EDUCAÇÃO EM E-LIXO',
                          style: theme.textTheme.labelMedium,
                        ),
                      ),
                      const SizedBox(height: ReciclaSpacing.s4),
                      Text(
                        'Identifique e descarte seus eletrônicos corretamente',
                        style: theme.textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: ReciclaSpacing.s3),
                      Text(
                        'Envie uma foto de aparelho eletrônico para receber orientações de descarte.',
                        style: theme.textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: ReciclaSpacing.s6),

                // ── Action Buttons ──
                Center(
                  child: Wrap(
                    spacing: ReciclaSpacing.s3,
                    runSpacing: ReciclaSpacing.s3,
                    alignment: WrapAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _loading ? null : () => _analyze(ImageSource.gallery),
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Selecionar foto'),
                      ),
                      OutlinedButton.icon(
                        onPressed: (_loading || !_cameraSecureContext)
                            ? null
                            : () => _analyze(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Capturar câmera'),
                      ),
                    ],
                  ),
                ),

                if (!_cameraSecureContext) ...[
                  const SizedBox(height: ReciclaSpacing.s3),
                  _buildToast(
                    icon: Icons.warning_amber_rounded,
                    text: 'Câmera web exige contexto seguro (HTTPS). Para teste em HTTP, envie imagem da galeria.',
                    color: ReciclaColors.warning,
                    bgColor: ReciclaColors.warningSurface,
                  ),
                ],

                const SizedBox(height: ReciclaSpacing.s4),
                if (_loading) ...[
                  const LinearProgressIndicator(),
                  const SizedBox(height: ReciclaSpacing.s3),
                  Text(
                    'Analisando imagem…',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],

                if (_error != null) ...[
                  const SizedBox(height: ReciclaSpacing.s2),
                  _buildToast(
                    icon: Icons.error_outline,
                    text: _error!,
                    color: ReciclaColors.error,
                    bgColor: ReciclaColors.errorSurface,
                  ),
                ],

                if (_result != null) ...[
                  const SizedBox(height: ReciclaSpacing.s6),
                  const Divider(),
                  const SizedBox(height: ReciclaSpacing.s4),
                  ResultPanel(result: _result!),
                ],

                const SizedBox(height: ReciclaSpacing.s6),
                Text(
                  'Aviso: Informações educacionais, não substituem orientação técnica ou jurídica. As imagens enviadas podem ser armazenadas e usadas para depuração, melhoria e treinamento do modelo.',
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
