import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../journal/journal_repository.dart';
import '../theme.dart';
import '../utils/plates.dart';
import '../utils/weight_units.dart';

class PlateCalculatorPage extends StatefulWidget {
  const PlateCalculatorPage({super.key, required this.journal});

  final JournalRepository journal;

  @override
  State<PlateCalculatorPage> createState() => _PlateCalculatorPageState();
}

class _PlateCalculatorPageState extends State<PlateCalculatorPage> {
  final _targetController = TextEditingController();
  var _barLb = defaultBarLb;
  PlateCalculationResult? _result;
  var _unit = WeightUnit.lb;
  var _loadingUnit = true;

  @override
  void initState() {
    super.initState();
    _loadUnit();
  }

  Future<void> _loadUnit() async {
    final unit = await widget.journal.storedWeightUnit();
    if (!mounted) return;
    setState(() {
      _unit = unit;
      _loadingUnit = false;
    });
  }

  @override
  void dispose() {
    _targetController.dispose();
    super.dispose();
  }

  void _runCalc() {
    final targetLb = displayWeightToLbs(_targetController.text, _unit);
    if (targetLb == null) return;
    setState(() {
      _result = calculatePlates(targetLb, _barLb, plateSizesLb);
    });
  }

  void _setQuick(double weightLb) {
    _targetController.text = lbsToDisplayWeightString(weightLb, _unit);
    setState(() {
      _result = calculatePlates(weightLb, _barLb, plateSizesLb);
    });
  }

  @override
  Widget build(BuildContext context) {
    final unitLabel = _unit == WeightUnit.lb ? 'lb' : 'kg';
    final totalLb = _result == null
        ? 0.0
        : totalWeightLb(_barLb, _result!.plates);
    final exact = _result != null && platesAreExact(_result!.remainder);

    return Scaffold(
      appBar: AppBar(title: const Text('Plate calculator')),
      body: _loadingUnit
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Target weight ($unitLabel)',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: LiftBigColors.muted,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _targetController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                  ),
                  decoration: InputDecoration(
                    hintText: _unit == WeightUnit.lb ? '225' : '100',
                    filled: true,
                    fillColor: LiftBigColors.cardInner,
                  ),
                  onSubmitted: (_) => _runCalc(),
                ),
                const SizedBox(height: 16),
                Text(
                  'Bar weight (lb bar math)',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: LiftBigColors.muted,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (final w in barChoicesLb)
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: w == barChoicesLb.first ? 8 : 0,
                          ),
                          child: OutlinedButton(
                            onPressed: () => setState(() {
                              _barLb = w;
                              _result = null;
                            }),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: _barLb == w
                                  ? LiftBigColors.primary.withValues(alpha: 0.15)
                                  : LiftBigColors.cardInner,
                              side: BorderSide(
                                color: _barLb == w
                                    ? LiftBigColors.primary
                                    : LiftBigColors.border,
                              ),
                            ),
                            child: Text(
                              '${lbsToDisplayWeightString(w, _unit)} $unitLabel',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _runCalc,
                  child: const Text('Calculate plates'),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final row in plateQuickPresetsLb)
                      ActionChip(
                        label: Text(row.label),
                        onPressed: () => _setQuick(row.weightLb),
                      ),
                  ],
                ),
                if (_result != null) ...[
                  const SizedBox(height: 24),
                  Text(
                    exact
                        ? 'Per side (${formatWeightWithUnit(totalLb, _unit)})'
                        : 'Closest load (${formatWeightWithUnit(totalLb, _unit)}) — ${formatWeightWithUnit(_result!.remainder * 2, _unit)} short per side',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  if (_result!.plates.isEmpty)
                    const Text(
                      'No plates fit — check bar and target.',
                      style: TextStyle(color: LiftBigColors.muted),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final plate in _result!.plates)
                          _PlateChip(
                            weightLb: plate,
                            unit: _unit,
                            colorHex: plateColorsLb[plate],
                          ),
                      ],
                    ),
                ],
              ],
            ),
    );
  }
}

class _PlateChip extends StatelessWidget {
  const _PlateChip({
    required this.weightLb,
    required this.unit,
    this.colorHex,
  });

  final double weightLb;
  final WeightUnit unit;
  final String? colorHex;

  @override
  Widget build(BuildContext context) {
    Color? color;
    if (colorHex != null && colorHex!.length >= 7) {
      final hex = colorHex!.replaceFirst('#', '');
      final value = int.tryParse(hex, radix: 16);
      if (value != null) {
        color = Color(0xFF000000 | value);
      }
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: (color ?? LiftBigColors.primary).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: LiftBigColors.border),
      ),
      child: Text(
        '${lbsToDisplayWeightString(weightLb, unit)} ${unit == WeightUnit.lb ? 'lb' : 'kg'}',
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}
