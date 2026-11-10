import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/app_database.dart';
import '../journal/journal_repository.dart';
import '../rest/rest_timer_controller.dart';
import 'rest_timer_banner.dart';
import 'set_value_sheet.dart';

const _offsetKey = 'rest_timer_tile_offset';

/// Rest card above every route, including sheets. Hidden while rest is off.
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

  Future<void> _edit() async {
    final context = navigatorKey.currentContext;
    if (context == null || !context.mounted) return;
    final picked = await showRestDurationDialog(
      context,
      initialSeconds: controller.remaining,
    );
    if (picked == null) return;
    await controller.setRemaining(picked);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (!controller.isActive) return const SizedBox.shrink();
        return RestTimerTileOverlay(
          journal: journal,
          remaining: controller.remaining,
          running: controller.isRunning,
          exerciseName: controller.snapshot.exerciseName,
          onPause: controller.togglePause,
          onEdit: _edit,
          onDismiss: controller.dismiss,
        );
      },
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
    required this.exerciseName,
    required this.onPause,
    required this.onEdit,
    required this.onDismiss,
  });

  final JournalRepository journal;
  final int remaining;
  final bool running;
  final String? exerciseName;
  final VoidCallback onPause;
  final VoidCallback onEdit;
  final VoidCallback onDismiss;

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
            ..where((setting) => setting.key.equals(_offsetKey)))
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
              key: _offsetKey,
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
                    exerciseName: widget.exerciseName,
                    onPause: widget.onPause,
                    onEdit: widget.onEdit,
                    onDismiss: widget.onDismiss,
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
  return Offset(math.max(8, width - restTimerTileWidth - 8), 8);
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
