import 'package:flutter_test/flutter_test.dart';
import 'package:reciclamack_web/src/totem_result_sequence.dart';

void main() {
  test('shows actionable guidance for 20 seconds and closing for 3', () {
    final sequence = TotemResultSequence();

    expect(sequence.stage, TotemResultStage.actionable);
    expect(sequence.remainingSeconds, 20);

    for (var second = 1; second < 20; second++) {
      expect(sequence.tick(), isFalse);
    }
    expect(sequence.stage, TotemResultStage.actionable);
    expect(sequence.remainingSeconds, 1);

    expect(sequence.tick(), isFalse);
    expect(sequence.stage, TotemResultStage.closing);
    expect(sequence.remainingSeconds, 3);

    for (var second = 1; second < 3; second++) {
      expect(sequence.tick(), isFalse);
    }
    expect(sequence.remainingSeconds, 1);
    expect(sequence.tick(), isTrue);
  });

  test('early finish starts the three-second closing page', () {
    final sequence = TotemResultSequence()..showClosing();

    expect(sequence.stage, TotemResultStage.closing);
    expect(sequence.remainingSeconds, 3);
  });
}
