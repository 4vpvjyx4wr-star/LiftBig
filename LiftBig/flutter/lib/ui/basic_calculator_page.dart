import 'package:flutter/material.dart';

import '../theme.dart';

class BasicCalculatorPage extends StatefulWidget {
  const BasicCalculatorPage({super.key});

  @override
  State<BasicCalculatorPage> createState() => _BasicCalculatorPageState();
}

class _BasicCalculatorPageState extends State<BasicCalculatorPage> {
  var _display = '0';
  var _stored = 0.0;
  String? _pendingOp;
  var _freshEntry = true;

  void _inputDigit(String digit) {
    setState(() {
      if (_freshEntry) {
        _display = digit;
        _freshEntry = false;
      } else if (_display == '0' && digit != '.') {
        _display = digit;
      } else if (digit == '.' && _display.contains('.')) {
        return;
      } else {
        _display = '$_display$digit';
      }
    });
  }

  double get _current => double.tryParse(_display) ?? 0;

  void _clear() {
    setState(() {
      _display = '0';
      _stored = 0;
      _pendingOp = null;
      _freshEntry = true;
    });
  }

  void _applyPending() {
    final op = _pendingOp;
    if (op == null) {
      _stored = _current;
      return;
    }
    switch (op) {
      case '+':
        _stored += _current;
      case '-':
        _stored -= _current;
      case '×':
        _stored *= _current;
      case '÷':
        if (_current != 0) {
          _stored /= _current;
        } else {
          _display = 'Error';
          _pendingOp = null;
          _freshEntry = true;
          return;
        }
    }
    _display = _trimDisplay(_stored);
  }

  String _trimDisplay(double value) {
    if (value == value.roundToDouble()) {
      return value.round().toString();
    }
    return value.toStringAsFixed(6).replaceFirst(RegExp(r'\.?0+$'), '');
  }

  void _setOp(String op) {
    setState(() {
      if (_pendingOp != null && !_freshEntry) {
        _applyPending();
      } else {
        _stored = _current;
      }
      _pendingOp = op;
      _freshEntry = true;
    });
  }

  void _equals() {
    setState(() {
      if (_pendingOp == null) return;
      _applyPending();
      _pendingOp = null;
      _freshEntry = true;
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
              child: Text(
                _display,
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.end,
              ),
            ),
          ),
          _Keypad(
            onDigit: _inputDigit,
            onClear: _clear,
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
    required this.onOp,
    required this.onEquals,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onClear;
  final ValueChanged<String> onOp;
  final VoidCallback onEquals;

  @override
  Widget build(BuildContext context) {
    Widget key(String label, VoidCallback onTap, {Color? bg}) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: FilledButton(
            onPressed: onTap,
            style: FilledButton.styleFrom(
              backgroundColor: bg ?? LiftBigColors.cardInner,
              foregroundColor: LiftBigColors.foreground,
              padding: const EdgeInsets.symmetric(vertical: 18),
            ),
            child: Text(label, style: const TextStyle(fontSize: 20)),
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
            key('C', onClear, bg: LiftBigColors.border),
            key('÷', () => onOp('÷')),
            key('×', () => onOp('×')),
            key('-', () => onOp('-')),
          ]),
          row([
            key('7', () => onDigit('7')),
            key('8', () => onDigit('8')),
            key('9', () => onDigit('9')),
            key('+', () => onOp('+'), bg: LiftBigColors.primary.withValues(alpha: 0.25)),
          ]),
          row([
            key('4', () => onDigit('4')),
            key('5', () => onDigit('5')),
            key('6', () => onDigit('6')),
            key('=', onEquals, bg: LiftBigColors.primary),
          ]),
          row([
            key('1', () => onDigit('1')),
            key('2', () => onDigit('2')),
            key('3', () => onDigit('3')),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: FilledButton(
                  onPressed: () => onDigit('0'),
                  style: FilledButton.styleFrom(
                    backgroundColor: LiftBigColors.cardInner,
                    foregroundColor: LiftBigColors.foreground,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                  child: const Text('0', style: TextStyle(fontSize: 20)),
                ),
              ),
            ),
          ]),
          row([
            key('.', () => onDigit('.')),
          ]),
        ],
      ),
    );
  }
}
