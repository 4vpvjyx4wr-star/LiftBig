import 'package:flutter/material.dart';

import '../rest/rest_timer_state.dart';
import '../theme.dart';

const double restTimerTileWidth = 176;
const double restTimerTileHeight = 96;

/// Asks before a rest countdown is cleared. No leaves the timer running.
Future<bool> confirmCancelRestTimer(BuildContext context) async {
  final yes = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Cancel Timer?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes'),
          ),
        ],
      );
    },
  );
  return yes == true;
}

/// Compact draggable rest card. Icon buttons only, so the square stays small.
class RestTimerBanner extends StatelessWidget {
  const RestTimerBanner({
    super.key,
    required this.remaining,
    required this.running,
    required this.onPause,
    required this.onReset,
    required this.onDismiss,
    required this.onCancel,
    required this.onOpen,
  });

  final int remaining;
  final bool running;
  final VoidCallback onPause;
  final VoidCallback onReset;
  final VoidCallback onDismiss;
  final VoidCallback onCancel;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final done = remaining == 0;
    final border = done ? context.liftBig.success : context.liftBig.primary;
    return SizedBox(
      width: restTimerTileWidth,
      child: Material(
        color: done ? const Color(0xFF163020) : context.liftBig.card,
        elevation: 8,
        shadowColor: Colors.black54,
        borderRadius: BorderRadius.circular(16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border, width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onOpen,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 2),
                  child: Text(
                    formatRestClock(remaining),
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                      color: done
                          ? context.liftBig.success
                          : context.liftBig.foreground,
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _iconButton(
                    tooltip: done ? 'Stop' : (running ? 'Pause' : 'Resume'),
                    icon: done
                        ? Icons.stop
                        : (running ? Icons.pause : Icons.play_arrow),
                    onPressed: onPause,
                  ),
                  _iconButton(
                    tooltip: 'Reset',
                    icon: Icons.replay,
                    onPressed: onReset,
                  ),
                  _iconButton(
                    tooltip: 'Dismiss',
                    icon: Icons.vertical_align_top,
                    onPressed: onDismiss,
                  ),
                  _iconButton(
                    tooltip: 'Cancel',
                    icon: Icons.close,
                    onPressed: onCancel,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconButton({
    required String tooltip,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      icon: Icon(icon, size: 20),
    );
  }
}

/// Live rest parked above the Lift date. One control returns the floating card.
class AnchoredRestTimer extends StatelessWidget {
  const AnchoredRestTimer({
    super.key,
    required this.remaining,
    required this.running,
    required this.onPause,
    required this.onReset,
    required this.onFloat,
    required this.onCancel,
  });

  final int remaining;
  final bool running;
  final VoidCallback onPause;
  final VoidCallback onReset;
  final VoidCallback onFloat;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final done = remaining == 0;
    return Material(
      color: done ? const Color(0xFF163020) : context.liftBig.card,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            Text(
              formatRestClock(remaining),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: done ? context.liftBig.success : context.liftBig.foreground,
              ),
            ),
            const Spacer(),
            _icon(
              tooltip: done ? 'Stop' : (running ? 'Pause' : 'Resume'),
              icon: done ? Icons.stop : (running ? Icons.pause : Icons.play_arrow),
              onPressed: onPause,
            ),
            _icon(tooltip: 'Reset', icon: Icons.replay, onPressed: onReset),
            _icon(
              tooltip: 'Move Timer',
              icon: Icons.open_with,
              onPressed: onFloat,
            ),
            _icon(
              tooltip: 'Cancel',
              icon: Icons.close,
              onPressed: () {
                confirmCancelRestTimer(context).then((yes) {
                  if (yes) onCancel();
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _icon({
    required String tooltip,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      icon: Icon(icon, size: 20),
    );
  }
}
