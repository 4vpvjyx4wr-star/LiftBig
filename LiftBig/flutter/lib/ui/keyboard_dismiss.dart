import 'package:flutter/material.dart';

import '../theme.dart';

/// Keyboard overlap in logical pixels, including when a scaffold has already
/// removed [MediaQuery.viewInsets] from its children.
double keyboardBottomInset(BuildContext context) {
  final media = MediaQuery.viewInsetsOf(context).bottom;
  final view = View.maybeOf(context);
  if (view == null || view.devicePixelRatio == 0) return media;
  final raw = view.viewInsets.bottom / view.devicePixelRatio;
  return media > raw ? media : raw;
}

/// Page shell that dismisses the keyboard on a tap outside the focused field
/// and shows a Done bar above the keyboard.
class KeyboardDismissScaffold extends StatelessWidget {
  const KeyboardDismissScaffold({
    super.key,
    required this.title,
    required this.body,
  });

  final String title;
  final Widget body;

  static const toolbarHeight = 44.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: Text(title)),
      body: KeyboardDismiss(
        fill: false,
        child: SafeArea(top: false, child: body),
      ),
    );
  }
}

/// Done bar plus a tap outside the focused field.
///
/// [fill] is for a page body that should keep the parent's height. Sheets and
/// dialogs use [fill] false so they stay as tall as their content, with the
/// keyboard inset taken out of the space the child can use.
class KeyboardDismiss extends StatefulWidget {
  const KeyboardDismiss({super.key, required this.child, this.fill = true});

  final Widget child;
  final bool fill;

  @override
  State<KeyboardDismiss> createState() => _KeyboardDismissState();
}

class _KeyboardDismissState extends State<KeyboardDismiss> {
  Offset? _pointerDown;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(_onFocus);
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_onFocus);
    super.dispose();
  }

  void _onFocus() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return _buildDismiss(context);
  }

  Widget _buildDismiss(BuildContext context) {
    final media = MediaQuery.viewInsetsOf(context).bottom;
    final open = textInputHasPrimaryFocus();
    final lift = media > 0 ? media : 0.0;
    final bar = open ? KeyboardDismissScaffold.toolbarHeight : 0.0;
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) => _pointerDown = event.position,
      onPointerUp: (event) {
        final down = _pointerDown;
        _pointerDown = null;
        if (down == null) return;
        if ((event.position - down).distance > 8) return;
        dismissKeyboardIfOutside(event.position);
      },
      onPointerCancel: (_) => _pointerDown = null,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bounded =
              constraints.hasBoundedHeight && constraints.maxHeight.isFinite;
          if (!widget.fill || !bounded) {
            // A modal sheet already pads by the keyboard inset and still
            // reports that inset. Subtracting it again throws the sheet
            // to the top and covers the field.
            final screen = MediaQuery.sizeOf(context).height;
            final alreadyLifted =
                bounded && lift > 0 && constraints.maxHeight + lift <= screen - 8;
            final extra = alreadyLifted ? 0.0 : lift;
            final limit = bounded
                ? (constraints.maxHeight - extra - bar).clamp(0.0, constraints.maxHeight)
                : double.infinity;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: limit),
                  child: widget.child,
                ),
                if (open)
                  const SizedBox(
                    height: KeyboardDismissScaffold.toolbarHeight,
                    child: KeyboardDoneBar(),
                  ),
                if (extra > 0) SizedBox(height: extra),
              ],
            );
          }
          return Stack(
            fit: StackFit.expand,
            children: [
              Padding(
                padding: EdgeInsets.only(bottom: lift + bar),
                child: widget.child,
              ),
              if (open)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: lift,
                  height: KeyboardDismissScaffold.toolbarHeight,
                  child: const KeyboardDoneBar(),
                ),
            ],
          );
        },
      ),
    );
  }
}

class KeyboardDoneBar extends StatelessWidget {
  const KeyboardDoneBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.liftBig.card,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: context.liftBig.border)),
        ),
        child: Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            style: TextButton.styleFrom(
              minimumSize: const Size(64, KeyboardDismissScaffold.toolbarHeight),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              visualDensity: VisualDensity.standard,
            ),
            onPressed: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: const Text('Done'),
          ),
        ),
      ),
    );
  }
}

/// True when the focused control is a text field. A stale keyboard inset
/// does not count: the Done bar stays up only while the field is focused.
bool textInputHasPrimaryFocus() {
  final focus = FocusManager.instance.primaryFocus;
  if (focus == null || !focus.hasFocus) return false;
  if (focus.debugLabel == 'EditableText') return true;
  final element = focus.context;
  if (element == null) return false;
  if (element.widget is EditableText) return true;
  var found = false;
  element.visitAncestorElements((ancestor) {
    if (ancestor.widget is EditableText) {
      found = true;
      return false;
    }
    return true;
  });
  return found;
}

/// Unfocuses the primary field when [global] is outside that field.
void dismissKeyboardIfOutside(Offset global) {
  final focus = FocusManager.instance.primaryFocus;
  if (focus == null || !focus.hasFocus) return;
  final object = focus.context?.findRenderObject();
  if (object is RenderBox && object.attached && object.hasSize) {
    final rect = object.localToGlobal(Offset.zero) & object.size;
    if (rect.contains(global)) return;
  }
  focus.unfocus();
}
