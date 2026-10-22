import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../journal/set_prescription.dart';
import '../theme.dart';
import '../utils/weight_units.dart';
import 'liftbig_sheet.dart';

const int repsPickerMax = 50;

/// 500, 495, … 0. Same rows as the Vue weight menu (pounds display).
List<String> weightPickerOptions([WeightUnit unit = WeightUnit.lb]) =>
    weightPickerOptionsFor(unit);

/// 50 down to 1. Same rows as the Vue reps menu.
List<String> repsPickerOptions() => [
  for (var reps = repsPickerMax; reps >= 1; reps--) '$reps',
];

/// Nearest 5 lb step from 0 to 500, matching `snapToPickerStoredLbs`.
String? snapWeightOption(String raw, [WeightUnit unit = WeightUnit.lb]) =>
    snapWeightOptionFor(raw, unit);

/// Typed number, plus a slider and the Vue stepped list.
Future<String?> showSetValueSheet(
  BuildContext context, {
  required String title,
  required String initial,
  required List<String> options,
  String? pinnedValue,
  String? goalLabel,
  bool selectAll = false,
  WeightUnit? weightUnit,
  double? sliderStep,
  double sliderMin = 0,
  double sliderMax = 500,
  int sliderDivisions = 100,
}) {
  final edited = ValueNotifier<String?>(null);
  final step = sliderStep ??
      (weightUnit == null ? 1 : weightPickerStepForUnit(weightUnit));
  return showLiftBigSheet<String>(
    context,
    builder: (context) {
      return _SetValueSheet(
        title: title,
        initial: initial,
        options: options,
        pinnedValue: pinnedValue,
        goalLabel: goalLabel,
        selectAll: selectAll,
        weightUnit: weightUnit,
        sliderStep: step,
        sliderMin: sliderMin,
        sliderMax: sliderMax,
        sliderDivisions: sliderDivisions,
        onEdited: (value) => edited.value = value,
      );
    },
  ).then((result) => result ?? edited.value);
}

class _SetValueSheet extends StatefulWidget {
  const _SetValueSheet({
    required this.title,
    required this.initial,
    required this.options,
    required this.sliderMin,
    required this.sliderMax,
    required this.sliderDivisions,
    required this.sliderStep,
    required this.onEdited,
    this.pinnedValue,
    this.goalLabel,
    this.selectAll = false,
    this.weightUnit,
  });

  final String title;
  final String initial;
  final List<String> options;
  final String? pinnedValue;
  final String? goalLabel;
  final bool selectAll;
  final WeightUnit? weightUnit;
  final double sliderStep;
  final double sliderMin;
  final double sliderMax;
  final int sliderDivisions;
  final ValueChanged<String> onEdited;

  @override
  State<_SetValueSheet> createState() => _SetValueSheetState();
}

class _SetValueSheetState extends State<_SetValueSheet> {
  late final TextEditingController _text;
  late double _slider;
  final _scroll = ScrollController();
  var _sliderTouched = false;

