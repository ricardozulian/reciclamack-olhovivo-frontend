import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../design_tokens.dart';

class TotemPairLayout extends StatelessWidget {
  const TotemPairLayout({
    required this.first,
    required this.second,
    super.key,
  });

  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = ReciclaSpacing.s4;
        final landscape = constraints.maxWidth >= constraints.maxHeight;
        final side = landscape
            ? math.min((constraints.maxWidth - gap) / 2, constraints.maxHeight)
            : math.min(constraints.maxWidth, (constraints.maxHeight - gap) / 2);
        final safeSide = math.max(0.0, side);
        final panels = [
          SizedBox.square(dimension: safeSide, child: first),
          SizedBox.square(dimension: safeSide, child: second),
        ];
        return Center(
          child: landscape
              ? Row(
                  key: const Key('totem-landscape-pair'),
                  mainAxisSize: MainAxisSize.min,
                  children: [panels[0], const SizedBox(width: gap), panels[1]],
                )
              : Column(
                  key: const Key('totem-portrait-pair'),
                  mainAxisSize: MainAxisSize.min,
                  children: [panels[0], const SizedBox(height: gap), panels[1]],
                ),
        );
      },
    );
  }
}
