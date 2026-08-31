import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reciclamack_web/src/widgets/totem_pair_layout.dart';
import 'package:reciclamack_web/src/widgets/totem_result_panels.dart';

void main() {
  testWidgets('places equal square panels side by side in landscape', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1366, 768));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TotemPairLayout(
            first: ColoredBox(color: Colors.red),
            second: ColoredBox(color: Colors.blue),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('totem-landscape-pair')), findsOneWidget);
    expect(find.byKey(const Key('totem-portrait-pair')), findsNothing);
    final boxes = tester.widgetList<SizedBox>(find.byType(SizedBox)).where(
          (box) => box.width != null && box.width == box.height,
        );
    expect(boxes.length, greaterThanOrEqualTo(2));
  });

  testWidgets('stacks equal square panels in portrait', (tester) async {
    await tester.binding.setSurfaceSize(const Size(768, 1366));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TotemPairLayout(
            first: ColoredBox(color: Colors.red),
            second: ColoredBox(color: Colors.blue),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('totem-portrait-pair')), findsOneWidget);
    expect(find.byKey(const Key('totem-landscape-pair')), findsNothing);
  });

  testWidgets('fits the actionable result in one square without scrolling', (
    tester,
  ) async {
    final result = <String, dynamic>{
      'detections': [
        {
          'class_name': 'mobile_phone_tablet',
          'display_label_pt_br': 'telefone celular, tablet e e-reader',
          'confidence': 0.92,
        },
      ],
      'guidance': [
        {
          'hazard_summary': 'Risco baixo, exceto pela bateria interna.',
          'typical_contents': [
            'placa eletrônica',
            'plástico',
            'bateria',
            'metais'
          ],
          'disposal_steps': [
            'Faça uma cópia dos dados importantes.',
            'Apague os dados pessoais.',
            'Não coloque o aparelho no lixo comum.',
            'Leve o aparelho a um ponto autorizado.',
          ],
          'legal_basis': [
            'PNRS Lei 12.305/2010 - https://www.planalto.gov.br/lei',
            'Decreto 10.240/2020 - https://www.planalto.gov.br/decreto',
            'ABREMA Panorama - https://www.abrema.org.br/panorama/',
          ],
        },
      ],
      'next_best_action': 'Leve o equipamento a um ponto de coleta autorizado.',
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox.square(
              dimension: 600,
              child: MediaQuery(
                data: const MediaQueryData(
                  textScaler: TextScaler.linear(1.5),
                ),
                child: TotemActionablePanel(
                  result: result,
                  remainingSeconds: 20,
                  totalSeconds: 20,
                  onFinishNow: () {},
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(Scrollable), findsNothing);
    expect(find.textContaining('Próxima etapa em 20 s'), findsOneWidget);
    expect(find.text('FONTES DOS DADOS'), findsOneWidget);
    expect(find.textContaining('planalto.gov.br'), findsWidgets);
  });
}
