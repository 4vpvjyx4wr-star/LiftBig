import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'companion/companion_bridge.dart';
import 'data/app_database.dart';
import 'journal/journal_repository.dart';
import 'pro/pro_status.dart';
import 'reminder/daily_lift_notifications.dart';
import 'rest/rest_notifications.dart';
import 'rest/rest_timer_controller.dart';
import 'sync/firebase_bootstrap.dart';
import 'sync/sync_controller.dart';
import 'theme.dart';
import 'ui/app_shell.dart';
import 'ui/theme_backdrop.dart';
import 'ui/rest_timer_scope.dart';
import 'ui/rest_timer_tile.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final firebaseReady = await initializeFirebaseIfReady();
  final journal = JournalRepository(AppDatabase.defaults());
  final sync = SyncController(journal: journal, firebaseReady: firebaseReady);
  await sync.load();
  CompanionBridge.shared.setWatchCompanions(
    await journal.loadWatchCompanionSettings(),
  );
  final notifications = FlutterRestNotificationScheduler();
  await notifications.initialize();
  final dailyReminder = FlutterDailyLiftReminderScheduler(
    restScheduler: notifications,
  );
  final reminderSettings = await journal.loadDailyLiftReminderSettings();
  await dailyReminder.applySettings(reminderSettings);
  final restTimer = RestTimerController(
    journal: journal,
    notifications: notifications,
  );
  await restTimer.load();
  runApp(
    LiftBigApp(
      journal: journal,
      sync: sync,
      restTimer: restTimer,
      dailyReminder: dailyReminder,
    ),
  );
}

class LiftBigApp extends StatefulWidget {
  const LiftBigApp({
    super.key,
    required this.journal,
    required this.sync,
    required this.restTimer,
    required this.dailyReminder,
  });

  final JournalRepository journal;
  final SyncController sync;
  final RestTimerController restTimer;
  final DailyLiftReminderScheduler dailyReminder;

  @override
  State<LiftBigApp> createState() => _LiftBigAppState();
}

class _LiftBigAppState extends State<LiftBigApp>
    with SingleTickerProviderStateMixin {
  late final LiftBigThemeController _themes;
  late final AnimationController _backdropMotion;
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _backdropMotion = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    );
    _themes = LiftBigThemeController();
    _themes.addListener(_onTheme);
    _loadTheme();
  }

  void _onTheme() {
    _syncBackdropMotion();
    if (mounted) setState(() {});
  }

  /// Keeps the same clock running. Stopping holds the phase, and repeating
  /// continues from that value instead of jumping back to the start.
  void _syncBackdropMotion() {
    final animated = LiftBigBackdrop.animates(_themes.palette.backdrop);
    if (animated) {
      if (!_backdropMotion.isAnimating) _backdropMotion.repeat();
    } else if (_backdropMotion.isAnimating) {
      _backdropMotion.stop();
    }
  }

  Future<void> _loadTheme() async {
    final id = await widget.journal.loadColorThemeId();
    final pro = await ProStatus(
      unlockStore: JournalTesterUnlockStore(widget.journal),
    ).refresh();
    if (!mounted) return;
    _themes.applyStored(id, proActive: pro);
  }

  @override
  void dispose() {
    _themes.removeListener(_onTheme);
    _themes.dispose();
    _backdropMotion.dispose();
    widget.restTimer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RestTimerScope(
      controller: widget.restTimer,
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        title: 'LiftBig',
        debugShowCheckedModeBanner: false,
        theme: buildLiftBigTheme(_themes.palette),
        scrollBehavior: const LiftBigScrollBehavior(),
        builder: (context, child) {
          final colors =
              Theme.of(context).extension<LiftBigPalette>() ??
              liftBigThemePresets.first;
          final base = colors.canvas;
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle(
              statusBarColor: base,
              statusBarBrightness: Brightness.dark,
              statusBarIconBrightness: Brightness.light,
              systemNavigationBarColor: base,
              systemNavigationBarIconBrightness: Brightness.light,
            ),
            child: ColoredBox(
              color: base,
              child: Stack(
                children: [
                  if (colors.backdrop != LiftBigBackdrop.none)
                    Positioned.fill(
                      child: RepaintBoundary(
                        child: LiftBigThemeBackdrop(
                          palette: colors,
                          motion: LiftBigBackdrop.animates(colors.backdrop)
                              ? _backdropMotion
                              : null,
                        ),
                      ),
                    ),
                  child ?? const SizedBox.shrink(),
                  RestTimerOverlay(
                    journal: widget.journal,
                    controller: widget.restTimer,
                    navigatorKey: _navigatorKey,
                  ),
                ],
              ),
            ),
          );
        },
        home: AppShell(
          journal: widget.journal,
          sync: widget.sync,
          dailyReminder: widget.dailyReminder,
          themes: _themes,
        ),
      ),
    );
  }
}

/// Clamps scroll at content edges and disables overscroll glow/stretch app-wide.
final class LiftBigScrollBehavior extends MaterialScrollBehavior {
  const LiftBigScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics();
  }

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}
