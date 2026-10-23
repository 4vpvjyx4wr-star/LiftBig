import 'package:flutter/material.dart';

import '../theme.dart';

/// Plan or workout description, collapsed to a single row until opened.
class WorkoutDetailsSection extends StatefulWidget {
  const WorkoutDetailsSection({
    super.key,
    required this.text,
    this.style,
  });

  final String text;
  final TextStyle? style;

  @override
  State<WorkoutDetailsSection> createState() => _WorkoutDetailsSectionState();
}

class _WorkoutDetailsSectionState extends State<WorkoutDetailsSection> {
  var _open = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => setState(() => _open = !_open),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Details/Instructions',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.liftBig.foreground,
                    ),
                  ),
                ),
                Icon(
                  _open ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                  color: context.liftBig.muted,
                ),
              ],
            ),
          ),
        ),
        if (_open)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 4),
            child: Text(widget.text, style: widget.style),
          ),
      ],
    );
  }
}
