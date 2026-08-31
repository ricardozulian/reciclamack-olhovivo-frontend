enum TotemResultStage { actionable, closing }

class TotemResultSequence {
  TotemResultSequence({
    this.actionableSeconds = 20,
    this.closingSeconds = 3,
  })  : assert(actionableSeconds > 0),
        assert(closingSeconds > 0),
        remainingSeconds = actionableSeconds;

  final int actionableSeconds;
  final int closingSeconds;

  TotemResultStage stage = TotemResultStage.actionable;
  int remainingSeconds;

  void reset() {
    stage = TotemResultStage.actionable;
    remainingSeconds = actionableSeconds;
  }

  void showClosing() {
    stage = TotemResultStage.closing;
    remainingSeconds = closingSeconds;
  }

  bool tick() {
    if (remainingSeconds > 1) {
      remainingSeconds -= 1;
      return false;
    }
    if (stage == TotemResultStage.actionable) {
      showClosing();
      return false;
    }
    return true;
  }
}
