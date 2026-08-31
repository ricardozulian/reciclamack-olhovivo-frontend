import 'package:flutter/material.dart';

import '../design_tokens.dart';

Widget buildEducationBadge(ThemeData theme) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: ReciclaColors.primarySurface,
        border: Border.all(color: ReciclaColors.primaryBorder),
        borderRadius: BorderRadius.circular(ReciclaRadii.pill),
      ),
      child: Text('EDUCAÇÃO EM E-LIXO', style: theme.textTheme.labelMedium),
    );

Widget buildLegalNotice(ThemeData theme) => Text(
      'Aviso:\n'
      '• Este sistema utiliza inteligência artificial e pode apresentar erros.\n'
      '• As informações são educacionais e não substituem orientação técnica, legal ou jurídica.\n'
      '• Imagens eventualmente retidas e previsões automáticas não constituem dados auditados.',
      style: theme.textTheme.bodySmall,
    );
