import 'package:flutter/material.dart';

import '../theme.dart';
import '../utils/plates.dart';
import '../utils/variable_machine.dart';
import '../utils/weight_units.dart';
import 'plate_load_graphic.dart';

/// Whether the log draws plate graphics, and which bar those graphics use.
class PlateGraphicConfig extends InheritedWidget {
  const PlateGraphicConfig({
    super.key,
    required this.showGraphic,
    required this.barLb,
    required super.child,
  });

  final bool showGraphic;
  final double barLb;

  static PlateGraphicConfig of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<PlateGraphicConfig>() ??
        const PlateGraphicConfig(
          showGraphic: true,
          barLb: defaultBarLb,
          child: SizedBox.shrink(),
        );
  }

  @override
  bool updateShouldNotify(PlateGraphicConfig oldWidget) {
    return showGraphic != oldWidget.showGraphic || barLb != oldWidget.barLb;
  }
}

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
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: context.liftBig.muted,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
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
                fillColor: context.liftBig.cardInner,
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
    this.showGraphic = true,
  });

  final VariableMachineKind kind;
  final TextEditingController startingController;
  final TextEditingController weightController;
  final WeightUnit unit;
  final bool showGraphic;

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
          padding: const EdgeInsets.only(left: 64, right: 8, bottom: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showGraphic && result.plates.isNotEmpty) ...[
                ExcludeSemantics(
                  child: PlateLoadGraphic(
                    plates: result.plates,
                    unit: unit,
                    centerLabel: kind == VariableMachineKind.smith
                        ? 'BAR'
                        : 'SLED',
                    compact: true,
                  ),
                ),
                const SizedBox(height: 2),
              ],
              Text(
                text,
                style: TextStyle(
                  fontSize: 11,
                  color: context.liftBig.muted,
                  height: 1.3,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Bar graphic for a barbell compound. No sled-start field.
class BarbellSetPlateHint extends StatelessWidget {
  const BarbellSetPlateHint({
    super.key,
    required this.weightController,
    required this.unit,
    this.barLb = defaultBarLb,
  });

  final TextEditingController weightController;
  final WeightUnit unit;
  final double barLb;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: weightController,
      builder: (context, _) {
        final goalLb = displayWeightToLbs(weightController.text, unit);
        if (goalLb == null || goalLb + 0.001 < barLb) {
          return const SizedBox.shrink();
        }
        final result = calculatePlates(goalLb, barLb, plateSizesLb);
        final summary = result.plates.isEmpty
            ? null
            : eachSidePlateSummary(
                result.plates,
                label: (weightLb) => lbsToDisplayWeightString(weightLb, unit),
              );
        return Padding(
          padding: const EdgeInsets.only(left: 64, right: 8, bottom: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(
                child: PlateLoadGraphic(
                  plates: result.plates,
                  unit: unit,
                  centerLabel: 'BAR',
                  compact: true,
                ),
              ),
              if (summary != null) ...[
                const SizedBox(height: 2),
                Text(
                  'Each side: $summary',
                  style: TextStyle(
                    fontSize: 11,
                    color: context.liftBig.muted,
                    height: 1.3,
                  ),
                ),
              ],
            ],
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

  final summary = eachSidePlateSummary(
    result.plates,
    label: (weightLb) => lbsToDisplayWeightString(weightLb, unit),
  );
  var line = 'Each side: $summary';
  if (result.status == MachinePlatesStatus.inexact &&
      result.remainderLb > 0.001) {
    line += ' (${formatWeightWithUnit(result.remainderLb, unit)} short)';
  }
  return line;
}
