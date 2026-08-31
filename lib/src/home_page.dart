import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'analysis_api.dart';
import 'design_tokens.dart';
import 'widgets/annotated_image.dart';
import 'widgets/brand_app_bar.dart';
import 'widgets/result_panel.dart';
import 'widgets/shared_page_content.dart';

/// The manual upload and capture page for the normal web application.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const int _maxUploadBytes = 10 * 1024 * 1024;

  final ImagePicker _picker = ImagePicker();
  final AnalysisApi _api = AnalysisApi();
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _result;
  Uint8List? _selectedBytes;
  String? _selectedName;
  late final bool _cameraSecureContext;

  @override
  void initState() {
    super.initState();
    _cameraSecureContext = _isSecureCameraContext();
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
      final analyzed = await _api.analyzeWithRetry(filename, bytes);
      if (!mounted) return;
      setState(() {
        _result = analyzed;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error =
            'Falha ao analisar a imagem. Verifique o sistema e tente novamente.';
        _loading = false;
      });
    }
  }

  Future<void> _retryAnalysis() async {
    final bytes = _selectedBytes;
    final name = _selectedName;
    if (bytes != null && name != null) await _analyzeBytes(name, bytes);
  }

  int _responseDimension(String key) => (_result?[key] as num?)?.toInt() ?? 0;

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
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      const SizedBox(height: ReciclaSpacing.s4),
                      buildEducationBadge(theme),
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
                _buildActions(),
                if (!_cameraSecureContext) ...[
                  const SizedBox(height: ReciclaSpacing.s3),
                  buildNotice(
                    icon: Icons.warning_amber_rounded,
                    text:
                        'Câmera web exige contexto seguro (HTTPS). Em HTTP, envie uma imagem da galeria.',
                    color: ReciclaColors.warning,
                    bgColor: ReciclaColors.warningSurface,
                  ),
                ],
                if (bytes != null) ...[
                  const SizedBox(height: ReciclaSpacing.s4),
                  AnnotatedImage(
                    bytes: bytes,
                    imageWidth: _responseDimension('image_width'),
                    imageHeight: _responseDimension('image_height'),
                    detections: detectionsFrom(_result),
                    loading: _loading,
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: ReciclaSpacing.s3),
                  buildNotice(
                    icon: Icons.error_outline,
                    text: _error!,
                    color: ReciclaColors.error,
                    bgColor: ReciclaColors.errorSurface,
                  ),
                  if (bytes != null)
                    Padding(
                      padding: const EdgeInsets.only(top: ReciclaSpacing.s3),
                      child: OutlinedButton.icon(
                        onPressed: _loading ? null : _retryAnalysis,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Tentar análise novamente'),
                      ),
                    ),
                ],
                if (_result != null) ...[
                  const SizedBox(height: ReciclaSpacing.s6),
                  const Divider(),
                  const SizedBox(height: ReciclaSpacing.s4),
                  ResultPanel(result: _result!),
                ],
                const SizedBox(height: ReciclaSpacing.s6),
                buildLegalNotice(theme),
                const SizedBox(height: ReciclaSpacing.s8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActions() => Center(
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

Widget buildNotice({
  required IconData icon,
  required String text,
  required Color color,
  required Color bgColor,
}) =>
    Container(
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
