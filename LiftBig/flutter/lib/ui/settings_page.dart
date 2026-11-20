import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../companion/companion_bridge.dart';
import '../journal/app_settings.dart';
import '../journal/body_weight_settings.dart';
import '../journal/logged_day.dart';
import '../pro/pro_status.dart';
import '../reminder/daily_lift_reminder.dart';
import '../reminder/daily_lift_notifications.dart';
import '../rest/rest_alarm.dart';
import '../sync/account_reauth.dart';
import '../sync/sync_controller.dart';
import '../theme.dart';
import '../utils/barbell_compound.dart';
import '../utils/distance_units.dart';
import '../utils/height_entry.dart';
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
  var _authBusy = false;
  var _autoFill = true;
  var _autoAdvanceWeightToReps = true;
  var _timerOnDone = false;
  var _saveRepsMarksDone = false;
  var _logDifficulty = false;
  var _prescribeWarmup = false;
  var _showPlateGraphic = true;
  var _proActive = false;
  var _proBusy = false;
  List<ProProduct> _proProducts = const [];
  final _unlockCode = TextEditingController();
  late final ProStatus _proStatus;
  final _heightFeet = TextEditingController();
  final _heightInches = TextEditingController();
  final _heightMeters = TextEditingController();
  final _heightCm = TextEditingController();
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
  final _scroll = ScrollController();
  final _freeThemeScroll = ScrollController();
  final _proThemeScroll = ScrollController();
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
    widget.sync.addListener(_onAccountSync);
  }

  var _sawSettingsRevision = 0;

  Future<void> _syncNow() async {
    if (_heightFeet.text.trim().isNotEmpty ||
        _heightInches.text.trim().isNotEmpty ||
        _heightMeters.text.trim().isNotEmpty ||
        _heightCm.text.trim().isNotEmpty) {
      await _saveHeight();
    }
    if (_bodyWeight.text.trim().isNotEmpty) await _saveBodyWeight();
    await widget.sync.syncNow();
  }

  /// A finished sync that wrote account preferences reloads the fields.
  void _onAccountSync() {
    final revision = widget.sync.settingsRevision;
    if (revision == _sawSettingsRevision) return;
    _sawSettingsRevision = revision;
    if (revision == 0) return;
    unawaited(_reloadFromAccount());
  }

  Future<void> _reloadFromAccount() async {
    final themeId = await widget.sync.journal.loadColorThemeId();
    final pro = await _proStatus.refresh();
    if (!mounted) return;
    widget.themes.applyStored(themeId, proActive: pro);
    setState(() => _proActive = pro);
    await _loadLogging();
    await _loadPrefs();
    await _loadReminder();
    if (!mounted) return;
    final scope = context.getInheritedWidgetOfExactType<RestTimerScope>();
    if (scope != null) {
      try {
        await scope.controller.reloadAlertSettings();
      } catch (_) {}
    }
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
    _applyHeightFields(height, distanceUnit);
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
      _loadingPrefs = false;
    });
  }

  void _applyHeightFields(double? inches, DistanceUnit unit) {
    final entry = heightEntryFromInches(inches, unit);
    if (unit == DistanceUnit.km) {
      _heightMeters.text = entry.primary;
      _heightCm.text = entry.secondary;
      _heightFeet.text = '';
      _heightInches.text = '';
      return;
    }
    _heightFeet.text = entry.primary;
    _heightInches.text = entry.secondary;
    _heightMeters.text = '';
    _heightCm.text = '';
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
    final products = await _proStatus.loadProducts();
    if (!mounted) return;
    widget.themes.setProActive(active);
    setState(() {
      _proActive = active;
      _proProducts = products;
    });
  }

  Future<void> _purchasePro(String productId) async {
    if (_proBusy) return;
    setState(() => _proBusy = true);
    final result = await _proStatus.purchase(productId);
    if (!mounted) return;
    setState(() => _proBusy = false);
    if (result.active && result.message == null) {
      showLiftBigNotice(context, 'LiftBig Pro is unlocked.');
    } else if (result.message != null) {
      showLiftBigNotice(context, result.message!);
    }
    await _loadPro();
  }

  Future<void> _restorePro() async {
    if (_proBusy) return;
    setState(() => _proBusy = true);
    final result = await _proStatus.restorePurchases('');
    if (!mounted) return;
    setState(() => _proBusy = false);
    showLiftBigNotice(
      context,
      result.isPro
          ? 'LiftBig Pro is unlocked.'
          : 'No Pro purchase was found.',
    );
    await _loadPro();
  }

  Future<void> _submitUnlockCode() async {
    if (_proBusy) return;
    setState(() => _proBusy = true);
    final result = await _proStatus.restorePurchases(_unlockCode.text.trim());
    if (!mounted) return;
    setState(() => _proBusy = false);
    if (result.codeMatched || result.isPro) {
      _unlockCode.clear();
      showLiftBigNotice(context, 'LiftBig Pro is unlocked.');
    } else {
      showLiftBigNotice(context, 'That code did not unlock Pro.');
    }
    await _loadPro();
  }

  String _proButtonLabel(String title, String productId) {
    final price = _proProducts
        .where((product) => product.id == productId)
        .map((product) => product.displayPrice)
        .firstWhere((price) => price.isNotEmpty, orElse: () => '');
    if (price.isEmpty) return title;
    return '$title · $price';
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
    if (unit == _weightUnit) return;
    final from = _weightUnit;
    final raw = _bodyWeight.text;
    final stored = await widget.sync.journal.storedBodyWeightLbs();
    if (!mounted) return;
    final trimmed = raw.trim().replaceAll(',', '.');
    final typed = displayWeightToLbs(raw, from);
    final showsStored = stored != null &&
        stored > 0 &&
        trimmed.isNotEmpty &&
        lbsToDisplayWeightString(stored, from) == trimmed;
    if (trimmed.isEmpty || (typed != null && !showsStored)) {
      await _saveBodyWeight();
    }
    if (!mounted) return;
    final basis = showsStored
        ? stored
        : await widget.sync.journal.storedBodyWeightLbs();
    final next = trimmed.isEmpty
        ? null
        : bodyWeightFieldAfterUnitChange(
            raw: raw,
            from: from,
            to: unit,
            storedLbs: basis,
          );
    setState(() {
      _weightUnit = unit;
      if (trimmed.isEmpty) {
        _bodyWeight.text = '';
      } else if (next != null) {
        _bodyWeight.text = next;
      }
    });
    await widget.sync.journal.setWeightUnit(unit);
  }

  Future<void> _saveHeight() async {
    final inches = inchesFromHeightFields(
      unit: _distanceUnit,
      primary: _distanceUnit == DistanceUnit.km
          ? _heightMeters.text
          : _heightFeet.text,
      secondary: _distanceUnit == DistanceUnit.km
          ? _heightCm.text
          : _heightInches.text,
    );
    final wrote = await _bodyWeightService.saveHeightInches(
      inches,
      tryHealthWrite: _appleHealth,
    );
    final stored = await widget.sync.journal.storedHeightInches();
    if (!mounted) return;
    _applyHeightFields(stored, _distanceUnit);
    if (wrote == false) {
      setState(() {
        _healthNote = 'Saved on this device. Apple Health needs permission to sync height.';
      });
    }
  }

  Future<void> _setDistanceUnit(DistanceUnit unit) async {
    if (unit == _distanceUnit) return;
    await _saveHeight();
    if (!mounted) return;
    setState(() => _distanceUnit = unit);
    await widget.sync.journal.setDistanceUnit(unit);
    final stored = await widget.sync.journal.storedHeightInches();
    if (!mounted) return;
    setState(() => _applyHeightFields(stored, unit));
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
      'whistle' => 'Whistle',
      'pulse' => 'Pulse',
      'gong' => 'Gong',
      'digital' => 'Digital',
      'boing' => 'Boing',
      _ => 'Beep',
    };
  }

  /// One-shot preview of the selected tone. A rest alarm that is already
  /// looping is left alone.
  Future<void> _previewAlarmTone() async {
    final scope = context.getInheritedWidgetOfExactType<RestTimerScope>();
    if (scope != null && scope.controller.alarmRinging) return;
    await RestAlarm.play(loop: false, soundId: _restAlerts.soundId);
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
    final themeId = await widget.sync.journal.loadColorThemeId();
    final pro = await _proStatus.refresh();
    if (!mounted) return;
    widget.themes.applyStored(themeId, proActive: pro);
    setState(() => _proActive = pro);
    await _loadLogging();
    await _loadPrefs();
    await _loadReminder();
    if (!mounted) return;
    final scope = context.getInheritedWidgetOfExactType<RestTimerScope>();
    if (scope != null) {
      try {
        await scope.controller.reloadAlertSettings();
      } catch (_) {}
    }
    if (!mounted) return;
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
    required ScrollController controller,
  }) {
    return SizedBox(
      height: 136,
      child: ListView.separated(
        controller: controller,
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
    widget.sync.removeListener(_onAccountSync);
    _email.dispose();
    _password.dispose();
    _unlockCode.dispose();
    _reminderMessage.dispose();
    _bodyWeight.dispose();
    _heightFeet.dispose();
    _heightInches.dispose();
    _heightMeters.dispose();
    _heightCm.dispose();
    _averageRest.dispose();
    _averageLift.dispose();
    _scroll.dispose();
    _freeThemeScroll.dispose();
    _proThemeScroll.dispose();
    super.dispose();
  }

  bool get _authLocked => _authBusy || widget.sync.busy;

  Future<void> _runAuth(Future<String?> Function() action) async {
    setState(() {
      _authBusy = true;
      _authError = null;
    });
    final error = await action();
    if (!mounted) return;
    setState(() {
      _authBusy = false;
      _authError = error;
    });
  }

  Future<void> _auth(bool createAccount) {
    return _runAuth(
      () => widget.sync.signIn(
        emailAddress: _email.text,
        password: _password.text,
        createAccount: createAccount,
      ),
    );
  }

  Future<void> _signInWithApple() {
    return _runAuth(widget.sync.signInWithApple);
  }

  Future<void> _signInWithGoogle() {
    return _runAuth(widget.sync.signInWithGoogle);
  }

  Future<void> _sendPasswordReset() {
    final address = widget.sync.signedIn
        ? (widget.sync.email ?? _email.text)
        : _email.text;
    return _runAuth(() => widget.sync.sendPasswordReset(address));
  }

  Future<void> _deleteAccount() async {
    final method = widget.sync.reauthMethod;
    var password = '';
    if (method == AccountReauthMethod.password) {
      final entered = await _askDeletePassword();
      if (entered == null || !mounted) return;
      password = entered;
    } else if (method == AccountReauthMethod.google ||
        method == AccountReauthMethod.apple) {
      final confirmed = await _confirmProviderDelete(method);
      if (confirmed != true || !mounted) return;
    } else {
      setState(() {
        _authError =
            'Sign in again with email, Google, or Apple before deleting the account.';
      });
      return;
    }
    await _runAuth(() => widget.sync.deleteAccount(password));
  }

  String _signedInLine(SyncController sync) {
    final who = sync.email;
    switch (sync.reauthMethod) {
      case AccountReauthMethod.password:
        return 'Signed in with email as $who.';
      case AccountReauthMethod.google:
        return 'Signed in with Google as $who.';
      case AccountReauthMethod.apple:
        return 'Signed in with Apple as $who.';
      case AccountReauthMethod.unsupported:
        return 'Signed in as $who.';
    }
  }

  Future<String?> _askDeletePassword() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          scrollable: true,
          title: const Text('Delete Account'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'This removes the cloud copy and your sign-in. The journal on this phone stays.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                obscureText: true,
                autocorrect: false,
                enableSuggestions: false,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(labelText: 'Password'),
                onSubmitted: (value) => Navigator.pop(context, value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Delete Account'),
            ),
          ],
        );
      },
    ).whenComplete(controller.dispose);
  }

  Future<bool?> _confirmProviderDelete(AccountReauthMethod method) {
    final provider = method == AccountReauthMethod.apple ? 'Apple' : 'Google';
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          scrollable: true,
          title: const Text('Delete Account'),
          content: Text(
            'This removes the cloud copy and your sign-in. The journal on this phone stays. $provider will ask you to confirm.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete Account'),
            ),
          ],
        );
      },
    );
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

  List<Widget> _proActivation() {
    if (_proActive) {
      return const [
        Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            'Pro is active on this account.',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ];
    }
    return [
      SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: _proBusy ? null : () => _purchasePro(proYearlyProductId),
          child: Text(_proButtonLabel('Yearly', proYearlyProductId)),
        ),
      ),
      const SizedBox(height: 8),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: _proBusy ? null : () => _purchasePro(proMonthlyProductId),
          child: Text(_proButtonLabel('Monthly', proMonthlyProductId)),
        ),
      ),
      const SizedBox(height: 8),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: _proBusy ? null : _restorePro,
          child: const Text('Restore'),
        ),
      ),
      const SizedBox(height: 8),
      TextField(
        controller: _unlockCode,
        textInputAction: TextInputAction.done,
        enabled: !_proBusy,
        decoration: const InputDecoration(
          labelText: 'Unlock Code',
          isDense: true,
        ),
        onSubmitted: (_) => _submitUnlockCode(),
      ),
      Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: _proBusy ? null : _submitUnlockCode,
          child: const Text('Unlock'),
        ),
      ),
    ];
  }

  Widget _settingsCard(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.liftBig.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.liftBig.border),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: context.liftBig.primary,
                ),
              ),
              const SizedBox(height: 6),
              ...children,
            ],
          ),
        ),
      ),
    );
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
          'Coming in a future update.',
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
        SignInWithAppleButton(
          onPressed: _authLocked ? null : _signInWithApple,
          style: Theme.of(context).brightness == Brightness.dark
              ? SignInWithAppleButtonStyle.white
              : SignInWithAppleButtonStyle.black,
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(44),
          ),
          onPressed: _authLocked ? null : _signInWithGoogle,
          child: const Text('Continue with Google'),
        ),
        const SizedBox(height: 16),
        Text(
          'Or use email and password.',
          style: TextStyle(color: context.liftBig.muted),
        ),
        const SizedBox(height: 8),
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
          onPressed: _authLocked ? null : () => _auth(false),
          child: const Text('Sign In'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: _authLocked ? null : () => _auth(true),
          child: const Text('Create Account'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _authLocked ? null : _sendPasswordReset,
          child: const Text('Reset Password'),
        ),
      ],
      if (sync.signedIn) ...[
        Text(_signedInLine(sync)),
        if (_authError != null) ...[
          const SizedBox(height: 8),
          Text(_authError!, style: TextStyle(color: context.liftBig.primary)),
        ],
        const SizedBox(height: 12),
        FilledButton(
          onPressed: sync.busy || !sync.syncEnabled ? null : _syncNow,
          child: Text(sync.busy ? 'Syncing…' : 'Sync Now'),
        ),
        if (sync.passwordAccount) ...[
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _authLocked ? null : _sendPasswordReset,
            child: const Text('Reset Password'),
          ),
        ],
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: _authLocked ? null : _deleteAccount,
          child: const Text('Delete Account'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: _authLocked ? null : sync.signOut,
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
                controller: _scroll,
                primary: false,
                padding: const EdgeInsets.all(20),
                children: [
                  _settingsCard('Tools', _toolSection(sync)),
                  _settingsCard('LiftBig Pro', _proActivation()),
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
                      return _settingsCard('Appearance', [
                          _themeStrip(
                            palettes: free,
                            selectedId: selectedId,
                            controller: _freeThemeScroll,
                          ),
                          Text(
                            'Pro Themes',
                            style: TextStyle(
                              color: context.liftBig.foreground,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (!_proActive)
                            Padding(
                              padding: const EdgeInsets.only(top: 4, bottom: 4),
                              child: Text(
                                'LiftBig Pro unlocks these themes.',
                                style: TextStyle(color: context.liftBig.muted),
                              ),
                            ),
                          _themeStrip(
                            palettes: pro,
                            selectedId: selectedId,
                            controller: _proThemeScroll,
                          ),
                        ]);
                    },
                  ),
                  _settingsCard('Units', [
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
                  ]),
                  _settingsCard('Your Metrics', [
                  if (_distanceUnit == DistanceUnit.mi)
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
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _heightMeters,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Height (m)',
                            ),
                            onSubmitted: (_) => _saveHeight(),
                            onEditingComplete: _saveHeight,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
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
                        ),
                      ],
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
                  ]),
                  _settingsCard('Logging', [
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
                    title: const Text('Include Warmup Sets on Heavy Compounds'),
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
                  ]),
                  _settingsCard('Rest Timer', [
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
                      'Repeats until you stop it from the timer, the lock-screen notification, or the watch. The notification sound plays once.',
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
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Play Tone',
                            onPressed: _previewAlarmTone,
                            icon: Icon(
                              Icons.play_arrow,
                              color: context.liftBig.primary,
                            ),
                          ),
                          Icon(
                            Icons.expand_more,
                            color: context.liftBig.primary,
                          ),
                        ],
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
                  ]),
                  _settingsCard('Daily Reminder', [
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
                  ]),
                  if (_proActive)
                    _settingsCard('Smart Watch', _watchSection()),
                  _settingsCard('Apple Health', [
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
                  ]),
                  _settingsCard('Lift Name Overlap', [
                  LiftNameConvergenceSection(journal: sync.journal),
                  ]),
                  _settingsCard('Account and Sync', _cloudSection(sync)),
                  _settingsCard('Backup', [
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
                  ]),
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
        'Enable Email/Password, Google, and Sign in with Apple in the Firebase Auth console.',
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
                            Align(
                              alignment: Alignment.center,
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
