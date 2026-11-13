import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../journal/set_prescription.dart';
import '../theme.dart';
import '../utils/weight_units.dart';
import 'keyboard_dismiss.dart';
import 'liftbig_sheet.dart';

const int repsPickerMax = 50;

/// 500, 495, … 0. Same rows as the Vue weight menu (pounds display).
List<String> weightPickerOptions([WeightUnit unit = WeightUnit.lb]) =>
    weightPickerOptionsFor(unit);

/// [max] down to 1. Same rows as the Vue reps menu when [max] is 50.
List<String> repsPickerOptions({int max = repsPickerMax}) => [
  for (var reps = max; reps >= 1; reps--) '$reps',
];

/// Horizontal travel that moves the reps or weight slider one step.
///
/// Matches the touch slop, so the drag that wins the horizontal axis is the
/// first step. Further travel keeps stepping one increment at a time.
const double sheetWheelPixelsPerStep = kTouchSlop;

/// Which way a wheel drag has locked. Null until one axis passes the slop.
enum SheetWheelLock { horizontal, vertical }

/// First axis whose travel passes [slop]. A sample where both pass locks to
/// the larger one, so a diagonal swipe does not scroll and step together.
SheetWheelLock? sheetWheelLock({
  required double dx,
  required double dy,
  double slop = kTouchSlop,
}) {
  final absX = dx.abs();
  final absY = dy.abs();
  final xPast = absX > slop;
  final yPast = absY > slop;
  if (!xPast && !yPast) return null;
  if (xPast && !yPast) return SheetWheelLock.horizontal;
  if (yPast && !xPast) return SheetWheelLock.vertical;
  return absX >= absY ? SheetWheelLock.horizontal : SheetWheelLock.vertical;
}

