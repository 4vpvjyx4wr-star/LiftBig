import 'package:flutter/material.dart';

import '../theme.dart';
import '../utils/variable_machine.dart';
import '../utils/weight_units.dart';

/// Compact starting-weight field plus per-set plate hint for variable machines.
class MachineStartingWeightField extends StatelessWidget {
  const MachineStartingWeightField({
    super.key,
    required this.kind,
    required this.controller,
    required this.unit,
    required this.onChanged,
  });

  final VariableMachineKind kind;
  final TextEditingController controller;
  final WeightUnit unit;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final unitLabel = unit == WeightUnit.lb ? 'lb' : 'kg';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              startingWeightLabel(kind),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: LiftBigColors.muted,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
                hintText: unitLabel,
                filled: true,
                fillColor: LiftBigColors.cardInner,
              ),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class MachineSetPlateHint extends StatelessWidget {
  const MachineSetPlateHint({
    super.key,
    required this.kind,
    required this.startingController,
    required this.weightController,
    required this.unit,
  });

  final VariableMachineKind kind;
  final TextEditingController startingController;
  final TextEditingController weightController;
  final WeightUnit unit;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([startingController, weightController]),
      builder: (context, _) {
        final startingLb = displayWeightToLbs(startingController.text, unit);
        final goalLb = displayWeightToLbs(weightController.text, unit);
        if (startingLb == null || goalLb == null) {
          return const SizedBox.shrink();
        }
        final result = machinePlatesForGoal(
          goalLb: goalLb,
          startingLb: startingLb,
          kind: kind,
        );
        final text = _formatHint(result, kind, unit);
        if (text == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(left: 64, bottom: 4),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              color: LiftBigColors.muted,
              height: 1.3,
            ),
          ),
        );
      },
    );
  }
}

String? _formatHint(
  MachinePlatesResult result,
  VariableMachineKind kind,
  WeightUnit unit,
) {
  switch (result.status) {
    case MachinePlatesStatus.noPlatesNeeded:
      return kind == VariableMachineKind.smith
          ? 'No plates needed (bar only).'
          : 'No plates needed (starting weight only).';
    case MachinePlatesStatus.goalBelowStarting:
      return 'Goal is below machine starting weight — no plates to add.';
    case MachinePlatesStatus.platesComputed:
    case MachinePlatesStatus.inexact:
      break;
  }

  if (result.plates.isEmpty) {
    return result.status == MachinePlatesStatus.inexact
        ? 'Cannot match plates exactly with standard sizes.'
        : null;
  }

  final plateLabels = result.plates
      .map((p) => lbsToDisplayWeightString(p, unit))
      .join(', ');
  final prefix = result.mode == VariableMachinePlateMode.perSide
      ? 'Per side: '
      : 'Add plates: ';
  var line = '$prefix$plateLabels';
  if (result.status == MachinePlatesStatus.inexact &&
      result.remainderLb > 0.001) {
    line +=
        ' (${formatWeightWithUnit(result.remainderLb, unit)} short)';
  }
  return line;
}
