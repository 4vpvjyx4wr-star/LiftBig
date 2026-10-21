import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../journal/journal_repository.dart';
import '../theme.dart';
import '../utils/one_rep_max.dart';
import '../utils/weight_units.dart';

class OneRepMaxCalculatorPage extends StatefulWidget {
  const OneRepMaxCalculatorPage({super.key, required this.journal});

  final JournalRepository journal;

  @override
  State<OneRepMaxCalculatorPage> createState() =>
      _OneRepMaxCalculatorPageState();
}

class _OneRepMaxCalculatorPageState extends State<OneRepMaxCalculatorPage> {
  final _weightController = TextEditingController();
  final _repsController = TextEditingController(text: '5');
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
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unitLabel = _unit == WeightUnit.lb ? 'lb' : 'kg';
    final weightLbs = displayWeightToLbs(_weightController.text, _unit);
    final reps = int.tryParse(_repsController.text.trim());
    final validWeight = weightLbs != null && weightLbs > 0;
    final validReps = reps != null && reps >= 1;

    final List<({OneRmFormulaMeta formula, double? value})> estimates;
    if (validWeight && validReps) {
      final w = weightLbs;
      final r = reps;
      estimates = [
        for (final formula in oneRmFormulas)
          (
            formula: formula,
            value: estimateOneRepMax(w, r, formula.id),
          ),
      ];
    } else {
      estimates = const [];
    }

    final values = estimates.map((e) => e.value).whereType<double>().toList();
    final average = values.isEmpty
        ? null
        : values.reduce((a, b) => a + b) / values.length;

    return Scaffold(
      appBar: AppBar(title: const Text('One rep max')),
      body: _loadingUnit
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Weight lifted ($unitLabel)',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: LiftBigColors.muted,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _weightController,
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
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                Text(
                  'Reps (to failure)',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: LiftBigColors.muted,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _repsController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                  ),
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: LiftBigColors.cardInner,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                if (validWeight && validReps && values.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  if (average != null)
                    Text(
                      'Average estimate: ${_formatEstimate(average)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  const SizedBox(height: 12),
                  for (final row in estimates)
                    if (row.value != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              row.formula.label,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              _formatEstimate(row.value!),
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                ],
              ],
            ),
    );
  }

  String _formatEstimate(double lbs) => formatWeightWithUnit(lbs, _unit);
}