/// Whole slider steps in [travel], and the unused pixels toward the next one.
///
/// Positive travel steps up. Negative travel steps down. The remainder keeps
/// the sign of the leftover so reversing mid-drag does not skip a step.
({int steps, double remainder}) sheetWheelSteps(
  double travel, {
  double pixelsPerStep = sheetWheelPixelsPerStep,
}) {
  if (pixelsPerStep <= 0 || travel == 0) {
    return (steps: 0, remainder: travel);
  }
  final steps = travel ~/ pixelsPerStep;
  return (steps: steps, remainder: travel - steps * pixelsPerStep);
}

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
  String? predictedLabel,
  bool selectAll = false,
  WeightUnit? weightUnit,
  double? sliderStep,
  double sliderMin = 0,
  double sliderMax = 500,
  int sliderDivisions = 100,
}) {
  final edited = ValueNotifier<String?>(null);
  final step =
      sliderStep ??
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
        predictedLabel: predictedLabel,
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
    this.predictedLabel,
    this.selectAll = false,
    this.weightUnit,
  });

  final String title;
  final String initial;
  final List<String> options;
  final String? pinnedValue;
  final String? goalLabel;
  final String? predictedLabel;
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
  var _chose = false;
  double _wheelRemainder = 0;

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
      _scrollToOpening();
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
    if (fromSlider) _chose = true;
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

  void _scrollToOpening() {
    if (widget.weightUnit != null) {
      _scrollToCurrent();
      return;
    }
    final predicted = widget.predictedLabel?.trim() ?? '';
    if (widget.initial.trim().isEmpty &&
        predicted.isNotEmpty &&
        _scroll.hasClients) {
      final index = widget.options.indexOf(predicted);
      if (index >= 0) {
        final target = index * repSheetRowExtent;
        final max = _scroll.position.maxScrollExtent;
        _scroll.jumpTo(target.clamp(0, max));
        return;
      }
    }
    final anchor = repSheetFiveRowAnchorIndex(
      pickerMax: widget.sliderMax.round(),
      goalReps: widget.goalLabel,
    );
    if (anchor == null || !_scroll.hasClients) {
      _scrollToCurrent();
      return;
    }
    final target = anchor * repSheetRowExtent;
    final max = _scroll.position.maxScrollExtent;
    _scroll.jumpTo(target.clamp(0, max));
  }

  void _scrollToCurrent() {
    if (!_scroll.hasClients) return;
    final key = widget.weightUnit == null
        ? _text.text.trim()
        : snapWeightOption(_text.text, widget.weightUnit!);
    final index = key == null ? -1 : widget.options.indexOf(key);
    if (index < 0) return;
    const row = repSheetRowExtent;
    final target = index * row;
    final max = _scroll.position.maxScrollExtent;
    _scroll.jumpTo(target.clamp(0, max));
  }

  void _choose(String value) {
    _chose = true;
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

  void _endWheelDrag() {
    _wheelRemainder = 0;
  }

  /// A horizontal wheel drag steps the slider and counts as a choice.
  void _nudgeSliderByTravel(double travel) {
    final earned = sheetWheelSteps(_wheelRemainder + travel);
    _wheelRemainder = earned.remainder;
    if (earned.steps == 0) return;
    final next = _applyStep(_slider + earned.steps * widget.sliderStep);
    if (_lastSliderTick != next) {
      _lastSliderTick = next;
      liftBigSelectionHaptic();
    }
    _publish(_formatStep(next), fromSlider: true);
  }

  Map<Type, GestureRecognizerFactory> _wheelGestures() {
    return <Type, GestureRecognizerFactory>{
      _SheetWheelRecognizer:
          GestureRecognizerFactoryWithHandlers<_SheetWheelRecognizer>(
            () => _SheetWheelRecognizer(),
            (instance) {
              instance.onStep = _nudgeSliderByTravel;
              instance.onEnd = _endWheelDrag;
            },
          ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final repsSheet = widget.weightUnit == null;
    final typed = _text.text.trim();
    final goal = widget.goalLabel?.trim() ?? '';
    final predicted = widget.predictedLabel?.trim() ?? '';
    final band = repsSheet ? repSheetGoalBand(goal) : null;
    final loggedOpening = widget.initial.trim().isNotEmpty;
    return KeyboardDismiss(
      fill: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screen = MediaQuery.sizeOf(context).height;
          final fraction = repsSheet ? 0.92 : 0.72;
          final wanted = screen * fraction;
          final max = constraints.maxHeight;
          final height = !max.isFinite ? wanted : (max < wanted ? max : wanted);
          final column = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: goal.isEmpty && predicted.isEmpty
                    ? Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (goal.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Goal: $goal',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: context.liftBig.success,
                              ),
                            ),
                          ],
                          if (predicted.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Predicted: $predicted',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: context.liftBig.muted,
                              ),
                            ),
                          ],
                        ],
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: SizedBox(
                  height: 48,
                  child: Text(
                    typed.isEmpty ? (repsSheet ? '' : '—') : typed,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: TextField(
                  controller: _text,
                  autofocus: true,
                  textAlign: TextAlign.center,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.done,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  decoration: InputDecoration(
                    hintText: repsSheet
                        ? (goal.isNotEmpty ? goal : 'Type reps.')
                        : widget.weightUnit == WeightUnit.kg
                        ? 'Type kilograms.'
                        : 'Type pounds.',
                    hintStyle: TextStyle(color: context.liftBig.muted),
                  ),
                  onChanged: (value) {
                    _chose = true;
                    widget.onEdited(value);
                    setState(() => _slider = _sliderFor(value));
                  },
                  onSubmitted: (_) =>
                      FocusManager.instance.primaryFocus?.unfocus(),
                ),
              ),
              if (repsSheet)
                _RepTickRow(
                  min: widget.sliderMin,
                  max: widget.sliderMax,
                  goalMin: band?.min,
                  goalMax: band?.max,
                  value: loggedOpening || _chose ? _slider : null,
                  onChanged: (value) {
                    if (_lastSliderTick != value) {
                      _lastSliderTick = value;
                      liftBigSelectionHaptic();
                    }
                    _publish(_formatStep(value), fromSlider: true);
                  },
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Slider(
                    min: widget.sliderMin,
                    max: widget.sliderMax,
                    divisions: widget.sliderDivisions,
                    value: _slider,
                    activeColor: context.liftBig.primary,
                    label: _sliderTouched || typed.isNotEmpty
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
                child: _valueList(
                  repsSheet: repsSheet,
                  loggedOpening: loggedOpening,
                  band: band,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: FilledButton(
                  onPressed: () {
                    liftBigConfirmHaptic();
                    if (repsSheet) {
                      final saved = repSheetValueOnSave(
                        chose: _chose,
                        pending: _text.text,
                      );
                      Navigator.of(context).pop(saved ?? '');
                      return;
                    }
                    Navigator.of(context).pop(_text.text);
                  },
                  child: const Text('Save'),
                ),
              ),
            ],
          );
          final boxHeight = height < 180 ? 180.0 : height;
          return SizedBox(height: boxHeight, child: column);
        },
      ),
    );
  }

  Widget _valueList({
    required bool repsSheet,
    required bool loggedOpening,
    required ({int min, int max})? band,
  }) {
    final list = ListView.builder(
      controller: _scroll,
      itemExtent: repSheetRowExtent,
      itemCount: widget.options.length,
      itemBuilder: (context, index) {
        final option = widget.options[index];
        final typed = _text.text.trim();
        final selected = repsSheet
            ? typed.isNotEmpty && option == typed && (loggedOpening || _chose)
            : option == typed ||
                  (widget.weightUnit != null &&
                      option == snapWeightOption(typed, widget.weightUnit!));
        final count = int.tryParse(option);
        final predicted = widget.predictedLabel?.trim() ?? '';
        final predictedMark =
            repsSheet && predicted.isNotEmpty && option == predicted && !selected;
        final inGoal =
            band != null &&
            count != null &&
            count >= band.min &&
            count <= band.max;
        final isRangeTop = inGoal && count == band.max;
        final isRangeBottom = inGoal && count == band.min;
        final rangeLine = BorderSide(
          color: context.liftBig.success.withValues(alpha: 0.7),
          width: 2,
        );
        return RawGestureDetector(
          behavior: HitTestBehavior.opaque,
          gestures: _wheelGestures(),
          child: InkWell(
            onTap: () => _choose(option),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: selected
                    ? context.liftBig.primary.withValues(alpha: 0.16)
                    : Colors.transparent,
                border: isRangeTop || isRangeBottom
                    ? Border(
                        top: isRangeTop ? rangeLine : BorderSide.none,
                        bottom: isRangeBottom ? rangeLine : BorderSide.none,
                      )
                    : null,
              ),
              child: Center(
                child: Text(
                  option,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: selected || predictedMark
                        ? FontWeight.w800
                        : FontWeight.w500,
                    color: predictedMark
                        ? context.liftBig.primary
                        : inGoal
                        ? context.liftBig.success
                        : selected
                        ? context.liftBig.primary
                        : context.liftBig.foreground,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
    return list;
  }
}

/// Horizontal drags on a wheel row step the slider. Vertical drags are
/// rejected so the list scrolls as it does now. The first axis past the slop
/// wins, and a later move on the other axis does not do both.
class _SheetWheelRecognizer extends OneSequenceGestureRecognizer {
  ValueChanged<double>? onStep;
  VoidCallback? onEnd;

  double _dx = 0;
  double _dy = 0;
  double _reported = 0;
  SheetWheelLock? _lock;

  void _clear() {
    _dx = 0;
    _dy = 0;
    _reported = 0;
    _lock = null;
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event is PointerDownEvent) {
      _clear();
      return;
    }
    if (event is PointerUpEvent || event is PointerCancelEvent) {
      if (_lock != SheetWheelLock.horizontal) {
        resolve(GestureDisposition.rejected);
      }
      stopTrackingPointer(event.pointer);
      return;
    }
    if (event is! PointerMoveEvent || _lock == SheetWheelLock.vertical) return;
    _dx += event.delta.dx;
    _dy += event.delta.dy;
    if (_lock == null) {
      final lock = sheetWheelLock(dx: _dx, dy: _dy);
      if (lock == null) return;
      _lock = lock;
      if (lock == SheetWheelLock.vertical) {
        resolve(GestureDisposition.rejected);
        return;
      }
      resolve(GestureDisposition.accepted);
    }
    final travel = _dx - _reported;
    _reported = _dx;
    if (travel == 0 || onStep == null) return;
    invokeCallback<void>('onStep', () => onStep!(travel));
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    _clear();
    final end = onEnd;
    if (end != null) invokeCallback<void>('onEnd', end);
  }

  @override
  void rejectGesture(int pointer) {
    stopTrackingPointer(pointer);
  }

  @override
  String get debugDescription => 'sheet wheel';
}

class _RepTickRow extends StatelessWidget {
  const _RepTickRow({
    required this.min,
    required this.max,
    required this.value,
    required this.onChanged,
    this.goalMin,
    this.goalMax,
  });

  final double min;
  final double max;
  final int? goalMin;
  final int? goalMax;
  final double? value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final inside = context.liftBig.success;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;

          void pick(double dx) {
            if (max <= min) {
              onChanged(min);
              return;
            }
            final t = (dx / width).clamp(0.0, 1.0);
            final raw = min + t * (max - min);
            onChanged(raw.roundToDouble().clamp(min, max).toDouble());
          }

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) => pick(details.localPosition.dx),
            onHorizontalDragStart: (details) => pick(details.localPosition.dx),
            onHorizontalDragUpdate: (details) => pick(details.localPosition.dx),
            child: SizedBox(
              height: 36,
              width: width,
              child: CustomPaint(
                painter: _RepTickPainter(
                  min: min,
                  max: max,
                  goalMin: goalMin,
                  goalMax: goalMax,
                  value: value,
                  inside: inside,
                  outside: context.liftBig.muted,
                  chosen: context.liftBig.foreground,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RepTickPainter extends CustomPainter {
  const _RepTickPainter({
    required this.min,
    required this.max,
    required this.goalMin,
    required this.goalMax,
    required this.value,
    required this.inside,
    required this.outside,
    required this.chosen,
  });

  final double min;
  final double max;
  final int? goalMin;
  final int? goalMax;
  final double? value;
  final Color inside;
  final Color outside;
  final Color chosen;

  @override
  void paint(Canvas canvas, Size size) {
    if (max < min) return;
    final span = max - min;
    for (var tick = min.round(); tick <= max.round(); tick++) {
      final t = span == 0 ? 0.5 : (tick - min) / span;
      final x = t.clamp(0.0, 1.0) * size.width;
      final inGoal =
          goalMin != null &&
          goalMax != null &&
          tick >= goalMin! &&
          tick <= goalMax!;
      final paint = Paint()
        ..color = inGoal ? inside : outside
        ..strokeWidth = inGoal ? 2 : 1
        ..strokeCap = StrokeCap.round;
      final inset = inGoal ? 0.0 : 4.0;
      canvas.drawLine(Offset(x, 4 + inset), Offset(x, 28 - inset), paint);
    }
    if (value != null) {
      final t = span == 0 ? 0.5 : (value! - min) / span;
      final x = t.clamp(0.0, 1.0) * size.width;
      canvas.drawCircle(Offset(x, 16), 4.5, Paint()..color = chosen);
    }
  }

  @override
  bool shouldRepaint(covariant _RepTickPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.min != min ||
        oldDelegate.max != max ||
        oldDelegate.goalMin != goalMin ||
        oldDelegate.goalMax != goalMax ||
        oldDelegate.inside != inside ||
        oldDelegate.outside != outside;
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
    return KeyboardDismiss(
      fill: false,
      child: ListView(
        shrinkWrap: false,
        padding: EdgeInsets.fromLTRB(20, 8, 20, 16 + bottom),
        children: [
          const Text(
            'Rest Timer',
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
            textInputAction: TextInputAction.done,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(hintText: 'Seconds'),
            onSubmitted: (_) => FocusManager.instance.primaryFocus?.unfocus(),
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
