import 'package:flutter_test/flutter_test.dart';

import 'package:reciclamack_web/main.dart';

void main() {
  testWidgets('renders web upload actions', (tester) async {
    await tester.pumpWidget(const ReciclaMackApp());

    expect(find.text('Selecionar foto'), findsOneWidget);
    expect(find.text('Capturar câmera'), findsOneWidget);
    expect(find.textContaining('Envie uma foto'), findsOneWidget);
  });
}
