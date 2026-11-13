import 'package:flutter/material.dart';

import '../theme.dart';
import '../utils/weight_units.dart';

/// 1 mile in kilometers. Weight uses the journal's kg constant.
const double calculatorKmPerMile = 1.609344;

const List<String> calculatorSwapUnits = ['lb', 'kg', 'mi', 'km'];

/// Converts [value] into [target]. Pounds and kilograms swap with each other.
/// Miles and kilometers swap with each other.
double convertCalculatorUnit(double value, String target) {
  switch (target) {
    case 'lb':
      return kgToLbs(value);
    case 'kg':
      return lbsToKg(value);
    case 'mi':
      return value / calculatorKmPerMile;
    case 'km':
      return value * calculatorKmPerMile;
    default:
      return value;
  }
}

/// Rounded display for a converted number. Whole values drop the decimal.
String formatCalculatorConversion(double value) {
  if (!value.isFinite) return 'Error';
  return formatRoundedNumber(value, 3);
}

class BasicCalculatorPage extends StatefulWidget {
  const BasicCalculatorPage({super.key});

  @override
  State<BasicCalculatorPage> createState() => _BasicCalculatorPageState();
}

class _BasicCalculatorPageState extends State<BasicCalculatorPage> {
  var _display = '0';
  var _value = 0.0;
  var _stored = 0.0;
  String? _pendingOp;
  String? _unit;
  var _freshEntry = true;

  void _setEntry(double value, String display, {String? unit}) {
    _value = value;
    _display = display;
    _unit = unit;
  }

  void _inputDigit(String digit) {
    setState(() {
      if (_freshEntry) {
        _display = digit;
        _freshEntry = false;
      } else if (_display == '0' && digit != '.') {
        _display = digit;
      } else if (digit == '.' && _display.contains('.')) {
        return;
      } else if (_display == 'Error') {
        _display = digit;
      } else {
        _display = '$_display$digit';
      }
      _value = double.tryParse(_display) ?? 0;
      _unit = null;
    });
  }

  void _clear() {
    setState(() {
      _setEntry(0, '0');
      _stored = 0;
      _pendingOp = null;
      _freshEntry = true;
    });
  }

  void _percent() {
    if (_display == 'Error') return;
    setState(() {
      final next = _value / 100;
      _setEntry(next, _trimDisplay(next));
      _freshEntry = true;
    });
  }

  Future<void> _swapTo() async {
    if (_display == 'Error') return;
    final target = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Swap To'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final unit in calculatorSwapUnits)
                ListTile(
                  title: Text(unit),
                  onTap: () => Navigator.pop(context, unit),
                ),
            ],
          ),
        );
      },
    );
    if (target == null || !mounted) return;
    if (_unit == target) return;
    final next = convertCalculatorUnit(_value, target);
    setState(() {
      _setEntry(next, formatCalculatorConversion(next), unit: target);
      _freshEntry = true;
    });
  }

  void _applyPending() {
    final op = _pendingOp;
    if (op == null) {
      _stored = _value;
      return;
    }
    switch (op) {
      case '+':
        _stored += _value;
      case '-':
        _stored -= _value;
      case '×':
        _stored *= _value;
      case '÷':
        if (_value != 0) {
          _stored /= _value;
        } else {
          _setEntry(0, 'Error');
          _pendingOp = null;
          _freshEntry = true;
          return;
        }
    }
    _setEntry(_stored, _trimDisplay(_stored));
  }

  String _trimDisplay(double value) {
    if (!value.isFinite) return 'Error';
    if (value == value.roundToDouble()) {
      return value.round().toString();
    }
    return value.toStringAsFixed(6).replaceFirst(RegExp(r'\.?0+$'), '');
  }

  void _setOp(String op) {
    setState(() {
      if (_display == 'Error') return;
      if (_pendingOp != null && !_freshEntry) {
        _applyPending();
        if (_display == 'Error') return;
      } else {
        _stored = _value;
      }
      _pendingOp = op;
      _freshEntry = true;
      _unit = null;
    });
  }

  void _equals() {
    setState(() {
      if (_pendingOp == null || _display == 'Error') return;
      _applyPending();
      _pendingOp = null;
      _freshEntry = true;
      _unit = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calculator')),
      body: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              alignment: Alignment.bottomRight,
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Flexible(
                    child: Text(
                      _display,
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                  if (_unit != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      _unit!,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: context.liftBig.muted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          _Keypad(
            onDigit: _inputDigit,
            onClear: _clear,
            onPercent: _percent,
            onSwap: _swapTo,
            onOp: _setOp,
            onEquals: _equals,
          ),
        ],
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({
    required this.onDigit,
    required this.onClear,
    required this.onPercent,
    required this.onSwap,
    required this.onOp,
    required this.onEquals,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onClear;
  final VoidCallback onPercent;
  final VoidCallback onSwap;
  final ValueChanged<String> onOp;
  final VoidCallback onEquals;

  @override
  Widget build(BuildContext context) {
    final functionColor = context.liftBig.border;
    final operatorColor = context.liftBig.primary.withValues(alpha: 0.25);

    Widget key(
      String label,
      VoidCallback onTap, {
      int flex = 1,
      Color? bg,
      double fontSize = 20,
    }) {
      return Expanded(
        flex: flex,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: FilledButton(
            onPressed: onTap,
            style: FilledButton.styleFrom(
              backgroundColor: bg ?? context.liftBig.cardInner,
              foregroundColor: context.liftBig.foreground,
              padding: const EdgeInsets.symmetric(vertical: 18),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(label, style: TextStyle(fontSize: fontSize)),
            ),
          ),
        ),
      );
    }

    Row row(List<Widget> children) {
      return Row(children: children);
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          row([
            key('C', onClear, bg: functionColor),
            key('%', onPercent, bg: functionColor),
            key('Swap To', onSwap, bg: functionColor, fontSize: 16),
            key('÷', () => onOp('÷'), bg: operatorColor),
          ]),
          row([
            key('7', () => onDigit('7')),
            key('8', () => onDigit('8')),
            key('9', () => onDigit('9')),
            key('×', () => onOp('×'), bg: operatorColor),
          ]),
          row([
            key('4', () => onDigit('4')),
            key('5', () => onDigit('5')),
            key('6', () => onDigit('6')),
            key('-', () => onOp('-'), bg: operatorColor),
          ]),
          row([
            key('1', () => onDigit('1')),
            key('2', () => onDigit('2')),
            key('3', () => onDigit('3')),
            key('+', () => onOp('+'), bg: operatorColor),
          ]),
          row([
            key('0', () => onDigit('0'), flex: 2),
            key('.', () => onDigit('.')),
            key('=', onEquals, bg: context.liftBig.primary),
          ]),
        ],
      ),
    );
  }
}
