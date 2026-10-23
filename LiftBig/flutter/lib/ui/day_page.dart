import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../catalog/liftbig_catalog.dart';
import '../companion/companion_bridge.dart';
import '../companion/watch_session.dart';
import '../date_key.dart';
import '../health/journal_health_sync.dart';
import '../journal/body_weight_settings.dart';
import '../journal/journal_repository.dart';
import '../journal/logged_day.dart';
import '../journal/set_prescription.dart';
import '../journal/machine_starting_weight_settings.dart';
import '../model/journal_day.dart';
import '../pro/pro_status.dart';
import '../utils/distance_units.dart';
import '../utils/variable_machine.dart';
import '../utils/weight_units.dart';
import '../rest/rest_timer_controller.dart';
import '../rest/rest_timer_state.dart';
import '../theme.dart';
import 'assign_plan_sheet.dart';
import 'basic_calculator_page.dart';
import 'clear_day.dart';
import 'day_transfer.dart';
import 'one_rep_max_calculator_page.dart';
import 'plate_calculator_page.dart';
import 'rest_timer_banner.dart';
import 'rest_timer_scope.dart';
import 'machine_plates_hint.dart';
import 'exercise_info_sheet.dart';
import 'liftbig_sheet.dart';
import 'set_value_sheet.dart';
import 'swap_exercise_sheet.dart';
import 'workout_details_section.dart';

const List<String> commonLifts = [
  'Bench Press',
  'Squat',
  'Deadlift',
  'Overhead Press',
  'Barbell Row',
  'Pull-Up',
  'Romanian Deadlift',
  'Lat Pulldown',
];

/// Every exercise stored for one calendar day, with set editing.
class DayPage extends StatefulWidget {
  const DayPage({
    super.key,
    required this.journal,
    required this.dateKey,
    this.refreshToken = 0,
    this.embedRestBanner = true,
    this.onOpenSettings,
    this.initialExerciseId,
  });

  final JournalRepository journal;
  final String dateKey;
  final Future<void> Function()? onOpenSettings;

  /// Lift to bring into view after the day loads.
  final String? initialExerciseId;

  /// Bumped by the shell after import or when this tab is opened again.
  final int refreshToken;

  /// False when the tab shell already shows the app-wide rest banner.
  final bool embedRestBanner;

  @override
  State<DayPage> createState() => _DayPageState();
}

class _DayPageState extends State<DayPage> {
  final _customName = TextEditingController();
  final _workoutName = TextEditingController();
  final _dayNotes = TextEditingController();
  final _workoutNameFocus = FocusNode();
  final _dayNotesFocus = FocusNode();
  final _reps = <String, TextEditingController>{};
  final _weights = <String, TextEditingController>{};
  final _durations = <String, TextEditingController>{};
  final _calories = <String, TextEditingController>{};
  final _pendingWrites = <String, Future<void>>{};

  JournalDay? _day;
  var _priorNotes = <String, List<PriorExerciseNote>>{};
  var _loaded = false;
  var _didScrollToExercise = false;
  final _exerciseKeys = <String, GlobalKey>{};
  var _adding = false;
  var _averageRest = defaultAverageRestSeconds;
  var _weightUnit = WeightUnit.lb;
  var _distanceUnit = DistanceUnit.mi;
  final _bodyWeight = TextEditingController();
  final _bodyWeightFocus = FocusNode();
  late final BodyWeightSettingsService _bodyWeightService;
  late final MachineStartingWeightSettings _machineStartingService;
  final _machineStarting = <VariableMachineKind, TextEditingController>{};
  RestTimerController? _restTimer;
  var _autoAdvance = true;
  var _startTimerOnDone = false;
  var _logDifficulty = false;
  String? _nameError;
  late final JournalHealthSync _healthSync;
  late final CompanionBridge _companion;
  late final ProStatus _proStatus;
  LiftBigCatalog? _catalog;
  var _assigning = false;

  @override
  void initState() {
    super.initState();
    _bodyWeightService = BodyWeightSettingsService(journal: widget.journal);
    _machineStartingService = MachineStartingWeightSettings(
      journal: widget.journal,
    );
    _healthSync = JournalHealthSync(
      journal: widget.journal,
      onStored: () {
        if (mounted) _load();
      },
    );
    _companion = CompanionBridge.shared;
    _proStatus = ProStatus(
      unlockStore: JournalTesterUnlockStore(widget.journal),
    );
    _companion.addListener(_onCompanionMessage);
    _load(syncHealth: true);
    _loadCatalog();
  }

  @override
  void didUpdateWidget(DayPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dateKey != widget.dateKey ||
        oldWidget.refreshToken != widget.refreshToken) {
      _load();
    }
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

