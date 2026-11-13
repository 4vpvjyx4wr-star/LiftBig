import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/app_database.dart';
import '../journal/journal_repository.dart';
import '../rest/rest_timer_controller.dart';
import '../rest/rest_timer_state.dart';
import '../theme.dart';
import 'liftbig_sheet.dart';
import 'rest_timer_banner.dart';
import 'set_value_sheet.dart';

/// Rest card above every route, including sheets. Hidden while rest is off,
/// while it is anchored on the Lift tab, and while its menu is open.
/// A looping alarm replaces that card with a centered Stop.
class RestTimerOverlay extends StatelessWidget {
  const RestTimerOverlay({
    super.key,
    required this.journal,
    required this.controller,
    required this.navigatorKey,
  });

  final JournalRepository journal;
  final RestTimerController controller;
  final GlobalKey<NavigatorState> navigatorKey;

  Future<void> _confirmCancel(RestTimerController controller) async {
    final context = navigatorKey.currentContext;
    if (context == null || !context.mounted) return;
    if (!await confirmCancelRestTimer(context)) return;
    await controller.dismiss();
  }

  Future<void> _openMenu() async {
    final context = navigatorKey.currentContext;
    if (context == null || !context.mounted) return;
    await showRestTimerMenu(context, controller);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (controller.alarmRinging) {
          return RestAlarmStopButton(onStop: controller.stopAlarm);
        }
        if (!controller.showsFloatingCard) return const SizedBox.shrink();
        return RestTimerTileOverlay(
          journal: journal,
          remaining: controller.remaining,
          running: controller.isRunning,
          onPause: controller.togglePause,
          onReset: controller.reset,
          onDismiss: () => controller.setChrome(RestTimerChrome.anchored),
          onCancel: () {
            _confirmCancel(controller);
          },
          onOpen: _openMenu,
        );
      },
    );
  }
}

/// Live rest menu shared by the floating card and the Lift date timer.
Future<void> showRestTimerMenu(
  BuildContext context,
  RestTimerController controller,
) async {
  if (!context.mounted) return;
  controller.setMenuOpen(true);
  try {
    await showLiftBigSheet<void>(
      context,
      builder: (context) => RestTimerMenu(controller: controller),
    );
  } finally {
    controller.setMenuOpen(false);
  }
}

/// Pause, reset, dismiss, edit, and cancel, with the countdown still running.
class RestTimerMenu extends StatelessWidget {
  const RestTimerMenu({super.key, required this.controller});

  final RestTimerController controller;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final remaining = controller.remaining;
        final running = controller.isRunning;
        final done = remaining == 0;
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 16 + bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                formatRestClock(remaining),
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  color: done ? context.liftBig.success : context.liftBig.foreground,
                ),
              ),
              if (done)
                Text(
                  'Rest done.',
                  style: TextStyle(
                    color: context.liftBig.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: done ? controller.stopAlarm : controller.togglePause,
                      icon: Icon(
                        done
                            ? Icons.stop
                            : (running ? Icons.pause : Icons.play_arrow),
                      ),
                      label: Text(done ? 'Stop' : (running ? 'Pause' : 'Resume')),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: controller.reset,
                      icon: const Icon(Icons.replay),
                      label: const Text('Reset'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showRestDurationDialog(
                      context,
                      initialSeconds: controller.remaining,
                    );
                    if (picked == null) return;
                    await controller.setRemaining(picked);
                  },
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    await controller.setChrome(RestTimerChrome.anchored);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.vertical_align_top),
                  label: const Text('Dismiss'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final yes = await confirmCancelRestTimer(context);
                    if (!yes || !context.mounted) return;
                    await controller.dismiss();
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.close),
                  label: const Text('Cancel'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Large Stop shown on every screen while the rest tone is looping.
class RestAlarmStopButton extends StatelessWidget {
  const RestAlarmStopButton({super.key, required this.onStop});

  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FilledButton(
        onPressed: onStop,
        style: FilledButton.styleFrom(
          minimumSize: const Size(220, 220),
          shape: const CircleBorder(),
          textStyle: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800),
        ),
        child: const Text('Stop'),
      ),
    );
  }
}

