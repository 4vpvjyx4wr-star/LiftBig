import 'package:flutter/material.dart';

import '../rest/rest_timer_state.dart';
import '../theme.dart';

class RestTimerBanner extends StatelessWidget {
  const RestTimerBanner({
    super.key,
    required this.remaining,
    required this.running,
    required this.exerciseName,
    required this.onPause,
    required this.onReset,
    required this.onDismiss,
  });

  final int remaining;
  final bool running;
  final String? exerciseName;
  final VoidCallback onPause;
  final VoidCallback onReset;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final done = remaining == 0;
    final subtitle = exerciseName?.trim();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: done ? const Color(0xFF163020) : LiftBigColors.card,
        border: Border(
          bottom: BorderSide(
            color: done ? LiftBigColors.success : LiftBigColors.primary,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    done ? 'Rest done' : 'Rest',
                    style: TextStyle(
                      color: done ? LiftBigColors.success : LiftBigColors.muted,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  if (subtitle != null && subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: LiftBigColors.foreground,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  Text(
                    formatRestClock(remaining),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            RestTimerControls(
              remaining: remaining,
              running: running,
              onPause: onPause,
              onReset: onReset,
            ),
            TextButton(
              onPressed: onDismiss,
              child: Text(done ? 'Dismiss' : 'Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}

class RestTimerControls extends StatelessWidget {
  const RestTimerControls({
    super.key,
    required this.remaining,
    required this.running,
    required this.onPause,
    required this.onReset,
    this.compact = false,
  });

  final int remaining;
  final bool running;
  final VoidCallback onPause;
  final VoidCallback onReset;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final done = remaining == 0;
    if (done) {
      return TextButton(
        onPressed: onReset,
        style: TextButton.styleFrom(
          visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
          padding: compact ? const EdgeInsets.symmetric(horizontal: 6) : null,
        ),
        child: const Text('Reset'),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton(
          onPressed: onPause,
          style: TextButton.styleFrom(
            visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
            padding: compact ? const EdgeInsets.symmetric(horizontal: 6) : null,
          ),
          child: Text(running ? 'Pause' : 'Resume'),
        ),
        TextButton(
          onPressed: onReset,
          style: TextButton.styleFrom(
            visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
            padding: compact ? const EdgeInsets.symmetric(horizontal: 6) : null,
          ),
          child: const Text('Reset'),
        ),
      ],
    );
  }
}