  void _onRestTimerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _companion.removeListener(_onCompanionMessage);
    _healthSync.dispose();
    _restTimer?.removeListener(_onRestTimerChanged);
    _customName.dispose();
    _workoutName.dispose();
    _dayNotes.dispose();
    _workoutNameFocus.dispose();
    _dayNotesFocus.dispose();
    _bodyWeight.dispose();
    _bodyWeightFocus.dispose();
    for (final controller in _reps.values) {
      controller.dispose();
    }
    for (final controller in _weights.values) {
      controller.dispose();
    }
    for (final controller in _durations.values) {
      controller.dispose();
    }
    for (final controller in _calories.values) {
      controller.dispose();
    }
    for (final controller in _machineStarting.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load({bool prefill = true, bool syncHealth = false}) async {
    try {
      var day = await widget.journal.getDay(widget.dateKey);
      final settings = await widget.journal.localCloudSettings();
      final weightUnit = await widget.journal.storedWeightUnit();
      final distanceUnit = await widget.journal.storedDistanceUnit();
      final averageRest = await widget.journal.storedAverageRestSeconds();
      final autoFill = await widget.journal.autoFillSetsEnabled();
      final timerOnDone = await widget.journal.startTimerOnDone();
      final logDifficulty = await widget.journal.logSetDifficultyEnabled();
      var bodyLbs = await _bodyWeightService.importFromHealthIfEmpty();
      bodyLbs ??= await widget.journal.storedBodyWeightLbs();
      if (!mounted) return;
      if (prefill && autoFill) {
        final wrote = await widget.journal.prefillEmptySets(widget.dateKey);
        if (!mounted) return;
        if (wrote > 0) {
          await _load(prefill: false, syncHealth: syncHealth);
          return;
        }
        day = await widget.journal.getDay(widget.dateKey);
        if (!mounted) return;
      }
      final priorNotes = await widget.journal.priorNotesForDay(
        widget.dateKey,
        day?.exercises ?? const [],
      );
      if (!mounted) return;
      await _ensureMachineStartingControllers(weightUnit);
      if (!mounted) return;
      _ensureControllers(day, weightUnit: weightUnit, distanceUnit: distanceUnit);
      _applyHeader(day);
      _applyBodyWeightField(bodyLbs, weightUnit);
      setState(() {
        _day = day;
        _priorNotes = priorNotes;
        _loaded = true;
        _weightUnit = weightUnit;
        _distanceUnit = distanceUnit;
        _averageRest = averageRest;
        _autoAdvance = autoAdvanceFromSettings(settings?.settingsJson);
        _startTimerOnDone = timerOnDone;
        _logDifficulty = logDifficulty;
      });
      if (syncHealth) _healthSync.scheduleDay(widget.dateKey);
      await _publishWatch();
      _scheduleScrollToExercise();
    } catch (error) {
      if (!mounted) return;
      setState(() => _loaded = true);
      _snack('$error');
    }
  }

  GlobalKey _exerciseKey(String id) {
    return _exerciseKeys.putIfAbsent(id, GlobalKey.new);
  }

  void _scheduleScrollToExercise() {
    final id = widget.initialExerciseId;
    if (id == null || _didScrollToExercise) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _didScrollToExercise) return;
      final target = _exerciseKeys[id]?.currentContext;
      if (target == null) return;
      _didScrollToExercise = true;
      Scrollable.ensureVisible(
        target,
        alignment: 0.08,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _applyHeader(JournalDay? day) {
    _setIfIdle(_workoutName, _workoutNameFocus, day?.workoutName ?? '');
    _setIfIdle(_dayNotes, _dayNotesFocus, day?.notes ?? '');
  }

  void _setIfIdle(TextEditingController controller, FocusNode focus, String value) {
    if (focus.hasFocus || controller.text == value) return;
    controller.text = value;
  }

  void _syncField(
    Map<String, TextEditingController> fields,
    String id,
    String value,
  ) {
    final existing = fields[id];
    if (existing == null) {
      fields[id] = TextEditingController(text: value);
      return;
    }
    if (existing.text == value) return;
    existing.text = value;
  }

  void _applyBodyWeightField(double? bodyLbs, WeightUnit unit) {
    final display = bodyLbs == null ? '' : lbsToDisplayWeightString(bodyLbs, unit);
    _setIfIdle(_bodyWeight, _bodyWeightFocus, display);
  }

  JournalExercise? _exerciseForSet(String setId) {
    for (final exercise in _day?.exercises ?? const <JournalExercise>[]) {
      if (exercise.sets.any((set) => set.id == setId)) return exercise;
    }
    return null;
  }

  String _displayWeightToStored(String setId, String display) {
    final exercise = _exerciseForSet(setId);
    if (exercise?.isCardio == true) {
      final miles = displayDistanceToMiles(display, _distanceUnit);
      if (miles == null) return display.trim();
      return milesToDisplayDistanceString(miles, DistanceUnit.mi);
    }
    return displayToStoredLbsString(display, _weightUnit) ?? display.trim();
  }

  String _storedWeightToDisplay(
    JournalExercise exercise,
    String stored, {
    WeightUnit? weightUnit,
    DistanceUnit? distanceUnit,
  }) {
    final wUnit = weightUnit ?? _weightUnit;
    final dUnit = distanceUnit ?? _distanceUnit;
    if (stored.trim().isEmpty) return stored;
    if (exercise.isCardio) {
      final miles = double.tryParse(stored.trim().replaceAll(',', '.'));
      if (miles == null) return stored;
      return milesToDisplayDistanceString(miles, dUnit);
    }
    return storedLbsToDisplay(stored, wUnit);
  }

  Future<void> _saveBodyWeight(String display) async {
    final lbs = display.trim().isEmpty
        ? null
        : displayWeightToLbs(display, _weightUnit);
    await _bodyWeightService.saveBodyWeightLbs(
      lbs,
      tryHealthWrite: await widget.journal.appleHealthSyncEnabled(),
    );
  }

  Future<void> _ensureMachineStartingControllers(WeightUnit unit) async {
    for (final kind in VariableMachineKind.values) {
      final stored = await _machineStartingService.storedLbs(kind);
      final display = stored == null
          ? ''
          : lbsToDisplayWeightString(stored, unit);
      final existing = _machineStarting[kind];
      if (existing == null) {
        _machineStarting[kind] = TextEditingController(text: display);
      } else if (existing.text != display) {
        existing.text = display;
      }
    }
  }

  Future<void> _saveMachineStarting(VariableMachineKind kind, String display) async {
    final lbs = display.trim().isEmpty
        ? null
        : displayWeightToLbs(display, _weightUnit);
    try {
      await _machineStartingService.saveLbs(kind, lbs);
    } catch (error) {
      if (mounted) _snack('$error');
    }
  }

  void _ensureControllers(
    JournalDay? day, {
    required WeightUnit weightUnit,
    required DistanceUnit distanceUnit,
  }) {
    for (final exercise in day?.exercises ?? const <JournalExercise>[]) {
      _calories.putIfAbsent(
        exercise.id,
        () => TextEditingController(text: exercise.loggedCalories ?? ''),
      );
      for (final set in exercise.sets) {
        _syncField(_reps, set.id, loggedRepsField(set.reps));
        _syncField(
          _weights,
          set.id,
          _storedWeightToDisplay(
            exercise,
            set.weight,
            weightUnit: weightUnit,
            distanceUnit: distanceUnit,
          ),
        );
        _durations.putIfAbsent(
          set.id,
          () => TextEditingController(text: set.durationSeconds ?? ''),
        );
      }
    }
  }

  Future<void> _writeSet(String setId, Future<void> Function() write) {
    final previous = _pendingWrites[setId] ?? Future<void>.value();
    final next = previous.catchError((Object _) {}).then((_) => write());
    _pendingWrites[setId] = next;
    return next;
  }

  Future<void> _saveReps(String setId, String reps) async {
    try {
      final exercise = _exerciseForSet(setId);
      JournalSet? set;
      if (exercise != null) {
        for (final item in exercise.sets) {
          if (item.id == setId) set = item;
        }
      }
      if (exercise != null &&
          set != null &&
          storedRepsAreGoal(set.reps) &&
          (exercise.targetReps ?? '').trim().isEmpty) {
        await widget.journal.updateExerciseTargets(
          exercise.id,
          targetReps: set.reps.trim(),
          setTargetReps: true,
        );
      }
      await _writeSet(setId, () => widget.journal.updateSet(setId, reps: reps));
    } catch (error) {
      if (mounted) _snack('$error');
    }
  }

  Future<void> _saveWeight(String setId, String weight) async {
    final stored = _displayWeightToStored(setId, weight);
    try {
      await _writeSet(
        setId,
        () => widget.journal.updateSet(setId, weight: stored),
      );
    } catch (error) {
      if (mounted) _snack('$error');
    }
  }

  Future<void> _saveDuration(String setId, String duration) async {
    try {
      await _writeSet(
        setId,
        () => widget.journal.updateSet(setId, durationSeconds: duration),
      );
    } catch (error) {
      if (mounted) _snack('$error');
    }
  }

  Future<void> _saveCalories(String exerciseId, String calories) async {
    try {
      await widget.journal.updateLoggedCalories(exerciseId, calories);
    } catch (error) {
      if (mounted) _snack('$error');
    }
  }

  Future<void> _saveWorkoutName(String value) async {
    try {
      await widget.journal.updateDayHeader(
        widget.dateKey,
        workoutName: value,
        setWorkoutName: true,
      );
    } catch (error) {
      if (mounted) _snack('$error');
    }
  }

  Future<void> _saveExerciseNotes(String exerciseId, String value) async {
    try {
      await widget.journal.updateExerciseNotes(exerciseId, value);
      final day = _day;
      if (day == null) return;
      final exercises = [
        for (final exercise in day.exercises)
          exercise.id == exerciseId
              ? exercise.copyWith(
                  notes: value.trim().isEmpty ? null : value,
                  setNotes: true,
                )
              : exercise,
      ];
      setState(() => _day = day.copyWith(exercises: exercises));
    } catch (error) {
      if (mounted) _snack('$error');
    }
  }

  Future<void> _saveDayNotes(String value) async {
    try {
      await widget.journal.updateDayHeader(
        widget.dateKey,
        notes: value,
        setNotes: true,
      );
    } catch (error) {
      if (mounted) _snack('$error');
    }
  }

  Future<void> _loadCatalog() async {
    try {
      final catalog = await LiftBigCatalog.load();
      if (!mounted) return;
      setState(() => _catalog = catalog);
    } catch (_) {}
  }

  bool _showsBodyWeight(List<JournalExercise> exercises) {
    final catalog = _catalog;
    if (catalog == null || exercises.isEmpty) return false;
    for (final exercise in exercises) {
      if (exercise.isCardio) continue;
      final lift = _libraryLift(catalog, exercise);
      if (lift == null || lift.isCardio) continue;
      if (lift.equipment.trim().toLowerCase() == 'bodyweight') return true;
    }
    return false;
  }

  LibraryLift? _libraryLift(LiftBigCatalog catalog, JournalExercise exercise) {
    final id = exercise.libraryId?.trim();
    if (id != null && id.isNotEmpty) {
      final byId = catalog.liftById(id);
      if (byId != null) return byId;
    }
    final name = exercise.name.trim().toLowerCase();
    if (name.isEmpty) return null;
    for (final lift in catalog.lifts) {
      if (lift.name.trim().toLowerCase() == name) return lift;
    }
    return null;
  }

  Future<void> _assignPlan() async {
    if (_assigning) return;
    final pick = await showAssignPlanSheet(
      context,
      journal: widget.journal,
    );
    if (pick == null || !mounted) return;
    final existing = _day;
    if (existing != null && existing.exercises.isNotEmpty) {
      final add = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Add to this day?'),
          content: const Text(
            'This day already has exercises. The workout will be added alongside them.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Add'),
            ),
          ],
        ),
      );
      if (add != true || !mounted) return;
    }
    _assigning = true;
    try {
      final notes = pick.workout.notes.trim();
      await widget.journal.updateDayHeader(
        widget.dateKey,
        workoutName: pick.workout.name,
        setWorkoutName: true,
        planName: pick.planName,
        setPlanName: true,
        workoutNotes: notes,
        setWorkoutNotes: true,
      );
      final prescribeWarmup = await widget.journal.prescribeWarmupEnabled();
      for (final lift in pick.workout.lifts) {
        final prescribed = prescriptionFromCatalogSets([
          for (final set in lift.sets) (reps: set.reps, weight: set.weight),
        ]);
        await widget.journal.addExercise(
          dateKey: widget.dateKey,
          name: lift.name,
          libraryId: lift.libraryId,
          isCardio: lift.isCardio,
          isCore: lift.isCore,
          isCircuit: lift.isCircuit,
          prescribeWarmup: prescribeWarmup,
          targetReps: prescribed.targetReps,
          targetWeight: prescribed.targetWeight,
          supersetGroupId: lift.supersetGroupId,
          supersetLabel: lift.supersetLabel,
          supersetOrder: lift.supersetOrder,
          targetRestSeconds: lift.targetRestSeconds,
          sets: [
            for (var i = 0; i < prescribed.sets.length; i++)
              JournalSet(
                id: '',
                sortOrder: i,
                reps: prescribed.sets[i].reps,
                weight: prescribed.sets[i].weight,
              ),
          ],
        );
      }
      if (!mounted) return;
      _snack('${pick.workout.name} added.');
      await _load(syncHealth: true);
    } catch (error) {
      if (mounted) _snack('$error');
    } finally {
      _assigning = false;
    }
  }

  Future<void> _clearDay() async {
    final confirmed = await confirmClearDay(context);
    if (!confirmed || !mounted) return;
    try {
      await widget.journal.deleteDay(widget.dateKey);
      if (!mounted) return;
      FocusManager.instance.primaryFocus?.unfocus();
      _workoutName.text = '';
      _dayNotes.text = '';
      await _load(syncHealth: true);
    } catch (error) {
      if (mounted) _snack('$error');
    }
  }

  Widget _bodyWeightField() {
    final unit = _weightUnit == WeightUnit.lb ? 'lb' : 'kg';
    return TextField(
      controller: _bodyWeight,
      focusNode: _bodyWeightFocus,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: 'Body weight ($unit)',
        hintText: 'Optional — same as Settings',
      ),
      onChanged: _saveBodyWeight,
    );
  }

  Future<void> _toggleRest(bool rest) async {
    final ok = await widget.journal.setRestDay(widget.dateKey, rest: rest);
    if (!mounted) return;
    if (!ok) {
      _snack('This day already has exercises.');
      return;
    }
    await _load(syncHealth: true);
  }

  Future<void> _setChecked(
    JournalExercise exercise,
    JournalSet set,
    bool checked,
  ) async {
    final completing = checked && !set.checked;
    final weight = _weights[set.id]?.text;
    final reps = _reps[set.id]?.text;
    final storedWeight =
        weight == null ? null : _displayWeightToStored(set.id, weight);
    try {
      await _writeSet(
        set.id,
        () => widget.journal.updateSet(
          set.id,
          checked: checked,
          weight: storedWeight ?? weight,
          reps: reps,
        ),
      );
    } catch (error) {
      if (mounted) _snack('$error');
      return;
    }
    if (!mounted) return;
    await _load(syncHealth: true);
    if (!mounted) return;
    if (!checked && set.checked && _startTimerOnDone) {
      final rest = _restTimer;
      if (rest != null &&
          rest.isActive &&
          rest.isRunning &&
          rest.snapshot.exerciseId == exercise.id) {
        await rest.pause();
      }
      return;
    }
    if (!completing || !_startTimerOnDone) return;
    if (!startsRestAfterSet(exercise, _day?.exercises ?? const [])) return;
    _startRest(exercise);
  }

  void _startDayRest() {
    final seconds = _day?.chosenRestSeconds ?? _averageRest;
    _restTimer?.start(
      exerciseId: '',
      exerciseName: _day?.workoutName?.trim().isNotEmpty == true
          ? _day!.workoutName!
          : 'Rest',
      fullSeconds: seconds,
    );
  }

  Future<void> _pickDayRest() async {
    final initial = _day?.chosenRestSeconds ?? _averageRest;
    final picked = await showDayRestPicker(context, initialSeconds: initial);
    if (picked == null || !mounted) return;
    try {
      await widget.journal.setChosenRestSeconds(widget.dateKey, picked);
      await _load(syncHealth: true);
    } catch (error) {
      if (mounted) _snack('$error');
    }
  }

  Future<void> _publishWatch() async {
    final json = await _watchSessionJson();
    if (json == null) return;
    await _companion.publishSession(json);
  }

  Future<String?> _watchSessionJson() async {
    final pro = await _proStatus.refresh();
    if (!mounted) return null;
    final day = _day;
    final rest = day?.chosenRestSeconds ?? _averageRest;
    final session = buildWatchSession(
      dateKey: widget.dateKey,
      exercises: day?.exercises ?? const [],
      restSeconds: rest,
      weightUnit: _weightUnit,
      pro: pro,
    );
    return jsonEncode(session.toJson());
  }

  Future<void> _startOnWatch() async {
    final json = await _watchSessionJson();
    if (json == null) return;
    await _companion.publishSession(json);
    await _companion.startWorkout(json);
    if (!mounted) return;
    _snack('Sent to your Apple Watch. This workout stays on your iPhone.');
  }

  Future<void> _finishWorkout() async {
    await _healthSync.syncDay(widget.dateKey, honorToggle: false);
    if (!mounted) return;
    await _load();
    if (!mounted) return;
    final kcal = _day?.healthEnergyKcal;
    if (kcal == null) {
      _snack('Workout saved. Active calories show up when Apple Health has them.');
      return;
    }
    _snack('${formatRoundedNumber(kcal, 0)} active kcal saved on this workout.');
  }

  Future<void> _onCompanionMessage(String raw) async {
    final message = parseCompanionMessage(raw, fallbackUnit: _weightUnit);
    if (message == null || message.dateKey != widget.dateKey) return;
    if (message.isFinish) {
      if (message.activeKcal != null) {
        await widget.journal.setHealthEnergyKcal(widget.dateKey, message.activeKcal);
      } else {
        await _healthSync.syncDay(widget.dateKey, honorToggle: false);
      }
      if (!mounted) return;
      await _load();
      return;
    }
    if (message.isSetRest && message.restSeconds != null) {
      await widget.journal.setChosenRestSeconds(widget.dateKey, message.restSeconds!);
      if (!mounted) return;
      await _load(syncHealth: false);
      return;
    }
    final completed = await widget.journal.persistCompanionMessage(message);
    if (!mounted) return;
    await _load(syncHealth: true);
    if (!mounted || !completed || !_startTimerOnDone) return;
    final seconds = _day?.chosenRestSeconds ?? _averageRest;
    final exercise = _day?.exercises
        .where((item) => item.id == message.exerciseId)
        .firstOrNull;
    _restTimer?.start(
      exerciseId: message.exerciseId,
      exerciseName: exercise?.name ?? 'Rest',
      fullSeconds: seconds,
    );
  }

  Future<void> _editGoal(JournalExercise exercise) async {
    final exercises = _day?.exercises ?? const <JournalExercise>[];
    final editGoal = !exercise.isCardio && !exercise.isCircuit;
    final showLinkWithNext = _canLinkExerciseWithNext(exercise, exercises);
    final showLinkWithPartner =
        _linkPartnersFor(exercise, exercises).isNotEmpty;
    if (!editGoal && !showLinkWithNext && !showLinkWithPartner) return;
    final result = await showDialog<_GoalEdit>(
      context: context,
      builder: (context) => _GoalEditDialog(
        exercise: exercise,
        unit: _weightUnit,
        editGoal: editGoal,
        showLinkWithNext: showLinkWithNext,
        showLinkWithPartner: showLinkWithPartner,
      ),
    );
    if (result == null || !mounted) return;
    if (result.linkNext) {
      await _linkWithNext(exercise);
      return;
    }
    if (result.linkPartner) {
      await _linkWithPartner(exercise);
      return;
    }
    try {
      if (result.revert) {
        await widget.journal.revertExerciseGoal(exercise.id);
      } else {
        final stored = displayToStoredLbsString(result.weight, _weightUnit);
        await widget.journal.updateExerciseGoal(
          exerciseId: exercise.id,
          targetReps: result.reps,
          targetWeight: stored ?? result.weight,
          setCount: result.setCount,
        );
      }
      await _load(syncHealth: true);
    } catch (error) {
      if (mounted) _snack('$error');
    }
  }

  Future<void> _onMenu(String action) async {
    switch (action) {
      case 'settings':
        await widget.onOpenSettings?.call();
        if (mounted) await _load(syncHealth: true);
      case 'calculator':
        await Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const BasicCalculatorPage()),
        );
      case 'plates':
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => PlateCalculatorPage(journal: widget.journal),
          ),
        );
      case 'orm':
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => OneRepMaxCalculatorPage(journal: widget.journal),
          ),
        );
      case 'copy':
        await _copyDay();
      case 'move':
        await _moveDay();
    }
  }

  void _startRest(JournalExercise exercise) {
    final seconds = restSecondsForExercise(
      exercise,
      averageRestSeconds: _averageRest,
    );
    _restTimer?.start(
      exerciseId: exercise.id,
      exerciseName: exercise.name,
      fullSeconds: seconds,
    );
  }

  int? _restHintRemaining(String exerciseId) {
    final rest = _restTimer;
    if (rest == null || !rest.isActive) return null;
    final snap = rest.snapshot;
    if (snap.exerciseId != exerciseId) return null;
    if (!rest.isRunning && rest.remaining >= snap.fullSeconds) return null;
    return rest.remaining;
  }

  Future<void> _editRest(JournalExercise exercise) async {
    final initial = restSecondsForExercise(
      exercise,
      averageRestSeconds: _averageRest,
    );
    final picked = await showRestDurationDialog(
      context,
      initialSeconds: initial,
    );
    if (picked == null || !mounted) return;
    try {
      await widget.journal.updateTargetRestSeconds(exercise.id, picked);
      await _load(syncHealth: true);
    } catch (error) {
      if (mounted) _snack('$error');
    }
  }

  Future<void> _editWeight(
    JournalExercise exercise,
    JournalSet set,
    int index,
  ) async {
    final logged = (_weights[set.id]?.text ?? '').trim();
    final storedGoal = (exercise.targetWeight ?? '').trim();
    final programmed = storedGoal.isEmpty
        ? ''
        : storedLbsToDisplay(storedGoal, _weightUnit);
    final opening = logged.isNotEmpty ? logged : programmed;
    final goalWeight = exercise.targetWeight ?? '';
    final goal = index == 0
        ? snapWeightOption(
            storedLbsToDisplay(goalWeight, _weightUnit),
            _weightUnit,
          )
        : null;
    final maxDisplay = weightPickerMaxForUnit(_weightUnit);
    final step = weightPickerStepForUnit(_weightUnit);
    final next = await showSetValueSheet(
      context,
      title: 'Weight (${_weightUnit == WeightUnit.lb ? 'lb' : 'kg'})',
      initial: opening,
      options: weightPickerOptions(_weightUnit),
      pinnedValue: goal,
      weightUnit: _weightUnit,
      sliderStep: step,
      selectAll: opening.isNotEmpty,
      sliderMin: 0,
      sliderMax: maxDisplay,
      sliderDivisions: (maxDisplay / step).round(),
    );
    if (!mounted || next == null || next.trim() == logged) return;
    _weights[set.id]?.text = next;
    await _saveWeight(set.id, next);
    if (!mounted) return;
    final advance = advanceAfterWeight(
      enabled: _autoAdvance,
      weight: next,
      setId: set.id,
    );
    if (advance == null) return;
    await _editReps(exercise, set, index);
  }

  Future<void> _editReps(
    JournalExercise exercise,
    JournalSet set,
    int index,
  ) async {
    final field = (_reps[set.id]?.text ?? loggedRepsField(set.reps)).trim();
    final goal = goalRepsForSet(
      targetReps: exercise.targetReps,
      storedReps: set.reps,
    );
    final openingCount = repSheetOpeningCount(
      loggedReps: set.reps,
      goalReps: goal,
    );
    final opening = openingCount?.toString() ?? field;
    final next = await showSetValueSheet(
      context,
      title: 'Reps',
      initial: opening,
      goalLabel: goal,
      selectAll: opening.isNotEmpty,
      options: repsPickerOptions(),
      sliderMin: 1,
      sliderMax: repsPickerMax.toDouble(),
      sliderDivisions: repsPickerMax - 1,
      sliderStep: 1,
    );
    if (!mounted || next == null || next.trim() == field) return;
    _reps[set.id]?.text = next;
    await _saveReps(set.id, next);
    if (!mounted) return;
    final nextIndex = index + 1;
    if (nextIndex >= exercise.sets.length) return;
    final advance = advanceAfterReps(
      enabled: _autoAdvance,
      reps: next,
      nextSetId: exercise.sets[nextIndex].id,
    );
    if (advance == null) return;
    await _editWeight(exercise, exercise.sets[nextIndex], nextIndex);
  }

  Future<void> _setDifficulty(JournalSet set, String? difficulty) async {
    try {
      await _writeSet(
        set.id,
        () => widget.journal.updateSet(
          set.id,
          difficulty: difficulty,
          setDifficulty: true,
        ),
      );
    } catch (error) {
      if (mounted) _snack('$error');
      return;
    }
    if (!mounted) return;
    await _load(syncHealth: true);
  }

  Future<void> _setWarmup(JournalSet set, bool warmup) async {
    try {
      await _writeSet(
        set.id,
        () => widget.journal.updateSet(set.id, isWarmup: warmup),
      );
    } catch (error) {
      if (mounted) _snack('$error');
      return;
    }
    if (!mounted) return;
    await _load(syncHealth: true);
  }

  Future<void> _addSet(String exerciseId) async {
    try {
      await widget.journal.addSet(exerciseId);
      await _load(syncHealth: true);
    } catch (error) {
      if (mounted) _snack('$error');
    }
  }

  Future<void> _deleteSet(String setId) async {
    try {
      await widget.journal.deleteSet(setId);
      await _load(syncHealth: true);
    } catch (error) {
      if (mounted) _snack('$error');
    }
  }

  Future<void> _addNamed(
    String name, {
    String? libraryId,
    bool isCardio = false,
    bool isCore = false,
  }) async {
    if (_adding) return;
    _adding = true;
    try {
      final prescribeWarmup = await widget.journal.prescribeWarmupEnabled();
      await widget.journal.addExercise(
        dateKey: widget.dateKey,
        name: name,
        sets: const [],
        libraryId: libraryId,
        isCardio: isCardio,
        isCore: isCore,
        prescribeWarmup: prescribeWarmup,
      );
      if (!mounted) return;
      _customName.clear();
      setState(() => _nameError = null);
      await _load(syncHealth: true);
    } catch (error) {
      if (mounted) _snack('$error');
    } finally {
      _adding = false;
    }
  }

  Future<void> _addCustom() async {
    final name = _customName.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Name the exercise first.');
      return;
    }
    await _addNamed(name);
  }

  Future<void> _deleteExercise(JournalExercise exercise) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete exercise?'),
          content: Text('Remove ${exercise.name} and its sets from this day.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;
    try {
      await widget.journal.deleteExercise(exercise.id);
      await _load(syncHealth: true);
    } catch (error) {
      if (mounted) _snack('$error');
    }
  }

  Future<void> _moveBlock(int index, int delta) async {
    final blocks = groupExercisesForDisplay(_day?.exercises ?? const []);
    final target = index + delta;
    if (target < 0 || target >= blocks.length) return;
    final order = [...blocks];
    final moved = order.removeAt(index);
    order.insert(target, moved);
    try {
      await widget.journal.reorderExercises(widget.dateKey, [
        for (final block in order) ...block.map((exercise) => exercise.id),
      ]);
      await _load(syncHealth: true);
    } catch (error) {
      if (mounted) _snack('$error');
    }
  }

  Future<void> _copyDay() async {
    final changed = await copyLoggedDay(context, widget.journal, widget.dateKey);
    if (changed && mounted) await _load(syncHealth: true);
  }

  Future<void> _moveDay() async {
    final changed = await moveLoggedDay(context, widget.journal, widget.dateKey);
    if (changed && mounted) await _load(syncHealth: true);
  }

  void _openExerciseInfo(JournalExercise exercise) {
    showExerciseInfoSheet(
      context,
      journal: widget.journal,
      exerciseName: exercise.name,
      libraryId: exercise.libraryId,
    );
  }

  Future<void> _swapExercise(JournalExercise exercise) async {
    final saved = await showSwapExerciseSheet(
      context,
      journal: widget.journal,
      exercise: exercise,
    );
    if (saved && mounted) await _load(syncHealth: true);
  }

  Future<void> _linkWithNext(JournalExercise exercise) async {
    final exercises = _day?.exercises ?? const <JournalExercise>[];
    final index = exercises.indexWhere((item) => item.id == exercise.id);
    if (index < 0 || index + 1 >= exercises.length) return;
    try {
      await widget.journal.linkSupersetPair(
        dateKey: widget.dateKey,
        firstExerciseId: exercise.id,
        secondExerciseId: exercises[index + 1].id,
      );
      if (mounted) await _load(syncHealth: true);
    } catch (error) {
      if (mounted) _snack('$error');
    }
  }

  Future<void> _linkWithPartner(JournalExercise exercise) async {
    final partners = [
      for (final item in _day?.exercises ?? const <JournalExercise>[])
        if (item.id != exercise.id && !exerciseInSuperset(item)) item,
    ];
    if (partners.isEmpty || !mounted) return;
    final picked = await showLiftBigSheet<JournalExercise>(
      context,
      builder: (context) => ListView(
        shrinkWrap: true,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              'Link with',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ),
          for (final partner in partners)
            ListTile(
              title: Text(partner.name),
              onTap: () {
                liftBigSelectionHaptic();
                Navigator.of(context).pop(partner);
              },
            ),
        ],
      ),
    );
    if (picked == null || !mounted) return;
    try {
      await widget.journal.linkSupersetPair(
        dateKey: widget.dateKey,
        firstExerciseId: exercise.id,
        secondExerciseId: picked.id,
      );
      if (mounted) await _load(syncHealth: true);
    } catch (error) {
      if (mounted) _snack('$error');
    }
  }

  Future<void> _unlinkSuperset(String groupId) async {
    try {
      await widget.journal.unlinkSuperset(
        dateKey: widget.dateKey,
        groupId: groupId,
      );
      if (mounted) await _load(syncHealth: true);
    } catch (error) {
      if (mounted) _snack('$error');
    }
  }

  Future<void> _swapSupersetOrder(String groupId) async {
    try {
      await widget.journal.swapSupersetOrder(
        dateKey: widget.dateKey,
        groupId: groupId,
      );
      if (mounted) await _load(syncHealth: true);
    } catch (error) {
      if (mounted) _snack('$error');
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final day = _day;
    final workoutNotes = day?.workoutNotes;
    final exercises = day?.exercises ?? const <JournalExercise>[];
    final restDay = day?.isRestDay == true && exercises.isEmpty;

    final blocks = groupExercisesForDisplay(exercises);
    final rest = _restTimer;
    final showBanner =
        widget.embedRestBanner && rest != null && rest.isActive;
    Widget logBody = !_loaded
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _workoutName,
                      focusNode: _workoutNameFocus,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Workout Name',
                        hintText: 'Workout name',
                      ),
                      onChanged: _saveWorkoutName,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Tooltip(
                    message: 'Assign a plan',
                    child: OutlinedButton(
                      onPressed: _assigning ? null : _assignPlan,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 56),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        foregroundColor: context.liftBig.foreground,
                        backgroundColor: context.liftBig.cardInner,
                        side:  BorderSide(color: context.liftBig.border),
                      ),
                      child:  Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.assignment_outlined,
                            size: 18,
                            color: context.liftBig.primary,
                          ),
                          SizedBox(width: 6),
                          Text('Plan'),
                        ],
                      ),
                    ),
                  ),
                  if (exercises.isNotEmpty)
                    IconButton(
                      tooltip: 'Clear day',
                      onPressed: _clearDay,
                      color: context.liftBig.primary,
                      icon: const Icon(Icons.delete_outline),
                    ),
                ],
              ),
              if (day?.planName != null) ...[
                const SizedBox(height: 6),
                Text(
                  day!.planName!,
                  style:  TextStyle(color: context.liftBig.muted),
                ),
              ],
              if (exercises.isNotEmpty) ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _startOnWatch,
                  icon: const Icon(Icons.watch),
                  label: const Text('Start workout'),
                ),
              ],
              if (workoutNotes != null && workoutNotes.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                WorkoutDetailsSection(
                  key: ValueKey('workout-notes-${widget.dateKey}'),
                  text: workoutNotes,
                  style:  TextStyle(color: context.liftBig.foreground),
                ),
              ],
              const SizedBox(height: 8),
              TextField(
                controller: _dayNotes,
                focusNode: _dayNotesFocus,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  hintText: 'Notes for this day',
                  isDense: true,
                ),
                onChanged: _saveDayNotes,
              ),
              if (exercises.isEmpty) ...[
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => _toggleRest(!restDay),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    foregroundColor: restDay
                        ? context.liftBig.success
                        : context.liftBig.foreground,
                    backgroundColor: restDay
                        ? context.liftBig.success.withValues(alpha: 0.12)
                        : context.liftBig.cardInner,
                    side: BorderSide(
                      color: restDay
                          ? context.liftBig.success
                          : context.liftBig.border,
                    ),
                  ),
                  child: Text(restDay ? 'Clear rest' : 'Rest day'),
                ),
                if (!restDay)
                   Padding(
                    padding: EdgeInsets.only(top: 8, bottom: 12),
                    child: Text(
                      'Nothing logged.',
                      style: TextStyle(color: context.liftBig.muted),
                    ),
                  )
                else
                  const SizedBox(height: 12),
              ],
              for (var index = 0; index < blocks.length; index++)
                _ExerciseBlock(
                  exercises: blocks[index],
                  canMoveUp: index > 0,
                  canMoveDown: index < blocks.length - 1,
                  onMoveUp: () => _moveBlock(index, -1),
                  onMoveDown: () => _moveBlock(index, 1),
                  reps: _reps,
                  weights: _weights,
                  durations: _durations,
                  calories: _calories,
                  onReps: _saveReps,
                  onWeight: _saveWeight,
                  onDuration: _saveDuration,
                  onCalories: _saveCalories,
                  onChecked: _setChecked,
                  onWarmup: _setWarmup,
                  showDifficulty: _logDifficulty,
                  onDifficulty: _setDifficulty,
                  onAddSet: _addSet,
                  onDeleteSet: _deleteSet,
                  onDeleteExercise: _deleteExercise,
                  onEditWeight: _editWeight,
                  onEditReps: _editReps,
                  onStartTimer: _startRest,
                  onEditTimer: _editRest,
                  restHintRemaining: _restHintRemaining,
                  priorNotesByExerciseId: _priorNotes,
                  onExerciseNotes: _saveExerciseNotes,
                  weightUnit: _weightUnit,
                  machineStarting: _machineStarting,
                  onMachineStartingChanged: _saveMachineStarting,
                  onEditGoal: _editGoal,
                  dayExercises: exercises,
                  onInfo: _openExerciseInfo,
                  onSwap: _swapExercise,
                  onUnlinkSuperset: _unlinkSuperset,
                  onSwapSupersetOrder: _swapSupersetOrder,
                  exerciseKey: _exerciseKey,
                ),
              _AddExerciseCard(
                name: _customName,
                error: _nameError,
                onAddNamed: _addNamed,
                onAddCustom: _addCustom,
              ),
              if (_showsBodyWeight(exercises)) ...[
                const SizedBox(height: 16),
                _bodyWeightField(),
              ],
              if (day?.healthEnergyKcal != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    '${formatRoundedNumber(day!.healthEnergyKcal!, 0)} kcal',
                    textAlign: TextAlign.center,
                    style:  TextStyle(
                      color: context.liftBig.foreground,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              if (exercises.isNotEmpty) ...[
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _finishWorkout,
                  child: const Text('Done'),
                ),
              ],
            ],
          );
    final restBanner = showBanner
        ? Positioned(
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
                  fullSeconds: snap.fullSeconds > 0 ? snap.fullSeconds : 60,
                );
              },
              onDismiss: () => rest.dismiss(),
            ),
          )
        : null;
    final chosenRest = day?.chosenRestSeconds ?? _averageRest;
    return Scaffold(
      backgroundColor: context.liftBig.background,
      appBar: AppBar(
        backgroundColor: context.liftBig.background,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        titleSpacing: 12,
        title: Row(
          children: [
            Flexible(
              child: Text(
                formatDisplayDate(widget.dateKey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            IconButton(
              tooltip: 'Start rest',
              onPressed: _startDayRest,
              icon: const Icon(Icons.timer_outlined),
            ),
            InkWell(
              onTap: _pickDayRest,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: context.liftBig.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  formatRestDurationLabel(chosenRest),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Menu',
            icon: const Icon(Icons.menu),
            onSelected: _onMenu,
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'settings', child: Text('Settings')),
              const PopupMenuItem(value: 'calculator', child: Text('Calculator')),
              const PopupMenuItem(
                value: 'plates',
                child: Text('Plate calculator'),
              ),
              const PopupMenuItem(value: 'orm', child: Text('1RM calculator')),
              PopupMenuItem(
                value: 'copy',
                enabled: exercises.isNotEmpty,
                child: const Text('Copy'),
              ),
              PopupMenuItem(
                value: 'move',
                enabled: exercises.isNotEmpty,
                child: const Text('Move'),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          logBody,
          ?restBanner,
        ],
      ),
    );
  }
}

class _ExerciseBlock extends StatelessWidget {
  const _ExerciseBlock({
    required this.exercises,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.reps,
    required this.weights,
    required this.durations,
    required this.calories,
    required this.onReps,
    required this.onWeight,
    required this.onDuration,
    required this.onCalories,
    required this.onChecked,
    required this.onWarmup,
    required this.showDifficulty,
    required this.onDifficulty,
    required this.onAddSet,
    required this.onDeleteSet,
    required this.onDeleteExercise,
    required this.onEditWeight,
    required this.onEditReps,
    required this.onStartTimer,
    required this.onEditTimer,
    required this.restHintRemaining,
    required this.priorNotesByExerciseId,
    required this.onExerciseNotes,
    required this.weightUnit,
    required this.machineStarting,
    required this.onMachineStartingChanged,
    required this.onEditGoal,
    required this.dayExercises,
    required this.onInfo,
    required this.onSwap,
    required this.onUnlinkSuperset,
    required this.onSwapSupersetOrder,
    required this.exerciseKey,
  });

  final List<JournalExercise> exercises;
  final bool canMoveUp;
  final bool canMoveDown;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final Map<String, TextEditingController> reps;
  final Map<String, TextEditingController> weights;
  final Map<String, TextEditingController> durations;
  final Map<String, TextEditingController> calories;
  final Future<void> Function(String setId, String reps) onReps;
  final Future<void> Function(String setId, String weight) onWeight;
  final Future<void> Function(String setId, String duration) onDuration;
  final Future<void> Function(String exerciseId, String calories) onCalories;
  final Future<void> Function(
    JournalExercise exercise,
    JournalSet set,
    bool checked,
  )
  onChecked;
  final Future<void> Function(JournalSet set, bool warmup) onWarmup;
  final bool showDifficulty;
  final Future<void> Function(JournalSet set, String? difficulty) onDifficulty;
  final Future<void> Function(String exerciseId) onAddSet;
  final Future<void> Function(String setId) onDeleteSet;
  final Future<void> Function(JournalExercise exercise) onDeleteExercise;
  final Future<void> Function(JournalExercise exercise, JournalSet set, int index)
  onEditWeight;
  final Future<void> Function(JournalExercise exercise, JournalSet set, int index)
  onEditReps;
  final void Function(JournalExercise exercise) onStartTimer;
  final Future<void> Function(JournalExercise exercise) onEditTimer;
  final int? Function(String exerciseId) restHintRemaining;
  final Map<String, List<PriorExerciseNote>> priorNotesByExerciseId;
  final Future<void> Function(String exerciseId, String notes) onExerciseNotes;
  final WeightUnit weightUnit;
  final Map<VariableMachineKind, TextEditingController> machineStarting;
  final Future<void> Function(VariableMachineKind kind, String display)
  onMachineStartingChanged;
  final Future<void> Function(JournalExercise exercise) onEditGoal;
  final List<JournalExercise> dayExercises;
  final void Function(JournalExercise exercise) onInfo;
  final Future<void> Function(JournalExercise exercise) onSwap;
  final Future<void> Function(String groupId) onUnlinkSuperset;
  final Future<void> Function(String groupId) onSwapSupersetOrder;
  final GlobalKey Function(String id) exerciseKey;

  bool get _superset =>
      (exercises.first.supersetGroupId?.trim().isNotEmpty ?? false);

  @override
  Widget build(BuildContext context) {
    final label = exercises.first.supersetLabel?.trim();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: _superset ? const EdgeInsets.fromLTRB(8, 8, 8, 4) : EdgeInsets.zero,
      decoration: _superset
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.liftBig.primary),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_superset)
            Row(
              children: [
                Expanded(
                  child: Text(
                    label == null || label.isEmpty ? 'Superset' : 'Superset $label',
                    style:  TextStyle(
                      color: context.liftBig.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
                _MoveButtons(
                  canMoveUp: canMoveUp,
                  canMoveDown: canMoveDown,
                  onMoveUp: onMoveUp,
                  onMoveDown: onMoveDown,
                ),
                TextButton(
                  onPressed: () => onSwapSupersetOrder(
                    exercises.first.supersetGroupId ?? '',
                  ),
                  child: const Text('Swap order'),
                ),
                TextButton(
                  onPressed: () =>
                      onUnlinkSuperset(exercises.first.supersetGroupId ?? ''),
                  child: const Text('Unlink'),
                ),
              ],
            ),
          for (final exercise in exercises)
            KeyedSubtree(
              key: exerciseKey(exercise.id),
              child: _ExerciseCard(
              exercise: exercise,
              showMove: !_superset,
              canMoveUp: canMoveUp,
              canMoveDown: canMoveDown,
              onMoveUp: onMoveUp,
              onMoveDown: onMoveDown,
              reps: reps,
              weights: weights,
              durations: durations,
              calories: calories,
              onReps: onReps,
              onWeight: onWeight,
              onDuration: onDuration,
              onCalories: onCalories,
              onChecked: onChecked,
              onWarmup: onWarmup,
              showDifficulty: showDifficulty,
              onDifficulty: onDifficulty,
              onAddSet: () => onAddSet(exercise.id),
              onDeleteSet: onDeleteSet,
              onDeleteExercise: () => onDeleteExercise(exercise),
              onEditWeight: onEditWeight,
              onEditReps: onEditReps,
              onStartTimer: () => onStartTimer(exercise),
              onEditTimer: () => onEditTimer(exercise),
              restHintSeconds: restHintRemaining(exercise.id),
              priorNotes: priorNotesByExerciseId[exercise.id] ?? const [],
              onExerciseNotes: onExerciseNotes,
              weightUnit: weightUnit,
              machineStarting: machineStarting,
              onMachineStartingChanged: onMachineStartingChanged,
              onEditGoal: () => onEditGoal(exercise),
              dayExercises: dayExercises,
              onInfo: () => onInfo(exercise),
              onSwap: () => onSwap(exercise),
            ),
            ),
        ],
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    required this.exercise,
    required this.showMove,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.reps,
    required this.weights,
    required this.durations,
    required this.calories,
    required this.onReps,
    required this.onWeight,
    required this.onDuration,
    required this.onCalories,
    required this.onChecked,
    required this.onWarmup,
    required this.showDifficulty,
    required this.onDifficulty,
    required this.onAddSet,
    required this.onDeleteSet,
    required this.onDeleteExercise,
    required this.onEditWeight,
    required this.onEditReps,
    required this.onStartTimer,
    required this.onEditTimer,
    required this.restHintSeconds,
    required this.priorNotes,
    required this.onExerciseNotes,
    required this.weightUnit,
    required this.machineStarting,
    required this.onMachineStartingChanged,
    required this.onEditGoal,
    required this.dayExercises,
    required this.onInfo,
    required this.onSwap,
  });

  final JournalExercise exercise;
  final bool showMove;
  final bool canMoveUp;
  final bool canMoveDown;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final Map<String, TextEditingController> reps;
  final Map<String, TextEditingController> weights;
  final Map<String, TextEditingController> durations;
  final Map<String, TextEditingController> calories;
  final Future<void> Function(String setId, String reps) onReps;
  final Future<void> Function(String setId, String weight) onWeight;
  final Future<void> Function(String setId, String duration) onDuration;
  final Future<void> Function(String exerciseId, String calories) onCalories;
  final Future<void> Function(
    JournalExercise exercise,
    JournalSet set,
    bool checked,
  )
  onChecked;
  final Future<void> Function(JournalSet set, bool warmup) onWarmup;
  final bool showDifficulty;
  final Future<void> Function(JournalSet set, String? difficulty) onDifficulty;
  final VoidCallback onAddSet;
  final Future<void> Function(String setId) onDeleteSet;
  final VoidCallback onDeleteExercise;
  final Future<void> Function(JournalExercise exercise, JournalSet set, int index)
  onEditWeight;
  final Future<void> Function(JournalExercise exercise, JournalSet set, int index)
  onEditReps;
  final VoidCallback onStartTimer;
  final VoidCallback onEditTimer;
  final int? restHintSeconds;
  final List<PriorExerciseNote> priorNotes;
  final Future<void> Function(String exerciseId, String notes) onExerciseNotes;
  final WeightUnit weightUnit;
  final Map<VariableMachineKind, TextEditingController> machineStarting;
  final Future<void> Function(VariableMachineKind kind, String display)
  onMachineStartingChanged;
  final VoidCallback onEditGoal;
  final List<JournalExercise> dayExercises;
  final VoidCallback onInfo;
  final VoidCallback onSwap;

  bool get _cardio => exercise.isCardio && !exercise.isCircuit;

  bool get _canOfferSupersetLink =>
      _canLinkExerciseWithNext(exercise, dayExercises) ||
      _linkPartnersFor(exercise, dayExercises).isNotEmpty;
  VariableMachineKind? get _machineKind => variableMachineKindForExercise(
    libraryId: exercise.libraryId,
    name: exercise.name,
  );
  bool get _core => exercise.isCore && !_cardio && !exercise.isCircuit;

  Widget _setFields(BuildContext context, int index, JournalSet set, String label) {
    final repsController = reps[set.id];
    final weightController = weights[set.id];
    if (repsController == null || weightController == null) {
      return const SizedBox.shrink();
    }
    final kind = _machineKind;
    final starting = kind == null ? null : machineStarting[kind];
    return _SetFields(
      key: ValueKey(set.id),
      index: index,
      label: label,
      set: set,
      reps: repsController,
      weight: weightController,
      duration: _core ? durations[set.id] : null,
      onDuration: (value) => onDuration(set.id, value),
      onChecked: (value) => onChecked(exercise, set, value),
      onWarmup: (value) => onWarmup(set, value),
      showDifficulty: showDifficulty,
      onDifficulty: (value) => onDifficulty(set, value),
      onDelete: () => onDeleteSet(set.id),
      onEditWeight: () => onEditWeight(exercise, set, index),
      onEditReps: () => onEditReps(exercise, set, index),
      restTimerSlot: _restTimerSlot(context, primary: index == 0),
      machineKind: kind,
      machineStarting: starting,
      weightUnit: weightUnit,
    );
  }

  Widget _restTimerSlot(BuildContext context, {bool primary = true}) {
    final hint = restHintSeconds;
    if (hint != null && primary) {
      return Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(
          formatRestClock(hint),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: hint == 0 ? context.liftBig.success : context.liftBig.foreground,
          ),
        ),
      );
    }
    return _TimerButton(onStart: onStartTimer, onEdit: onEditTimer);
  }

  @override
  Widget build(BuildContext context) {
    final badge = supersetBadge(exercise);
    final goal = _goalLine(exercise);
    final caloriesController = calories[exercise.id];
    final allDone = exerciseAllSetsChecked(exercise);
    return Container(
      margin: EdgeInsets.only(bottom: showMove ? 12 : 8),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: context.liftBig.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: allDone ? context.liftBig.success : context.liftBig.border,
          width: allDone ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  exercise.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (showMove)
                _MoveButtons(
                  canMoveUp: canMoveUp,
                  canMoveDown: canMoveDown,
                  onMoveUp: onMoveUp,
                  onMoveDown: onMoveDown,
                ),
              IconButton(
                tooltip: 'Exercise info',
                onPressed: onInfo,
                visualDensity: VisualDensity.compact,
                color: context.liftBig.primary,
                icon: const Icon(Icons.info_outline, size: 20),
              ),
              IconButton(
                tooltip: 'Swap lift',
                onPressed: onSwap,
                visualDensity: VisualDensity.compact,
                color: context.liftBig.primary,
                icon: const Icon(Icons.swap_horiz, size: 20),
              ),
              IconButton(
                tooltip: 'Delete exercise',
                onPressed: onDeleteExercise,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          if (badge != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                badge,
                style:  TextStyle(
                  color: context.liftBig.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          if (!_cardio && !exercise.isCircuit)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(child: _goalRichText(context, exercise, weightUnit)),
                  _GoalEditPencil(tooltip: 'Edit goal', onPressed: onEditGoal),
                ],
              ),
            )
          else if (goal != null || _canOfferSupersetLink)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  if (goal != null)
                    Expanded(
                      child: Text(
                        goal,
                        style: TextStyle(color: context.liftBig.muted),
                      ),
                    )
                  else
                    const Spacer(),
                  if (_canOfferSupersetLink)
                    _GoalEditPencil(
                      tooltip: 'Link exercises',
                      onPressed: onEditGoal,
                    ),
                ],
              ),
            ),
          _ExerciseNotesPanel(
            exercise: exercise,
            priorNotes: priorNotes,
            onSave: onExerciseNotes,
          ),
          if (_machineKind != null &&
              !_cardio &&
              !exercise.isCircuit &&
              machineStarting[_machineKind] != null)
            MachineStartingWeightField(
              kind: _machineKind!,
              controller: machineStarting[_machineKind]!,
              unit: weightUnit,
              onChanged: (value) =>
                  onMachineStartingChanged(_machineKind!, value),
            ),
          if (_cardio)
            _CardioFields(
              exercise: exercise,
              reps: reps,
              weights: weights,
              calories: caloriesController,
              onReps: onReps,
              onWeight: onWeight,
              onCalories: (value) => onCalories(exercise.id, value),
              onChecked: (set, value) => onChecked(exercise, set, value),
              restTimerSlot: _restTimerSlot(context),
            )
          else if (exercise.isCircuit)
            for (var index = 0; index < exercise.sets.length; index++)
              _CircuitRow(
                exercise: exercise,
                index: index,
                set: exercise.sets[index],
                onChecked: (value) =>
                    onChecked(exercise, exercise.sets[index], value),
                showDifficulty: showDifficulty,
                onDifficulty: (value) =>
                    onDifficulty(exercise.sets[index], value),
                restTimerSlot: _restTimerSlot(context, primary: index == 0),
                onDelete: () => onDeleteSet(exercise.sets[index].id),
              )
          else ...[
            if (exercise.sets.isEmpty)
               Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'No sets.',
                  style: TextStyle(color: context.liftBig.muted),
                ),
              )
            else
              _SetColumnHeader(showTime: _core),
            for (final row in _labeledSets(exercise))
              _setFields(context, row.$1, row.$2, row.$3),
          ],
          if (!_cardio)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onAddSet,
                icon: const Icon(Icons.add),
                label: Text(exercise.isCircuit ? 'Add round' : 'Add set'),
              ),
            ),
        ],
      ),
    );
  }
}

