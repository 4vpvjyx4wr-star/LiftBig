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
    this.onBarLb,
    required super.child,
  });

  final bool showGraphic;
  final double barLb;

  /// Saves a new Olympic bar weight for the plate graphics in this workout.
  final ValueChanged<double>? onBarLb;

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

/// Picks the bar or sled weight. Returns pounds, or null when dismissed.
Future<double?> showBarWeightSheet(
  BuildContext context, {
  required double currentLb,
  required WeightUnit unit,
  String title = 'Bar Weight',
}) {
  return showModalBottomSheet<double>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => _BarWeightSheet(
      currentLb: currentLb,
      unit: unit,
      title: title,
    ),
  );
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
    this.onStartingChanged,
  });

  final VariableMachineKind kind;
  final TextEditingController startingController;
  final TextEditingController weightController;
  final WeightUnit unit;
  final bool showGraphic;
  final ValueChanged<String>? onStartingChanged;

  Future<void> _editStarting(BuildContext context, WeightUnit unit) async {
    final current = displayWeightToLbs(startingController.text, unit) ??
        (kind == VariableMachineKind.smith ? defaultSmithBarLb : defaultBarLb);
    final picked = await showBarWeightSheet(
      context,
      currentLb: current,
      unit: unit,
      title: kind == VariableMachineKind.smith ? 'Bar Weight' : 'Sled Weight',
    );
    if (picked == null) return;
    final display = lbsToDisplayWeightString(picked, unit);
    startingController.text = display;
    onStartingChanged?.call(display);
  }

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
          padding: const EdgeInsets.fromLTRB(8, 2, 8, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (showGraphic && result.plates.isNotEmpty) ...[
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _editStarting(context, unit),
                  child: ExcludeSemantics(
                    child: PlateLoadGraphic(
                      plates: result.plates,
                      unit: unit,
                      centerLabel: BarbellSetPlateHint._barFaceLabel(
                        startingLb,
                        unit,
                      ),
                      compact: true,
                    ),
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
    this.barController,
    this.emptyBarLb = defaultBarLb,
    this.onChangeBar,
  });

  final TextEditingController weightController;
  final WeightUnit unit;
  final double barLb;

  /// When set, the bar weight is read from this field (a Smith bar).
  final TextEditingController? barController;

  /// Bar used when [barController] is empty.
  final double emptyBarLb;

  /// Saves a new bar weight in pounds. Falls back to [PlateGraphicConfig.onBarLb].
  final ValueChanged<double>? onChangeBar;

  @override
  Widget build(BuildContext context) {
    final listen = barController == null
        ? weightController
        : Listenable.merge([weightController, barController!]);
    return ListenableBuilder(
      listenable: listen,
      builder: (context, _) {
        final bar = _resolvedBarLb();
        final change = onChangeBar ?? PlateGraphicConfig.of(context).onBarLb;
        final goalLb = displayWeightToLbs(weightController.text, unit);
        final loaded = goalLb != null && goalLb + 0.001 >= bar;
        var plates = const <double>[];
        String? summary;
        if (loaded) {
          final result = calculatePlates(goalLb, bar, plateSizesLb);
          plates = result.plates;
          if (plates.isNotEmpty) {
            summary = eachSidePlateSummary(
              plates,
              label: (weightLb) => lbsToDisplayWeightString(weightLb, unit),
            );
          }
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(8, 2, 8, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (loaded)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: change == null
                      ? null
                      : () async {
                          final picked = await showBarWeightSheet(
                            context,
                            currentLb: bar,
                            unit: unit,
                          );
                          if (picked == null) return;
                          change(picked);
                        },
                  child: ExcludeSemantics(
                    child: PlateLoadGraphic(
                      plates: plates,
                      unit: unit,
                      centerLabel: _barFaceLabel(bar, unit),
                      compact: true,
                    ),
                  ),
                ),
              if (summary != null)
                Text(
                  'Each Side: $summary',
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

  static String _barFaceLabel(double barLb, WeightUnit unit) {
    final number = lbsToDisplayWeightString(barLb, unit);
    final suffix = unit == WeightUnit.lb ? 'lb' : 'kg';
    return '$number $suffix';
  }

  double _resolvedBarLb() {
    final controller = barController;
    if (controller == null) return barLb;
    return displayWeightToLbs(controller.text, unit) ?? emptyBarLb;
  }
}

class _BarWeightSheet extends StatefulWidget {
  const _BarWeightSheet({
    required this.currentLb,
    required this.unit,
    required this.title,
  });

  final double currentLb;
  final WeightUnit unit;
  final String title;

  @override
  State<_BarWeightSheet> createState() => _BarWeightSheetState();
}

class _BarWeightSheetState extends State<_BarWeightSheet> {
  late final TextEditingController _custom = TextEditingController();

  @override
  void dispose() {
    _custom.dispose();
    super.dispose();
  }

  void _choose(double lb) {
    if (!mounted) return;
    Navigator.of(context).pop(lb);
  }

  var _applied = false;

  void _applyCustom() {
    if (_applied) return;
    final lb = displayWeightToLbs(_custom.text, widget.unit);
    if (lb == null || lb < minCustomBarLb || lb > maxCustomBarLb) return;
    _applied = true;
    _choose(lb);
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    final safe = inset > 0 ? 0.0 : MediaQuery.paddingOf(context).bottom;
    final unitLabel = widget.unit == WeightUnit.lb ? 'lb' : 'kg';
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 4, 20, 16 + safe + inset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            widget.title == 'Sled Weight'
                ? 'Set the sled on this machine. The plates update for this workout.'
                : 'Set the bar you have on the rack. The plates update for this workout.',
            style: TextStyle(color: context.liftBig.muted, height: 1.3),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final lb in barChoicesLb)
                ChoiceChip(
                  label: Text(
                    '${lbsToDisplayWeightString(lb, widget.unit)} $unitLabel',
                  ),
                  selected: (widget.currentLb - lb).abs() < 0.05,
                  onSelected: (_) => _choose(lb),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _custom,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: 'Other Weight',
                    suffixText: unitLabel,
                    isDense: true,
                  ),
                  onSubmitted: (_) => _applyCustom(),
                  onEditingComplete: _applyCustom,
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _applyCustom,
                child: const Text('Use'),
              ),
            ],
          ),
        ],
      ),
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
  var line = 'Each Side: $summary';
  if (result.status == MachinePlatesStatus.inexact &&
      result.remainderLb > 0.001) {
    line += ' (${formatWeightWithUnit(result.remainderLb, unit)} short)';
  }
  return line;
}