  @override
  void initState() {
    super.initState();
    _text = TextEditingController(text: widget.initial);
    if (widget.selectAll && widget.initial.isNotEmpty) {
      _text.selection = TextSelection(
        baseOffset: 0,
        extentOffset: widget.initial.length,
      );
    }
    _slider = _sliderFor(widget.initial);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.selectAll && _text.text.isNotEmpty) {
        _text.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _text.text.length,
        );
      }
      _scrollToCurrent();
    });
  }

  @override
  void dispose() {
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  double _sliderFor(String raw) {
    final parsed = double.tryParse(raw.trim().replaceAll(',', '.'));
    var value = parsed == null || parsed.isNaN ? widget.sliderMin : parsed;
    value = value.clamp(widget.sliderMin, widget.sliderMax).toDouble();
    final step = (widget.sliderMax - widget.sliderMin) / widget.sliderDivisions;
    if (step == 0) return value;
    final ticks = ((value - widget.sliderMin) / step).round();
    return (widget.sliderMin + ticks * step)
        .clamp(widget.sliderMin, widget.sliderMax)
        .toDouble();
  }

  void _publish(String value, {bool fromSlider = false}) {
    widget.onEdited(value);
    setState(() {
      _text.value = TextEditingValue(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
      );
      if (fromSlider) {
        _sliderTouched = true;
        _slider = _sliderFor(value);
      } else {
        _slider = _sliderFor(value);
      }
    });
  }

  void _scrollToCurrent() {
    if (!_scroll.hasClients) return;
    final key = widget.weightUnit == null
        ? _text.text.trim()
        : snapWeightOption(_text.text, widget.weightUnit!);
    final index = key == null ? -1 : widget.options.indexOf(key);
    if (index < 0) return;
    const row = 44.0;
    final target = index * row;
    final max = _scroll.position.maxScrollExtent;
    _scroll.jumpTo(target.clamp(0, max));
  }

  void _choose(String value) {
    liftBigSelectionHaptic();
    widget.onEdited(value);
    Navigator.of(context).pop(value);
  }

  double _applyStep(double value) {
    final step = widget.sliderStep;
    if (step <= 0) return value;
    final stepped = (value / step).round() * step;
    return stepped.clamp(widget.sliderMin, widget.sliderMax).toDouble();
  }

  String _formatStep(double value) {
    final step = widget.sliderStep;
    if (step >= 1 && (step - step.roundToDouble()).abs() < 0.001) {
      return '${value.round()}';
    }
    var text = value.toStringAsFixed(1);
    if (text.endsWith('.0')) text = text.substring(0, text.length - 2);
    return text;
  }

  double? _lastSliderTick;

  @override
  Widget build(BuildContext context) {
    final shown = _text.text.trim().isEmpty ? '—' : _text.text.trim();
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final goal = widget.goalLabel?.trim() ?? '';
    return LayoutBuilder(
      builder: (context, constraints) {
        final screen = MediaQuery.sizeOf(context).height;
        final cap = constraints.maxHeight.isFinite
            ? constraints.maxHeight - bottom
            : screen * 0.72;
        final height = cap < screen * 0.72 ? cap : screen * 0.72;
        return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SizedBox(
        height: height < 160 ? 160 : height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Text(
                widget.title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
            if (goal.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                child: Text(
                  'Goal $goal',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.liftBig.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Text(
                shown,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: TextField(
                controller: _text,
                autofocus: true,
                textAlign: TextAlign.center,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                decoration: InputDecoration(
                  hintText: widget.weightUnit == null
                      ? 'Type reps'
                      : widget.weightUnit == WeightUnit.kg
                      ? 'Type kilograms'
                      : 'Type pounds',
                ),
                onChanged: (value) {
                  widget.onEdited(value);
                  setState(() => _slider = _sliderFor(value));
                },
                onSubmitted: _choose,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Slider(
                min: widget.sliderMin,
                max: widget.sliderMax,
                divisions: widget.sliderDivisions,
                value: _slider,
                activeColor: context.liftBig.primary,
                label: _sliderTouched || _text.text.trim().isNotEmpty
                    ? _formatStep(_slider)
                    : null,
                onChanged: (value) {
                  final stepped = _applyStep(value);
                  if (_lastSliderTick != stepped) {
                    _lastSliderTick = stepped;
                    liftBigSelectionHaptic();
                  }
                  _publish(_formatStep(stepped), fromSlider: true);
                },
              ),
            ),
            if (widget.pinnedValue != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: OutlinedButton(
                  onPressed: () => _choose(widget.pinnedValue!),
                  child: Text('Goal ${widget.pinnedValue}'),
                ),
              ),
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                itemExtent: 44,
                itemCount: widget.options.length,
                itemBuilder: (context, index) {
                  final option = widget.options[index];
                  final selected = option == _text.text.trim() ||
                      (widget.weightUnit != null &&
                          option ==
                              snapWeightOption(_text.text, widget.weightUnit!));
                  return InkWell(
                    onTap: () => _choose(option),
                    child: ColoredBox(
                      color: selected
                          ? context.liftBig.primary.withValues(alpha: 0.16)
                          : Colors.transparent,
                      child: Center(
                        child: Text(
                          option,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                            color: selected
                                ? context.liftBig.primary
                                : context.liftBig.foreground,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: FilledButton(
                onPressed: () {
                  liftBigConfirmHaptic();
                  Navigator.of(context).pop(_text.text);
                },
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
      },
    );
  }
}

Future<int?> showRestDurationDialog(
  BuildContext context, {
  required int initialSeconds,
}) {
  return showLiftBigSheet<int>(
    context,
    builder: (context) => _RestDurationSheet(initialSeconds: initialSeconds),
  );
}

class _RestDurationSheet extends StatefulWidget {
  const _RestDurationSheet({required this.initialSeconds});

  final int initialSeconds;

  @override
  State<_RestDurationSheet> createState() => _RestDurationSheetState();
}

class _RestDurationSheetState extends State<_RestDurationSheet> {
  late final TextEditingController _text;
  late double _sliderSeconds;
  late int _pending;
  var _edited = false;
  int? _lastTick;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialSeconds < 0 ? 0 : widget.initialSeconds;
    _pending = initial;
    final visual = initial > restEditorMaxSeconds
        ? restEditorMaxSeconds
        : snapRestEditorSeconds(initial);
    _sliderSeconds = visual.toDouble();
    _text = TextEditingController(text: '$initial');
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _setPending(int seconds, {required bool fromSlider}) {
    final next = fromSlider ? snapRestEditorSeconds(seconds) : seconds;
    if (_lastTick != next) {
      _lastTick = next;
      liftBigSelectionHaptic();
    }
    setState(() {
      _edited = true;
      _pending = next;
      _sliderSeconds = snapRestEditorSeconds(next).toDouble();
      _text.text = '$next';
    });
  }

  void _save() {
    final parsed = int.tryParse(_text.text.trim());
    if (parsed != null && parsed != _pending) {
      _edited = true;
      _pending = parsed;
    }
    liftBigConfirmHaptic();
    Navigator.of(context).pop(
      restEditorValueOnSave(
        initialSeconds: widget.initialSeconds,
        edited: _edited,
        pendingSeconds: _pending,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final picks = restEditorQuickPicks();
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Rest timer',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            restEditorDurationLabel(_pending),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
          ),
          TextField(
            controller: _text,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(hintText: 'Seconds'),
            onChanged: (value) {
              final parsed = int.tryParse(value.trim());
              if (parsed == null) return;
              setState(() {
                _edited = true;
                _pending = parsed;
                if (parsed >= restEditorMinSeconds &&
                    parsed <= restEditorMaxSeconds) {
                  _sliderSeconds = snapRestEditorSeconds(parsed).toDouble();
                }
              });
            },
          ),
          Slider(
            min: restEditorMinSeconds.toDouble(),
            max: restEditorMaxSeconds.toDouble(),
            divisions: (restEditorMaxSeconds - restEditorMinSeconds) ~/ 5,
            value: _sliderSeconds,
            activeColor: context.liftBig.primary,
            label: restEditorDurationLabel(_sliderSeconds.round()),
            onChanged: (value) => _setPending(value.round(), fromSlider: true),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final seconds in picks)
                ChoiceChip(
                  label: Text(restEditorDurationLabel(seconds)),
                  selected: _pending == seconds,
                  onSelected: (_) => _setPending(seconds, fromSlider: true),
                ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
    );
  }
}