/// One compact rest card. The stack around it does not hit-test, so the log
/// and the tab bar stay usable. The offset is remembered after a drag.
class RestTimerTileOverlay extends StatefulWidget {
  const RestTimerTileOverlay({
    super.key,
    required this.journal,
    required this.remaining,
    required this.running,
    required this.onPause,
    required this.onReset,
    required this.onDismiss,
    required this.onCancel,
    required this.onOpen,
  });

  final JournalRepository journal;
  final int remaining;
  final bool running;
  final VoidCallback onPause;
  final VoidCallback onReset;
  final VoidCallback onDismiss;
  final VoidCallback onCancel;
  final VoidCallback onOpen;

  @override
  State<RestTimerTileOverlay> createState() => _RestTimerTileOverlayState();
}

class _RestTimerTileOverlayState extends State<RestTimerTileOverlay> {
  Offset? _offset;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final stored = await _readOffset();
    if (!mounted || stored == null) return;
    setState(() => _offset = stored);
  }

  Future<Offset?> _readOffset() async {
    try {
      final row = await (widget.journal.db.select(widget.journal.db.localSettings)
            ..where((setting) => setting.key.equals(restTimerTileOffsetKey)))
          .getSingleOrNull();
      return _parseOffset(row?.value);
    } catch (_) {
      return null;
    }
  }

  Future<void> _persist(Offset offset) async {
    try {
      await widget.journal.db.into(widget.journal.db.localSettings).insertOnConflictUpdate(
            LocalSettingsCompanion.insert(
              key: restTimerTileOffsetKey,
              value: '${offset.dx.toStringAsFixed(1)},${offset.dy.toStringAsFixed(1)}',
            ),
          );
    } catch (_) {
      // The card still moves for this session if the setting cannot be saved.
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final top = media.padding.top;
    final bottom = math.max(media.viewInsets.bottom, media.padding.bottom);
    return Padding(
      padding: EdgeInsets.only(top: top, bottom: bottom),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final offset = _clamp(_offset ?? _defaultOffset(constraints), constraints);
          return Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                left: offset.dx,
                top: offset.dy,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      final current = _offset ?? _defaultOffset(constraints);
                      _offset = _clamp(current + details.delta, constraints);
                    });
                  },
                  onPanEnd: (_) {
                    final saved = _offset;
                    if (saved != null) _persist(saved);
                  },
                  child: RestTimerBanner(
                    remaining: widget.remaining,
                    running: widget.running,
                    onPause: widget.onPause,
                    onReset: widget.onReset,
                    onDismiss: widget.onDismiss,
                    onCancel: widget.onCancel,
                    onOpen: widget.onOpen,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

Offset _defaultOffset(BoxConstraints constraints) {
  final width = constraints.maxWidth.isFinite ? constraints.maxWidth : restTimerTileWidth;
  return Offset(math.max(0, (width - restTimerTileWidth) / 2), 8);
}

Offset _clamp(Offset offset, BoxConstraints constraints) {
  final width = constraints.maxWidth.isFinite ? constraints.maxWidth : restTimerTileWidth;
  final height = constraints.maxHeight.isFinite ? constraints.maxHeight : restTimerTileHeight;
  final maxX = math.max(0.0, width - restTimerTileWidth);
  final maxY = math.max(0.0, height - restTimerTileHeight);
  return Offset(offset.dx.clamp(0.0, maxX), offset.dy.clamp(0.0, maxY));
}

Offset? _parseOffset(String? raw) {
  if (raw == null) return null;
  final parts = raw.split(',');
  if (parts.length != 2) return null;
  final dx = double.tryParse(parts[0].trim());
  final dy = double.tryParse(parts[1].trim());
  if (dx == null || dy == null || !dx.isFinite || !dy.isFinite) return null;
  return Offset(dx, dy);
}