class _MoveButtons extends StatelessWidget {
  const _MoveButtons({
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  final bool canMoveUp;
  final bool canMoveDown;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Move up',
          onPressed: canMoveUp ? onMoveUp : null,
          icon: const Icon(Icons.arrow_upward),
        ),
        IconButton(
          tooltip: 'Move down',
          onPressed: canMoveDown ? onMoveDown : null,
          icon: const Icon(Icons.arrow_downward),
        ),
      ],
    );
  }
}

class _CardioFields extends StatelessWidget {
  const _CardioFields({
    required this.exercise,
    required this.reps,
    required this.weights,
    required this.calories,
    required this.onReps,
    required this.onWeight,
    required this.onCalories,
    required this.onChecked,
    required this.restTimerSlot,
  });

  final JournalExercise exercise;
  final Map<String, TextEditingController> reps;
  final Map<String, TextEditingController> weights;
  final TextEditingController? calories;
  final Future<void> Function(String setId, String reps) onReps;
  final Future<void> Function(String setId, String weight) onWeight;
  final ValueChanged<String> onCalories;
  final void Function(JournalSet set, bool checked) onChecked;
  final Widget restTimerSlot;

  @override
  Widget build(BuildContext context) {
    final set = exercise.sets.isEmpty ? null : exercise.sets.first;
    if (set == null) {
      return  Text(
        'No activity logged.',
        style: TextStyle(color: context.liftBig.muted),
      );
    }
    final duration = reps[set.id];
    final distance = weights[set.id];
    final showDistance =
        (exercise.targetDistance?.trim().isNotEmpty ?? false) ||
        set.weight.trim().isNotEmpty;
    if (duration == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: duration,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Duration (minutes)',
            hintText: exercise.targetDuration?.trim().isNotEmpty == true
                ? '${exercise.targetDuration} min goal'
                : 'Minutes',
          ),
          onChanged: (value) => onReps(set.id, value),
        ),
        if (showDistance && distance != null) ...[
          const SizedBox(height: 8),
          TextField(
            controller: distance,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Distance',
              hintText: exercise.targetDistance?.trim().isNotEmpty == true
                  ? exercise.targetDistance
                  : 'Optional',
            ),
            onChanged: (value) => onWeight(set.id, value),
          ),
        ],
        if (calories != null) ...[
          const SizedBox(height: 8),
          TextField(
            controller: calories,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Calories (optional)',
            ),
            onChanged: onCalories,
          ),
        ],
        const SizedBox(height: 4),
        Row(
          children: [
            Checkbox(
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              value: set.checked,
              onChanged: (value) => onChecked(set, value ?? false),
            ),
            const Text('Done'),
            restTimerSlot,
          ],
        ),
      ],
    );
  }
}

