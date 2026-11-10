import 'package:flutter/material.dart';

import '../theme.dart';

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
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    final keyboardOpen = inset > 0;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: Text(title)),
      body: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (event) => dismissKeyboardIfOutside(event.position),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.only(
                bottom: keyboardOpen ? inset + toolbarHeight : 0,
              ),
              child: SafeArea(
                top: false,
                bottom: !keyboardOpen,
                child: body,
              ),
            ),
            if (keyboardOpen)
              Positioned(
                left: 0,
                right: 0,
                bottom: inset,
                height: toolbarHeight,
                child: const KeyboardDoneBar(),
              ),
          ],
        ),
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
            onPressed: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: const Text('Done'),
          ),
        ),
      ),
    );
  }
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
