import 'package:flutter_test/flutter_test.dart';
import 'package:reciclamack_web/src/totem_scan_state.dart';

Map<String, dynamic> detection(String className, double area) => {
      'class_name': className,
      'bbox': {'x1': 0, 'y1': 0, 'x2': area, 'y2': 1},
    };

void main() {
  test('confirms the first dominant frame in one-step mode', () {
    final state = TotemScanState(confirmationFrames: 1);

    expect(
      state.recordDetections(
          [detection('mobile_phone_tablet', 50)]).confirmedClass,
      'mobile_phone_tablet',
    );
  });

  test('confirms the largest class after two matching frames', () {
    final state = TotemScanState(confirmationFrames: 2);

    expect(
      state.recordDetections([
        detection('battery', 10),
        detection('laptop', 50),
      ]).shouldPersist,
      isFalse,
    );
    expect(
      state.recordDetections([
        detection('laptop', 50),
        detection('battery', 10),
      ]).confirmedClass,
      'laptop',
    );
  });

  test('empty and different-class probes reset confirmation', () {
    final state = TotemScanState(confirmationFrames: 2);

    state.recordDetections([detection('battery', 10)]);
    state.recordDetections([]);
    expect(
      state.recordDetections([detection('battery', 10)]).shouldPersist,
      isFalse,
    );
    expect(
      state.recordDetections([detection('laptop', 10)]).shouldPersist,
      isFalse,
    );
    expect(
      state.recordDetections([detection('laptop', 10)]).confirmedClass,
      'laptop',
    );
  });

  test('requires two empty probes before it rearms', () {
    final state = TotemScanState(confirmationFrames: 2)..requireClear();

    state.recordDetections([]);
    expect(state.requiresClear, isTrue);
    expect(state.clearFrameCount, 1);
    state.recordDetections([detection('battery', 10)]);
    expect(state.clearFrameCount, 0);
    state.recordDetections([]);
    expect(state.requiresClear, isTrue);
    expect(state.clearFrameCount, 1);
    state.recordDetections([]);
    expect(state.requiresClear, isFalse);
    expect(state.clearFrameCount, 0);
  });

  test('uses the specified retry delays and resets after success', () {
    final schedule = TotemRetrySchedule();

    expect(schedule.recordFailure(), const Duration(seconds: 2));
    expect(schedule.recordFailure(), const Duration(seconds: 4));
    expect(schedule.recordFailure(), const Duration(seconds: 8));
    expect(schedule.recordFailure(), const Duration(seconds: 10));
    expect(schedule.recordFailure(), const Duration(seconds: 10));
    schedule.recordSuccess();
    expect(schedule.recordFailure(), const Duration(seconds: 2));
  });
}