class _CircuitRow extends StatelessWidget {
  const _CircuitRow({
    required this.exercise,
    required this.index,
    required this.set,
    required this.onChecked,
    required this.showDifficulty,
    required this.onDifficulty,
    required this.restTimerSlot,
    required this.onDelete,
  });

  final JournalExercise exercise;
  final int index;
  final JournalSet set;
  final ValueChanged<bool> onChecked;
  final bool showDifficulty;
  final ValueChanged<String?> onDifficulty;
  final Widget restTimerSlot;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Checkbox(
            visualDensity: VisualDensity.compact,
            value: set.checked,
            onChanged: (value) => onChecked(value ?? false),
          ),
          const Text('Done'),
          if (showDifficulty)
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: _DifficultyPicker(
                  value: set.difficulty,
                  onChanged: onDifficulty,
                ),
              ),
            ),
          restTimerSlot,
          Expanded(
            child: Text(
              'Set ${index + 1}  ${_circuitLine(exercise, set)}',
              style:  TextStyle(color: context.liftBig.foreground),
            ),
          ),
          IconButton(
            tooltip: 'Delete set',
            onPressed: onDelete,
            icon:  Icon(Icons.close, size: 16, color: context.liftBig.muted),
          ),
        ],
      ),
    );
  }
}

class _GoalEditPencil extends StatelessWidget {
  const _GoalEditPencil({required this.tooltip, required this.onPressed});

  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints.tightFor(width: 22, height: 22),
        icon:  Icon(Icons.edit, size: 14, color: context.liftBig.muted),
      ),
    );
  }
}

