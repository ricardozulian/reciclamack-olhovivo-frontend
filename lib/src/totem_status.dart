enum TotemPhase {
  initializing,
  scanning,
  capturing,
  analyzing,
  candidate,
  confirming,
  waitingForClear,
  retrying,
  cameraError,
}

class TotemStatus {
  const TotemStatus({
    required this.phase,
    required this.headline,
    required this.instruction,
  });

  final TotemPhase phase;
  final String headline;
  final String instruction;
}
