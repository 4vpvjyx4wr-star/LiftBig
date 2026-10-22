import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../journal/journal_repository.dart';
import '../theme.dart';
import '../utils/plates.dart';
import '../utils/weight_units.dart';
import 'keyboard_dismiss.dart';

/// Opens on a 225 lb target and a 45 lb bar so the plates for that load are visible.
const double plateCalculatorDefaultTargetLb = 225;

class PlateCalculatorPage extends StatefulWidget {
  const PlateCalculatorPage({super.key, required this.journal});

  final JournalRepository journal;

  @override
  State<PlateCalculatorPage> createState() => _PlateCalculatorPageState();
}

class _PlateCalculatorPageState extends State<PlateCalculatorPage> {
  final _targetController = TextEditingController(text: '225');
  final _customBarController = TextEditingController();
  var _presetBarLb = defaultBarLb;
  double? _customBarLb;
  double? _targetLb = plateCalculatorDefaultTargetLb;
  PlateCalculationResult? _result = calculatePlates(
    plateCalculatorDefaultTargetLb,
    defaultBarLb,
    plateSizesLb,
  );
  var _unit = WeightUnit.lb;
  var _loadingUnit = true;

  double get _barLb => _customBarLb ?? _presetBarLb;

  bool get _usingCustomBar => _customBarLb != null;

  @override
  void initState() {
    super.initState();
    _loadUnit();
  }

  Future<void> _loadUnit() async {
    final unit = await widget.journal.storedWeightUnit();
    if (!mounted) return;
    if (unit != WeightUnit.lb &&
        _targetLb == plateCalculatorDefaultTargetLb &&
        _targetController.text == '225') {
      _targetController.text = lbsToDisplayWeightString(
        plateCalculatorDefaultTargetLb,
        unit,
      );
    }
    setState(() {
      _unit = unit;
      _loadingUnit = false;
      _targetLb = plateCalculatorDefaultTargetLb;
      _recalc();
    });
  }

  @override
  void dispose() {
    _targetController.dispose();
    _customBarController.dispose();
    super.dispose();
  }

  void _recalc() {
    final target = _targetLb;
    if (target == null) {
      _result = null;
      return;
    }
    _result = calculatePlates(target, _barLb, plateSizesLb);
  }

  void _onTargetChanged(String raw) {
    setState(() {
      _targetLb = displayWeightToLbs(raw, _unit);
      _recalc();
    });
  }

  void _selectPreset(double barLb) {
    _customBarController.clear();
    setState(() {
      _presetBarLb = barLb;
      _customBarLb = null;
      _recalc();
    });
  }

  void _onCustomBarChanged(String raw) {
    setState(() {
      _customBarLb = displayWeightToLbs(raw, _unit);
      _recalc();
    });
  }

  void _setQuick(double weightLb) {
    _targetController.text = lbsToDisplayWeightString(weightLb, _unit);
    setState(() {
      _targetLb = weightLb;
      _recalc();
    });
  }