class _TimerButton extends StatelessWidget {
  const _TimerButton({required this.onStart, required this.onEdit});

  final VoidCallback onStart;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Start rest. Hold to change the time.',
      onPressed: onStart,
      onLongPress: onEdit,
      visualDensity: VisualDensity.compact,
      icon: const Icon(Icons.timer_outlined, size: 20),
    );
  }
}

class _DifficultyPicker extends StatelessWidget {
  const _DifficultyPicker({required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String?> onChanged;

  static const _choices = <(String, String)>[
    (setDifficultyEasy, 'Easy'),
    (setDifficultyModerate, 'Mod'),
    (setDifficultyDifficult, 'Hard'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final choice in _choices)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: _DifficultyChoice(
              label: choice.$2,
              stored: choice.$1,
              selected: value == choice.$1,
              onTap: () => onChanged(value == choice.$1 ? null : choice.$1),
            ),
          ),
      ],
    );
  }
}

class _DifficultyChoice extends StatelessWidget {
  const _DifficultyChoice({
    required this.label,
    required this.stored,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String stored;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: stored,
      child: Material(
        color: selected ? context.liftBig.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 44, minHeight: 40),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: selected ? context.liftBig.primary : context.liftBig.border,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? context.liftBig.foreground : context.liftBig.muted,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SetFields extends StatelessWidget {
  const _SetFields({
    super.key,
    required this.index,
    required this.label,
    required this.set,
    required this.reps,
    required this.weight,
    required this.onDuration,
    required this.onChecked,
    required this.onWarmup,
    required this.showDifficulty,
    required this.onDifficulty,
    required this.onDelete,
    required this.onEditWeight,
    required this.onEditReps,
    required this.restTimerSlot,
    this.duration,
    this.machineKind,
    this.machineStarting,
    this.weightUnit = WeightUnit.lb,
  });

  final int index;
  final String label;
  final JournalSet set;
  final TextEditingController reps;
  final TextEditingController weight;
  final TextEditingController? duration;
  final ValueChanged<String> onDuration;
  final ValueChanged<bool> onChecked;
  final ValueChanged<bool> onWarmup;
  final bool showDifficulty;
  final ValueChanged<String?> onDifficulty;
  final VoidCallback onDelete;
  final VoidCallback onEditWeight;
  final VoidCallback onEditReps;
  final Widget restTimerSlot;
  final VariableMachineKind? machineKind;
  final TextEditingController? machineStarting;
  final WeightUnit weightUnit;

  @override
  Widget build(BuildContext context) {
    final labelColor = set.isWarmup
        ? const Color(0xFFFBBF24)
        : context.liftBig.muted;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: set.isWarmup ? const Color(0x1AF59E0B) : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: set.isWarmup ? 4 : 0),
              child: Row(
                children: [
                  SizedBox(
                    width: 64,
                    child: InkWell(
                      onTap: () => onWarmup(!set.isWarmup),
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: labelColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: _LoggedValueBox(
                      controller: weight,
                      hint: weightUnit == WeightUnit.kg ? 'kg' : 'lb',
                      onTap: onEditWeight,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: _LoggedValueBox(
                      controller: reps,
                      hint: 'Reps',
                      onTap: onEditReps,
                    ),
                  ),
                  if (duration != null) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: duration,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        style:  TextStyle(
                          fontSize: 16,
                          color: context.liftBig.foreground,
                        ),
                        cursorColor: context.liftBig.primary,
                        decoration: _setInputDecoration(context, 'Sec'),
                        onChanged: onDuration,
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: IconButton(
                      tooltip: 'Delete set',
                      onPressed: onDelete,
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints.tightFor(
                        width: 32,
                        height: 32,
                      ),
                      icon:  Icon(
                        Icons.close,
                        size: 16,
                        color: context.liftBig.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (machineKind != null && machineStarting != null)
            MachineSetPlateHint(
              kind: machineKind!,
              startingController: machineStarting!,
              weightController: weight,
              unit: weightUnit,
            ),
          Row(
            children: [
              const SizedBox(width: 72),
              Expanded(
                flex: 5,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Transform.scale(
                      scale: 1.2,
                      child: Checkbox(
                        visualDensity: VisualDensity.standard,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        value: set.checked,
                        onChanged: (value) => onChecked(value ?? false),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => onChecked(!set.checked),
                      child: const Text(
                        'Done',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                    restTimerSlot,
                  ],
                ),
              ),
              if (duration != null) ...[
                const SizedBox(width: 8),
                const Expanded(child: SizedBox.shrink()),
              ],
              const SizedBox(width: 40),
            ],
          ),
          if (showDifficulty)
            Align(
              alignment: Alignment.center,
              child: _DifficultyPicker(
                value: set.difficulty,
                onChanged: onDifficulty,
              ),
            ),
        ],
      ),
    );
  }
}

class _SetColumnHeader extends StatelessWidget {
  const _SetColumnHeader({this.showTime = false});

  final bool showTime;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      color: context.liftBig.muted,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const SizedBox(width: 64),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text('WEIGHT', textAlign: TextAlign.center, style: style),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text('REPS', textAlign: TextAlign.center, style: style),
          ),
          if (showTime) ...[
            const SizedBox(width: 8),
            Expanded(
              child: Text('TIME', textAlign: TextAlign.center, style: style),
            ),
          ],
          const SizedBox(width: 8),
          const SizedBox(width: 32),
        ],
      ),
    );
  }
}

List<(int, JournalSet, String)> _labeledSets(JournalExercise exercise) {
  final rows = <(int, JournalSet, String)>[];
  var working = 0;
  for (var index = 0; index < exercise.sets.length; index++) {
    final set = exercise.sets[index];
    if (set.isWarmup) {
      rows.add((index, set, 'Warmup'));
    } else {
      working += 1;
      rows.add((index, set, 'Set $working'));
    }
  }
  return rows;
}

Widget _goalRichText(
  BuildContext context,
  JournalExercise exercise,
  WeightUnit unit,
) {
  final reps =
      exerciseGoalReps(
        targetReps: exercise.targetReps,
        storedReps: [for (final set in exercise.sets) set.reps],
      ) ??
      '';
  final storedWeight = exercise.targetWeight?.trim() ?? '';
  final weight = storedWeight.isEmpty ? '' : storedLbsToDisplay(storedWeight, unit);
  final time = exercise.targetTimeSeconds?.trim() ?? '';
  final count = '${exercise.sets.length}';
  final muted =  TextStyle(color: context.liftBig.muted);
  final number =  TextStyle(
    color: context.liftBig.foreground,
    fontWeight: FontWeight.w800,
  );
  final spans = <InlineSpan>[
    TextSpan(text: 'Goal', style: muted),
  ];
  if (exercise.sets.isNotEmpty || reps.isNotEmpty || weight.isNotEmpty) {
    spans.add(TextSpan(text: ': ', style: muted));
    spans.add(TextSpan(text: count, style: number));
    if (reps.isNotEmpty) {
      spans.add(TextSpan(text: ' × ', style: muted));
      spans.add(TextSpan(text: reps, style: number));
    } else {
      spans.add(TextSpan(text: ' sets', style: muted));
    }
    if (weight.isNotEmpty) {
      spans.add(TextSpan(text: ' @ ', style: muted));
      spans.add(TextSpan(text: weight, style: number));
      spans.add(
        TextSpan(text: unit == WeightUnit.kg ? ' kg' : ' lb', style: muted),
      );
    }
    if (time.isNotEmpty) {
      spans.add(TextSpan(text: ' · $time sec', style: muted));
    }
  }
  return Text.rich(TextSpan(children: spans));
}

String _suggestionDetail(LibraryLift lift) {
  final groups = [
    for (final group in lift.muscleGroups) muscleGroupLabels[group] ?? group,
  ];
  if (groups.isEmpty) return lift.equipment;
  return groups.join(', ');
}

String? _goalLine(JournalExercise exercise) {
  if (exercise.isCardio && !exercise.isCircuit) {
    final parts = <String>[];
    final duration = exercise.targetDuration?.trim() ?? '';
    final distance = exercise.targetDistance?.trim() ?? '';
    if (duration.isNotEmpty) parts.add('$duration min');
    if (distance.isNotEmpty) parts.add(distance);
    if (parts.isEmpty) return 'No duration goal';
    return 'Goal: ${parts.join(' · ')}';
  }
  if (exercise.isCircuit) return null;
  final reps = exercise.targetReps?.trim() ?? '';
  final weight = exercise.targetWeight?.trim() ?? '';
  final time = exercise.targetTimeSeconds?.trim() ?? '';
  if (reps.isEmpty && weight.isEmpty && time.isEmpty) {
    return exercise.isCore ? 'Log reps and/or time per set' : null;
  }
  final count = exercise.sets.length;
  final mid = reps.isNotEmpty ? '$count × $reps' : '$count sets';
  final tail = weight.isNotEmpty ? ' @ $weight lb' : '';
  final timeTail = time.isNotEmpty ? ' · $time sec' : '';
  return 'Goal: $mid$tail$timeTail';
}

String _circuitLine(JournalExercise exercise, JournalSet set) {
  final reps = set.reps.trim().isNotEmpty
      ? set.reps.trim()
      : (exercise.targetReps ?? '').trim();
  final weight = set.weight.trim().isNotEmpty
      ? set.weight.trim()
      : (exercise.targetWeight ?? '').trim();
  final seconds = int.tryParse((set.durationSeconds ?? '').trim());
  final String effort;
  if (seconds != null && seconds > 0) {
    effort = seconds < 60
        ? '$seconds sec'
        : seconds % 60 == 0
        ? '${seconds ~/ 60} min'
        : _clock(seconds);
  } else if (reps.isEmpty) {
    effort = 'AMRAP';
  } else {
    effort = '$reps reps';
  }
  if (weight.isEmpty) return effort;
  return '$effort @ $weight lb';
}

InputDecoration _setInputDecoration(BuildContext context, String hint) {
  const radius = BorderRadius.all(Radius.circular(8));
  final idle = OutlineInputBorder(
    borderRadius: radius,
    borderSide: BorderSide(color: context.liftBig.border),
  );
  final focused = OutlineInputBorder(
    borderRadius: radius,
    borderSide: BorderSide(color: context.liftBig.primary),
  );
  return InputDecoration(
    hintText: hint,
    hintStyle:  TextStyle(color: context.liftBig.muted, fontSize: 16),
    isDense: true,
    filled: true,
    fillColor: context.liftBig.cardInner,
    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    border: idle,
    enabledBorder: idle,
    disabledBorder: idle,
    errorBorder: idle,
    focusedBorder: focused,
    focusedErrorBorder: focused,
  );
}

class _AddExerciseCard extends StatefulWidget {
  const _AddExerciseCard({
    required this.name,
    required this.error,
    required this.onAddNamed,
    required this.onAddCustom,
  });

