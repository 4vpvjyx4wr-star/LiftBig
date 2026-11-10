import 'package:flutter/material.dart';

import '../rest/rest_timer_state.dart';
import '../theme.dart';

const double restTimerTileWidth = 176;
const double restTimerTileHeight = 72;

/// Compact rest card: clock, pause, and dismiss. A tap on the clock edits
/// the time still left. Only this card is painted, even when a parent stretches
/// the slot.
class RestTimerBanner extends StatelessWidget {
  const RestTimerBanner({
    super.key,
    required this.remaining,
    required this.running,
    required this.exerciseName,
    required this.onPause,
    required this.onEdit,
    required this.onDismiss,
  });

  final int remaining;
  final bool running;
  final String? exerciseName;
  final VoidCallback onPause;
  final VoidCallback onEdit;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final card = SizedBox(
      width: restTimerTileWidth,
      child: _card(context),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final stretched = constraints.hasTightWidth &&
            constraints.maxWidth > restTimerTileWidth + 1;
        if (!stretched) return card;
        return Align(alignment: Alignment.topRight, child: card);
      },
    );
  }

  Widget _card(BuildContext context) {
    final done = remaining == 0;
    final name = exerciseName?.trim();
    final border = done ? context.liftBig.success : context.liftBig.primary;
    return Material(
      color: done ? const Color(0xFF163020) : context.liftBig.card,
      elevation: 8,
      shadowColor: Colors.black54,
      borderRadius: BorderRadius.circular(16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border, width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 2, 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: onEdit,
                    child: Text(
                      formatRestClock(remaining),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                        color: done ? context.liftBig.success : context.liftBig.foreground,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (!done)
                    _iconButton(
                      tooltip: running ? 'Pause' : 'Resume',
                      icon: running ? Icons.pause : Icons.play_arrow,
                      onPressed: onPause,
                    ),
                  _iconButton(
                    tooltip: 'Dismiss',
                    icon: Icons.close,
                    onPressed: onDismiss,
                  ),
                ],
              ),
              if (done || (name != null && name.isNotEmpty))
                Padding(
                  padding: const EdgeInsets.only(right: 8, bottom: 2),
                  child: GestureDetector(
                    onTap: done ? null : onEdit,
                    child: Text(
                      done ? 'Rest done' : (name ?? ''),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: done ? context.liftBig.success : context.liftBig.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
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
    required VoidCallback onPressed,
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
