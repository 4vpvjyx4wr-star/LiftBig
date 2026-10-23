import 'package:flutter/material.dart';

import '../companion/companion_bridge.dart';
import '../companion/watch_session.dart';
import '../date_key.dart';
import '../health/journal_health_sync.dart';
import '../journal/journal_repository.dart';
import '../reminder/daily_lift_notifications.dart';
import '../sync/sync_controller.dart';
import '../theme.dart';
import 'day_page.dart';
import 'home_page.dart';
import 'library_page.dart';
import 'plans_page.dart';
import 'progress_page.dart';
import 'settings_page.dart';
import '../rest/rest_timer_controller.dart';
import 'rest_timer_banner.dart';
import 'rest_timer_scope.dart';
import 'liftbig_sheet.dart';
import 'shell_tabs.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.journal,
    required this.sync,
    required this.dailyReminder,
    required this.themes,
  });

  final JournalRepository journal;
  final SyncController sync;
  final DailyLiftReminderScheduler dailyReminder;
  final LiftBigThemeController themes;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  var _index = 0;
  var _refresh = 0;
  final _opened = <int>{0};
  String? _homeFocusDateKey;
  RestTimerController? _restTimer;
  late final JournalHealthSync _healthSync;
  final _companion = CompanionBridge.shared;
  Future<void> _watchWrites = Future<void>.value();

  @override
  void initState() {
    super.initState();
    _healthSync = JournalHealthSync(journal: widget.journal);
    _companion.addListener(_onWatchMessage);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = RestTimerScope.of(context);
    if (_restTimer != next) {
      _restTimer?.removeListener(_onRestTimerChanged);
      _restTimer = next;
      _restTimer!.addListener(_onRestTimerChanged);
    }
  }

  @override
  void dispose() {
    _companion.removeListener(_onWatchMessage);
    _healthSync.dispose();
    _restTimer?.removeListener(_onRestTimerChanged);
    super.dispose();
  }

  void _onWatchMessage(String raw) {
    _watchWrites = _watchWrites.then((_) => _applyWatchMessage(raw));
  }

  Future<void> _applyWatchMessage(String raw) async {
    final unit = await widget.journal.storedWeightUnit();
    final message = parseCompanionMessage(raw, fallbackUnit: unit);
    if (message == null) return;
    if (message.isFinish) {
      if (message.activeKcal != null) {
        await widget.journal.setHealthEnergyKcal(message.dateKey, message.activeKcal);
      } else {
        await _healthSync.syncDay(message.dateKey, honorToggle: false);
      }
    } else if (message.isSetRest && message.restSeconds != null) {
      await widget.journal.setChosenRestSeconds(message.dateKey, message.restSeconds!);
    } else if (!message.isSkipRest) {
      await widget.journal.persistCompanionMessage(message);
    }
    if (mounted) setState(() => _refresh++);
  }

  void _onRestTimerChanged() {
    if (mounted) setState(() {});
  }

  void _select(int index) {
    setState(() {
      _index = index;
      _opened.add(index);
      if (index == ShellTab.home.index ||
          index == ShellTab.progress.index ||
          index == ShellTab.lift.index ||
          index == ShellTab.plans.index) {
        _refresh++;
      }
    });
  }

  void _openHomeOnDate(String dateKey) {
    setState(() {
      _homeFocusDateKey = dateKey;
      _index = ShellTab.home.index;
      _opened.add(ShellTab.home.index);
      _refresh++;
    });
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SettingsPage(
          sync: widget.sync,
          dailyReminder: widget.dailyReminder,
          themes: widget.themes,
        ),
      ),
    );
    if (!mounted) return;
    setState(() => _refresh++);
  }

  @override
  Widget build(BuildContext context) {
    final today = todayKey();
    final rest = _restTimer;
    final showRestBanner = rest != null && rest.isActive;
    return Scaffold(
      backgroundColor: context.liftBig.background,
      body: Column(
        children: [
          _ShellHeader(
            showTagline: _index == ShellTab.home.index,
            onSettings: _openSettings,
          ),
          Expanded(
            child: Stack(
              children: [
                IndexedStack(
                  index: _index,
                  children: [
                    for (var tab = 0; tab < ShellTab.values.length; tab++)
                      _opened.contains(tab)
                          ? _page(tab, today)
                          : const SizedBox.shrink(),
                  ],
                ),
                if (showRestBanner)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: RestTimerBanner(
                      remaining: rest.remaining,
                      running: rest.isRunning,
                      exerciseName: rest.snapshot.exerciseName,
                      onPause: () => rest.togglePause(),
                      onReset: () {
                        final snap = rest.snapshot;
                        rest.reset(
                          fullSeconds: snap.fullSeconds > 0
                              ? snap.fullSeconds
                              : 60,
                        );
                      },
                      onDismiss: () => rest.dismiss(),
                    ),
                  ),
              ],
            ),
          ),
          _ShellBar(index: _index, onSelect: _select),
        ],
      ),
    );
  }

  Widget _page(int tab, String today) {
    return switch (ShellTab.values[tab]) {
      ShellTab.home => HomePage(
        journal: widget.journal,
        refreshToken: _refresh,
        focusDateKey: _homeFocusDateKey,
        onOpenSettings: _openSettings,
      ),
      ShellTab.progress => ProgressPage(
        journal: widget.journal,
        refreshToken: _refresh,
      ),
      ShellTab.lift => DayPage(
        journal: widget.journal,
        dateKey: today,
        refreshToken: _refresh,
        embedRestBanner: false,
        onOpenSettings: _openSettings,
      ),
      ShellTab.plans => PlansPage(
        journal: widget.journal,
        refreshToken: _refresh,
        onPlanScheduled: _openHomeOnDate,
      ),
      ShellTab.library => const LibraryPage(),
    };
  }
}

