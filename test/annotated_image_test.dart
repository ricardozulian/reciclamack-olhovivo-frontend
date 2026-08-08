import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reciclamack_web/src/widgets/annotated_image.dart';

void main() {
  testWidgets('renders an overlay for valid detections', (tester) async {
    final bytes = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 400,
          child: AnnotatedImage(
            bytes: bytes,
            imageWidth: 100,
            imageHeight: 50,
            detections: const [
              {
                'class_id': 0,
                'class_name': 'battery',
                'display_label_pt_br': 'bateria',
                'confidence': 0.92,
                'bbox': {'x1': 10, 'y1': 5, 'x2': 80, 'y2': 40},
              },
            ],
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('detection-overlay')), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('does not render boxes for invalid coordinates', (tester) async {
    final bytes = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: AnnotatedImage(
          bytes: bytes,
          imageWidth: 0,
          imageHeight: 0,
          detections: const [],
        ),
      ),
    );

    expect(find.byKey(const Key('detection-overlay')), findsNothing);
  });
}
