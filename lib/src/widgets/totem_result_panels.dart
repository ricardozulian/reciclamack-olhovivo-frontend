import 'package:flutter/material.dart';

import '../design_tokens.dart';

class TotemActionablePanel extends StatelessWidget {
  const TotemActionablePanel({
    required this.result,
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.onFinishNow,
    super.key,
  });

  final Map<String, dynamic> result;
  final int remainingSeconds;
  final int totalSeconds;
  final VoidCallback onFinishNow;

  @override
  Widget build(BuildContext context) {
    final detections = _mapList(result['detections']);
    final guidance = _mapList(result['guidance']);
    final detection =
        detections.isEmpty ? const <String, dynamic>{} : detections.first;
    final guide = guidance.isEmpty ? const <String, dynamic>{} : guidance.first;
    final contents =
        (guide['typical_contents'] as List?)?.map((e) => '$e').toList() ??
            const [];
    final steps =
        (guide['disposal_steps'] as List?)?.map((e) => '$e').toList() ??
            const [];
    final sources =
        (guide['legal_basis'] as List?)?.map((e) => '$e').toList() ?? const [];
    final progress = totalSeconds <= 0 ? 0.0 : remainingSeconds / totalSeconds;

    return _SquarePanel(
      color: ReciclaColors.primary,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact =
              constraints.maxWidth < 800 || constraints.maxHeight < 800;
          final bodySize = compact ? 16.0 : 18.0;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.recycling, color: ReciclaColors.primary),
                  const SizedBox(width: ReciclaSpacing.s2),
                  Expanded(
                    child: Text(
                      'Próxima etapa em $remainingSeconds s',
                      style: TextStyle(
                        fontSize: bodySize,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    key: const Key('totem-finish-now'),
                    onPressed: onFinishNow,
                    icon: const Icon(Icons.skip_next),
                    label: Text(compact ? 'Outro item' : 'Analisar outro item'),
                  ),
                ],
              ),
              const SizedBox(height: ReciclaSpacing.s2),
              LinearProgressIndicator(
                value: progress.clamp(0, 1),
                color: ReciclaColors.primary,
                backgroundColor: ReciclaColors.primarySurface,
              ),
              const SizedBox(height: ReciclaSpacing.s2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      '${detection['display_label_pt_br'] ?? detection['class_name'] ?? 'Equipamento identificado'}',
                      maxLines: compact ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: compact ? 28 : 34,
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                      ),
                    ),
                  ),
                  const SizedBox(width: ReciclaSpacing.s2),
                  Text(
                    '${(((detection['confidence'] as num?) ?? 0) * 100).round()}%',
                    style: TextStyle(
                      color: ReciclaColors.primaryLight,
                      fontSize: bodySize,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: ReciclaSpacing.s2),
              _disposalSection(
                steps,
                bodySize,
                limit: compact ? 2 : 3,
                stepLines: compact ? 1 : 2,
              ),
              const SizedBox(height: ReciclaSpacing.s2),
              _section(
                'ATENÇÃO',
                '${guide['hazard_summary'] ?? ''}',
                bodySize,
                maxLines: 1,
              ),
              if (!compact) ...[
                const SizedBox(height: ReciclaSpacing.s2),
                _section(
                  'CONTEÚDO TÍPICO',
                  _limitedItems(contents, 4),
                  bodySize,
                  maxLines: 1,
                ),
              ],
              if (sources.isNotEmpty) ...[
                const SizedBox(height: ReciclaSpacing.s2),
                _sourceSection(
                  sources,
                  bodySize,
                  limit: compact ? 1 : 2,
                ),
              ],
              const Spacer(),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(ReciclaSpacing.s3),
                decoration: BoxDecoration(
                  color: ReciclaColors.successSurface,
                  borderRadius: BorderRadius.circular(ReciclaRadii.sm),
                ),
                child: Text(
                  '${result['next_best_action'] ?? ''}',
                  maxLines: compact ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: ReciclaColors.primaryLight,
                    fontSize: bodySize,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _section(
    String label,
    String value,
    double bodySize, {
    required int maxLines,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: ReciclaColors.primaryLight,
            fontSize: bodySize - 2,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: ReciclaSpacing.s1),
        Text(
          value,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: bodySize, height: 1.3),
        ),
      ],
    );
  }

  String _limitedItems(List<String> values, int limit) {
    final shown = values.take(limit).join(' • ');
    final remaining = values.length - limit;
    return remaining > 0 ? '$shown • +$remaining itens' : shown;
  }

  String _sourceLabel(String source) {
    final separator = source.indexOf(' - http');
    if (separator < 0) return source;
    final title = source.substring(0, separator);
    final url = source.substring(separator + 3);
    final host = Uri.tryParse(url)?.host.replaceFirst('www.', '') ?? '';
    return host.isEmpty ? title : '$title · $host';
  }

  Widget _sourceSection(
    List<String> sources,
    double bodySize, {
    required int limit,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FONTES DOS DADOS',
          style: TextStyle(
            color: ReciclaColors.info,
            fontSize: bodySize - 2,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: ReciclaSpacing.s1),
        ...sources.take(limit).map(
              (source) => Text(
                _sourceLabel(source),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: bodySize - 2, height: 1.2),
              ),
            ),
        if (sources.length > limit)
          Text(
            '+${sources.length - limit} fontes',
            style: TextStyle(fontSize: bodySize - 2),
          ),
      ],
    );
  }

  Widget _disposalSection(
    List<String> steps,
    double bodySize, {
    required int limit,
    required int stepLines,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DESCARTE CORRETO',
          style: TextStyle(
            color: ReciclaColors.primaryLight,
            fontSize: bodySize - 2,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: ReciclaSpacing.s1),
        ...steps.take(limit).toList().asMap().entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  '${entry.key + 1}. ${entry.value}',
                  maxLines: stepLines,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: bodySize, height: 1.2),
                ),
              ),
            ),
        if (steps.length > limit)
          Text(
            '+${steps.length - limit} etapas',
            style: TextStyle(fontSize: bodySize),
          ),
      ],
    );
  }
}

