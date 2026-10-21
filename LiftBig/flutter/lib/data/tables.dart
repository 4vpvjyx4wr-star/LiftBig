import 'package:drift/drift.dart';

/// One journal day, keyed by local `YYYY-MM-DD`.
@TableIndex(name: 'idx_days_updated_at', columns: {#updatedAt})
class Days extends Table {
  TextColumn get dateKey => text()();
  TextColumn get notes => text().nullable()();
  BoolColumn get isRestDay => boolean().withDefault(const Constant(false))();

  /// Session that was logged. Backup JSON still calls this `planName`.
  TextColumn get workoutName => text().nullable()();

  /// Plan (Vue folder) that [workoutName] belonged to.
  TextColumn get planName => text().nullable()();

  /// Coaching notes from that workout. Backup JSON still calls this `planNotes`.
  TextColumn get workoutNotes => text().nullable()();

  /// ISO-8601 timestamp. The newer value wins when merging with Firestore.
  TextColumn get updatedAt => text()();

  /// Rest length chosen on this day. Null uses the settings average.
  IntColumn get chosenRestSeconds => integer().nullable()();

  /// Active energy Apple Health or Health Connect reported for this day.
  RealColumn get healthEnergyKcal => real().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {dateKey};
}

/// Exercises belonging to a day. Sets are separate rows.
@TableIndex(name: 'idx_exercises_date_key', columns: {#dateKey})
class Exercises extends Table {
  TextColumn get id => text()();
  TextColumn get dateKey =>
      text().references(Days, #dateKey, onDelete: KeyAction.cascade)();
  IntColumn get sortOrder => integer()();
  TextColumn get name => text()();
  TextColumn get libraryId => text().nullable()();
  TextColumn get notes => text().nullable()();
  BoolColumn get isCircuit => boolean().withDefault(const Constant(false))();
  BoolColumn get isCardio => boolean().withDefault(const Constant(false))();
  BoolColumn get isCore => boolean().withDefault(const Constant(false))();
  TextColumn get targetDuration => text().nullable()();
  TextColumn get targetTimeSeconds => text().nullable()();
  TextColumn get targetDistance => text().nullable()();
  TextColumn get loggedCalories => text().nullable()();
  TextColumn get targetReps => text().nullable()();
  TextColumn get targetWeight => text().nullable()();
  TextColumn get supersetGroupId => text().nullable()();
  TextColumn get supersetLabel => text().nullable()();
  IntColumn get supersetOrder => integer().nullable()();

  /// JSON array of library ids.
  TextColumn get preferredSwapLibraryIds => text().nullable()();
  IntColumn get targetRestSeconds => integer().nullable()();

  /// Snapshot of the plan goal before the first pencil edit on this day.
  TextColumn get prescribedReps => text().nullable()();
  TextColumn get prescribedWeight => text().nullable()();
  IntColumn get prescribedSetCount => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Logged sets. [weight] is pounds, kept as text to match the Vue backup.
@TableIndex(name: 'idx_sets_exercise_id', columns: {#exerciseId})
class WorkoutSets extends Table {
  @override
  String get tableName => 'sets';

  TextColumn get id => text()();
  TextColumn get exerciseId =>
      text().references(Exercises, #id, onDelete: KeyAction.cascade)();
  IntColumn get sortOrder => integer()();
  TextColumn get reps => text().withDefault(const Constant(''))();
  TextColumn get weight => text().withDefault(const Constant(''))();
  TextColumn get durationSeconds => text().nullable()();
  BoolColumn get checked => boolean().withDefault(const Constant(false))();
  BoolColumn get isWarmup => boolean().withDefault(const Constant(false))();

  /// Easy, Moderate, or Difficult. Null until the lifter rates the set.
  TextColumn get difficulty => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Small local key/value store for the sync switch, templates, and settings.
class LocalSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}