  final TextEditingController name;
  final String? error;
  final void Function(
    String name, {
    String? libraryId,
    bool isCardio,
    bool isCore,
  })
  onAddNamed;
  final VoidCallback onAddCustom;

  @override
  State<_AddExerciseCard> createState() => _AddExerciseCardState();
}

class _AddExerciseCardState extends State<_AddExerciseCard> {
  List<LibraryLift> _catalog = const [];

  @override
  void initState() {
    super.initState();
    widget.name.addListener(_onName);
    _loadCatalog();
  }

  @override
  void didUpdateWidget(covariant _AddExerciseCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.name != widget.name) {
      oldWidget.name.removeListener(_onName);
      widget.name.addListener(_onName);
    }
  }

  @override
  void dispose() {
    widget.name.removeListener(_onName);
    super.dispose();
  }

  void _onName() {
    if (mounted) setState(() {});
  }

  Future<void> _loadCatalog() async {
    try {
      final catalog = await LiftBigCatalog.load();
      if (!mounted) return;
      setState(() => _catalog = catalog.lifts);
    } catch (_) {}
  }

  List<LibraryLift> get _suggestions =>
      rankExerciseSuggestions(_catalog, widget.name.text).take(40).toList();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Add exercise',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
             Text(
              'Pick a common lift or type a name.',
              style: TextStyle(color: context.liftBig.muted),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final lift in commonLifts)
                  ActionChip(
                    label: Text(lift),
                    backgroundColor: context.liftBig.cardInner,
                    side:  BorderSide(color: context.liftBig.border),
                    labelStyle:  TextStyle(
                      color: context.liftBig.foreground,
                    ),
                    onPressed: () => widget.onAddNamed(lift),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: widget.name,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'Exercise name',
                    ),
                    onSubmitted: (_) => widget.onAddCustom(),
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: FilledButton(
                    onPressed: widget.onAddCustom,
                    child: const Text('Add'),
                  ),
                ),
              ],
            ),
            if (widget.error != null) ...[
              const SizedBox(height: 8),
              Text(
                widget.error!,
                style:  TextStyle(color: context.liftBig.primary),
              ),
            ],
            if (_suggestions.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 220,
                child: ListView(
                  children: [
                    for (final lift in _suggestions)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(lift.name),
                        subtitle: Text(
                          _suggestionDetail(lift),
                          style:  TextStyle(color: context.liftBig.muted),
                        ),
                        onTap: () => widget.onAddNamed(
                          lift.name,
                          libraryId: lift.id,
                          isCardio: lift.isCardio,
                          isCore: lift.isCore,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ExerciseNotesPanel extends StatefulWidget {
  const _ExerciseNotesPanel({
    required this.exercise,
    required this.priorNotes,
    required this.onSave,
  });

  final JournalExercise exercise;
  final List<PriorExerciseNote> priorNotes;
  final Future<void> Function(String exerciseId, String notes) onSave;

  @override
  State<_ExerciseNotesPanel> createState() => _ExerciseNotesPanelState();
}

class _ExerciseNotesPanelState extends State<_ExerciseNotesPanel> {
  var _expanded = false;
  late TextEditingController _draft;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _draft = TextEditingController(text: widget.exercise.notes ?? '');
  }

  @override
  void didUpdateWidget(covariant _ExerciseNotesPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exercise.id != widget.exercise.id) {
      _draft.text = widget.exercise.notes ?? '';
      _expanded = false;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _draft.dispose();
    super.dispose();
  }

  void _scheduleSave() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      widget.onSave(widget.exercise.id, _draft.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    final priorCount = widget.priorNotes.length;
    final subtitle = priorCount == 0
        ? 'Notes for this lift'
        : '$priorCount earlier ${priorCount == 1 ? 'note' : 'notes'}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: context.liftBig.background,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Notes',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            subtitle,
                            style:  TextStyle(
                              color: context.liftBig.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      _expanded
                          ? Icons.expand_less
                          : Icons.expand_more,
                      color: context.liftBig.muted,
                    ),
                  ],
                ),
                if (_expanded) ...[
                  const SizedBox(height: 8),
                  if (widget.priorNotes.isNotEmpty) ...[
                    const Text(
                      'Earlier sessions',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    for (final note in widget.priorNotes)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              formatDisplayDate(note.dateKey),
                              style:  TextStyle(
                                color: context.liftBig.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(note.text),
                          ],
                        ),
                      ),
                  ],
                  TextField(
                    controller: _draft,
                    minLines: 2,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'This session',
                      hintText: 'Notes for this lift today…',
                      alignLabelWithHint: true,
                    ),
                    onChanged: (_) => _scheduleSave(),
                    onEditingComplete: () =>
                        widget.onSave(widget.exercise.id, _draft.text),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _clock(int seconds) => formatRestClock(seconds);

class _LoggedValueBox extends StatelessWidget {
  const _LoggedValueBox({
    required this.controller,
    required this.hint,
    required this.onTap,
  });

  final TextEditingController controller;
  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final empty = value.text.trim().isEmpty;
        return Material(
          color: context.liftBig.cardInner,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              alignment: Alignment.center,
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: context.liftBig.border),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  empty ? hint : value.text.trim(),
                  maxLines: 1,
                  softWrap: false,
                  style: TextStyle(
                    fontSize: 16,
                    color: empty ? context.liftBig.muted : context.liftBig.foreground,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

bool _canLinkExerciseWithNext(
  JournalExercise exercise,
  List<JournalExercise> dayExercises,
) {
  if (exerciseInSuperset(exercise)) return false;
  final index = dayExercises.indexWhere((item) => item.id == exercise.id);
  if (index < 0 || index + 1 >= dayExercises.length) return false;
  return !exerciseInSuperset(dayExercises[index + 1]);
}

List<JournalExercise> _linkPartnersFor(
  JournalExercise exercise,
  List<JournalExercise> dayExercises,
) {
  if (exerciseInSuperset(exercise)) return const [];
  return [
    for (final item in dayExercises)
      if (item.id != exercise.id && !exerciseInSuperset(item)) item,
  ];
}

class _GoalEdit {
  const _GoalEdit({
    required this.setCount,
    required this.reps,
    required this.weight,
    this.revert = false,
    this.linkNext = false,
    this.linkPartner = false,
  });

  final int setCount;
  final String reps;
  final String weight;
  final bool revert;
  final bool linkNext;
  final bool linkPartner;
}

class _GoalEditDialog extends StatefulWidget {
  const _GoalEditDialog({
    required this.exercise,
    required this.unit,
    required this.editGoal,
    required this.showLinkWithNext,
    required this.showLinkWithPartner,
  });

  final JournalExercise exercise;
  final WeightUnit unit;
  final bool editGoal;
  final bool showLinkWithNext;
  final bool showLinkWithPartner;

  @override
  State<_GoalEditDialog> createState() => _GoalEditDialogState();
}

class _GoalEditDialogState extends State<_GoalEditDialog> {
  late final TextEditingController _sets;
  late final TextEditingController _reps;
  late final TextEditingController _weight;

  @override
  void initState() {
    super.initState();
    _sets = TextEditingController(text: '${widget.exercise.sets.length}');
    _reps = TextEditingController(text: widget.exercise.targetReps ?? '');
    final stored = widget.exercise.targetWeight ?? '';
    _weight = TextEditingController(
      text: stored.trim().isEmpty ? '' : storedLbsToDisplay(stored, widget.unit),
    );
  }

  @override
  void dispose() {
    _sets.dispose();
    _reps.dispose();
    _weight.dispose();
    super.dispose();
  }

  bool get _canRevert => widget.exercise.prescribedSetCount != null;

  void _popLink({required bool next}) {
    Navigator.of(context).pop(
      _GoalEdit(
        setCount: 0,
        reps: '',
        weight: '',
        linkNext: next,
        linkPartner: !next,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unit = widget.unit == WeightUnit.kg ? 'kg' : 'lb';
    final links = widget.showLinkWithNext || widget.showLinkWithPartner;
    return AlertDialog(
      title: Text(widget.exercise.name),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.editGoal) ...[
            TextField(
              controller: _sets,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Sets'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reps,
              decoration: const InputDecoration(labelText: 'Reps'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _weight,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: 'Weight ($unit)'),
            ),
          ],
          if (widget.editGoal && links) const SizedBox(height: 8),
          if (links)
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 4,
                children: [
                  if (widget.showLinkWithNext)
                    TextButton(
                      onPressed: () => _popLink(next: true),
                      child: const Text('Link with next'),
                    ),
                  if (widget.showLinkWithPartner)
                    TextButton(
                      onPressed: () => _popLink(next: false),
                      child: const Text('Link with another'),
                    ),
                ],
              ),
            ),
        ],
      ),
      actions: [
        if (widget.editGoal && _canRevert)
          TextButton(
            onPressed: () => Navigator.of(context).pop(
              const _GoalEdit(setCount: 0, reps: '', weight: '', revert: true),
            ),
            child: const Text('Revert to plan'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        if (widget.editGoal)
          FilledButton(
            onPressed: () {
              final count =
                  int.tryParse(_sets.text.trim()) ?? widget.exercise.sets.length;
              Navigator.of(context).pop(
                _GoalEdit(
                  setCount: count,
                  reps: _reps.text.trim(),
                  weight: _weight.text.trim(),
                ),
              );
            },
            child: const Text('Save'),
          ),
      ],
    );
  }
}

Future<int?> showDayRestPicker(
  BuildContext context, {
  required int initialSeconds,
}) {
  final choices = dayRestChoices();
  var selected = initialSeconds;
  if (!choices.contains(selected)) {
    selected = choices.reduce(
      (best, seconds) =>
          (seconds - initialSeconds).abs() < (best - initialSeconds).abs()
          ? seconds
          : best,
    );
  }
  return showLiftBigSheet<int>(
    context,
    builder: (context) {
      return ListView(
        shrinkWrap: true,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              'Rest',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ),
          for (final seconds in choices)
            ListTile(
              title: Text(formatRestDurationLabel(seconds)),
              selected: seconds == selected,
              onTap: () {
                liftBigSelectionHaptic();
                Navigator.of(context).pop(seconds);
              },
            ),
        ],
      );
    },
  );
}