  @override
  Widget build(BuildContext context) {
    final unitLabel = _unit == WeightUnit.lb ? 'lb' : 'kg';
    return KeyboardDismissScaffold(
      title: 'Plate calculator',
      body: _loadingUnit
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                _SectionCard(
                  label: 'Bar weight',
                  child: Column(
                    children: [
                      Row(
                        children: [
                          for (var i = 0; i < barChoicesLb.length; i++) ...[
                            if (i > 0) const SizedBox(width: 8),
                            Expanded(
                              child: _BarPresetButton(
                                weightLb: barChoicesLb[i],
                                unit: _unit,
                                unitLabel: unitLabel,
                                subtitle: i == 0 ? 'Standard' : "Women's",
                                selected:
                                    !_usingCustomBar &&
                                    _presetBarLb == barChoicesLb[i],
                                onPressed: () => _selectPreset(barChoicesLb[i]),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      _CustomBarField(
                        controller: _customBarController,
                        unit: _unit,
                        active: _usingCustomBar,
                        onChanged: _onCustomBarChanged,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  label: 'Target weight ($unitLabel)',
                  child: TextField(
                    controller: _targetController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.done,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    ),
                    decoration:  InputDecoration(
                      hintText: 'Weight',
                      filled: true,
                      fillColor: context.liftBig.cardInner,
                    ),
                    onChanged: _onTargetChanged,
                    onSubmitted: (_) =>
                        FocusManager.instance.primaryFocus?.unfocus(),
                  ),
                ),
                if (_result != null) ...[
                  const SizedBox(height: 12),
                  _PlateResult(
                    result: _result!,
                    barLb: _barLb,
                    targetLb: _targetLb,
                    unit: _unit,
                  ),
                ],
                const SizedBox(height: 12),
                _QuickReference(
                  unit: _unit,
                  unitLabel: unitLabel,
                  onSelect: _setQuick,
                ),
              ],
            ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              label.toUpperCase(),
              style:  TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: context.liftBig.muted,
              ),
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _BarPresetButton extends StatelessWidget {
  const _BarPresetButton({
    required this.weightLb,
    required this.unit,
    required this.unitLabel,
    required this.subtitle,
    required this.selected,
    required this.onPressed,
  });

  final double weightLb;
  final WeightUnit unit;
  final String unitLabel;
  final String subtitle;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final label = lbsToDisplayWeightString(weightLb, unit);
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(64),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        backgroundColor: selected
            ? context.liftBig.primary.withValues(alpha: 0.15)
            : context.liftBig.cardInner,
        side: BorderSide(
          color: selected ? context.liftBig.primary : context.liftBig.border,
        ),
        foregroundColor: selected
            ? context.liftBig.foreground
            : context.liftBig.muted,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$label $unitLabel',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _CustomBarField extends StatelessWidget {
  const _CustomBarField({
    required this.controller,
    required this.unit,
    required this.active,
    required this.onChanged,
  });

  final TextEditingController controller;
  final WeightUnit unit;
  final bool active;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: active ? context.liftBig.primary : context.liftBig.border,
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        return Center(
          child: SizedBox(
            width: constraints.maxWidth * 0.5,
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800),
              decoration: InputDecoration(
                labelText: 'Custom bar',
                hintText: unit == WeightUnit.lb ? 'lb' : 'kg',
                isDense: true,
                filled: true,
                fillColor: active
                    ? context.liftBig.primary.withValues(alpha: 0.15)
                    : context.liftBig.cardInner,
                enabledBorder: border,
                focusedBorder: border.copyWith(
                  borderSide:  BorderSide(color: context.liftBig.primary),
                ),
              ),
              onChanged: onChanged,
              onSubmitted: (_) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
            ),
          ),
        );
      },
    );
  }
}

class _PlateResult extends StatelessWidget {
  const _PlateResult({
    required this.result,
    required this.barLb,
    required this.targetLb,
    required this.unit,
  });

  final PlateCalculationResult result;
  final double barLb;
  final double? targetLb;
  final WeightUnit unit;

  @override
  Widget build(BuildContext context) {
    final totalLb = totalWeightLb(barLb, result.plates);
    final exact = platesAreExact(result.remainder);
    final underBar = targetLb != null && targetLb! < barLb - 0.001;
    final unitWord = unit == WeightUnit.lb ? 'lb' : 'kg';
    final String caption;
    if (underBar) {
      caption = 'Target is under the bar';
    } else if (result.plates.isEmpty && !exact) {
      caption = 'No plates fit — check bar and target.';
    } else if (exact) {
      caption = 'Exact weight';
    } else {
      caption =
          'Closest load — ${formatWeightWithUnit(result.remainder * 2, unit)} short';
    }
    final accent = exact ? context.liftBig.success : const Color(0xFFF59E0B);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: exact ? const Color(0xFF0D2010) : context.liftBig.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: exact ? const Color(0xFF16A34A) : context.liftBig.border,
            ),
          ),
          child: Column(
            children: [
              Text(
                '${formatWeightWithUnit(totalLb, unit).replaceAll(' lb', '').replaceAll(' kg', '')} $unitWord',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: exact ? context.liftBig.success : context.liftBig.foreground,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                caption,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _BarVisual(plates: result.plates, unit: unit),
        if (result.plates.isNotEmpty) ...[
          const SizedBox(height: 12),
          _PlateSummary(plates: result.plates, unit: unit),
        ],
      ],
    );
  }
}

class _BarVisual extends StatelessWidget {
  const _BarVisual({required this.plates, required this.unit});

  final List<double> plates;
  final WeightUnit unit;

  static const _maxShown = 8;

  @override
  Widget build(BuildContext context) {
    final shown = plates.take(_maxShown).toList();
    final overflow = plates.length - shown.length;
    final left = shown.reversed.toList();
    final label = shown.isEmpty
        ? 'Bar only'
        : 'Plates per side: ${shown.map((plate) => _plateLabel(plate, unit)).join(', ')}';
    return Semantics(
      label: label,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: context.liftBig.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.liftBig.border),
        ),
        child: Column(
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const _Collar(),
                  for (final plate in left) _PlateDisc(weightLb: plate, unit: unit),
                  const _BarSleeve(),
                  for (final plate in shown)
                    _PlateDisc(weightLb: plate, unit: unit),
                  const _Collar(),
                ],
              ),
            ),
            if (overflow > 0) ...[
              const SizedBox(height: 8),
              Text(
                '+$overflow more',
                style:  TextStyle(color: context.liftBig.muted, fontSize: 12),
              ),
            ] else if (shown.isEmpty) ...[
              const SizedBox(height: 8),
               Text(
                'Just the bar — no plates needed',
                style: TextStyle(color: context.liftBig.muted, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Collar extends StatelessWidget {
  const _Collar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 46,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF9CA3AF),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

class _BarSleeve extends StatelessWidget {
  const _BarSleeve();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 16,
      alignment: Alignment.center,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF6B7280),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'BAR',
        style: TextStyle(
          color: Color(0xFFD1D5DB),
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _PlateDisc extends StatelessWidget {
  const _PlateDisc({required this.weightLb, required this.unit});

  final double weightLb;
  final WeightUnit unit;

  @override
  Widget build(BuildContext context) {
    final color = _colorForPlate(context, weightLb);
    final ink = color.computeLuminance() > 0.62
        ? const Color(0xFF111827)
        : Colors.white;
    final height = 32 + (weightLb / 45).clamp(0.12, 1.0) * 70;
    return Container(
      width: 30,
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.black.withValues(alpha: 0.28)),
      ),
      child: RotatedBox(
        quarterTurns: 1,
        child: Text(
          _plateLabel(weightLb, unit),
          maxLines: 1,
          style: TextStyle(
            color: ink,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _PlateSummary extends StatelessWidget {
  const _PlateSummary({required this.plates, required this.unit});

  final List<double> plates;
  final WeightUnit unit;

  @override
  Widget build(BuildContext context) {
    final counts = <double, int>{};
    for (final plate in plates) {
      counts[plate] = (counts[plate] ?? 0) + 1;
    }
    final unitWord = unit == WeightUnit.lb ? 'lb' : 'kg';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.liftBig.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.liftBig.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Each side',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          for (final size in plateSizesLb)
            if (counts[size] != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _colorForPlate(context, size),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _plateLabel(size, unit),
                        style: TextStyle(
                          color: _colorForPlate(context, size).computeLuminance() > 0.62
                              ? const Color(0xFF111827)
                              : Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${_plateLabel(size, unit)} $unitWord plate',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Text(
                      '× ${counts[size]}',
                      style:  TextStyle(
                        color: context.liftBig.primary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${_plateLabel(size * (counts[size] ?? 0), unit)} $unitWord)',
                      style:  TextStyle(
                        color: context.liftBig.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _QuickReference extends StatelessWidget {
  const _QuickReference({
    required this.unit,
    required this.unitLabel,
    required this.onSelect,
  });

  final WeightUnit unit;
  final String unitLabel;
  final ValueChanged<double> onSelect;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
             Text(
              'QUICK REFERENCE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: context.liftBig.muted,
              ),
            ),
            const SizedBox(height: 4),
            for (var i = 0; i < plateQuickPresetsLb.length; i++)
              InkWell(
                onTap: () => onSelect(plateQuickPresetsLb[i].weightLb),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    border: i == plateQuickPresetsLb.length - 1
                        ? null
                        :  Border(
                            bottom: BorderSide(color: context.liftBig.border),
                          ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          plateQuickPresetsLb[i].label,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        '${lbsToDisplayWeightString(plateQuickPresetsLb[i].weightLb, unit)} $unitLabel',
                        style:  TextStyle(color: context.liftBig.muted),
                      ),
                      const SizedBox(width: 4),
                       Icon(
                        Icons.chevron_right,
                        color: context.liftBig.primary,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String _plateLabel(double weightLb, WeightUnit unit) {
  return lbsToDisplayWeightString(weightLb, unit);
}

Color _colorForPlate(BuildContext context, double weightLb) {
  final hex = plateColorsLb[weightLb];
  if (hex == null || hex.length < 7) return context.liftBig.primary;
  final value = int.tryParse(hex.replaceFirst('#', ''), radix: 16);
  if (value == null) return context.liftBig.primary;
  return Color(0xFF000000 | value);
}
