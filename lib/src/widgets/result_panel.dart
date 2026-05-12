import 'package:flutter/material.dart';

import '../design_tokens.dart';

class ResultPanel extends StatelessWidget {
  const ResultPanel({required this.result, super.key});

  final Map<String, dynamic> result;

  List<Map<String, dynamic>> _mapList(dynamic value) {
    if (value is! List) {
      return const [];
    }
    return value.whereType<Map>().map((item) => item.cast<String, dynamic>()).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final detections = _mapList(result['detections']);
    final guidance = _mapList(result['guidance']);
    final uncertain = result['uncertainty_flag'] == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Meta info ──
        Text(
          'Modelo: ${result['model_version']} · Conteúdo: ${result['content_version']}',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: ReciclaSpacing.s4),

        // ── Detections ──
        Text(
          'DETECÇÕES',
          style: theme.textTheme.labelSmall?.copyWith(
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: ReciclaSpacing.s3),
        if (detections.isEmpty)
          Text(
            'Nenhuma detecção com confiança suficiente.',
            style: theme.textTheme.bodyMedium,
          )
        else
          ...detections.map(
            (d) => Padding(
              padding: const EdgeInsets.only(bottom: ReciclaSpacing.s2),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: ReciclaColors.bgCard,
                  border: Border.all(color: ReciclaColors.border),
                  borderRadius: BorderRadius.circular(ReciclaRadii.md),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${d['display_label_pt_br'] ?? d['class_name'] ?? 'desconhecido'}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: ReciclaColors.fg1,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: ReciclaColors.primarySurface,
                        border: Border.all(color: ReciclaColors.primaryBorder),
                        borderRadius: BorderRadius.circular(ReciclaRadii.pill),
                      ),
                      child: Text(
                        ((d['confidence'] as num?) ?? 0).toStringAsFixed(2),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: ReciclaColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        const SizedBox(height: ReciclaSpacing.s4),
        const Divider(),
        const SizedBox(height: ReciclaSpacing.s4),

        // ── Guidance ──
        Text(
          'ORIENTAÇÕES',
          style: theme.textTheme.labelSmall?.copyWith(
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: ReciclaSpacing.s3),
        ...guidance.map(
          (g) => Padding(
            padding: const EdgeInsets.only(bottom: ReciclaSpacing.s3),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ReciclaColors.bgCard,
                border: Border.all(color: ReciclaColors.border),
                borderRadius: BorderRadius.circular(ReciclaRadii.md),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with icon
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: ReciclaColors.catImpactSurface,
                          borderRadius: BorderRadius.circular(ReciclaRadii.sm),
                        ),
                        child: const Icon(
                          Icons.warning_amber_rounded,
                          color: ReciclaColors.catImpact,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${g['display_label_pt_br'] ?? g['class_name'] ?? 'Classe não informada'}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: ReciclaColors.fg1,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${g['hazard_summary'] ?? ''}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: ReciclaColors.fg2,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Typical contents
                  if ((g['typical_contents'] as List<dynamic>?)?.isNotEmpty == true) ...[
                    _sectionLabel('CONTEÚDO TÍPICO'),
                    const SizedBox(height: 4),
                    ...((g['typical_contents'] as List<dynamic>).map(
                      (item) => _bulletItem('$item', ReciclaColors.primary, '•'),
                    )),
                    const SizedBox(height: 10),
                  ],

                  // Disposal steps
                  if ((g['disposal_steps'] as List<dynamic>?)?.isNotEmpty == true) ...[
                    _sectionLabel('DESCARTE CORRETO'),
                    const SizedBox(height: 4),
                    ...((g['disposal_steps'] as List<dynamic>).asMap().entries.map(
                      (e) => _bulletItem('${e.value}', ReciclaColors.primary, '${e.key + 1}.'),
                    )),
                    const SizedBox(height: 10),
                  ],

                  // Legal basis
                  if ((g['legal_basis'] as List<dynamic>?)?.isNotEmpty == true) ...[
                    _sectionLabel('BASE LEGAL'),
                    const SizedBox(height: 4),
                    ...((g['legal_basis'] as List<dynamic>).map(
                      (law) => _bulletItem('$law', ReciclaColors.info, '§'),
                    )),
                  ],
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: ReciclaSpacing.s3),

        // ── Next Best Action ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: uncertain ? ReciclaColors.warningSurface : ReciclaColors.successSurface,
            border: Border.all(
              color: (uncertain ? ReciclaColors.warning : ReciclaColors.success)
                  .withValues(alpha: 0.25),
            ),
            borderRadius: BorderRadius.circular(ReciclaRadii.sm),
          ),
          child: Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                color: uncertain ? ReciclaColors.warning : ReciclaColors.success,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${result['next_best_action'] ?? ''}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: uncertain ? ReciclaColors.warning : ReciclaColors.success,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: ReciclaColors.fg3,
        letterSpacing: 0.6,
      ),
    );
  }

  Widget _bulletItem(String text, Color bulletColor, String bullet) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 20,
            child: Text(
              bullet,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: bulletColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: ReciclaColors.fg2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
