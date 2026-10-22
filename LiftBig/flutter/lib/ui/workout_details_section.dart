import 'package:flutter/material.dart';

import '../theme.dart';

/// Plan or workout description, collapsed under the day title.
class WorkoutDetailsSection extends StatelessWidget {
  const WorkoutDetailsSection({
    super.key,
    required this.text,
    this.style,
  });

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: false,
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(top: 4),
        visualDensity: VisualDensity.compact,
        dense: true,
        minTileHeight: 32,
        iconColor: context.liftBig.muted,
        collapsedIconColor: context.liftBig.muted,
        textColor: context.liftBig.foreground,
        collapsedTextColor: context.liftBig.foreground,
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
        expandedAlignment: Alignment.centerLeft,
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        shape: const Border(),
        collapsedShape: const Border(),
        title:  Text(
          'Details/Instructions',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: context.liftBig.foreground,
          ),
        ),
        children: [
          SizedBox(
            width: double.infinity,
            child: Text(text, style: style),
          ),
        ],
      ),
    );
  }
}
