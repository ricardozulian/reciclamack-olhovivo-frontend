class TotemScanDecision {
  const TotemScanDecision({this.confirmedClass});

  final String? confirmedClass;

  bool get shouldPersist => confirmedClass != null;
}

class TotemScanState {
  TotemScanState({required this.confirmationFrames, this.clearFrames = 2})
      : assert(confirmationFrames > 0),
        assert(clearFrames > 0);

  final int confirmationFrames;
  final int clearFrames;

  String? _candidateClass;
  int _candidateFrames = 0;
  int _emptyFrames = 0;
  bool _requiresClear = false;

  bool get requiresClear => _requiresClear;
  int get clearFrameCount => _emptyFrames;

  TotemScanDecision recordDetections(List<Map<String, dynamic>> detections) {
    final dominantName = dominantClass(detections);

    if (_requiresClear) {
      _recordClearFrame(dominantName == null);
      return const TotemScanDecision();
    }

    if (dominantName == null) {
      _resetCandidate();
      return const TotemScanDecision();
    }

    if (_candidateClass == dominantName) {
      _candidateFrames += 1;
    } else {
      _candidateClass = dominantName;
      _candidateFrames = 1;
    }

    if (_candidateFrames < confirmationFrames) {
      return const TotemScanDecision();
    }

    _resetCandidate();
    return TotemScanDecision(confirmedClass: dominantName);
  }

  void requireClear() {
    _requiresClear = true;
    _emptyFrames = 0;
    _resetCandidate();
  }

  void _recordClearFrame(bool isEmpty) {
    if (!isEmpty) {
      _emptyFrames = 0;
      return;
    }
    _emptyFrames += 1;
    if (_emptyFrames >= clearFrames) {
      _requiresClear = false;
      _emptyFrames = 0;
    }
  }

  void _resetCandidate() {
    _candidateClass = null;
    _candidateFrames = 0;
  }

  String? dominantClass(List<Map<String, dynamic>> detections) {
    Map<String, dynamic>? dominant;
    var dominantArea = -1.0;
    for (final detection in detections) {
      final bbox = detection['bbox'];
      final className = detection['class_name'];
      if (bbox is! Map || className is! String || className.isEmpty) continue;
      final x1 = (bbox['x1'] as num?)?.toDouble();
      final y1 = (bbox['y1'] as num?)?.toDouble();
      final x2 = (bbox['x2'] as num?)?.toDouble();
      final y2 = (bbox['y2'] as num?)?.toDouble();
      if (x1 == null || y1 == null || x2 == null || y2 == null) continue;
      final width = x2 > x1 ? x2 - x1 : 0.0;
      final height = y2 > y1 ? y2 - y1 : 0.0;
      final area = width * height;
      if (area > dominantArea) {
        dominant = detection;
        dominantArea = area;
      }
    }
    return dominant?['class_name'] as String?;
  }
}

class TotemRetrySchedule {
  static const List<Duration> delays = [
    Duration(seconds: 2),
    Duration(seconds: 4),
    Duration(seconds: 8),
    Duration(seconds: 10),
  ];

  int _failureCount = 0;

  Duration recordFailure() {
    final index =
        _failureCount < delays.length ? _failureCount : delays.length - 1;
    _failureCount += 1;
    return delays[index];
  }

  void recordSuccess() {
    _failureCount = 0;
  }
}
