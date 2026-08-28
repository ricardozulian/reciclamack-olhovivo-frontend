import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../design_tokens.dart';

class AnnotatedImage extends StatelessWidget {
  const AnnotatedImage({
    required this.bytes,
    required this.imageWidth,
    required this.imageHeight,
    required this.detections,
    this.loading = false,
    super.key,
  });

  final Uint8List bytes;
  final int imageWidth;
  final int imageHeight;
  final List<Map<String, dynamic>> detections;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final validWidth = imageWidth > 0 ? imageWidth : 4;
    final validHeight = imageHeight > 0 ? imageHeight : 3;
    return Semantics(
      label: detections.isEmpty
          ? 'Imagem enviada sem detecções'
          : 'Imagem analisada com ${detections.length} detecções',
      child: AspectRatio(
        aspectRatio: validWidth / validHeight,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(ReciclaRadii.md),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(
                color: ReciclaColors.bgDeep,
                child: _resultImage(),
              ),
              if (detections.isNotEmpty && imageWidth > 0 && imageHeight > 0)
                CustomPaint(
                  key: const Key('detection-overlay'),
                  painter: DetectionBoxPainter(
                    imageSize:
                        Size(imageWidth.toDouble(), imageHeight.toDouble()),
                    detections: detections,
                  ),
                ),
              if (loading)
                ColoredBox(
                  color: Colors.black.withValues(alpha: 0.42),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: ReciclaSpacing.s3),
                        Text(
                          'Analisando imagem…',
                          style: TextStyle(
                            color: ReciclaColors.fg1,
                            fontWeight: FontWeight.w600,
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
    );
  }

  Widget _resultImage() {
    if (!kIsWeb) {
      return Image.memory(
        bytes,
        key: ObjectKey(bytes),
        fit: BoxFit.contain,
        gaplessPlayback: true,
      );
    }
    return Image.network(
      'data:${_mediaType()};base64,${base64Encode(bytes)}',
      key: ObjectKey(bytes),
      fit: BoxFit.contain,
      gaplessPlayback: true,
      webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
      errorBuilder: (context, error, stackTrace) => const Center(
        child: Text(
          'Não foi possível mostrar a imagem confirmada.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  String _mediaType() {
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4e &&
        bytes[3] == 0x47) {
      return 'image/png';
    }
    if (bytes.length >= 6 &&
        bytes[0] == 0x47 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46) {
      return 'image/gif';
    }
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'image/webp';
    }
    return 'image/jpeg';
  }
}

class DetectionBoxPainter extends CustomPainter {
  DetectionBoxPainter({
    required this.imageSize,
    required this.detections,
  });

  final Size imageSize;
  final List<Map<String, dynamic>> detections;

  static const List<Color> _palette = [
    Color(0xFF34D399),
    Color(0xFF60A5FA),
    Color(0xFFFBBF24),
    Color(0xFFF472B6),
    Color(0xFFA78BFA),
    Color(0xFFFB7185),
    Color(0xFF22D3EE),
    Color(0xFFA3E635),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (imageSize.width <= 0 || imageSize.height <= 0) return;
    final scale =
        math.min(size.width / imageSize.width, size.height / imageSize.height);
    final rendered = Size(imageSize.width * scale, imageSize.height * scale);
    final offset = Offset(
      (size.width - rendered.width) / 2,
      (size.height - rendered.height) / 2,
    );

    for (final detection in detections) {
      final bbox = detection['bbox'];
      if (bbox is! Map) continue;
      final x1 = _coordinate(bbox['x1'], imageSize.width);
      final y1 = _coordinate(bbox['y1'], imageSize.height);
      final x2 = _coordinate(bbox['x2'], imageSize.width);
      final y2 = _coordinate(bbox['y2'], imageSize.height);
      if (x2 <= x1 || y2 <= y1) continue;

      final classId = (detection['class_id'] as num?)?.toInt() ?? 0;
      final color = _palette[classId.abs() % _palette.length];
      final rect = Rect.fromLTRB(
        offset.dx + x1 * scale,
        offset.dy + y1 * scale,
        offset.dx + x2 * scale,
        offset.dy + y2 * scale,
      );
      canvas.drawRect(
        rect,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
      final label =
          '${detection['display_label_pt_br'] ?? detection['class_name'] ?? 'objeto'} '
          '${(((detection['confidence'] as num?) ?? 0) * 100).round()}%';
      _paintLabel(canvas, rect, label, color, size);
    }
  }

  double _coordinate(dynamic value, double maximum) {
    final number = (value as num?)?.toDouble() ?? 0;
    return number.clamp(0, maximum).toDouble();
  }

  void _paintLabel(
      Canvas canvas, Rect box, String label, Color color, Size canvasSize) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: math.max(80, canvasSize.width - 16));
    const padding = EdgeInsets.symmetric(horizontal: 7, vertical: 4);
    final labelSize = Size(
      textPainter.width + padding.horizontal,
      textPainter.height + padding.vertical,
    );
    final left = box.left
        .clamp(0, math.max(0, canvasSize.width - labelSize.width))
        .toDouble();
    var top = box.top - labelSize.height;
    if (top < 0) top = box.top;
    final labelRect =
        Rect.fromLTWH(left, top, labelSize.width, labelSize.height);
    canvas.drawRRect(
      RRect.fromRectAndRadius(labelRect, const Radius.circular(4)),
      Paint()..color = color,
    );
    textPainter.paint(
      canvas,
      Offset(labelRect.left + padding.left, labelRect.top + padding.top),
    );
  }

  @override
  bool shouldRepaint(covariant DetectionBoxPainter oldDelegate) {
    return oldDelegate.imageSize != imageSize ||
        oldDelegate.detections != detections;
  }
}