class _ShellHeader extends StatelessWidget {
  const _ShellHeader({required this.showTagline, required this.onSettings});

  final bool showTagline;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return DecoratedBox(
      decoration:  BoxDecoration(
        color: context.liftBig.background,
        border: Border(bottom: BorderSide(color: context.liftBig.border)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, top + 8, 8, 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    'LIFTBIG',
                    style: TextStyle(
                      color: context.liftBig.primary,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                    ),
                  ),
                  if (showTagline)
                     Text(
                      'TRAINING JOURNAL',
                      style: TextStyle(
                        color: context.liftBig.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Settings',
              onPressed: onSettings,
              icon: const Icon(Icons.settings_outlined),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShellBar extends StatelessWidget {
  const _ShellBar({required this.index, required this.onSelect});

  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return DecoratedBox(
      decoration:  BoxDecoration(
        color: context.liftBig.card,
        border: Border(top: BorderSide(color: context.liftBig.border)),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: SizedBox(
          height: 64,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final tab in ShellTab.values)
                Expanded(
                  child: tab == ShellTab.lift
                      ? _LiftButton(
                          selected: index == tab.index,
                          onTap: () {
                            liftBigSelectionHaptic();
                            onSelect(tab.index);
                          },
                        )
                      : _TabButton(
                          tab: tab,
                          selected: index == tab.index,
                          onTap: () {
                            liftBigSelectionHaptic();
                            onSelect(tab.index);
                          },
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final ShellTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? context.liftBig.primary : context.liftBig.muted;
    return Semantics(
      button: true,
      selected: selected,
      label: tab.label,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 6, top: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(_icon(tab), size: 20, color: color),
              const SizedBox(height: 2),
              Text(
                tab.label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _icon(ShellTab tab) {
  return switch (tab) {
    ShellTab.home => Icons.home,
    ShellTab.progress => Icons.show_chart,
    ShellTab.lift => Icons.fitness_center,
    ShellTab.plans => Icons.assignment,
    ShellTab.library => Icons.menu_book,
  };
}

class _LiftButton extends StatelessWidget {
  const _LiftButton({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: 'Open today\'s workout log',
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Transform.translate(
              offset: const Offset(0, -16),
              child: Container(
                width: 77,
                height: 77,
                decoration:  BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.liftBig.background,
                ),
                alignment: Alignment.center,
                child: Container(
                  width: 67,
                  height: 67,
                  alignment: Alignment.center,
                  decoration:  BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.liftBig.primary,
                  ),
                  child:  Text(
                    'LIFT',
                    style: TextStyle(
                      color: context.liftBig.foreground,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.4,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
