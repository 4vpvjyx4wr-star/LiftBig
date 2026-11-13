import 'package:flutter/material.dart';

import '../theme.dart';

/// White ring with 45 in the middle, matching the dark list tiles.
class Plate45Icon extends StatelessWidget {
  const Plate45Icon({super.key, this.size = 28});

  final double size;

  @override
  Widget build(BuildContext context) {
    final color = context.liftBig.foreground;
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 1.6),
        ),
        child: Center(
          child: Text(
            '45',
            style: TextStyle(
              color: color,
              fontSize: size * 0.38,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class ForegroundIcon extends StatelessWidget {
  const ForegroundIcon(this.icon, {super.key, this.size = 22});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Icon(icon, size: size, color: context.liftBig.foreground);
  }
}

/// Menu row: foreground icon, then the label.
class ToolMenuLabel extends StatelessWidget {
  const ToolMenuLabel({super.key, required this.icon, required this.label});

  final Widget icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        icon,
        const SizedBox(width: 12),
        Flexible(child: Text(label)),
      ],
    );
  }
}
