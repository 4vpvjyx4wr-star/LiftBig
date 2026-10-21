import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../journal/logged_day.dart';
import '../theme.dart';
import '../utils/weight_units.dart';

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
  double sliderMin = 0,
  double sliderMax = 500,
  int sliderDivisions = 100,
}) {
  final edited = ValueNotifier<String?>(null);
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: LiftBigColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return _SetValueSheet(
        title: title,
        initial: initial,
        options: options,
        pinnedValue: pinnedValue,
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
    required this.onEdited,
    this.pinnedValue,
  });

  final String title;
  final String initial;
  final List<String> options;
  final String? pinnedValue;
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
    _slider = _sliderFor(widget.initial);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrent());
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
    final key = widget.title == 'Weight'
        ? snapWeightOption(_text.text)
        : _text.text.trim();
    final index = key == null ? -1 : widget.options.indexOf(key);
    if (index < 0) return;
    const row = 44.0;
    final target = index * row;
    final max = _scroll.position.maxScrollExtent;
    _scroll.jumpTo(target.clamp(0, max));
  }

  void _choose(String value) {
    widget.onEdited(value);
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final shown = _text.text.trim().isEmpty ? '—' : _text.text.trim();
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.72,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: LiftBigColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Text(
                widget.title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
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
                  hintText: widget.title == 'Weight' ? 'Type pounds' : 'Type reps',
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
                activeColor: LiftBigColors.primary,
                label: _sliderTouched || _text.text.trim().isNotEmpty
                    ? _slider.round().toString()
                    : null,
                onChanged: (value) {
                  final stepped = widget.title == 'Weight'
                      ? (value / weightPickerStepLbs).round() * weightPickerStepLbs
                      : value.round();
                  _publish('$stepped', fromSlider: true);
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
                      (widget.title == 'Weight' &&
                          option == snapWeightOption(_text.text));
                  return InkWell(
                    onTap: () => _choose(option),
                    child: ColoredBox(
                      color: selected
                          ? LiftBigColors.primary.withValues(alpha: 0.16)
                          : Colors.transparent,
                      child: Center(
                        child: Text(
                          option,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                            color: selected
                                ? LiftBigColors.primary
                                : LiftBigColors.foreground,
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
                onPressed: () => Navigator.of(context).pop(_text.text),
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<int?> showRestDurationDialog(
  BuildContext context, {
  required int initialSeconds,
}) {
  return showDialog<int>(
    context: context,
    builder: (context) => _RestDurationDialog(initialSeconds: initialSeconds),
  );
}

class _RestDurationDialog extends StatefulWidget {
  const _RestDurationDialog({required this.initialSeconds});

  final int initialSeconds;

  @override
  State<_RestDurationDialog> createState() => _RestDurationDialogState();
}

class _RestDurationDialogState extends State<_RestDurationDialog> {
  late final TextEditingController _text;
  late double _sliderSeconds;

  @override
  void initState() {
    super.initState();
    _sliderSeconds = _snapSeconds(widget.initialSeconds);
    _text = TextEditingController(text: '${widget.initialSeconds}');
  }

  double _snapSeconds(int seconds) {
    final clamped = seconds.clamp(minAverageRestSeconds, maxAverageRestSeconds);
    final snapped =
        ((((clamped - minAverageRestSeconds) / 5).round()) * 5) +
        minAverageRestSeconds;
    return snapped
        .clamp(minAverageRestSeconds, maxAverageRestSeconds)
        .toDouble();
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _save() {
    final parsed = int.tryParse(_text.text.trim());
    final seconds = clampAverageRestSeconds(
      parsed ?? _sliderSeconds.round(),
    );
    Navigator.of(context).pop(seconds);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rest timer'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${_text.text.trim().isEmpty ? _sliderSeconds.round() : _text.text.trim()} seconds',
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
              setState(() => _sliderSeconds = _snapSeconds(parsed));
            },
          ),
          Slider(
            min: minAverageRestSeconds.toDouble(),
            max: maxAverageRestSeconds.toDouble(),
            divisions: (maxAverageRestSeconds - minAverageRestSeconds) ~/ 5,
            value: _sliderSeconds,
            activeColor: LiftBigColors.primary,
            label: '${_sliderSeconds.round()}',
            onChanged: (value) {
              final stepped = _snapSeconds(value.round());
              setState(() {
                _sliderSeconds = stepped;
                _text.text = '${stepped.round()}';
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
