import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dart:convert';

import 'package:file_picker/file_picker.dart';

import '../companion/companion_bridge.dart';
import '../journal/app_settings.dart';
import '../journal/body_weight_settings.dart';
import '../journal/logged_day.dart';
import '../pro/pro_status.dart';
import '../reminder/daily_lift_reminder.dart';
import '../reminder/daily_lift_notifications.dart';
import '../sync/sync_controller.dart';
import '../theme.dart';
import '../utils/barbell_compound.dart';
import '../utils/distance_units.dart';
import '../utils/weight_units.dart';
import 'basic_calculator_page.dart';
import 'import_sheet.dart';
import 'keyboard_dismiss.dart';
import 'lift_name_convergence_section.dart';
import 'liftbig_sheet.dart';
import 'one_rep_max_calculator_page.dart';
import 'plate_calculator_page.dart';
import 'rest_timer_scope.dart';
import 'theme_backdrop.dart';
import 'tool_icons.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.sync,
    required this.dailyReminder,
    required this.themes,
  });

  final SyncController sync;
  final DailyLiftReminderScheduler dailyReminder;
  final LiftBigThemeController themes;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _authError;
  var _autoFill = true;
  var _autoAdvanceWeightToReps = true;
  var _timerOnDone = false;
  var _saveRepsMarksDone = false;
  var _logDifficulty = false;
  var _prescribeWarmup = false;
  var _showPlateGraphic = true;
  var _proActive = false;
  late final ProStatus _proStatus;
  final _heightFeet = TextEditingController();
  final _heightInches = TextEditingController();
  final _heightCm = TextEditingController();
  double? _heightStored;
  var _weightUnit = WeightUnit.lb;
  var _distanceUnit = DistanceUnit.mi;
  final _bodyWeight = TextEditingController();
  final _averageRest = TextEditingController(
    text: '$defaultAverageRestSeconds',
  );
  final _averageLift = TextEditingController(
    text: '$defaultAverageLiftSeconds',
  );
  var _restAlerts = RestTimerAlertSettings.defaults;
  var _watches = WatchCompanionSettings.defaults;
  var _appleHealth = false;
  String? _healthNote;
  var _loadingPrefs = true;
  DailyLiftReminderSettings _reminder = DailyLiftReminderSettings.defaults();
  final _reminderMessage = TextEditingController();
  var _loadingReminder = true;
  late final BodyWeightSettingsService _bodyWeightService;

  static const _weekdayLabels = {
    DateTime.monday: 'Mon',
    DateTime.tuesday: 'Tue',
    DateTime.wednesday: 'Wed',
    DateTime.thursday: 'Thu',
    DateTime.friday: 'Fri',
    DateTime.saturday: 'Sat',
    DateTime.sunday: 'Sun',
  };

  @override
  void initState() {
    super.initState();
    _bodyWeightService = BodyWeightSettingsService(
      journal: widget.sync.journal,
    );
    _proStatus = ProStatus(
      unlockStore: JournalTesterUnlockStore(widget.sync.journal),
    );
    _loadLogging();
    _loadPrefs();
    _loadReminder();
    _loadPro();
  }

  Future<void> _loadPrefs() async {
    final journal = widget.sync.journal;
    final weightUnit = await journal.storedWeightUnit();
    final distanceUnit = await journal.storedDistanceUnit();
    final rest = await journal.storedAverageRestSeconds();
    final lift = await journal.storedAverageLiftSeconds();
    final alerts = await journal.loadRestTimerAlertSettings();
    final watches = await journal.loadWatchCompanionSettings();
    final appleHealth = await journal.appleHealthSyncEnabled();
    var bodyLbs = await _bodyWeightService.importFromHealthIfEmpty();
    bodyLbs ??= await journal.storedBodyWeightLbs();
    var height = await _bodyWeightService.importHeightIfEmpty();
    height ??= await journal.storedHeightInches();
    if (!mounted) return;
    _applyHeightFields(height, weightUnit);
    _bodyWeight.text = bodyLbs == null
        ? ''
        : lbsToDisplayWeightString(bodyLbs, weightUnit);
    setState(() {
      _weightUnit = weightUnit;
      _distanceUnit = distanceUnit;
      _averageRest.text = '$rest';
      _averageLift.text = '$lift';
      _restAlerts = alerts;
      _watches = watches;
      _appleHealth = appleHealth;
      _heightStored = height;
      _loadingPrefs = false;
    });
  }

  void _applyHeightFields(double? inches, WeightUnit unit) {
    _heightStored = inches;
    if (inches == null) {
      _heightFeet.text = '';
      _heightInches.text = '';
      _heightCm.text = '';
      return;
    }
    if (unit == WeightUnit.kg) {
      _heightCm.text = formatRoundedNumber(inches * 2.54, 1);
      return;
    }
    final feet = inches ~/ 12;
    final inchPart = inches - feet * 12;
    _heightFeet.text = '$feet';
    _heightInches.text = formatRoundedNumber(inchPart, 1);
  }

  Future<void> _loadLogging() async {
    final journal = widget.sync.journal;
    final autoFill = await journal.autoFillSetsEnabled();
    final autoAdvance = await journal.autoAdvanceWeightToRepsEnabled();
    final timerOnDone = await journal.startTimerOnDone();
    final saveRepsMarksDone = await journal.saveRepsMarksSetDoneEnabled();
    final logDifficulty = await journal.logSetDifficultyEnabled();
    final prescribeWarmup = await journal.prescribeWarmupEnabled();
    final showPlateGraphic = await journal.showPlateGraphicEnabled();
    if (!mounted) return;
    setState(() {
      _autoFill = autoFill;
      _autoAdvanceWeightToReps = autoAdvance;
      _timerOnDone = timerOnDone;
      _saveRepsMarksDone = saveRepsMarksDone;
      _logDifficulty = logDifficulty;
      _prescribeWarmup = prescribeWarmup;
      _showPlateGraphic = showPlateGraphic;
    });
  }

  Future<void> _loadPro() async {
    final active = await _proStatus.refresh();
    if (!mounted) return;
    widget.themes.setProActive(active);
    setState(() => _proActive = active);
  }

  Future<void> _restorePro() async {
    final code = await _askRestoreCode();
    if (code == null || !mounted) return;
    final result = await _proStatus.restorePurchases(code);
    if (!mounted) return;
    widget.themes.setProActive(result.isPro);
    setState(() => _proActive = result.isPro);
    final message = result.codeMatched
        ? 'Pro is unlocked on this device.'
        : result.storeActive
        ? 'Purchases restored.'
        : 'No active subscription found.';
    showLiftBigNotice(context, message);
  }

  Future<String?> _askRestoreCode() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          scrollable: true,
          title: const Text('Restore Purchases'),
          content: TextField(
            controller: controller,
            autofocus: true,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(labelText: 'Code'),
            onSubmitted: (value) => Navigator.pop(context, value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Restore Purchases'),
            ),
          ],
        );
      },
    ).whenComplete(controller.dispose);
  }

  Future<void> _loadReminder() async {
    final settings = await widget.sync.journal.loadDailyLiftReminderSettings();
    if (!mounted) return;
    _reminderMessage.text = settings.customMessage ?? '';
    setState(() {
      _reminder = settings;
      _loadingReminder = false;
    });
  }

  Future<void> _persistReminder(DailyLiftReminderSettings next) async {
    setState(() => _reminder = next);
    await widget.sync.journal.saveDailyLiftReminderSettings(next);
    await widget.dailyReminder.applySettings(next);
  }

  Future<void> _setReminderEnabled(bool enabled) async {
    if (enabled) {
      final granted = await widget.dailyReminder.requestPermissionIfNeeded();
      if (!granted) {
        if (!mounted) return;
        showLiftBigNotice(
          context,
          'Notification permission is required for reminders.',
        );
        return;
      }
    }
    var next = _reminder.copyWith(enabled: enabled);
    if (enabled && sanitizeReminderWeekdays(next.weekdays).isEmpty) {
      next = next.copyWith(weekdays: DailyLiftReminderSettings.allWeekdays);
    }
    await _persistReminder(next);
  }

  Future<void> _pickReminderTime() async {
    final parsed = parseReminderTimeHHmm(_reminder.timeHHmm);
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: parsed.hour, minute: parsed.minute),
    );
    if (picked == null || !mounted) return;
    final next = _reminder.copyWith(
      timeHHmm: formatReminderTimeHHmm(picked.hour, picked.minute),
    );
    await _persistReminder(next);
  }

  Future<void> _toggleWeekday(int weekday, bool selected) async {
    final days = {..._reminder.weekdays};
    if (selected) {
      days.add(weekday);
    } else {
      days.remove(weekday);
    }
    final sanitized = sanitizeReminderWeekdays(days.toList());
    if (_reminder.enabled && sanitized.isEmpty) return;
    await _persistReminder(_reminder.copyWith(weekdays: sanitized));
  }

  Future<void> _saveReminderMessage() async {
    final text = _reminderMessage.text;
    await _persistReminder(
      _reminder.copyWith(
        customMessage: text.trim().isEmpty ? null : text,
        clearCustomMessage: text.trim().isEmpty,
      ),
    );
  }

  Future<void> _setAutoFill(bool value) async {
    setState(() => _autoFill = value);
    await widget.sync.journal.setAutoFillSetsEnabled(value);
  }

  Future<void> _setAutoAdvanceWeightToReps(bool value) async {
    setState(() => _autoAdvanceWeightToReps = value);
    await widget.sync.journal.setAutoAdvanceWeightToRepsEnabled(value);
  }

  Future<void> _setTimerOnDone(bool value) async {
    setState(() => _timerOnDone = value);
    await widget.sync.journal.setStartTimerOnDone(value);
  }

  Future<void> _setSaveRepsMarksDone(bool value) async {
    setState(() => _saveRepsMarksDone = value);
    await widget.sync.journal.setSaveRepsMarksSetDone(value);
  }

  Future<void> _setLogDifficulty(bool value) async {
    setState(() => _logDifficulty = value);
    await widget.sync.journal.setLogSetDifficultyEnabled(value);
  }

  Future<void> _setPrescribeWarmup(bool value) async {
    setState(() => _prescribeWarmup = value);
    await widget.sync.journal.setPrescribeWarmupEnabled(value);
  }

  Future<void> _setShowPlateGraphic(bool value) async {
    setState(() => _showPlateGraphic = value);
    await widget.sync.journal.setShowPlateGraphicEnabled(value);
  }

  Future<void> _setWeightUnit(WeightUnit unit) async {
    setState(() => _weightUnit = unit);
    await widget.sync.journal.setWeightUnit(unit);
    final lbs = await widget.sync.journal.storedBodyWeightLbs();
    if (lbs != null && mounted) {
      _bodyWeight.text = lbsToDisplayWeightString(lbs, unit);
    }
    if (mounted) _applyHeightFields(_heightStored, unit);
  }

  Future<void> _saveHeight() async {
    final double? inches;
    if (_weightUnit == WeightUnit.kg) {
      final cm = double.tryParse(_heightCm.text.trim().replaceAll(',', '.'));
      inches = cm == null ? null : cm / 2.54;
    } else {
      final feet = double.tryParse(_heightFeet.text.trim()) ?? 0;
      final inch =
          double.tryParse(_heightInches.text.trim().replaceAll(',', '.')) ?? 0;
      final total = feet * 12 + inch;
      inches = total <= 0 ? null : total;
    }
    final wrote = await _bodyWeightService.saveHeightInches(
      inches,
      tryHealthWrite: _appleHealth,
    );
    final stored = await widget.sync.journal.storedHeightInches();
    if (!mounted) return;
    _applyHeightFields(stored, _weightUnit);
    if (wrote == false) {
      setState(() {
        _healthNote = 'Saved on this device. Apple Health needs permission to sync height.';
      });
    }
  }

  Future<void> _setDistanceUnit(DistanceUnit unit) async {
    setState(() => _distanceUnit = unit);
    await widget.sync.journal.setDistanceUnit(unit);
  }

  Future<void> _saveBodyWeight() async {
    final raw = _bodyWeight.text.trim();
    final lbs = raw.isEmpty ? null : displayWeightToLbs(raw, _weightUnit);
    final result = await _bodyWeightService.saveBodyWeightLbs(
      lbs,
      tryHealthWrite: _appleHealth,
    );
    if (!mounted) return;
    if (result.healthWriteSucceeded == false) {
      setState(() {
        _healthNote = 'Saved on this device. Apple Health needs permission to sync body weight.';
      });
    } else {
      setState(() => _healthNote = null);
    }
  }

  Future<void> _selectTheme(String id) async {
    final palette = liftBigPaletteById(id);
    if (palette.proOnly && !_proActive) {
      if (!mounted) return;
      showLiftBigNotice(context, 'LiftBig Pro unlocks this theme.');
      return;
    }
    widget.themes.select(id);
    liftBigSelectionHaptic();
    await widget.sync.journal.setColorThemeId(widget.themes.palette.id);
  }

  Future<void> _saveAverageRest() async {
    final parsed = int.tryParse(_averageRest.text.trim());
    if (parsed == null) return;
    final clamped = clampAverageRestSeconds(parsed);
    _averageRest.text = '$clamped';
    await widget.sync.journal.setAverageRestSeconds(clamped);
  }

  Future<void> _saveAverageLift() async {
    final parsed = int.tryParse(_averageLift.text.trim());
    if (parsed == null) return;
    final clamped = clampAverageRestSeconds(parsed);
    _averageLift.text = '$clamped';
    await widget.sync.journal.setAverageLiftSeconds(clamped);
  }

  Future<void> _setRestAlert({
    bool? sound,
    bool? vibration,
    bool? notification,
    bool? ringUntilStopped,
    String? soundId,
  }) async {
    final next = _restAlerts.copyWith(
      soundEnabled: sound,
      vibrationEnabled: vibration,
      notificationEnabled: notification,
      ringUntilStopped: ringUntilStopped,
      soundId: soundId,
    );
    setState(() => _restAlerts = next);
    await widget.sync.journal.saveRestTimerAlertSettings(next);
    if (!mounted) return;
    try {
      RestTimerScope.of(context).reloadAlertSettings();
    } catch (_) {}
  }

  String _alarmToneLabel(String id) {
    return switch (RestTimerAlertSettings.canonicalSoundId(id)) {
      'bell' => 'Bell',
      'chime' => 'Chime',
      'horn' => 'Horn',
      _ => 'Beep',
    };
  }

  Future<void> _pickAlarmTone() async {
    final picked = await showLiftBigSheet<String>(
      context,
      builder: (context) {
        return ListView(
          shrinkWrap: true,
          children: [
            for (final id in RestTimerAlertSettings.soundIds)
              ListTile(
                title: Text(_alarmToneLabel(id)),
                trailing: id == _restAlerts.soundId
                    ? Icon(Icons.check, color: context.liftBig.primary)
                    : null,
                onTap: () => Navigator.of(context).pop(id),
              ),
          ],
        );
      },
    );
    if (picked == null || picked == _restAlerts.soundId) return;
    await _setRestAlert(soundId: picked);
  }

  Future<void> _setAppleHealth(bool enabled) async {
    if (enabled) {
      final granted = await _bodyWeightService.setAppleHealthEnabled(true);
      if (!granted && mounted) {
        setState(() {
          _appleHealth = true;
          _healthNote = 'Turned on. Grant Apple Health access when prompted to sync weight, height, and workouts.';
        });
        return;
      }
      final lbs = await widget.sync.journal.storedBodyWeightLbs();
      if (lbs != null) {
        await _bodyWeightService.saveBodyWeightLbs(lbs, tryHealthWrite: true);
      }
      final height = await widget.sync.journal.storedHeightInches();
      if (height != null) {
        await _bodyWeightService.saveHeightInches(height, tryHealthWrite: true);
      }
    } else {
      await _bodyWeightService.setAppleHealthEnabled(false);
    }
    if (!mounted) return;
    setState(() => _appleHealth = enabled);
  }

  Future<void> _import() async {
    final message = await showImportSheet(context, widget.sync.journal);
    if (message == null || !mounted) return;
    showLiftBigNotice(context, message);
  }

  Future<void> _export() async {
    try {
      final json = await widget.sync.journal.exportBackupJson();
      final saved = await FilePicker.saveFile(
        dialogTitle: 'Export LiftBig Backup',
        fileName: 'liftbig-backup.json',
        mimeType: 'application/json',
        bytes: Uint8List.fromList(utf8.encode(json)),
      );
      if (!mounted) return;
      if (saved == null) return;
      showLiftBigNotice(context, 'Backup exported. Import can read this file.');
    } catch (error) {
      if (!mounted) return;
      showLiftBigNotice(context, 'Could not export the backup. $error');
    }
  }

  Widget _themeStrip({
    required List<LiftBigPalette> palettes,
    required String selectedId,
  }) {
    return SizedBox(
      height: 136,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        primary: false,
        padding: const EdgeInsets.only(top: 4, bottom: 2),
        itemCount: palettes.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final palette = palettes[index];
          return _ThemePreviewCard(
            palette: palette,
            selected: palette.id == selectedId,
            locked: palette.proOnly && !_proActive,
            onTap: () => _selectTheme(palette.id),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _reminderMessage.dispose();
    _bodyWeight.dispose();
    _heightFeet.dispose();
    _heightInches.dispose();
    _heightCm.dispose();
    _averageRest.dispose();
    _averageLift.dispose();
    super.dispose();
  }

  Future<void> _auth(bool createAccount) async {
    final error = await widget.sync.signIn(
      emailAddress: _email.text,
      password: _password.text,
      createAccount: createAccount,
    );
    if (!mounted) return;
    setState(() => _authError = error);
  }

  Future<void> _setWatch(WatchCompanionSettings next) async {
    setState(() => _watches = next);
    await widget.sync.journal.saveWatchCompanionSettings(next);
    CompanionBridge.shared.setWatchCompanions(next);
    await CompanionBridge.shared.republishSession();
  }

  List<Widget> _toolSection(SyncController sync) {
    return [
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Plate45Icon(),
        title: const Text('Plate Calculator'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => PlateCalculatorPage(journal: sync.journal),
            ),
          );
        },
      ),
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const ForegroundIcon(Icons.fitness_center),
        title: const Text('One Rep Max'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => OneRepMaxCalculatorPage(journal: sync.journal),
            ),
          );
        },
      ),
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const ForegroundIcon(Icons.calculate_outlined),
        title: const Text('Calculator'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const BasicCalculatorPage(),
            ),
          );
        },
      ),
    ];
  }

  List<Widget> _sectionHeading(String title, {bool first = false}) {
    return [
      if (!first) ...[
        const SizedBox(height: 24),
        Divider(height: 1, thickness: 1, color: context.liftBig.border),
        const SizedBox(height: 24),
      ],
      Text(
        title,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 8),
    ];
  }

  List<Widget> _proSection() {
    return [
      ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(_proActive ? 'Pro · Active' : 'Pro'),
        subtitle: _proActive
            ? Text(
                'Watch sync is active.',
                style: TextStyle(color: context.liftBig.muted),
              )
            : null,
        trailing: TextButton(
          onPressed: _restorePro,
          child: const Text('Restore Purchases'),
        ),
      ),
    ];
  }

  List<Widget> _watchSection() {
    if (!_proActive) return const [];
    return [
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Apple'),
        value: _watches.apple,
        activeThumbColor: context.liftBig.primary,
        onChanged: (value) => _setWatch(_watches.copyWith(apple: value)),
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Garmin'),
        value: _watches.garmin,
        activeThumbColor: context.liftBig.primary,
        onChanged: (value) => _setWatch(_watches.copyWith(garmin: value)),
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Samsung'),
        subtitle: Text(
          'To be added in future update.',
          style: TextStyle(color: context.liftBig.muted),
        ),
        value: _watches.samsung,
        activeThumbColor: context.liftBig.primary,
        onChanged: (value) => _setWatch(_watches.copyWith(samsung: value)),
      ),
    ];
  }

  List<Widget> _cloudSection(SyncController sync) {
    return [
      Text(
        'The journal is stored on this phone. Sync stays off until you sign in and turn this switch on.',
        style: TextStyle(color: context.liftBig.muted),
      ),
      const SizedBox(height: 8),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Sync This Journal'),
        subtitle: Text(
          sync.syncEnabled
              ? 'On. Still uploads nothing until you are signed in.'
              : 'Off by default.',
          style: TextStyle(color: context.liftBig.muted),
        ),
        value: sync.syncEnabled,
        activeThumbColor: context.liftBig.primary,
        onChanged: sync.busy ? null : sync.setEnabled,
      ),
      if (sync.status != null) ...[
        const SizedBox(height: 8),
        Text(sync.status!, style: TextStyle(color: context.liftBig.foreground)),
      ],
      const SizedBox(height: 24),
      if (!sync.firebaseReady) const _FirebaseSetupCard(),
      if (sync.firebaseReady && !sync.signedIn) ...[
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          decoration: const InputDecoration(labelText: 'Email'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _password,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Password'),
        ),
        if (_authError != null) ...[
          const SizedBox(height: 8),
          Text(_authError!, style: TextStyle(color: context.liftBig.primary)),
        ],
        const SizedBox(height: 12),
        FilledButton(
          onPressed: sync.busy ? null : () => _auth(false),
          child: const Text('Sign In'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: sync.busy ? null : () => _auth(true),
          child: const Text('Create Account'),
        ),
      ],
      if (sync.signedIn) ...[
        Text('Signed in as ${sync.email}.'),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: sync.busy || !sync.syncEnabled ? null : sync.syncNow,
          child: Text(sync.busy ? 'Syncing…' : 'Sync Now'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: sync.busy ? null : sync.signOut,
          child: const Text('Sign Out'),
        ),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.liftBig;
    final patterned = colors.backdrop != LiftBigBackdrop.none;
    return LiftBigRouteUnderlay(
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          title: const Text('Settings'),
          backgroundColor: colors.background,
          surfaceTintColor: Colors.transparent,
          forceMaterialTransparency: patterned,
        ),
        body: KeyboardDismiss(
          child: ListenableBuilder(
            listenable: widget.sync,
            builder: (context, _) {
              final sync = widget.sync;
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  ..._sectionHeading('Tools', first: true),
                  ..._toolSection(sync),
                  ..._sectionHeading('Pro'),
                  ..._proSection(),
                  if (_proActive) ...[
                    ..._sectionHeading('Smart Watch'),
                    ..._watchSection(),
                  ],
                  ..._sectionHeading('Logging'),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Strength Prediction'),
                    subtitle: Text(
                      'Use data from old lifts to predict new lifts.',
                      style: TextStyle(color: context.liftBig.muted),
                    ),
                    value: _autoFill,
                    activeThumbColor: context.liftBig.primary,
                    onChanged: _setAutoFill,
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Open Reps After Saving Weight'),
                    subtitle: Text(
                      'Saving a weight opens reps input when that set has none yet.',
                      style: TextStyle(color: context.liftBig.muted),
                    ),
                    value: _autoAdvanceWeightToReps,
                    activeThumbColor: context.liftBig.primary,
                    onChanged: _setAutoAdvanceWeightToReps,
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Done Button Starts Timer'),
                    subtitle: Text(
                      'The rest button on the exercise still starts the timer.',
                      style: TextStyle(color: context.liftBig.muted),
                    ),
                    value: _timerOnDone,
                    activeThumbColor: context.liftBig.primary,
                    onChanged: _setTimerOnDone,
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Saving Reps Marks the Set Done'),
                    subtitle: Text(
                      'Saving a rep count checks the set off. An empty save does not.',
                      style: TextStyle(color: context.liftBig.muted),
                    ),
                    value: _saveRepsMarksDone,
                    activeThumbColor: context.liftBig.primary,
                    onChanged: _setSaveRepsMarksDone,
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Include Warm Ups on Heavy Compounds'),
                    subtitle: Text(
                      'Squat, bench, deadlift, overhead press, barbell row, Pendlay row, power clean, clean and jerk, and snatch.',
                      style: TextStyle(color: context.liftBig.muted),
                    ),
                    value: _prescribeWarmup,
                    activeThumbColor: context.liftBig.primary,
                    onChanged: _setPrescribeWarmup,
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Plate Graphic'),
                    subtitle: Text(
                      plateGraphicExamplesLabel,
                      style: TextStyle(color: context.liftBig.muted),
                    ),
                    value: _showPlateGraphic,
                    activeThumbColor: context.liftBig.primary,
                    onChanged: _setShowPlateGraphic,
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Rate Set Difficulty'),
                    subtitle: Text(
                      'Set difficulty can be tracked with easy, moderate, or difficult, which factors into your strength predictions. Unrated sets carry default weight.',
                      style: TextStyle(color: context.liftBig.muted),
                    ),
                    value: _logDifficulty,
                    activeThumbColor: context.liftBig.primary,
                    onChanged: _setLogDifficulty,
                  ),
                  ..._sectionHeading('Themes'),
                  ListenableBuilder(
                    listenable: widget.themes,
                    builder: (context, _) {
                      final selectedId = widget.themes.palette.id;
                      final free = [
                        for (final palette in liftBigThemePresets)
                          if (!palette.proOnly) palette,
                      ];
                      final pro = [
                        for (final palette in liftBigThemePresets)
                          if (palette.proOnly) palette,
                      ];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _themeStrip(palettes: free, selectedId: selectedId),
                          ..._sectionHeading('LiftBig Pro'),
                          if (!_proActive)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                'LiftBig Pro unlocks these themes.',
                                style: TextStyle(color: context.liftBig.muted),
                              ),
                            ),
                          _themeStrip(palettes: pro, selectedId: selectedId),
                        ],
                      );
                    },
                  ),
                  ..._sectionHeading('Units'),
                  if (_loadingPrefs)
                    const LinearProgressIndicator()
                  else ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: SegmentedButton<WeightUnit>(
                            segments: const [
                              ButtonSegment(
                                value: WeightUnit.lb,
                                label: Text('lb'),
                              ),
                              ButtonSegment(
                                value: WeightUnit.kg,
                                label: Text('kg'),
                              ),
                            ],
                            selected: {_weightUnit},
                            onSelectionChanged: (value) {
                              liftBigSelectionHaptic();
                              _setWeightUnit(value.first);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SegmentedButton<DistanceUnit>(
                            segments: const [
                              ButtonSegment(
                                value: DistanceUnit.mi,
                                label: Text('mi'),
                              ),
                              ButtonSegment(
                                value: DistanceUnit.km,
                                label: Text('km'),
                              ),
                            ],
                            selected: {_distanceUnit},
                            onSelectionChanged: (value) {
                              liftBigSelectionHaptic();
                              _setDistanceUnit(value.first);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                  ..._sectionHeading('Your Stats'),
                  if (_weightUnit == WeightUnit.lb)
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _heightFeet,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Height (ft)',
                            ),
                            onSubmitted: (_) => _saveHeight(),
                            onEditingComplete: _saveHeight,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _heightInches,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Height (in)',
                            ),
                            onSubmitted: (_) => _saveHeight(),
                            onEditingComplete: _saveHeight,
                          ),
                        ),
                      ],
                    )
                  else
                    TextField(
                      controller: _heightCm,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Height (cm)',
                      ),
                      onSubmitted: (_) => _saveHeight(),
                      onEditingComplete: _saveHeight,
                    ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _bodyWeight,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    decoration: InputDecoration(
                      labelText:
                          'Body Weight (${_weightUnit == WeightUnit.lb ? 'lb' : 'kg'})',
                      hintText: 'Optional',
                      helperText: 'Default = 180',
                    ),
                    onSubmitted: (_) => _saveBodyWeight(),
                    onEditingComplete: _saveBodyWeight,
                  ),
                  ..._sectionHeading('Timer and Reminders'),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Alarm Sound'),
                    value: _restAlerts.soundEnabled,
                    activeThumbColor: context.liftBig.primary,
                    onChanged: (value) => _setRestAlert(sound: value),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Vibration'),
                    value: _restAlerts.vibrationEnabled,
                    activeThumbColor: context.liftBig.primary,
                    onChanged: (value) => _setRestAlert(vibration: value),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Lock-Screen Notification'),
                    value: _restAlerts.notificationEnabled,
                    activeThumbColor: context.liftBig.primary,
                    onChanged: (value) => _setRestAlert(notification: value),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Ring Until Stopped'),
                    subtitle: Text(
                      'The in-app tone repeats until you stop it from the timer. The lock-screen notification still plays once.',
                      style: TextStyle(color: context.liftBig.muted),
                    ),
                    value: _restAlerts.ringUntilStopped,
                    activeThumbColor: context.liftBig.primary,
                    onChanged: (value) =>
                        _setRestAlert(ringUntilStopped: value),
                  ),
                  if (_proActive)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Alarm Tone'),
                      subtitle: Text(
                        _alarmToneLabel(_restAlerts.soundId),
                        style: TextStyle(color: context.liftBig.muted),
                      ),
                      trailing: Icon(
                        Icons.expand_more,
                        color: context.liftBig.primary,
                      ),
                      onTap: _pickAlarmTone,
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _averageRest,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Average Rest (sec)',
                            helperText: '5–600',
                          ),
                          onSubmitted: (_) => _saveAverageRest(),
                          onEditingComplete: _saveAverageRest,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _averageLift,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Average Lift (sec)',
                            helperText: '5–600',
                          ),
                          onSubmitted: (_) => _saveAverageLift(),
                          onEditingComplete: _saveAverageLift,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_loadingReminder)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: LinearProgressIndicator(),
                    )
                  else ...[
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Enable Daily Reminder'),
                      subtitle: _reminder.enabled
                          ? Text(
                              'Scheduled for ${_reminder.timeHHmm}.',
                              style: TextStyle(color: context.liftBig.muted),
                            )
                          : null,
                      value: _reminder.enabled,
                      activeThumbColor: context.liftBig.primary,
                      onChanged: _setReminderEnabled,
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      enabled: _reminder.enabled,
                      title: const Text('Reminder Time'),
                      subtitle: Text(_reminder.timeHHmm),
                      trailing: const Icon(Icons.schedule),
                      onTap: _reminder.enabled ? _pickReminderTime : null,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 4),
                      child: Text(
                        'Days',
                        style: TextStyle(
                          color: _reminder.enabled
                              ? context.liftBig.foreground
                              : context.liftBig.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final day in DailyLiftReminderSettings.allWeekdays)
                          FilterChip(
                            label: Text(_weekdayLabels[day]!),
                            selected: _reminder.weekdays.contains(day),
                            onSelected: _reminder.enabled
                                ? (value) => _toggleWeekday(day, value)
                                : null,
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _reminderMessage,
                      enabled: _reminder.enabled,
                      decoration: InputDecoration(
                        labelText: 'Notification Message',
                        hintText: dailyLiftReminderDefaultBody,
                        helperText: 'Leave blank to use the default sentence.',
                      ),
                      onSubmitted: (_) => _saveReminderMessage(),
                      onEditingComplete: _saveReminderMessage,
                    ),
                  ],
                  ..._sectionHeading('Apple Health Sync'),
                  Text(
                    'Reads and writes body weight, height, and workouts. Calories are Apple’s active energy for the workout window.',
                    style: TextStyle(color: context.liftBig.muted),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Sync with Apple Health'),
                    value: _appleHealth,
                    activeThumbColor: context.liftBig.primary,
                    onChanged: _setAppleHealth,
                  ),
                  if (_healthNote != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _healthNote!,
                      style: TextStyle(
                        color: context.liftBig.muted,
                        height: 1.35,
                      ),
                    ),
                  ],
                  ..._sectionHeading('Lift Name Overlap'),
                  LiftNameConvergenceSection(journal: sync.journal),
                  ..._sectionHeading('Backup'),
                  Text(
                    'JSON import is the legacy path for an existing LiftBig backup.',
                    style: TextStyle(color: context.liftBig.muted),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: _import,
                    child: const Text('Import Backup'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: _export,
                    child: const Text('Export Backup'),
                  ),
                  ..._sectionHeading('Cloud Sync'),
                  ..._cloudSection(sync),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _FirebaseSetupCard extends StatelessWidget {
  const _FirebaseSetupCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.liftBig.cardInner,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.liftBig.border),
      ),
      child: const Text(
        'Firebase is not configured, so sign-in and sync do nothing.\n\n'
        'Drop in:\n'
        '• android/app/google-services.json\n'
        '• ios/Runner/GoogleService-Info.plist\n'
        'Then run flutterfire configure, which overwrites lib/firebase_options.dart, '
        'and set kFirebaseEnabled = true in lib/sync/firebase_enabled.dart.\n\n'
        'Deploy firestore.rules so a user can only read and write their own documents. '
        'Enable Email/Password in the Firebase Auth console.',
        style: TextStyle(height: 1.4),
      ),
    );
  }
}

class _ThemePreviewCard extends StatelessWidget {
  const _ThemePreviewCard({
    required this.palette,
    required this.selected,
    required this.locked,
    required this.onTap,
  });

  final LiftBigPalette palette;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.liftBig;
    final label = locked
        ? '${palette.label}. LiftBig Pro unlocks this theme.'
        : palette.label;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: SizedBox(
        width: 112,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected ? colors.primary : colors.border,
                      width: selected ? 2.5 : 1,
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(selected ? 1.5 : 3),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(13),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          LiftBigThemePreview(palette: palette),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Container(
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: palette.primary,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: palette.card,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: palette.border),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (selected)
                            Positioned(
                              top: 6,
                              left: 6,
                              child: Icon(
                                Icons.check_circle,
                                size: 16,
                                color: colors.primary,
                              ),
                            ),
                          if (locked)
                            Positioned(
                              top: 6,
                              right: 6,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: palette.card,
                                  shape: BoxShape.circle,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(2),
                                  child: Icon(
                                    Icons.lock_outline,
                                    size: 14,
                                    color: palette.foreground,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                palette.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.15,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: locked ? colors.muted : colors.foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
