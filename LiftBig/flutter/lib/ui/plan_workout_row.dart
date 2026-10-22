import 'package:flutter/material.dart';

import '../catalog/liftbig_catalog.dart';
import '../theme.dart';

/// One day inside a plan. Tapping the day name shows or hides its lifts.
class PlanWorkoutRow extends StatefulWidget {
  const PlanWorkoutRow({
    super.key,
    required this.workout,
    this.trailing,
  });

  final CatalogWorkout workout;
  final Widget? trailing;

  @override
  State<PlanWorkoutRow> createState() => _PlanWorkoutRowState();
}

class _PlanWorkoutRowState extends State<PlanWorkoutRow> {
  var _open = false;

  @override
  Widget build(BuildContext context) {
    final workout = widget.workout;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => setState(() => _open = !_open),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            workout.name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Icon(
                          _open ? Icons.expand_less : Icons.expand_more,
                          color: LiftBigColors.muted,
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (widget.trailing != null) widget.trailing!,
          ],
        ),
        if (_open)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: LiftBigColors.cardInner,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: LiftBigColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (workout.lifts.isEmpty)
                      const Text(
                        'No lifts in this day.',
                        style: TextStyle(color: LiftBigColors.muted, fontSize: 13),
                      )
                    else
                      for (final lift in workout.lifts)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            '${lift.name} · ${lift.sets.length} sets',
                            style: const TextStyle(
                              color: LiftBigColors.muted,
                              fontSize: 13,
                            ),
                          ),
                        ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
