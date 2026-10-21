import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../journal/app_settings.dart';
import '../journal/body_weight_settings.dart';
import '../journal/logged_day.dart';
import '../journal/strength_standards.dart';
import '../pro/pro_status.dart';
import '../reminder/daily_lift_reminder.dart';
import '../reminder/daily_lift_notifications.dart';
import '../sync/sync_controller.dart';
import '../theme.dart';
import '../utils/distance_units.dart';
import '../utils/weight_units.dart';
import 'rest_timer_scope.dart';
import 'basic_calculator_page.dart';
import 'import_sheet.dart';
import 'lift_name_convergence_section.dart';
import 'one_rep_max_calculator_page.dart';
import 'plate_calculator_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.sync,
    required this.dailyReminder,
  });

  final SyncController sync;
  final DailyLiftReminderScheduler dailyReminder;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _authError;
  var _autoFill = true;
  var _timerOnDone = false;
  var _logDifficulty = false;
  var _prescribeWarmup = false;
  var _proActive = false;
  late final ProStatus _proStatus;
  final _heightFeet = TextEditingController();
  final _heightInches = TextEditingController();
  final _heightCm = TextEditingController();
  double? _heightStored;
  var _weightUnit = WeightUnit.lb;
  var _distanceUnit = DistanceUnit.mi;
  final _bodyWeight = TextEditingController();
  final _averageRest = TextEditingController(text: '$defaultAverageRestSeconds');
  final _averageLift = TextEditingController(text: '$defaultAverageLiftSeconds');
  var _restAlerts = RestTimerAlertSettings.defaults;
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
    final timerOnDone = await journal.startTimerOnDone();
    final logDifficulty = await journal.logSetDifficultyEnabled();
    final prescribeWarmup = await journal.prescribeWarmupEnabled();
    if (!mounted) return;
    setState(() {
      _autoFill = autoFill;
      _timerOnDone = timerOnDone;
      _logDifficulty = logDifficulty;
      _prescribeWarmup = prescribeWarmup;
    });
  }

  Future<void> _loadPro() async {
    final active = await _proStatus.refresh();
    if (!mounted) return;
    setState(() => _proActive = active);
  }

  Future<void> _restorePro() async {
    final code = await _askRestoreCode();
    if (code == null || !mounted) return;
    final result = await _proStatus.restorePurchases(code);
    if (!mounted) return;
    setState(() => _proActive = result.isPro);
    final message = result.codeMatched
        ? 'Pro is unlocked on this device.'
        : result.storeActive
        ? 'Purchases restored.'
        : 'No active subscription found.';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<String?> _askRestoreCode() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Restore Purchases'),
          content: TextField(
            controller: controller,
            autofocus: true,
            autocorrect: false,
            enableSuggestions: false,
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification permission is required for reminders.'),
          ),
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

  Future<void> _setTimerOnDone(bool value) async {
    setState(() => _timerOnDone = value);
    await widget.sync.journal.setStartTimerOnDone(value);
  }

  Future<void> _setLogDifficulty(bool value) async {
    setState(() => _logDifficulty = value);
    await widget.sync.journal.setLogSetDifficultyEnabled(value);
  }

  Future<void> _setPrescribeWarmup(bool value) async {
    setState(() => _prescribeWarmup = value);
    await widget.sync.journal.setPrescribeWarmupEnabled(value);
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
      final inch = double.tryParse(_heightInches.text.trim().replaceAll(',', '.')) ?? 0;
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
        _healthNote =
            'Saved on this device. Apple Health needs permission to sync height.';
      });
    }
  }

  Future<void> _setDistanceUnit(DistanceUnit unit) async {
    setState(() => _distanceUnit = unit);
    await widget.sync.journal.setDistanceUnit(unit);
  }

  Future<void> _saveBodyWeight() async {
    final raw = _bodyWeight.text.trim();
    final lbs = raw.isEmpty
        ? null
        : displayWeightToLbs(raw, _weightUnit);
    final result = await _bodyWeightService.saveBodyWeightLbs(
      lbs,
      tryHealthWrite: _appleHealth,
    );
    if (!mounted) return;
    if (result.healthWriteSucceeded == false) {
      setState(() {
        _healthNote =
            'Saved on this device. Apple Health needs permission to sync body weight.';
      });
    } else {
      setState(() => _healthNote = null);
    }
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
  }) async {
    final next = _restAlerts.copyWith(
      soundEnabled: sound,
      vibrationEnabled: vibration,
      notificationEnabled: notification,
    );
    setState(() => _restAlerts = next);
    await widget.sync.journal.saveRestTimerAlertSettings(next);
    if (!mounted) return;
    try {
      await RestTimerScope.of(context).reloadAlertSettings();
    } catch (_) {}
  }

  Future<void> _setAppleHealth(bool enabled) async {
    if (enabled) {
      final granted = await _bodyWeightService.setAppleHealthEnabled(true);
      if (!granted && mounted) {
        setState(() {
          _appleHealth = true;
          _healthNote =
              'Turned on. Grant Apple Health access when prompted to sync weight, height, and workouts.';
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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

  List<Widget> _toolSection(SyncController sync) {
    return [
      const Text(
        'Tools',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 4),
      const Text(
        'Calculators from the LiftBig web app.',
        style: TextStyle(color: LiftBigColors.muted),
      ),
      ListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Plate calculator'),
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
        title: const Text('One rep max'),
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
      const SizedBox(height: 8),
      ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(_proActive ? 'Pro · Active' : 'Pro'),
        subtitle: Text(
          _proActive
              ? 'Watch companions are unlocked.'
              : 'Restore purchases. The journal stays available.',
          style: const TextStyle(color: LiftBigColors.muted),
        ),
        trailing: TextButton(
          onPressed: _restorePro,
          child: const Text('Restore Purchases'),
        ),
      ),
      const SizedBox(height: 24),
    ];
  }

  List<Widget> _cloudSection(SyncController sync) {
    return [
      const SizedBox(height: 24),
      const Text(
        'Cloud sync',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 8),
      const Text(
        'The journal is stored on this phone. Sync stays off until you sign in and turn this switch on.',
        style: TextStyle(color: LiftBigColors.muted),
      ),
      const SizedBox(height: 8),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Sync this journal'),
        subtitle: Text(
          sync.syncEnabled
              ? 'On. Still uploads nothing until you are signed in.'
              : 'Off by default.',
          style: const TextStyle(color: LiftBigColors.muted),
        ),
        value: sync.syncEnabled,
        activeThumbColor: LiftBigColors.primary,
        onChanged: sync.busy ? null : sync.setEnabled,
      ),
      if (sync.status != null) ...[
        const SizedBox(height: 8),
        Text(
          sync.status!,
          style: const TextStyle(color: LiftBigColors.foreground),
        ),
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
          Text(
            _authError!,
            style: const TextStyle(color: LiftBigColors.primary),
          ),
        ],
        const SizedBox(height: 12),
        FilledButton(
          onPressed: sync.busy ? null : () => _auth(false),
          child: const Text('Sign in'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: sync.busy ? null : () => _auth(true),
          child: const Text('Create account'),
        ),
      ],
      if (sync.signedIn) ...[
        Text('Signed in as ${sync.email}'),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: sync.busy || !sync.syncEnabled ? null : sync.syncNow,
          child: Text(sync.busy ? 'Syncing…' : 'Sync now'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: sync.busy ? null : sync.signOut,
          child: const Text('Sign out'),
        ),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListenableBuilder(
        listenable: widget.sync,
        builder: (context, _) {
          final sync = widget.sync;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              ..._toolSection(sync),
              const Text(
                'Logging',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Fill in predicted weight and reps'),
                subtitle: const Text(
                  'On by default. New sets start from your earlier work on that lift.',
                  style: TextStyle(color: LiftBigColors.muted),
                ),
                value: _autoFill,
                activeThumbColor: LiftBigColors.primary,
                onChanged: _setAutoFill,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Start the timer when Done is tapped'),
                subtitle: const Text(
                  'Off by default. The timer button next to Done still starts the rest.',
                  style: TextStyle(color: LiftBigColors.muted),
                ),
                value: _timerOnDone,
                activeThumbColor: LiftBigColors.primary,
                onChanged: _setTimerOnDone,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Add a warmup set on new barbell compounds'),
                subtitle: const Text(
                  'Off by default. New squats, benches, and deadlifts get one warmup set. Pull-ups and lat pulldowns do not. Days already logged stay as they are.',
                  style: TextStyle(color: LiftBigColors.muted),
                ),
                value: _prescribeWarmup,
                activeThumbColor: LiftBigColors.primary,
                onChanged: _setPrescribeWarmup,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Rate set difficulty'),
                subtitle: const Text(
                  'Off by default. When on, each set can be marked Easy, Moderate, or Difficult. Leave it unset if you skip it.',
                  style: TextStyle(color: LiftBigColors.muted),
                ),
                value: _logDifficulty,
                activeThumbColor: LiftBigColors.primary,
                onChanged: _setLogDifficulty,
              ),
              const SizedBox(height: 24),
              const Text(
                'Units',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              const Text(
                'Weights stay in pounds and distances in miles in your journal. These toggles change display and entry only.',
                style: TextStyle(color: LiftBigColors.muted),
              ),
              if (_loadingPrefs)
                const LinearProgressIndicator()
              else ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<WeightUnit>(
                        segments: const [
                          ButtonSegment(value: WeightUnit.lb, label: Text('lb')),
                          ButtonSegment(value: WeightUnit.kg, label: Text('kg')),
                        ],
                        selected: {_weightUnit},
                        onSelectionChanged: (value) =>
                            _setWeightUnit(value.first),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SegmentedButton<DistanceUnit>(
                        segments: const [
                          ButtonSegment(value: DistanceUnit.mi, label: Text('mi')),
                          ButtonSegment(value: DistanceUnit.km, label: Text('km')),
                        ],
                        selected: {_distanceUnit},
                        onSelectionChanged: (value) =>
                            _setDistanceUnit(value.first),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              const Text(
                'Body & timing',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              const Text(
                'Body weight powers strength estimates when you have no history. Time averages feed shuffle and rest defaults.',
                style: TextStyle(color: LiftBigColors.muted),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _bodyWeight,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                decoration: InputDecoration(
                  labelText: 'Body weight (${_weightUnit == WeightUnit.lb ? 'lb' : 'kg'})',
                  hintText: 'Optional',
                  helperText:
                      'Leave blank to use the labeled $defaultAssumedBodyWeightLabel default in predictions.',
                ),
                onSubmitted: (_) => _saveBodyWeight(),
                onEditingComplete: _saveBodyWeight,
              ),
              const SizedBox(height: 12),
              if (_weightUnit == WeightUnit.lb)
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _heightFeet,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Height (ft)'),
                        onSubmitted: (_) => _saveHeight(),
                        onEditingComplete: _saveHeight,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _heightInches,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Height (in)'),
                        onSubmitted: (_) => _saveHeight(),
                        onEditingComplete: _saveHeight,
                      ),
                    ),
                  ],
                )
              else
                TextField(
                  controller: _heightCm,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Height (cm)'),
                  onSubmitted: (_) => _saveHeight(),
                  onEditingComplete: _saveHeight,
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _averageRest,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Average rest (sec)',
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
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Average lift (sec)',
                        helperText: '5–600',
                      ),
                      onSubmitted: (_) => _saveAverageLift(),
                      onEditingComplete: _saveAverageLift,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'When rest finishes',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              const Text(
                'Choose sound, vibration, and/or the lock-screen notification.',
                style: TextStyle(color: LiftBigColors.muted),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Sound'),
                value: _restAlerts.soundEnabled,
                activeThumbColor: LiftBigColors.primary,
                onChanged: (value) => _setRestAlert(sound: value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Vibration'),
                value: _restAlerts.vibrationEnabled,
                activeThumbColor: LiftBigColors.primary,
                onChanged: (value) => _setRestAlert(vibration: value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Lock-screen notification'),
                value: _restAlerts.notificationEnabled,
                activeThumbColor: LiftBigColors.primary,
                onChanged: (value) => _setRestAlert(notification: value),
              ),
              const SizedBox(height: 24),
              const Text(
                'Apple Health',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              const Text(
                'Reads and writes body weight, height, and workouts. Calories are Apple’s active energy for the workout window, never a LiftBig estimate.',
                style: TextStyle(color: LiftBigColors.muted),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Sync with Apple Health'),
                value: _appleHealth,
                activeThumbColor: LiftBigColors.primary,
                onChanged: _setAppleHealth,
              ),
              if (_healthNote != null) ...[
                const SizedBox(height: 4),
                Text(
                  _healthNote!,
                  style: const TextStyle(color: LiftBigColors.muted, height: 1.35),
                ),
              ],
              const SizedBox(height: 24),
              const Text(
                'Daily lift reminder',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              const Text(
                'Local notification on the days and time you choose.',
                style: TextStyle(color: LiftBigColors.muted),
              ),
              if (_loadingReminder)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: LinearProgressIndicator(),
                )
              else ...[
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Enable daily reminder'),
                  subtitle: Text(
                    _reminder.enabled
                        ? 'Scheduled for ${_reminder.timeHHmm}'
                        : 'Off by default.',
                    style: const TextStyle(color: LiftBigColors.muted),
                  ),
                  value: _reminder.enabled,
                  activeThumbColor: LiftBigColors.primary,
                  onChanged: _setReminderEnabled,
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  enabled: _reminder.enabled,
                  title: const Text('Reminder time'),
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
                          ? LiftBigColors.foreground
                          : LiftBigColors.muted,
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
                    labelText: 'Notification message',
                    hintText: dailyLiftReminderDefaultBody,
                    helperText: 'Leave blank to use the default sentence.',
                  ),
                  onSubmitted: (_) => _saveReminderMessage(),
                  onEditingComplete: _saveReminderMessage,
                ),
              ],
              const SizedBox(height: 24),
              LiftNameConvergenceSection(journal: sync.journal),
              const SizedBox(height: 24),
              const Text(
                'Backup',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'JSON import is the legacy path for an existing LiftBig backup.',
                style: TextStyle(color: LiftBigColors.muted),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _import,
                child: const Text('Import backup'),
              ),
              ..._cloudSection(sync),
            ],
          );
        },
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
        color: LiftBigColors.cardInner,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LiftBigColors.border),
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
