import 'package:flutter/material.dart';

import '../design_tokens.dart';
import '../totem_status.dart';

class TotemHintPanel extends StatelessWidget {
  const TotemHintPanel({required this.status, super.key});

  final TotemStatus status;

  @override
  Widget build(BuildContext context) {
    final presentation = _presentation(status.phase);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: presentation.color.withValues(alpha: 0.14),
        border: Border.all(
          color: presentation.color.withValues(alpha: 0.75),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(ReciclaRadii.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(ReciclaSpacing.s8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 440;
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  presentation.icon,
                  color: presentation.color,
                  size: compact ? 58 : 82,
                ),
                SizedBox(
                    height: compact ? ReciclaSpacing.s4 : ReciclaSpacing.s8),
                Text(
                  status.headline,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: ReciclaColors.fg1,
                    fontSize: compact ? 26 : 34,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                SizedBox(
                    height: compact ? ReciclaSpacing.s4 : ReciclaSpacing.s6),
                Text(
                  status.instruction,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: ReciclaColors.fg1,
                    fontSize: compact ? 17 : 21,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
                if (_isActive(status.phase)) ...[
                  const SizedBox(height: ReciclaSpacing.s8),
                  SizedBox(
                    width: compact ? 150 : 210,
                    child: LinearProgressIndicator(
                      color: presentation.color,
                      backgroundColor:
                          presentation.color.withValues(alpha: 0.2),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  bool _isActive(TotemPhase phase) {
    return phase == TotemPhase.initializing ||
        phase == TotemPhase.capturing ||
        phase == TotemPhase.analyzing ||
        phase == TotemPhase.confirming;
  }

  _HintPresentation _presentation(TotemPhase phase) {
    switch (phase) {
      case TotemPhase.initializing:
        return const _HintPresentation(ReciclaColors.primary, Icons.settings);
      case TotemPhase.scanning:
        return const _HintPresentation(
          ReciclaColors.primary,
          Icons.center_focus_strong,
        );
      case TotemPhase.capturing:
        return const _HintPresentation(Color(0xFF22D3EE), Icons.photo_camera);
      case TotemPhase.analyzing:
        return const _HintPresentation(ReciclaColors.info, Icons.search);
      case TotemPhase.candidate:
        return const _HintPresentation(
          ReciclaColors.warning,
          Icons.visibility,
        );
      case TotemPhase.confirming:
        return const _HintPresentation(
          ReciclaColors.warning,
          Icons.fact_check_outlined,
        );
      case TotemPhase.waitingForClear:
        return const _HintPresentation(
          Color(0xFFF97316),
          Icons.pan_tool_alt_outlined,
        );
      case TotemPhase.retrying:
        return const _HintPresentation(ReciclaColors.error, Icons.refresh);
      case TotemPhase.cameraError:
        return const _HintPresentation(
          ReciclaColors.error,
          Icons.videocam_off_outlined,
        );
    }
  }
}

class _HintPresentation {
  const _HintPresentation(this.color, this.icon);

  final Color color;
  final IconData icon;
}