class TotemRemoveItemPanel extends StatelessWidget {
  const TotemRemoveItemPanel({required this.remainingSeconds, super.key});

  final int remainingSeconds;

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFF97316);
    return _SquarePanel(
      color: orange,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.pan_tool_alt_outlined, color: orange, size: 88),
          const SizedBox(height: ReciclaSpacing.s6),
          const Text(
            'Retire o item da câmera',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: ReciclaSpacing.s6),
          Text(
            '$remainingSeconds',
            key: const Key('totem-closing-countdown'),
            style: const TextStyle(
              color: orange,
              fontSize: 88,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: ReciclaSpacing.s6),
          const Text(
            'A próxima leitura começa automaticamente.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class TotemLegalPanel extends StatelessWidget {
  const TotemLegalPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SquarePanel(
      color: ReciclaColors.info,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline, color: ReciclaColors.info, size: 58),
          SizedBox(height: ReciclaSpacing.s5),
          Text(
            'Aviso importante',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: ReciclaSpacing.s5),
          Text(
            '• A inteligência artificial pode apresentar erros.\n\n'
            '• Estas informações são educacionais. Elas não substituem orientação técnica, legal ou jurídica.\n\n'
            '• Imagens retidas e previsões automáticas não constituem dados auditados.',
            style: TextStyle(fontSize: 18, height: 1.4),
          ),
          SizedBox(height: ReciclaSpacing.s5),
          Text(
            'Base legal: PNRS — Lei 12.305/2010 e Decreto 10.240/2020.',
            style: TextStyle(
              color: ReciclaColors.info,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SquarePanel extends StatelessWidget {
  const _SquarePanel({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ReciclaColors.bgElevated,
        border: Border.all(color: color.withValues(alpha: 0.65), width: 2),
        borderRadius: BorderRadius.circular(ReciclaRadii.md),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(ReciclaRadii.md - 2),
        child: Padding(
          padding: const EdgeInsets.all(ReciclaSpacing.s5),
          child: child,
        ),
      ),
    );
  }
}

List<Map<String, dynamic>> _mapList(dynamic value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((item) => item.cast<String, dynamic>())
      .toList();
}
