import 'package:flutter/material.dart';

import '../date_key.dart';
import '../theme.dart';

/// Bottom sheet to pick a start date for scheduling a multi-day plan.
Future<String?> showPlanScheduleStartDateSheet(
  BuildContext context, {
  required String planTitle,
  required int workoutCount,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: LiftBigColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => _PlanScheduleStartSheet(
      planTitle: planTitle,
      workoutCount: workoutCount,
    ),
  );
}

class _PlanScheduleStartSheet extends StatefulWidget {
  const _PlanScheduleStartSheet({
    required this.planTitle,
    required this.workoutCount,
  });

  final String planTitle;
  final int workoutCount;

  @override
  State<_PlanScheduleStartSheet> createState() =>
      _PlanScheduleStartSheetState();
}

class _PlanScheduleStartSheetState extends State<_PlanScheduleStartSheet> {
  late DateTime _start;

  @override
  void initState() {
    super.initState();
    _start = DateTime.now();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _start = picked);
  }

  void _apply() {
    Navigator.pop(context, toDateKey(_start));
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: LiftBigColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Text(
            'Add to calendar',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            widget.planTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          Text(
            '${widget.workoutCount} workouts · one per day in order',
            textAlign: TextAlign.center,
            style: const TextStyle(color: LiftBigColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 16),
          const Text(
            'START DATE',
            style: TextStyle(
              color: LiftBigColors.muted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _pickDate,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(formatDisplayDate(toDateKey(_start))),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: _apply,
                  child: const Text('Apply to calendar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
