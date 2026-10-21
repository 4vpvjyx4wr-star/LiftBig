// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $DaysTable extends Days with TableInfo<$DaysTable, Day> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DaysTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dateKeyMeta = const VerificationMeta(
    'dateKey',
  );
  @override
  late final GeneratedColumn<String> dateKey = GeneratedColumn<String>(
    'date_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isRestDayMeta = const VerificationMeta(
    'isRestDay',
  );
  @override
  late final GeneratedColumn<bool> isRestDay = GeneratedColumn<bool>(
    'is_rest_day',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_rest_day" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _workoutNameMeta = const VerificationMeta(
    'workoutName',
  );
  @override
  late final GeneratedColumn<String> workoutName = GeneratedColumn<String>(
    'workout_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _planNameMeta = const VerificationMeta(
    'planName',
  );
  @override
  late final GeneratedColumn<String> planName = GeneratedColumn<String>(
    'plan_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _workoutNotesMeta = const VerificationMeta(
    'workoutNotes',
  );
  @override
  late final GeneratedColumn<String> workoutNotes = GeneratedColumn<String>(
    'workout_notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _chosenRestSecondsMeta = const VerificationMeta(
    'chosenRestSeconds',
  );
  @override
  late final GeneratedColumn<int> chosenRestSeconds = GeneratedColumn<int>(
    'chosen_rest_seconds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _healthEnergyKcalMeta = const VerificationMeta(
    'healthEnergyKcal',
  );
  @override
  late final GeneratedColumn<double> healthEnergyKcal = GeneratedColumn<double>(
    'health_energy_kcal',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    dateKey,
    notes,
    isRestDay,
    workoutName,
    planName,
    workoutNotes,
    updatedAt,
    chosenRestSeconds,
    healthEnergyKcal,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'days';
  @override
  VerificationContext validateIntegrity(
    Insertable<Day> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('date_key')) {
      context.handle(
        _dateKeyMeta,
        dateKey.isAcceptableOrUnknown(data['date_key']!, _dateKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_dateKeyMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('is_rest_day')) {
      context.handle(
        _isRestDayMeta,
        isRestDay.isAcceptableOrUnknown(data['is_rest_day']!, _isRestDayMeta),
      );
    }
    if (data.containsKey('workout_name')) {
      context.handle(
        _workoutNameMeta,
        workoutName.isAcceptableOrUnknown(
          data['workout_name']!,
          _workoutNameMeta,
        ),
      );
    }
    if (data.containsKey('plan_name')) {
      context.handle(
        _planNameMeta,
        planName.isAcceptableOrUnknown(data['plan_name']!, _planNameMeta),
      );
    }
    if (data.containsKey('workout_notes')) {
      context.handle(
        _workoutNotesMeta,
        workoutNotes.isAcceptableOrUnknown(
          data['workout_notes']!,
          _workoutNotesMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('chosen_rest_seconds')) {
      context.handle(
        _chosenRestSecondsMeta,
        chosenRestSeconds.isAcceptableOrUnknown(
          data['chosen_rest_seconds']!,
          _chosenRestSecondsMeta,
        ),
      );
    }
    if (data.containsKey('health_energy_kcal')) {
      context.handle(
        _healthEnergyKcalMeta,
        healthEnergyKcal.isAcceptableOrUnknown(
          data['health_energy_kcal']!,
          _healthEnergyKcalMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {dateKey};
  @override
  Day map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Day(
      dateKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date_key'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      isRestDay: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_rest_day'],
      )!,
      workoutName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workout_name'],
      ),
      planName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plan_name'],
      ),
      workoutNotes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workout_notes'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      chosenRestSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chosen_rest_seconds'],
      ),
      healthEnergyKcal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}health_energy_kcal'],
      ),
    );
  }

  @override
  $DaysTable createAlias(String alias) {
    return $DaysTable(attachedDatabase, alias);
  }
}

class Day extends DataClass implements Insertable<Day> {
  final String dateKey;
  final String? notes;
  final bool isRestDay;

  /// Session that was logged. Backup JSON still calls this `planName`.
  final String? workoutName;

  /// Plan (Vue folder) that [workoutName] belonged to.
  final String? planName;

  /// Coaching notes from that workout. Backup JSON still calls this `planNotes`.
  final String? workoutNotes;

  /// ISO-8601 timestamp. The newer value wins when merging with Firestore.
  final String updatedAt;

  /// Rest length chosen on this day. Null uses the settings average.
  final int? chosenRestSeconds;

  /// Active energy Apple Health or Health Connect reported for this day.
  final double? healthEnergyKcal;
  const Day({
    required this.dateKey,
    this.notes,
    required this.isRestDay,
    this.workoutName,
    this.planName,
    this.workoutNotes,
    required this.updatedAt,
    this.chosenRestSeconds,
    this.healthEnergyKcal,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['date_key'] = Variable<String>(dateKey);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['is_rest_day'] = Variable<bool>(isRestDay);
    if (!nullToAbsent || workoutName != null) {
      map['workout_name'] = Variable<String>(workoutName);
    }
    if (!nullToAbsent || planName != null) {
      map['plan_name'] = Variable<String>(planName);
    }
    if (!nullToAbsent || workoutNotes != null) {
      map['workout_notes'] = Variable<String>(workoutNotes);
    }
    map['updated_at'] = Variable<String>(updatedAt);
    if (!nullToAbsent || chosenRestSeconds != null) {
      map['chosen_rest_seconds'] = Variable<int>(chosenRestSeconds);
    }
    if (!nullToAbsent || healthEnergyKcal != null) {
      map['health_energy_kcal'] = Variable<double>(healthEnergyKcal);
    }
    return map;
  }

  DaysCompanion toCompanion(bool nullToAbsent) {
    return DaysCompanion(
      dateKey: Value(dateKey),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      isRestDay: Value(isRestDay),
      workoutName: workoutName == null && nullToAbsent
          ? const Value.absent()
          : Value(workoutName),
      planName: planName == null && nullToAbsent
          ? const Value.absent()
          : Value(planName),
      workoutNotes: workoutNotes == null && nullToAbsent
          ? const Value.absent()
          : Value(workoutNotes),
      updatedAt: Value(updatedAt),
      chosenRestSeconds: chosenRestSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(chosenRestSeconds),
      healthEnergyKcal: healthEnergyKcal == null && nullToAbsent
          ? const Value.absent()
          : Value(healthEnergyKcal),
    );
  }

  factory Day.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Day(
      dateKey: serializer.fromJson<String>(json['dateKey']),
      notes: serializer.fromJson<String?>(json['notes']),
      isRestDay: serializer.fromJson<bool>(json['isRestDay']),
      workoutName: serializer.fromJson<String?>(json['workoutName']),
      planName: serializer.fromJson<String?>(json['planName']),
      workoutNotes: serializer.fromJson<String?>(json['workoutNotes']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      chosenRestSeconds: serializer.fromJson<int?>(json['chosenRestSeconds']),
      healthEnergyKcal: serializer.fromJson<double?>(json['healthEnergyKcal']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'dateKey': serializer.toJson<String>(dateKey),
      'notes': serializer.toJson<String?>(notes),
      'isRestDay': serializer.toJson<bool>(isRestDay),
      'workoutName': serializer.toJson<String?>(workoutName),
      'planName': serializer.toJson<String?>(planName),
      'workoutNotes': serializer.toJson<String?>(workoutNotes),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'chosenRestSeconds': serializer.toJson<int?>(chosenRestSeconds),
      'healthEnergyKcal': serializer.toJson<double?>(healthEnergyKcal),
    };
  }

  Day copyWith({
    String? dateKey,
    Value<String?> notes = const Value.absent(),
    bool? isRestDay,
    Value<String?> workoutName = const Value.absent(),
    Value<String?> planName = const Value.absent(),
    Value<String?> workoutNotes = const Value.absent(),
    String? updatedAt,
    Value<int?> chosenRestSeconds = const Value.absent(),
    Value<double?> healthEnergyKcal = const Value.absent(),
  }) => Day(
    dateKey: dateKey ?? this.dateKey,
    notes: notes.present ? notes.value : this.notes,
    isRestDay: isRestDay ?? this.isRestDay,
    workoutName: workoutName.present ? workoutName.value : this.workoutName,
    planName: planName.present ? planName.value : this.planName,
    workoutNotes: workoutNotes.present ? workoutNotes.value : this.workoutNotes,
    updatedAt: updatedAt ?? this.updatedAt,
    chosenRestSeconds: chosenRestSeconds.present
        ? chosenRestSeconds.value
        : this.chosenRestSeconds,
    healthEnergyKcal: healthEnergyKcal.present
        ? healthEnergyKcal.value
        : this.healthEnergyKcal,
  );
  Day copyWithCompanion(DaysCompanion data) {
    return Day(
      dateKey: data.dateKey.present ? data.dateKey.value : this.dateKey,
      notes: data.notes.present ? data.notes.value : this.notes,
      isRestDay: data.isRestDay.present ? data.isRestDay.value : this.isRestDay,
      workoutName: data.workoutName.present
          ? data.workoutName.value
          : this.workoutName,
      planName: data.planName.present ? data.planName.value : this.planName,
      workoutNotes: data.workoutNotes.present
          ? data.workoutNotes.value
          : this.workoutNotes,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      chosenRestSeconds: data.chosenRestSeconds.present
          ? data.chosenRestSeconds.value
          : this.chosenRestSeconds,
      healthEnergyKcal: data.healthEnergyKcal.present
          ? data.healthEnergyKcal.value
          : this.healthEnergyKcal,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Day(')
          ..write('dateKey: $dateKey, ')
          ..write('notes: $notes, ')
          ..write('isRestDay: $isRestDay, ')
          ..write('workoutName: $workoutName, ')
          ..write('planName: $planName, ')
          ..write('workoutNotes: $workoutNotes, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('chosenRestSeconds: $chosenRestSeconds, ')
          ..write('healthEnergyKcal: $healthEnergyKcal')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    dateKey,
    notes,
    isRestDay,
    workoutName,
    planName,
    workoutNotes,
    updatedAt,
    chosenRestSeconds,
    healthEnergyKcal,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Day &&
          other.dateKey == this.dateKey &&
          other.notes == this.notes &&
          other.isRestDay == this.isRestDay &&
          other.workoutName == this.workoutName &&
          other.planName == this.planName &&
          other.workoutNotes == this.workoutNotes &&
          other.updatedAt == this.updatedAt &&
          other.chosenRestSeconds == this.chosenRestSeconds &&
          other.healthEnergyKcal == this.healthEnergyKcal);
}

class DaysCompanion extends UpdateCompanion<Day> {
  final Value<String> dateKey;
  final Value<String?> notes;
  final Value<bool> isRestDay;
  final Value<String?> workoutName;
  final Value<String?> planName;
  final Value<String?> workoutNotes;
  final Value<String> updatedAt;
  final Value<int?> chosenRestSeconds;
  final Value<double?> healthEnergyKcal;
  final Value<int> rowid;
  const DaysCompanion({
    this.dateKey = const Value.absent(),
    this.notes = const Value.absent(),
    this.isRestDay = const Value.absent(),
    this.workoutName = const Value.absent(),
    this.planName = const Value.absent(),
    this.workoutNotes = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.chosenRestSeconds = const Value.absent(),
    this.healthEnergyKcal = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DaysCompanion.insert({
    required String dateKey,
    this.notes = const Value.absent(),
    this.isRestDay = const Value.absent(),
    this.workoutName = const Value.absent(),
    this.planName = const Value.absent(),
    this.workoutNotes = const Value.absent(),
    required String updatedAt,
    this.chosenRestSeconds = const Value.absent(),
    this.healthEnergyKcal = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : dateKey = Value(dateKey),
       updatedAt = Value(updatedAt);
  static Insertable<Day> custom({
    Expression<String>? dateKey,
    Expression<String>? notes,
    Expression<bool>? isRestDay,
    Expression<String>? workoutName,
    Expression<String>? planName,
    Expression<String>? workoutNotes,
    Expression<String>? updatedAt,
    Expression<int>? chosenRestSeconds,
    Expression<double>? healthEnergyKcal,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (dateKey != null) 'date_key': dateKey,
      if (notes != null) 'notes': notes,
      if (isRestDay != null) 'is_rest_day': isRestDay,
      if (workoutName != null) 'workout_name': workoutName,
      if (planName != null) 'plan_name': planName,
      if (workoutNotes != null) 'workout_notes': workoutNotes,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (chosenRestSeconds != null) 'chosen_rest_seconds': chosenRestSeconds,
      if (healthEnergyKcal != null) 'health_energy_kcal': healthEnergyKcal,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DaysCompanion copyWith({
    Value<String>? dateKey,
    Value<String?>? notes,
    Value<bool>? isRestDay,
    Value<String?>? workoutName,
    Value<String?>? planName,
    Value<String?>? workoutNotes,
    Value<String>? updatedAt,
    Value<int?>? chosenRestSeconds,
    Value<double?>? healthEnergyKcal,
    Value<int>? rowid,
  }) {
    return DaysCompanion(
      dateKey: dateKey ?? this.dateKey,
      notes: notes ?? this.notes,
      isRestDay: isRestDay ?? this.isRestDay,
      workoutName: workoutName ?? this.workoutName,
      planName: planName ?? this.planName,
      workoutNotes: workoutNotes ?? this.workoutNotes,
      updatedAt: updatedAt ?? this.updatedAt,
      chosenRestSeconds: chosenRestSeconds ?? this.chosenRestSeconds,
      healthEnergyKcal: healthEnergyKcal ?? this.healthEnergyKcal,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (dateKey.present) {
      map['date_key'] = Variable<String>(dateKey.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (isRestDay.present) {
      map['is_rest_day'] = Variable<bool>(isRestDay.value);
    }
    if (workoutName.present) {
      map['workout_name'] = Variable<String>(workoutName.value);
    }
    if (planName.present) {
      map['plan_name'] = Variable<String>(planName.value);
    }
    if (workoutNotes.present) {
      map['workout_notes'] = Variable<String>(workoutNotes.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (chosenRestSeconds.present) {
      map['chosen_rest_seconds'] = Variable<int>(chosenRestSeconds.value);
    }
    if (healthEnergyKcal.present) {
      map['health_energy_kcal'] = Variable<double>(healthEnergyKcal.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DaysCompanion(')
          ..write('dateKey: $dateKey, ')
          ..write('notes: $notes, ')
          ..write('isRestDay: $isRestDay, ')
          ..write('workoutName: $workoutName, ')
          ..write('planName: $planName, ')
          ..write('workoutNotes: $workoutNotes, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('chosenRestSeconds: $chosenRestSeconds, ')
          ..write('healthEnergyKcal: $healthEnergyKcal, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExercisesTable extends Exercises
    with TableInfo<$ExercisesTable, Exercise> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExercisesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateKeyMeta = const VerificationMeta(
    'dateKey',
  );
  @override
  late final GeneratedColumn<String> dateKey = GeneratedColumn<String>(
    'date_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES days (date_key) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _libraryIdMeta = const VerificationMeta(
    'libraryId',
  );
  @override
  late final GeneratedColumn<String> libraryId = GeneratedColumn<String>(
    'library_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isCircuitMeta = const VerificationMeta(
    'isCircuit',
  );
  @override
  late final GeneratedColumn<bool> isCircuit = GeneratedColumn<bool>(
    'is_circuit',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_circuit" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isCardioMeta = const VerificationMeta(
    'isCardio',
  );
  @override
  late final GeneratedColumn<bool> isCardio = GeneratedColumn<bool>(
    'is_cardio',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_cardio" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isCoreMeta = const VerificationMeta('isCore');
  @override
  late final GeneratedColumn<bool> isCore = GeneratedColumn<bool>(
    'is_core',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_core" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _targetDurationMeta = const VerificationMeta(
    'targetDuration',
  );
  @override
  late final GeneratedColumn<String> targetDuration = GeneratedColumn<String>(
    'target_duration',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _targetTimeSecondsMeta = const VerificationMeta(
    'targetTimeSeconds',
  );
  @override
  late final GeneratedColumn<String> targetTimeSeconds =
      GeneratedColumn<String>(
        'target_time_seconds',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _targetDistanceMeta = const VerificationMeta(
    'targetDistance',
  );
  @override
  late final GeneratedColumn<String> targetDistance = GeneratedColumn<String>(
    'target_distance',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _loggedCaloriesMeta = const VerificationMeta(
    'loggedCalories',
  );
  @override
  late final GeneratedColumn<String> loggedCalories = GeneratedColumn<String>(
    'logged_calories',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _targetRepsMeta = const VerificationMeta(
    'targetReps',
  );
  @override
  late final GeneratedColumn<String> targetReps = GeneratedColumn<String>(
    'target_reps',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _targetWeightMeta = const VerificationMeta(
    'targetWeight',
  );
  @override
  late final GeneratedColumn<String> targetWeight = GeneratedColumn<String>(
    'target_weight',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _supersetGroupIdMeta = const VerificationMeta(
    'supersetGroupId',
  );
  @override
  late final GeneratedColumn<String> supersetGroupId = GeneratedColumn<String>(
    'superset_group_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _supersetLabelMeta = const VerificationMeta(
    'supersetLabel',
  );
  @override
  late final GeneratedColumn<String> supersetLabel = GeneratedColumn<String>(
    'superset_label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _supersetOrderMeta = const VerificationMeta(
    'supersetOrder',
  );
  @override
  late final GeneratedColumn<int> supersetOrder = GeneratedColumn<int>(
    'superset_order',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _preferredSwapLibraryIdsMeta =
      const VerificationMeta('preferredSwapLibraryIds');
  @override
  late final GeneratedColumn<String> preferredSwapLibraryIds =
      GeneratedColumn<String>(
        'preferred_swap_library_ids',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _targetRestSecondsMeta = const VerificationMeta(
    'targetRestSeconds',
  );
  @override
  late final GeneratedColumn<int> targetRestSeconds = GeneratedColumn<int>(
    'target_rest_seconds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _prescribedRepsMeta = const VerificationMeta(
    'prescribedReps',
  );
  @override
  late final GeneratedColumn<String> prescribedReps = GeneratedColumn<String>(
    'prescribed_reps',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _prescribedWeightMeta = const VerificationMeta(
    'prescribedWeight',
  );
  @override
  late final GeneratedColumn<String> prescribedWeight = GeneratedColumn<String>(
    'prescribed_weight',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _prescribedSetCountMeta =
      const VerificationMeta('prescribedSetCount');
  @override
  late final GeneratedColumn<int> prescribedSetCount = GeneratedColumn<int>(
    'prescribed_set_count',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    dateKey,
    sortOrder,
    name,
    libraryId,
    notes,
    isCircuit,
    isCardio,
    isCore,
    targetDuration,
    targetTimeSeconds,
    targetDistance,
    loggedCalories,
    targetReps,
    targetWeight,
    supersetGroupId,
    supersetLabel,
    supersetOrder,
    preferredSwapLibraryIds,
    targetRestSeconds,
    prescribedReps,
    prescribedWeight,
    prescribedSetCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exercises';
  @override
  VerificationContext validateIntegrity(
    Insertable<Exercise> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('date_key')) {
      context.handle(
        _dateKeyMeta,
        dateKey.isAcceptableOrUnknown(data['date_key']!, _dateKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_dateKeyMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('library_id')) {
      context.handle(
        _libraryIdMeta,
        libraryId.isAcceptableOrUnknown(data['library_id']!, _libraryIdMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('is_circuit')) {
      context.handle(
        _isCircuitMeta,
        isCircuit.isAcceptableOrUnknown(data['is_circuit']!, _isCircuitMeta),
      );
    }
    if (data.containsKey('is_cardio')) {
      context.handle(
        _isCardioMeta,
        isCardio.isAcceptableOrUnknown(data['is_cardio']!, _isCardioMeta),
      );
    }
    if (data.containsKey('is_core')) {
      context.handle(
        _isCoreMeta,
        isCore.isAcceptableOrUnknown(data['is_core']!, _isCoreMeta),
      );
    }
    if (data.containsKey('target_duration')) {
      context.handle(
        _targetDurationMeta,
        targetDuration.isAcceptableOrUnknown(
          data['target_duration']!,
          _targetDurationMeta,
        ),
      );
    }
    if (data.containsKey('target_time_seconds')) {
      context.handle(
        _targetTimeSecondsMeta,
        targetTimeSeconds.isAcceptableOrUnknown(
          data['target_time_seconds']!,
          _targetTimeSecondsMeta,
        ),
      );
    }
    if (data.containsKey('target_distance')) {
      context.handle(
        _targetDistanceMeta,
        targetDistance.isAcceptableOrUnknown(
          data['target_distance']!,
          _targetDistanceMeta,
        ),
      );
    }
    if (data.containsKey('logged_calories')) {
      context.handle(
        _loggedCaloriesMeta,
        loggedCalories.isAcceptableOrUnknown(
          data['logged_calories']!,
          _loggedCaloriesMeta,
        ),
      );
    }
    if (data.containsKey('target_reps')) {
      context.handle(
        _targetRepsMeta,
        targetReps.isAcceptableOrUnknown(data['target_reps']!, _targetRepsMeta),
      );
    }
    if (data.containsKey('target_weight')) {
      context.handle(
        _targetWeightMeta,
        targetWeight.isAcceptableOrUnknown(
          data['target_weight']!,
          _targetWeightMeta,
        ),
      );
    }
    if (data.containsKey('superset_group_id')) {
      context.handle(
        _supersetGroupIdMeta,
        supersetGroupId.isAcceptableOrUnknown(
          data['superset_group_id']!,
          _supersetGroupIdMeta,
        ),
      );
    }
    if (data.containsKey('superset_label')) {
      context.handle(
        _supersetLabelMeta,
        supersetLabel.isAcceptableOrUnknown(
          data['superset_label']!,
          _supersetLabelMeta,
        ),
      );
    }
    if (data.containsKey('superset_order')) {
      context.handle(
        _supersetOrderMeta,
        supersetOrder.isAcceptableOrUnknown(
          data['superset_order']!,
          _supersetOrderMeta,
        ),
      );
    }
    if (data.containsKey('preferred_swap_library_ids')) {
      context.handle(
        _preferredSwapLibraryIdsMeta,
        preferredSwapLibraryIds.isAcceptableOrUnknown(
          data['preferred_swap_library_ids']!,
          _preferredSwapLibraryIdsMeta,
        ),
      );
    }
    if (data.containsKey('target_rest_seconds')) {
      context.handle(
        _targetRestSecondsMeta,
        targetRestSeconds.isAcceptableOrUnknown(
          data['target_rest_seconds']!,
          _targetRestSecondsMeta,
        ),
      );
    }
    if (data.containsKey('prescribed_reps')) {
      context.handle(
        _prescribedRepsMeta,
        prescribedReps.isAcceptableOrUnknown(
          data['prescribed_reps']!,
          _prescribedRepsMeta,
        ),
      );
    }
    if (data.containsKey('prescribed_weight')) {
      context.handle(
        _prescribedWeightMeta,
        prescribedWeight.isAcceptableOrUnknown(
          data['prescribed_weight']!,
          _prescribedWeightMeta,
        ),
      );
    }
    if (data.containsKey('prescribed_set_count')) {
      context.handle(
        _prescribedSetCountMeta,
        prescribedSetCount.isAcceptableOrUnknown(
          data['prescribed_set_count']!,
          _prescribedSetCountMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Exercise map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Exercise(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      dateKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date_key'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      libraryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}library_id'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      isCircuit: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_circuit'],
      )!,
      isCardio: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_cardio'],
      )!,
      isCore: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_core'],
      )!,
      targetDuration: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_duration'],
      ),
      targetTimeSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_time_seconds'],
      ),
      targetDistance: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_distance'],
      ),
      loggedCalories: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}logged_calories'],
      ),
      targetReps: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_reps'],
      ),
      targetWeight: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_weight'],
      ),
      supersetGroupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}superset_group_id'],
      ),
      supersetLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}superset_label'],
      ),
      supersetOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}superset_order'],
      ),
      preferredSwapLibraryIds: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}preferred_swap_library_ids'],
      ),
      targetRestSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_rest_seconds'],
      ),
      prescribedReps: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prescribed_reps'],
      ),
      prescribedWeight: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prescribed_weight'],
      ),
      prescribedSetCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}prescribed_set_count'],
      ),
    );
  }

  @override
  $ExercisesTable createAlias(String alias) {
    return $ExercisesTable(attachedDatabase, alias);
  }
}

class Exercise extends DataClass implements Insertable<Exercise> {
  final String id;
  final String dateKey;
  final int sortOrder;
  final String name;
  final String? libraryId;
  final String? notes;
  final bool isCircuit;
  final bool isCardio;
  final bool isCore;
  final String? targetDuration;
  final String? targetTimeSeconds;
  final String? targetDistance;
  final String? loggedCalories;
  final String? targetReps;
  final String? targetWeight;
  final String? supersetGroupId;
  final String? supersetLabel;
  final int? supersetOrder;

  /// JSON array of library ids.
  final String? preferredSwapLibraryIds;
  final int? targetRestSeconds;

  /// Snapshot of the plan goal before the first pencil edit on this day.
  final String? prescribedReps;
  final String? prescribedWeight;
  final int? prescribedSetCount;
  const Exercise({
    required this.id,
    required this.dateKey,
    required this.sortOrder,
    required this.name,
    this.libraryId,
    this.notes,
    required this.isCircuit,
    required this.isCardio,
    required this.isCore,
    this.targetDuration,
    this.targetTimeSeconds,
    this.targetDistance,
    this.loggedCalories,
    this.targetReps,
    this.targetWeight,
    this.supersetGroupId,
    this.supersetLabel,
    this.supersetOrder,
    this.preferredSwapLibraryIds,
    this.targetRestSeconds,
    this.prescribedReps,
    this.prescribedWeight,
    this.prescribedSetCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['date_key'] = Variable<String>(dateKey);
    map['sort_order'] = Variable<int>(sortOrder);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || libraryId != null) {
      map['library_id'] = Variable<String>(libraryId);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['is_circuit'] = Variable<bool>(isCircuit);
    map['is_cardio'] = Variable<bool>(isCardio);
    map['is_core'] = Variable<bool>(isCore);
    if (!nullToAbsent || targetDuration != null) {
      map['target_duration'] = Variable<String>(targetDuration);
    }
    if (!nullToAbsent || targetTimeSeconds != null) {
      map['target_time_seconds'] = Variable<String>(targetTimeSeconds);
    }
    if (!nullToAbsent || targetDistance != null) {
      map['target_distance'] = Variable<String>(targetDistance);
    }
    if (!nullToAbsent || loggedCalories != null) {
      map['logged_calories'] = Variable<String>(loggedCalories);
    }
    if (!nullToAbsent || targetReps != null) {
      map['target_reps'] = Variable<String>(targetReps);
    }
    if (!nullToAbsent || targetWeight != null) {
      map['target_weight'] = Variable<String>(targetWeight);
    }
    if (!nullToAbsent || supersetGroupId != null) {
      map['superset_group_id'] = Variable<String>(supersetGroupId);
    }
    if (!nullToAbsent || supersetLabel != null) {
      map['superset_label'] = Variable<String>(supersetLabel);
    }
    if (!nullToAbsent || supersetOrder != null) {
      map['superset_order'] = Variable<int>(supersetOrder);
    }
    if (!nullToAbsent || preferredSwapLibraryIds != null) {
      map['preferred_swap_library_ids'] = Variable<String>(
        preferredSwapLibraryIds,
      );
    }
    if (!nullToAbsent || targetRestSeconds != null) {
      map['target_rest_seconds'] = Variable<int>(targetRestSeconds);
    }
    if (!nullToAbsent || prescribedReps != null) {
      map['prescribed_reps'] = Variable<String>(prescribedReps);
    }
    if (!nullToAbsent || prescribedWeight != null) {
      map['prescribed_weight'] = Variable<String>(prescribedWeight);
    }
    if (!nullToAbsent || prescribedSetCount != null) {
      map['prescribed_set_count'] = Variable<int>(prescribedSetCount);
    }
    return map;
  }

  ExercisesCompanion toCompanion(bool nullToAbsent) {
    return ExercisesCompanion(
      id: Value(id),
      dateKey: Value(dateKey),
      sortOrder: Value(sortOrder),
      name: Value(name),
      libraryId: libraryId == null && nullToAbsent
          ? const Value.absent()
          : Value(libraryId),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      isCircuit: Value(isCircuit),
      isCardio: Value(isCardio),
      isCore: Value(isCore),
      targetDuration: targetDuration == null && nullToAbsent
          ? const Value.absent()
          : Value(targetDuration),
      targetTimeSeconds: targetTimeSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(targetTimeSeconds),
      targetDistance: targetDistance == null && nullToAbsent
          ? const Value.absent()
          : Value(targetDistance),
      loggedCalories: loggedCalories == null && nullToAbsent
          ? const Value.absent()
          : Value(loggedCalories),
      targetReps: targetReps == null && nullToAbsent
          ? const Value.absent()
          : Value(targetReps),
      targetWeight: targetWeight == null && nullToAbsent
          ? const Value.absent()
          : Value(targetWeight),
      supersetGroupId: supersetGroupId == null && nullToAbsent
          ? const Value.absent()
          : Value(supersetGroupId),
      supersetLabel: supersetLabel == null && nullToAbsent
          ? const Value.absent()
          : Value(supersetLabel),
      supersetOrder: supersetOrder == null && nullToAbsent
          ? const Value.absent()
          : Value(supersetOrder),
      preferredSwapLibraryIds: preferredSwapLibraryIds == null && nullToAbsent
          ? const Value.absent()
          : Value(preferredSwapLibraryIds),
      targetRestSeconds: targetRestSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(targetRestSeconds),
      prescribedReps: prescribedReps == null && nullToAbsent
          ? const Value.absent()
          : Value(prescribedReps),
      prescribedWeight: prescribedWeight == null && nullToAbsent
          ? const Value.absent()
          : Value(prescribedWeight),
      prescribedSetCount: prescribedSetCount == null && nullToAbsent
          ? const Value.absent()
          : Value(prescribedSetCount),
    );
  }

  factory Exercise.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Exercise(
      id: serializer.fromJson<String>(json['id']),
      dateKey: serializer.fromJson<String>(json['dateKey']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      name: serializer.fromJson<String>(json['name']),
      libraryId: serializer.fromJson<String?>(json['libraryId']),
      notes: serializer.fromJson<String?>(json['notes']),
      isCircuit: serializer.fromJson<bool>(json['isCircuit']),
      isCardio: serializer.fromJson<bool>(json['isCardio']),
      isCore: serializer.fromJson<bool>(json['isCore']),
      targetDuration: serializer.fromJson<String?>(json['targetDuration']),
      targetTimeSeconds: serializer.fromJson<String?>(
        json['targetTimeSeconds'],
      ),
      targetDistance: serializer.fromJson<String?>(json['targetDistance']),
      loggedCalories: serializer.fromJson<String?>(json['loggedCalories']),
      targetReps: serializer.fromJson<String?>(json['targetReps']),
      targetWeight: serializer.fromJson<String?>(json['targetWeight']),
      supersetGroupId: serializer.fromJson<String?>(json['supersetGroupId']),
      supersetLabel: serializer.fromJson<String?>(json['supersetLabel']),
      supersetOrder: serializer.fromJson<int?>(json['supersetOrder']),
      preferredSwapLibraryIds: serializer.fromJson<String?>(
        json['preferredSwapLibraryIds'],
      ),
      targetRestSeconds: serializer.fromJson<int?>(json['targetRestSeconds']),
      prescribedReps: serializer.fromJson<String?>(json['prescribedReps']),
      prescribedWeight: serializer.fromJson<String?>(json['prescribedWeight']),
      prescribedSetCount: serializer.fromJson<int?>(json['prescribedSetCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'dateKey': serializer.toJson<String>(dateKey),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'name': serializer.toJson<String>(name),
      'libraryId': serializer.toJson<String?>(libraryId),
      'notes': serializer.toJson<String?>(notes),
      'isCircuit': serializer.toJson<bool>(isCircuit),
      'isCardio': serializer.toJson<bool>(isCardio),
      'isCore': serializer.toJson<bool>(isCore),
      'targetDuration': serializer.toJson<String?>(targetDuration),
      'targetTimeSeconds': serializer.toJson<String?>(targetTimeSeconds),
      'targetDistance': serializer.toJson<String?>(targetDistance),
      'loggedCalories': serializer.toJson<String?>(loggedCalories),
      'targetReps': serializer.toJson<String?>(targetReps),
      'targetWeight': serializer.toJson<String?>(targetWeight),
      'supersetGroupId': serializer.toJson<String?>(supersetGroupId),
      'supersetLabel': serializer.toJson<String?>(supersetLabel),
      'supersetOrder': serializer.toJson<int?>(supersetOrder),
      'preferredSwapLibraryIds': serializer.toJson<String?>(
        preferredSwapLibraryIds,
      ),
      'targetRestSeconds': serializer.toJson<int?>(targetRestSeconds),
      'prescribedReps': serializer.toJson<String?>(prescribedReps),
      'prescribedWeight': serializer.toJson<String?>(prescribedWeight),
      'prescribedSetCount': serializer.toJson<int?>(prescribedSetCount),
    };
  }

  Exercise copyWith({
    String? id,
    String? dateKey,
    int? sortOrder,
    String? name,
    Value<String?> libraryId = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    bool? isCircuit,
    bool? isCardio,
    bool? isCore,
    Value<String?> targetDuration = const Value.absent(),
    Value<String?> targetTimeSeconds = const Value.absent(),
    Value<String?> targetDistance = const Value.absent(),
    Value<String?> loggedCalories = const Value.absent(),
    Value<String?> targetReps = const Value.absent(),
    Value<String?> targetWeight = const Value.absent(),
    Value<String?> supersetGroupId = const Value.absent(),
    Value<String?> supersetLabel = const Value.absent(),
    Value<int?> supersetOrder = const Value.absent(),
    Value<String?> preferredSwapLibraryIds = const Value.absent(),
    Value<int?> targetRestSeconds = const Value.absent(),
    Value<String?> prescribedReps = const Value.absent(),
    Value<String?> prescribedWeight = const Value.absent(),
    Value<int?> prescribedSetCount = const Value.absent(),
  }) => Exercise(
    id: id ?? this.id,
    dateKey: dateKey ?? this.dateKey,
    sortOrder: sortOrder ?? this.sortOrder,
    name: name ?? this.name,
    libraryId: libraryId.present ? libraryId.value : this.libraryId,
    notes: notes.present ? notes.value : this.notes,
    isCircuit: isCircuit ?? this.isCircuit,
    isCardio: isCardio ?? this.isCardio,
    isCore: isCore ?? this.isCore,
    targetDuration: targetDuration.present
        ? targetDuration.value
        : this.targetDuration,
    targetTimeSeconds: targetTimeSeconds.present
        ? targetTimeSeconds.value
        : this.targetTimeSeconds,
    targetDistance: targetDistance.present
        ? targetDistance.value
        : this.targetDistance,
    loggedCalories: loggedCalories.present
        ? loggedCalories.value
        : this.loggedCalories,
    targetReps: targetReps.present ? targetReps.value : this.targetReps,
    targetWeight: targetWeight.present ? targetWeight.value : this.targetWeight,
    supersetGroupId: supersetGroupId.present
        ? supersetGroupId.value
        : this.supersetGroupId,
    supersetLabel: supersetLabel.present
        ? supersetLabel.value
        : this.supersetLabel,
    supersetOrder: supersetOrder.present
        ? supersetOrder.value
        : this.supersetOrder,
    preferredSwapLibraryIds: preferredSwapLibraryIds.present
        ? preferredSwapLibraryIds.value
        : this.preferredSwapLibraryIds,
    targetRestSeconds: targetRestSeconds.present
        ? targetRestSeconds.value
        : this.targetRestSeconds,
    prescribedReps: prescribedReps.present
        ? prescribedReps.value
        : this.prescribedReps,
    prescribedWeight: prescribedWeight.present
        ? prescribedWeight.value
        : this.prescribedWeight,
    prescribedSetCount: prescribedSetCount.present
        ? prescribedSetCount.value
        : this.prescribedSetCount,
  );
  Exercise copyWithCompanion(ExercisesCompanion data) {
    return Exercise(
      id: data.id.present ? data.id.value : this.id,
      dateKey: data.dateKey.present ? data.dateKey.value : this.dateKey,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      name: data.name.present ? data.name.value : this.name,
      libraryId: data.libraryId.present ? data.libraryId.value : this.libraryId,
      notes: data.notes.present ? data.notes.value : this.notes,
      isCircuit: data.isCircuit.present ? data.isCircuit.value : this.isCircuit,
      isCardio: data.isCardio.present ? data.isCardio.value : this.isCardio,
      isCore: data.isCore.present ? data.isCore.value : this.isCore,
      targetDuration: data.targetDuration.present
          ? data.targetDuration.value
          : this.targetDuration,
      targetTimeSeconds: data.targetTimeSeconds.present
          ? data.targetTimeSeconds.value
          : this.targetTimeSeconds,
      targetDistance: data.targetDistance.present
          ? data.targetDistance.value
          : this.targetDistance,
      loggedCalories: data.loggedCalories.present
          ? data.loggedCalories.value
          : this.loggedCalories,
      targetReps: data.targetReps.present
          ? data.targetReps.value
          : this.targetReps,
      targetWeight: data.targetWeight.present
          ? data.targetWeight.value
          : this.targetWeight,
      supersetGroupId: data.supersetGroupId.present
          ? data.supersetGroupId.value
          : this.supersetGroupId,
      supersetLabel: data.supersetLabel.present
          ? data.supersetLabel.value
          : this.supersetLabel,
      supersetOrder: data.supersetOrder.present
          ? data.supersetOrder.value
          : this.supersetOrder,
      preferredSwapLibraryIds: data.preferredSwapLibraryIds.present
          ? data.preferredSwapLibraryIds.value
          : this.preferredSwapLibraryIds,
      targetRestSeconds: data.targetRestSeconds.present
          ? data.targetRestSeconds.value
          : this.targetRestSeconds,
      prescribedReps: data.prescribedReps.present
          ? data.prescribedReps.value
          : this.prescribedReps,
      prescribedWeight: data.prescribedWeight.present
          ? data.prescribedWeight.value
          : this.prescribedWeight,
      prescribedSetCount: data.prescribedSetCount.present
          ? data.prescribedSetCount.value
          : this.prescribedSetCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Exercise(')
          ..write('id: $id, ')
          ..write('dateKey: $dateKey, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('name: $name, ')
          ..write('libraryId: $libraryId, ')
          ..write('notes: $notes, ')
          ..write('isCircuit: $isCircuit, ')
          ..write('isCardio: $isCardio, ')
          ..write('isCore: $isCore, ')
          ..write('targetDuration: $targetDuration, ')
          ..write('targetTimeSeconds: $targetTimeSeconds, ')
          ..write('targetDistance: $targetDistance, ')
          ..write('loggedCalories: $loggedCalories, ')
          ..write('targetReps: $targetReps, ')
          ..write('targetWeight: $targetWeight, ')
          ..write('supersetGroupId: $supersetGroupId, ')
          ..write('supersetLabel: $supersetLabel, ')
          ..write('supersetOrder: $supersetOrder, ')
          ..write('preferredSwapLibraryIds: $preferredSwapLibraryIds, ')
          ..write('targetRestSeconds: $targetRestSeconds, ')
          ..write('prescribedReps: $prescribedReps, ')
          ..write('prescribedWeight: $prescribedWeight, ')
          ..write('prescribedSetCount: $prescribedSetCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    dateKey,
    sortOrder,
    name,
    libraryId,
    notes,
    isCircuit,
    isCardio,
    isCore,
    targetDuration,
    targetTimeSeconds,
    targetDistance,
    loggedCalories,
    targetReps,
    targetWeight,
    supersetGroupId,
    supersetLabel,
    supersetOrder,
    preferredSwapLibraryIds,
    targetRestSeconds,
    prescribedReps,
    prescribedWeight,
    prescribedSetCount,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Exercise &&
          other.id == this.id &&
          other.dateKey == this.dateKey &&
          other.sortOrder == this.sortOrder &&
          other.name == this.name &&
          other.libraryId == this.libraryId &&
          other.notes == this.notes &&
          other.isCircuit == this.isCircuit &&
          other.isCardio == this.isCardio &&
          other.isCore == this.isCore &&
          other.targetDuration == this.targetDuration &&
          other.targetTimeSeconds == this.targetTimeSeconds &&
          other.targetDistance == this.targetDistance &&
          other.loggedCalories == this.loggedCalories &&
          other.targetReps == this.targetReps &&
          other.targetWeight == this.targetWeight &&
          other.supersetGroupId == this.supersetGroupId &&
          other.supersetLabel == this.supersetLabel &&
          other.supersetOrder == this.supersetOrder &&
          other.preferredSwapLibraryIds == this.preferredSwapLibraryIds &&
          other.targetRestSeconds == this.targetRestSeconds &&
          other.prescribedReps == this.prescribedReps &&
          other.prescribedWeight == this.prescribedWeight &&
          other.prescribedSetCount == this.prescribedSetCount);
}

class ExercisesCompanion extends UpdateCompanion<Exercise> {
  final Value<String> id;
  final Value<String> dateKey;
  final Value<int> sortOrder;
  final Value<String> name;
  final Value<String?> libraryId;
  final Value<String?> notes;
  final Value<bool> isCircuit;
  final Value<bool> isCardio;
  final Value<bool> isCore;
  final Value<String?> targetDuration;
  final Value<String?> targetTimeSeconds;
  final Value<String?> targetDistance;
  final Value<String?> loggedCalories;
  final Value<String?> targetReps;
  final Value<String?> targetWeight;
  final Value<String?> supersetGroupId;
  final Value<String?> supersetLabel;
  final Value<int?> supersetOrder;
  final Value<String?> preferredSwapLibraryIds;
  final Value<int?> targetRestSeconds;
  final Value<String?> prescribedReps;
  final Value<String?> prescribedWeight;
  final Value<int?> prescribedSetCount;
  final Value<int> rowid;
  const ExercisesCompanion({
    this.id = const Value.absent(),
    this.dateKey = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.name = const Value.absent(),
    this.libraryId = const Value.absent(),
    this.notes = const Value.absent(),
    this.isCircuit = const Value.absent(),
    this.isCardio = const Value.absent(),
    this.isCore = const Value.absent(),
    this.targetDuration = const Value.absent(),
    this.targetTimeSeconds = const Value.absent(),
    this.targetDistance = const Value.absent(),
    this.loggedCalories = const Value.absent(),
    this.targetReps = const Value.absent(),
    this.targetWeight = const Value.absent(),
    this.supersetGroupId = const Value.absent(),
    this.supersetLabel = const Value.absent(),
    this.supersetOrder = const Value.absent(),
    this.preferredSwapLibraryIds = const Value.absent(),
    this.targetRestSeconds = const Value.absent(),
    this.prescribedReps = const Value.absent(),
    this.prescribedWeight = const Value.absent(),
    this.prescribedSetCount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExercisesCompanion.insert({
    required String id,
    required String dateKey,
    required int sortOrder,
    required String name,
    this.libraryId = const Value.absent(),
    this.notes = const Value.absent(),
    this.isCircuit = const Value.absent(),
    this.isCardio = const Value.absent(),
    this.isCore = const Value.absent(),
    this.targetDuration = const Value.absent(),
    this.targetTimeSeconds = const Value.absent(),
    this.targetDistance = const Value.absent(),
    this.loggedCalories = const Value.absent(),
    this.targetReps = const Value.absent(),
    this.targetWeight = const Value.absent(),
    this.supersetGroupId = const Value.absent(),
    this.supersetLabel = const Value.absent(),
    this.supersetOrder = const Value.absent(),
    this.preferredSwapLibraryIds = const Value.absent(),
    this.targetRestSeconds = const Value.absent(),
    this.prescribedReps = const Value.absent(),
    this.prescribedWeight = const Value.absent(),
    this.prescribedSetCount = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       dateKey = Value(dateKey),
       sortOrder = Value(sortOrder),
       name = Value(name);
  static Insertable<Exercise> custom({
    Expression<String>? id,
    Expression<String>? dateKey,
    Expression<int>? sortOrder,
    Expression<String>? name,
    Expression<String>? libraryId,
    Expression<String>? notes,
    Expression<bool>? isCircuit,
    Expression<bool>? isCardio,
    Expression<bool>? isCore,
    Expression<String>? targetDuration,
    Expression<String>? targetTimeSeconds,
    Expression<String>? targetDistance,
    Expression<String>? loggedCalories,
    Expression<String>? targetReps,
    Expression<String>? targetWeight,
    Expression<String>? supersetGroupId,
    Expression<String>? supersetLabel,
    Expression<int>? supersetOrder,
    Expression<String>? preferredSwapLibraryIds,
    Expression<int>? targetRestSeconds,
    Expression<String>? prescribedReps,
    Expression<String>? prescribedWeight,
    Expression<int>? prescribedSetCount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (dateKey != null) 'date_key': dateKey,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (name != null) 'name': name,
      if (libraryId != null) 'library_id': libraryId,
      if (notes != null) 'notes': notes,
      if (isCircuit != null) 'is_circuit': isCircuit,
      if (isCardio != null) 'is_cardio': isCardio,
      if (isCore != null) 'is_core': isCore,
      if (targetDuration != null) 'target_duration': targetDuration,
      if (targetTimeSeconds != null) 'target_time_seconds': targetTimeSeconds,
      if (targetDistance != null) 'target_distance': targetDistance,
      if (loggedCalories != null) 'logged_calories': loggedCalories,
      if (targetReps != null) 'target_reps': targetReps,
      if (targetWeight != null) 'target_weight': targetWeight,
      if (supersetGroupId != null) 'superset_group_id': supersetGroupId,
      if (supersetLabel != null) 'superset_label': supersetLabel,
      if (supersetOrder != null) 'superset_order': supersetOrder,
      if (preferredSwapLibraryIds != null)
        'preferred_swap_library_ids': preferredSwapLibraryIds,
      if (targetRestSeconds != null) 'target_rest_seconds': targetRestSeconds,
      if (prescribedReps != null) 'prescribed_reps': prescribedReps,
      if (prescribedWeight != null) 'prescribed_weight': prescribedWeight,
      if (prescribedSetCount != null)
        'prescribed_set_count': prescribedSetCount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExercisesCompanion copyWith({
    Value<String>? id,
    Value<String>? dateKey,
    Value<int>? sortOrder,
    Value<String>? name,
    Value<String?>? libraryId,
    Value<String?>? notes,
    Value<bool>? isCircuit,
    Value<bool>? isCardio,
    Value<bool>? isCore,
    Value<String?>? targetDuration,
    Value<String?>? targetTimeSeconds,
    Value<String?>? targetDistance,
    Value<String?>? loggedCalories,
    Value<String?>? targetReps,
    Value<String?>? targetWeight,
    Value<String?>? supersetGroupId,
    Value<String?>? supersetLabel,
    Value<int?>? supersetOrder,
    Value<String?>? preferredSwapLibraryIds,
    Value<int?>? targetRestSeconds,
    Value<String?>? prescribedReps,
    Value<String?>? prescribedWeight,
    Value<int?>? prescribedSetCount,
    Value<int>? rowid,
  }) {
    return ExercisesCompanion(
      id: id ?? this.id,
      dateKey: dateKey ?? this.dateKey,
      sortOrder: sortOrder ?? this.sortOrder,
      name: name ?? this.name,
      libraryId: libraryId ?? this.libraryId,
      notes: notes ?? this.notes,
      isCircuit: isCircuit ?? this.isCircuit,
      isCardio: isCardio ?? this.isCardio,
      isCore: isCore ?? this.isCore,
      targetDuration: targetDuration ?? this.targetDuration,
      targetTimeSeconds: targetTimeSeconds ?? this.targetTimeSeconds,
      targetDistance: targetDistance ?? this.targetDistance,
      loggedCalories: loggedCalories ?? this.loggedCalories,
      targetReps: targetReps ?? this.targetReps,
      targetWeight: targetWeight ?? this.targetWeight,
      supersetGroupId: supersetGroupId ?? this.supersetGroupId,
      supersetLabel: supersetLabel ?? this.supersetLabel,
      supersetOrder: supersetOrder ?? this.supersetOrder,
      preferredSwapLibraryIds:
          preferredSwapLibraryIds ?? this.preferredSwapLibraryIds,
      targetRestSeconds: targetRestSeconds ?? this.targetRestSeconds,
      prescribedReps: prescribedReps ?? this.prescribedReps,
      prescribedWeight: prescribedWeight ?? this.prescribedWeight,
      prescribedSetCount: prescribedSetCount ?? this.prescribedSetCount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (dateKey.present) {
      map['date_key'] = Variable<String>(dateKey.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (libraryId.present) {
      map['library_id'] = Variable<String>(libraryId.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (isCircuit.present) {
      map['is_circuit'] = Variable<bool>(isCircuit.value);
    }
    if (isCardio.present) {
      map['is_cardio'] = Variable<bool>(isCardio.value);
    }
    if (isCore.present) {
      map['is_core'] = Variable<bool>(isCore.value);
    }
    if (targetDuration.present) {
      map['target_duration'] = Variable<String>(targetDuration.value);
    }
    if (targetTimeSeconds.present) {
      map['target_time_seconds'] = Variable<String>(targetTimeSeconds.value);
    }
    if (targetDistance.present) {
      map['target_distance'] = Variable<String>(targetDistance.value);
    }
    if (loggedCalories.present) {
      map['logged_calories'] = Variable<String>(loggedCalories.value);
    }
    if (targetReps.present) {
      map['target_reps'] = Variable<String>(targetReps.value);
    }
    if (targetWeight.present) {
      map['target_weight'] = Variable<String>(targetWeight.value);
    }
    if (supersetGroupId.present) {
      map['superset_group_id'] = Variable<String>(supersetGroupId.value);
    }
    if (supersetLabel.present) {
      map['superset_label'] = Variable<String>(supersetLabel.value);
    }
    if (supersetOrder.present) {
      map['superset_order'] = Variable<int>(supersetOrder.value);
    }
    if (preferredSwapLibraryIds.present) {
      map['preferred_swap_library_ids'] = Variable<String>(
        preferredSwapLibraryIds.value,
      );
    }
    if (targetRestSeconds.present) {
      map['target_rest_seconds'] = Variable<int>(targetRestSeconds.value);
    }
    if (prescribedReps.present) {
      map['prescribed_reps'] = Variable<String>(prescribedReps.value);
    }
    if (prescribedWeight.present) {
      map['prescribed_weight'] = Variable<String>(prescribedWeight.value);
    }
    if (prescribedSetCount.present) {
      map['prescribed_set_count'] = Variable<int>(prescribedSetCount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExercisesCompanion(')
          ..write('id: $id, ')
          ..write('dateKey: $dateKey, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('name: $name, ')
          ..write('libraryId: $libraryId, ')
          ..write('notes: $notes, ')
          ..write('isCircuit: $isCircuit, ')
          ..write('isCardio: $isCardio, ')
          ..write('isCore: $isCore, ')
          ..write('targetDuration: $targetDuration, ')
          ..write('targetTimeSeconds: $targetTimeSeconds, ')
          ..write('targetDistance: $targetDistance, ')
          ..write('loggedCalories: $loggedCalories, ')
          ..write('targetReps: $targetReps, ')
          ..write('targetWeight: $targetWeight, ')
          ..write('supersetGroupId: $supersetGroupId, ')
          ..write('supersetLabel: $supersetLabel, ')
          ..write('supersetOrder: $supersetOrder, ')
          ..write('preferredSwapLibraryIds: $preferredSwapLibraryIds, ')
          ..write('targetRestSeconds: $targetRestSeconds, ')
          ..write('prescribedReps: $prescribedReps, ')
          ..write('prescribedWeight: $prescribedWeight, ')
          ..write('prescribedSetCount: $prescribedSetCount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WorkoutSetsTable extends WorkoutSets
    with TableInfo<$WorkoutSetsTable, WorkoutSet> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkoutSetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _exerciseIdMeta = const VerificationMeta(
    'exerciseId',
  );
  @override
  late final GeneratedColumn<String> exerciseId = GeneratedColumn<String>(
    'exercise_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES exercises (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _repsMeta = const VerificationMeta('reps');
  @override
  late final GeneratedColumn<String> reps = GeneratedColumn<String>(
    'reps',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _weightMeta = const VerificationMeta('weight');
  @override
  late final GeneratedColumn<String> weight = GeneratedColumn<String>(
    'weight',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _durationSecondsMeta = const VerificationMeta(
    'durationSeconds',
  );
  @override
  late final GeneratedColumn<String> durationSeconds = GeneratedColumn<String>(
    'duration_seconds',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _checkedMeta = const VerificationMeta(
    'checked',
  );
  @override
  late final GeneratedColumn<bool> checked = GeneratedColumn<bool>(
    'checked',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("checked" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isWarmupMeta = const VerificationMeta(
    'isWarmup',
  );
  @override
  late final GeneratedColumn<bool> isWarmup = GeneratedColumn<bool>(
    'is_warmup',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_warmup" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _difficultyMeta = const VerificationMeta(
    'difficulty',
  );
  @override
  late final GeneratedColumn<String> difficulty = GeneratedColumn<String>(
    'difficulty',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    exerciseId,
    sortOrder,
    reps,
    weight,
    durationSeconds,
    checked,
    isWarmup,
    difficulty,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sets';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkoutSet> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('exercise_id')) {
      context.handle(
        _exerciseIdMeta,
        exerciseId.isAcceptableOrUnknown(data['exercise_id']!, _exerciseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('reps')) {
      context.handle(
        _repsMeta,
        reps.isAcceptableOrUnknown(data['reps']!, _repsMeta),
      );
    }
    if (data.containsKey('weight')) {
      context.handle(
        _weightMeta,
        weight.isAcceptableOrUnknown(data['weight']!, _weightMeta),
      );
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
        _durationSecondsMeta,
        durationSeconds.isAcceptableOrUnknown(
          data['duration_seconds']!,
          _durationSecondsMeta,
        ),
      );
    }
    if (data.containsKey('checked')) {
      context.handle(
        _checkedMeta,
        checked.isAcceptableOrUnknown(data['checked']!, _checkedMeta),
      );
    }
    if (data.containsKey('is_warmup')) {
      context.handle(
        _isWarmupMeta,
        isWarmup.isAcceptableOrUnknown(data['is_warmup']!, _isWarmupMeta),
      );
    }
    if (data.containsKey('difficulty')) {
      context.handle(
        _difficultyMeta,
        difficulty.isAcceptableOrUnknown(data['difficulty']!, _difficultyMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkoutSet map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkoutSet(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      exerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exercise_id'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      reps: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reps'],
      )!,
      weight: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}weight'],
      )!,
      durationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}duration_seconds'],
      ),
      checked: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}checked'],
      )!,
      isWarmup: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_warmup'],
      )!,
      difficulty: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}difficulty'],
      ),
    );
  }

  @override
  $WorkoutSetsTable createAlias(String alias) {
    return $WorkoutSetsTable(attachedDatabase, alias);
  }
}

class WorkoutSet extends DataClass implements Insertable<WorkoutSet> {
  final String id;
  final String exerciseId;
  final int sortOrder;
  final String reps;
  final String weight;
  final String? durationSeconds;
  final bool checked;
  final bool isWarmup;

  /// Easy, Moderate, or Difficult. Null until the lifter rates the set.
  final String? difficulty;
  const WorkoutSet({
    required this.id,
    required this.exerciseId,
    required this.sortOrder,
    required this.reps,
    required this.weight,
    this.durationSeconds,
    required this.checked,
    required this.isWarmup,
    this.difficulty,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['exercise_id'] = Variable<String>(exerciseId);
    map['sort_order'] = Variable<int>(sortOrder);
    map['reps'] = Variable<String>(reps);
    map['weight'] = Variable<String>(weight);
    if (!nullToAbsent || durationSeconds != null) {
      map['duration_seconds'] = Variable<String>(durationSeconds);
    }
    map['checked'] = Variable<bool>(checked);
    map['is_warmup'] = Variable<bool>(isWarmup);
    if (!nullToAbsent || difficulty != null) {
      map['difficulty'] = Variable<String>(difficulty);
    }
    return map;
  }

  WorkoutSetsCompanion toCompanion(bool nullToAbsent) {
    return WorkoutSetsCompanion(
      id: Value(id),
      exerciseId: Value(exerciseId),
      sortOrder: Value(sortOrder),
      reps: Value(reps),
      weight: Value(weight),
      durationSeconds: durationSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(durationSeconds),
      checked: Value(checked),
      isWarmup: Value(isWarmup),
      difficulty: difficulty == null && nullToAbsent
          ? const Value.absent()
          : Value(difficulty),
    );
  }

  factory WorkoutSet.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkoutSet(
      id: serializer.fromJson<String>(json['id']),
      exerciseId: serializer.fromJson<String>(json['exerciseId']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      reps: serializer.fromJson<String>(json['reps']),
      weight: serializer.fromJson<String>(json['weight']),
      durationSeconds: serializer.fromJson<String?>(json['durationSeconds']),
      checked: serializer.fromJson<bool>(json['checked']),
      isWarmup: serializer.fromJson<bool>(json['isWarmup']),
      difficulty: serializer.fromJson<String?>(json['difficulty']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'exerciseId': serializer.toJson<String>(exerciseId),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'reps': serializer.toJson<String>(reps),
      'weight': serializer.toJson<String>(weight),
      'durationSeconds': serializer.toJson<String?>(durationSeconds),
      'checked': serializer.toJson<bool>(checked),
      'isWarmup': serializer.toJson<bool>(isWarmup),
      'difficulty': serializer.toJson<String?>(difficulty),
    };
  }

  WorkoutSet copyWith({
    String? id,
    String? exerciseId,
    int? sortOrder,
    String? reps,
    String? weight,
    Value<String?> durationSeconds = const Value.absent(),
    bool? checked,
    bool? isWarmup,
    Value<String?> difficulty = const Value.absent(),
  }) => WorkoutSet(
    id: id ?? this.id,
    exerciseId: exerciseId ?? this.exerciseId,
    sortOrder: sortOrder ?? this.sortOrder,
    reps: reps ?? this.reps,
    weight: weight ?? this.weight,
    durationSeconds: durationSeconds.present
        ? durationSeconds.value
        : this.durationSeconds,
    checked: checked ?? this.checked,
    isWarmup: isWarmup ?? this.isWarmup,
    difficulty: difficulty.present ? difficulty.value : this.difficulty,
  );
  WorkoutSet copyWithCompanion(WorkoutSetsCompanion data) {
    return WorkoutSet(
      id: data.id.present ? data.id.value : this.id,
      exerciseId: data.exerciseId.present
          ? data.exerciseId.value
          : this.exerciseId,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      reps: data.reps.present ? data.reps.value : this.reps,
      weight: data.weight.present ? data.weight.value : this.weight,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      checked: data.checked.present ? data.checked.value : this.checked,
      isWarmup: data.isWarmup.present ? data.isWarmup.value : this.isWarmup,
      difficulty: data.difficulty.present
          ? data.difficulty.value
          : this.difficulty,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutSet(')
          ..write('id: $id, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('reps: $reps, ')
          ..write('weight: $weight, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('checked: $checked, ')
          ..write('isWarmup: $isWarmup, ')
          ..write('difficulty: $difficulty')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    exerciseId,
    sortOrder,
    reps,
    weight,
    durationSeconds,
    checked,
    isWarmup,
    difficulty,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkoutSet &&
          other.id == this.id &&
          other.exerciseId == this.exerciseId &&
          other.sortOrder == this.sortOrder &&
          other.reps == this.reps &&
          other.weight == this.weight &&
          other.durationSeconds == this.durationSeconds &&
          other.checked == this.checked &&
          other.isWarmup == this.isWarmup &&
          other.difficulty == this.difficulty);
}

class WorkoutSetsCompanion extends UpdateCompanion<WorkoutSet> {
  final Value<String> id;
  final Value<String> exerciseId;
  final Value<int> sortOrder;
  final Value<String> reps;
  final Value<String> weight;
  final Value<String?> durationSeconds;
  final Value<bool> checked;
  final Value<bool> isWarmup;
  final Value<String?> difficulty;
  final Value<int> rowid;
  const WorkoutSetsCompanion({
    this.id = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.reps = const Value.absent(),
    this.weight = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.checked = const Value.absent(),
    this.isWarmup = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkoutSetsCompanion.insert({
    required String id,
    required String exerciseId,
    required int sortOrder,
    this.reps = const Value.absent(),
    this.weight = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.checked = const Value.absent(),
    this.isWarmup = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       exerciseId = Value(exerciseId),
       sortOrder = Value(sortOrder);
  static Insertable<WorkoutSet> custom({
    Expression<String>? id,
    Expression<String>? exerciseId,
    Expression<int>? sortOrder,
    Expression<String>? reps,
    Expression<String>? weight,
    Expression<String>? durationSeconds,
    Expression<bool>? checked,
    Expression<bool>? isWarmup,
    Expression<String>? difficulty,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (reps != null) 'reps': reps,
      if (weight != null) 'weight': weight,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (checked != null) 'checked': checked,
      if (isWarmup != null) 'is_warmup': isWarmup,
      if (difficulty != null) 'difficulty': difficulty,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkoutSetsCompanion copyWith({
    Value<String>? id,
    Value<String>? exerciseId,
    Value<int>? sortOrder,
    Value<String>? reps,
    Value<String>? weight,
    Value<String?>? durationSeconds,
    Value<bool>? checked,
    Value<bool>? isWarmup,
    Value<String?>? difficulty,
    Value<int>? rowid,
  }) {
    return WorkoutSetsCompanion(
      id: id ?? this.id,
      exerciseId: exerciseId ?? this.exerciseId,
      sortOrder: sortOrder ?? this.sortOrder,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      checked: checked ?? this.checked,
      isWarmup: isWarmup ?? this.isWarmup,
      difficulty: difficulty ?? this.difficulty,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<String>(exerciseId.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (reps.present) {
      map['reps'] = Variable<String>(reps.value);
    }
    if (weight.present) {
      map['weight'] = Variable<String>(weight.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<String>(durationSeconds.value);
    }
    if (checked.present) {
      map['checked'] = Variable<bool>(checked.value);
    }
    if (isWarmup.present) {
      map['is_warmup'] = Variable<bool>(isWarmup.value);
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<String>(difficulty.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutSetsCompanion(')
          ..write('id: $id, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('reps: $reps, ')
          ..write('weight: $weight, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('checked: $checked, ')
          ..write('isWarmup: $isWarmup, ')
          ..write('difficulty: $difficulty, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalSettingsTable extends LocalSettings
    with TableInfo<$LocalSettingsTable, LocalSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  LocalSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalSetting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $LocalSettingsTable createAlias(String alias) {
    return $LocalSettingsTable(attachedDatabase, alias);
  }
}

class LocalSetting extends DataClass implements Insertable<LocalSetting> {
  final String key;
  final String value;
  const LocalSetting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  LocalSettingsCompanion toCompanion(bool nullToAbsent) {
    return LocalSettingsCompanion(key: Value(key), value: Value(value));
  }

  factory LocalSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalSetting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  LocalSetting copyWith({String? key, String? value}) =>
      LocalSetting(key: key ?? this.key, value: value ?? this.value);
  LocalSetting copyWithCompanion(LocalSettingsCompanion data) {
    return LocalSetting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalSetting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalSetting &&
          other.key == this.key &&
          other.value == this.value);
}

class LocalSettingsCompanion extends UpdateCompanion<LocalSetting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const LocalSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalSettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<LocalSetting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalSettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return LocalSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $DaysTable days = $DaysTable(this);
  late final $ExercisesTable exercises = $ExercisesTable(this);
  late final $WorkoutSetsTable workoutSets = $WorkoutSetsTable(this);
  late final $LocalSettingsTable localSettings = $LocalSettingsTable(this);
  late final Index idxDaysUpdatedAt = Index(
    'idx_days_updated_at',
    'CREATE INDEX idx_days_updated_at ON days (updated_at)',
  );
  late final Index idxExercisesDateKey = Index(
    'idx_exercises_date_key',
    'CREATE INDEX idx_exercises_date_key ON exercises (date_key)',
  );
  late final Index idxSetsExerciseId = Index(
    'idx_sets_exercise_id',
    'CREATE INDEX idx_sets_exercise_id ON sets (exercise_id)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    days,
    exercises,
    workoutSets,
    localSettings,
    idxDaysUpdatedAt,
    idxExercisesDateKey,
    idxSetsExerciseId,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'days',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('exercises', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'exercises',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('sets', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$DaysTableCreateCompanionBuilder = DaysCompanion Function({
  required String dateKey,
  Value<String?> notes,
  Value<bool> isRestDay,
  Value<String?> workoutName,
  Value<String?> planName,
  Value<String?> workoutNotes,
  required String updatedAt,
  Value<int?> chosenRestSeconds,
  Value<double?> healthEnergyKcal,
  Value<int> rowid,
});
typedef $$DaysTableUpdateCompanionBuilder = DaysCompanion Function({
  Value<String> dateKey,
  Value<String?> notes,
  Value<bool> isRestDay,
  Value<String?> workoutName,
  Value<String?> planName,
  Value<String?> workoutNotes,
  Value<String> updatedAt,
  Value<int?> chosenRestSeconds,
  Value<double?> healthEnergyKcal,
  Value<int> rowid,
});

final class $$DaysTableReferences
    extends BaseReferences<_$AppDatabase, $DaysTable, Day> {
  $$DaysTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ExercisesTable, List<Exercise>>
  _exercisesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.exercises,
    aliasName: 'days__date_key__exercises__date_key',
  );

  $$ExercisesTableProcessedTableManager get exercisesRefs {
    final manager = $$ExercisesTableTableManager($_db, $_db.exercises).filter(
      (f) => f.dateKey.dateKey.sqlEquals($_itemColumn<String>('date_key')!),
    );

    final cache = $_typedResult.readTableOrNull(_exercisesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$DaysTableFilterComposer extends Composer<_$AppDatabase, $DaysTable> {
  $$DaysTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get dateKey => $composableBuilder(
    column: $table.dateKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isRestDay => $composableBuilder(
    column: $table.isRestDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get workoutName => $composableBuilder(
    column: $table.workoutName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get planName => $composableBuilder(
    column: $table.planName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get workoutNotes => $composableBuilder(
    column: $table.workoutNotes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get chosenRestSeconds => $composableBuilder(
    column: $table.chosenRestSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get healthEnergyKcal => $composableBuilder(
    column: $table.healthEnergyKcal,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> exercisesRefs(
    Expression<bool> Function($$ExercisesTableFilterComposer f) f,
  ) {
    final $$ExercisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dateKey,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.dateKey,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableFilterComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DaysTableOrderingComposer extends Composer<_$AppDatabase, $DaysTable> {
  $$DaysTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get dateKey => $composableBuilder(
    column: $table.dateKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isRestDay => $composableBuilder(
    column: $table.isRestDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get workoutName => $composableBuilder(
    column: $table.workoutName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get planName => $composableBuilder(
    column: $table.planName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get workoutNotes => $composableBuilder(
    column: $table.workoutNotes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get chosenRestSeconds => $composableBuilder(
    column: $table.chosenRestSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get healthEnergyKcal => $composableBuilder(
    column: $table.healthEnergyKcal,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DaysTableAnnotationComposer
    extends Composer<_$AppDatabase, $DaysTable> {
  $$DaysTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get dateKey =>
      $composableBuilder(column: $table.dateKey, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<bool> get isRestDay =>
      $composableBuilder(column: $table.isRestDay, builder: (column) => column);

  GeneratedColumn<String> get workoutName => $composableBuilder(
    column: $table.workoutName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get planName =>
      $composableBuilder(column: $table.planName, builder: (column) => column);

  GeneratedColumn<String> get workoutNotes => $composableBuilder(
    column: $table.workoutNotes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get chosenRestSeconds => $composableBuilder(
    column: $table.chosenRestSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<double> get healthEnergyKcal => $composableBuilder(
    column: $table.healthEnergyKcal,
    builder: (column) => column,
  );

  Expression<T> exercisesRefs<T extends Object>(
    Expression<T> Function($$ExercisesTableAnnotationComposer a) f,
  ) {
    final $$ExercisesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dateKey,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.dateKey,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableAnnotationComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DaysTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DaysTable,
          Day,
          $$DaysTableFilterComposer,
          $$DaysTableOrderingComposer,
          $$DaysTableAnnotationComposer,
          $$DaysTableCreateCompanionBuilder,
          $$DaysTableUpdateCompanionBuilder,
          (Day, $$DaysTableReferences),
          Day,
          PrefetchHooks Function({bool exercisesRefs})
        > {
  $$DaysTableTableManager(_$AppDatabase db, $DaysTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DaysTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DaysTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DaysTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> dateKey = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> isRestDay = const Value.absent(),
                Value<String?> workoutName = const Value.absent(),
                Value<String?> planName = const Value.absent(),
                Value<String?> workoutNotes = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<int?> chosenRestSeconds = const Value.absent(),
                Value<double?> healthEnergyKcal = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DaysCompanion(
                dateKey: dateKey,
                notes: notes,
                isRestDay: isRestDay,
                workoutName: workoutName,
                planName: planName,
                workoutNotes: workoutNotes,
                updatedAt: updatedAt,
                chosenRestSeconds: chosenRestSeconds,
                healthEnergyKcal: healthEnergyKcal,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String dateKey,
                Value<String?> notes = const Value.absent(),
                Value<bool> isRestDay = const Value.absent(),
                Value<String?> workoutName = const Value.absent(),
                Value<String?> planName = const Value.absent(),
                Value<String?> workoutNotes = const Value.absent(),
                required String updatedAt,
                Value<int?> chosenRestSeconds = const Value.absent(),
                Value<double?> healthEnergyKcal = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DaysCompanion.insert(
                dateKey: dateKey,
                notes: notes,
                isRestDay: isRestDay,
                workoutName: workoutName,
                planName: planName,
                workoutNotes: workoutNotes,
                updatedAt: updatedAt,
                chosenRestSeconds: chosenRestSeconds,
                healthEnergyKcal: healthEnergyKcal,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DaysTable, Day>(table),
                  $$DaysTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({exercisesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (exercisesRefs) db.exercises],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (exercisesRefs)
                    await $_getPrefetchedData<Day, $DaysTable, Exercise>(
                      currentTable: table,
                      referencedTable: $$DaysTableReferences
                          ._exercisesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$DaysTableReferences(db, table, p0).exercisesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.dateKey == item.dateKey,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$DaysTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DaysTable,
      Day,
      $$DaysTableFilterComposer,
      $$DaysTableOrderingComposer,
      $$DaysTableAnnotationComposer,
      $$DaysTableCreateCompanionBuilder,
      $$DaysTableUpdateCompanionBuilder,
      (Day, $$DaysTableReferences),
      Day,
      PrefetchHooks Function({bool exercisesRefs})
    >;
typedef $$ExercisesTableCreateCompanionBuilder = ExercisesCompanion Function({
  required String id,
  required String dateKey,
  required int sortOrder,
  required String name,
  Value<String?> libraryId,
  Value<String?> notes,
  Value<bool> isCircuit,
  Value<bool> isCardio,
  Value<bool> isCore,
  Value<String?> targetDuration,
  Value<String?> targetTimeSeconds,
  Value<String?> targetDistance,
  Value<String?> loggedCalories,
  Value<String?> targetReps,
  Value<String?> targetWeight,
  Value<String?> supersetGroupId,
  Value<String?> supersetLabel,
  Value<int?> supersetOrder,
  Value<String?> preferredSwapLibraryIds,
  Value<int?> targetRestSeconds,
  Value<String?> prescribedReps,
  Value<String?> prescribedWeight,
  Value<int?> prescribedSetCount,
  Value<int> rowid,
});
typedef $$ExercisesTableUpdateCompanionBuilder = ExercisesCompanion Function({
  Value<String> id,
  Value<String> dateKey,
  Value<int> sortOrder,
  Value<String> name,
  Value<String?> libraryId,
  Value<String?> notes,
  Value<bool> isCircuit,
  Value<bool> isCardio,
  Value<bool> isCore,
  Value<String?> targetDuration,
  Value<String?> targetTimeSeconds,
  Value<String?> targetDistance,
  Value<String?> loggedCalories,
  Value<String?> targetReps,
  Value<String?> targetWeight,
  Value<String?> supersetGroupId,
  Value<String?> supersetLabel,
  Value<int?> supersetOrder,
  Value<String?> preferredSwapLibraryIds,
  Value<int?> targetRestSeconds,
  Value<String?> prescribedReps,
  Value<String?> prescribedWeight,
  Value<int?> prescribedSetCount,
  Value<int> rowid,
});

final class $$ExercisesTableReferences
    extends BaseReferences<_$AppDatabase, $ExercisesTable, Exercise> {
  $$ExercisesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $DaysTable _dateKeyTable(_$AppDatabase db) =>
      db.days.createAlias('exercises__date_key__days__date_key');

  $$DaysTableProcessedTableManager get dateKey {
    final $_column = $_itemColumn<String>('date_key')!;

    final manager = $$DaysTableTableManager(
      $_db,
      $_db.days,
    ).filter((f) => f.dateKey.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_dateKeyTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$WorkoutSetsTable, List<WorkoutSet>>
  _workoutSetsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.workoutSets,
    aliasName: 'exercises__id__sets__exercise_id',
  );

  $$WorkoutSetsTableProcessedTableManager get workoutSetsRefs {
    final manager = $$WorkoutSetsTableTableManager(
      $_db,
      $_db.workoutSets,
    ).filter((f) => f.exerciseId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_workoutSetsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ExercisesTableFilterComposer
    extends Composer<_$AppDatabase, $ExercisesTable> {
  $$ExercisesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get libraryId => $composableBuilder(
    column: $table.libraryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCircuit => $composableBuilder(
    column: $table.isCircuit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCardio => $composableBuilder(
    column: $table.isCardio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCore => $composableBuilder(
    column: $table.isCore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetDuration => $composableBuilder(
    column: $table.targetDuration,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetTimeSeconds => $composableBuilder(
    column: $table.targetTimeSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetDistance => $composableBuilder(
    column: $table.targetDistance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get loggedCalories => $composableBuilder(
    column: $table.loggedCalories,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetReps => $composableBuilder(
    column: $table.targetReps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetWeight => $composableBuilder(
    column: $table.targetWeight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get supersetGroupId => $composableBuilder(
    column: $table.supersetGroupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get supersetLabel => $composableBuilder(
    column: $table.supersetLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get supersetOrder => $composableBuilder(
    column: $table.supersetOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get preferredSwapLibraryIds => $composableBuilder(
    column: $table.preferredSwapLibraryIds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetRestSeconds => $composableBuilder(
    column: $table.targetRestSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get prescribedReps => $composableBuilder(
    column: $table.prescribedReps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get prescribedWeight => $composableBuilder(
    column: $table.prescribedWeight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get prescribedSetCount => $composableBuilder(
    column: $table.prescribedSetCount,
    builder: (column) => ColumnFilters(column),
  );

  $$DaysTableFilterComposer get dateKey {
    final $$DaysTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dateKey,
      referencedTable: $db.days,
      getReferencedColumn: (t) => t.dateKey,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DaysTableFilterComposer(
            $db: $db,
            $table: $db.days,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> workoutSetsRefs(
    Expression<bool> Function($$WorkoutSetsTableFilterComposer f) f,
  ) {
    final $$WorkoutSetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workoutSets,
      getReferencedColumn: (t) => t.exerciseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutSetsTableFilterComposer(
            $db: $db,
            $table: $db.workoutSets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ExercisesTableOrderingComposer
    extends Composer<_$AppDatabase, $ExercisesTable> {
  $$ExercisesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get libraryId => $composableBuilder(
    column: $table.libraryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCircuit => $composableBuilder(
    column: $table.isCircuit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCardio => $composableBuilder(
    column: $table.isCardio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCore => $composableBuilder(
    column: $table.isCore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetDuration => $composableBuilder(
    column: $table.targetDuration,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetTimeSeconds => $composableBuilder(
    column: $table.targetTimeSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetDistance => $composableBuilder(
    column: $table.targetDistance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get loggedCalories => $composableBuilder(
    column: $table.loggedCalories,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetReps => $composableBuilder(
    column: $table.targetReps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetWeight => $composableBuilder(
    column: $table.targetWeight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get supersetGroupId => $composableBuilder(
    column: $table.supersetGroupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get supersetLabel => $composableBuilder(
    column: $table.supersetLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get supersetOrder => $composableBuilder(
    column: $table.supersetOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get preferredSwapLibraryIds => $composableBuilder(
    column: $table.preferredSwapLibraryIds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetRestSeconds => $composableBuilder(
    column: $table.targetRestSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get prescribedReps => $composableBuilder(
    column: $table.prescribedReps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get prescribedWeight => $composableBuilder(
    column: $table.prescribedWeight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get prescribedSetCount => $composableBuilder(
    column: $table.prescribedSetCount,
    builder: (column) => ColumnOrderings(column),
  );

  $$DaysTableOrderingComposer get dateKey {
    final $$DaysTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dateKey,
      referencedTable: $db.days,
      getReferencedColumn: (t) => t.dateKey,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DaysTableOrderingComposer(
            $db: $db,
            $table: $db.days,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExercisesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExercisesTable> {
  $$ExercisesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get libraryId =>
      $composableBuilder(column: $table.libraryId, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<bool> get isCircuit =>
      $composableBuilder(column: $table.isCircuit, builder: (column) => column);

  GeneratedColumn<bool> get isCardio =>
      $composableBuilder(column: $table.isCardio, builder: (column) => column);

  GeneratedColumn<bool> get isCore =>
      $composableBuilder(column: $table.isCore, builder: (column) => column);

  GeneratedColumn<String> get targetDuration => $composableBuilder(
    column: $table.targetDuration,
    builder: (column) => column,
  );

  GeneratedColumn<String> get targetTimeSeconds => $composableBuilder(
    column: $table.targetTimeSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<String> get targetDistance => $composableBuilder(
    column: $table.targetDistance,
    builder: (column) => column,
  );

  GeneratedColumn<String> get loggedCalories => $composableBuilder(
    column: $table.loggedCalories,
    builder: (column) => column,
  );

  GeneratedColumn<String> get targetReps => $composableBuilder(
    column: $table.targetReps,
    builder: (column) => column,
  );

  GeneratedColumn<String> get targetWeight => $composableBuilder(
    column: $table.targetWeight,
    builder: (column) => column,
  );

  GeneratedColumn<String> get supersetGroupId => $composableBuilder(
    column: $table.supersetGroupId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get supersetLabel => $composableBuilder(
    column: $table.supersetLabel,
    builder: (column) => column,
  );

  GeneratedColumn<int> get supersetOrder => $composableBuilder(
    column: $table.supersetOrder,
    builder: (column) => column,
  );

  GeneratedColumn<String> get preferredSwapLibraryIds => $composableBuilder(
    column: $table.preferredSwapLibraryIds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get targetRestSeconds => $composableBuilder(
    column: $table.targetRestSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<String> get prescribedReps => $composableBuilder(
    column: $table.prescribedReps,
    builder: (column) => column,
  );

  GeneratedColumn<String> get prescribedWeight => $composableBuilder(
    column: $table.prescribedWeight,
    builder: (column) => column,
  );

  GeneratedColumn<int> get prescribedSetCount => $composableBuilder(
    column: $table.prescribedSetCount,
    builder: (column) => column,
  );

  $$DaysTableAnnotationComposer get dateKey {
    final $$DaysTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dateKey,
      referencedTable: $db.days,
      getReferencedColumn: (t) => t.dateKey,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DaysTableAnnotationComposer(
            $db: $db,
            $table: $db.days,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> workoutSetsRefs<T extends Object>(
    Expression<T> Function($$WorkoutSetsTableAnnotationComposer a) f,
  ) {
    final $$WorkoutSetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workoutSets,
      getReferencedColumn: (t) => t.exerciseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutSetsTableAnnotationComposer(
            $db: $db,
            $table: $db.workoutSets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ExercisesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExercisesTable,
          Exercise,
          $$ExercisesTableFilterComposer,
          $$ExercisesTableOrderingComposer,
          $$ExercisesTableAnnotationComposer,
          $$ExercisesTableCreateCompanionBuilder,
          $$ExercisesTableUpdateCompanionBuilder,
          (Exercise, $$ExercisesTableReferences),
          Exercise,
          PrefetchHooks Function({bool dateKey, bool workoutSetsRefs})
        > {
  $$ExercisesTableTableManager(_$AppDatabase db, $ExercisesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExercisesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExercisesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExercisesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> dateKey = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> libraryId = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> isCircuit = const Value.absent(),
                Value<bool> isCardio = const Value.absent(),
                Value<bool> isCore = const Value.absent(),
                Value<String?> targetDuration = const Value.absent(),
                Value<String?> targetTimeSeconds = const Value.absent(),
                Value<String?> targetDistance = const Value.absent(),
                Value<String?> loggedCalories = const Value.absent(),
                Value<String?> targetReps = const Value.absent(),
                Value<String?> targetWeight = const Value.absent(),
                Value<String?> supersetGroupId = const Value.absent(),
                Value<String?> supersetLabel = const Value.absent(),
                Value<int?> supersetOrder = const Value.absent(),
                Value<String?> preferredSwapLibraryIds = const Value.absent(),
                Value<int?> targetRestSeconds = const Value.absent(),
                Value<String?> prescribedReps = const Value.absent(),
                Value<String?> prescribedWeight = const Value.absent(),
                Value<int?> prescribedSetCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExercisesCompanion(
                id: id,
                dateKey: dateKey,
                sortOrder: sortOrder,
                name: name,
                libraryId: libraryId,
                notes: notes,
                isCircuit: isCircuit,
                isCardio: isCardio,
                isCore: isCore,
                targetDuration: targetDuration,
                targetTimeSeconds: targetTimeSeconds,
                targetDistance: targetDistance,
                loggedCalories: loggedCalories,
                targetReps: targetReps,
                targetWeight: targetWeight,
                supersetGroupId: supersetGroupId,
                supersetLabel: supersetLabel,
                supersetOrder: supersetOrder,
                preferredSwapLibraryIds: preferredSwapLibraryIds,
                targetRestSeconds: targetRestSeconds,
                prescribedReps: prescribedReps,
                prescribedWeight: prescribedWeight,
                prescribedSetCount: prescribedSetCount,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String dateKey,
                required int sortOrder,
                required String name,
                Value<String?> libraryId = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> isCircuit = const Value.absent(),
                Value<bool> isCardio = const Value.absent(),
                Value<bool> isCore = const Value.absent(),
                Value<String?> targetDuration = const Value.absent(),
                Value<String?> targetTimeSeconds = const Value.absent(),
                Value<String?> targetDistance = const Value.absent(),
                Value<String?> loggedCalories = const Value.absent(),
                Value<String?> targetReps = const Value.absent(),
                Value<String?> targetWeight = const Value.absent(),
                Value<String?> supersetGroupId = const Value.absent(),
                Value<String?> supersetLabel = const Value.absent(),
                Value<int?> supersetOrder = const Value.absent(),
                Value<String?> preferredSwapLibraryIds = const Value.absent(),
                Value<int?> targetRestSeconds = const Value.absent(),
                Value<String?> prescribedReps = const Value.absent(),
                Value<String?> prescribedWeight = const Value.absent(),
                Value<int?> prescribedSetCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExercisesCompanion.insert(
                id: id,
                dateKey: dateKey,
                sortOrder: sortOrder,
                name: name,
                libraryId: libraryId,
                notes: notes,
                isCircuit: isCircuit,
                isCardio: isCardio,
                isCore: isCore,
                targetDuration: targetDuration,
                targetTimeSeconds: targetTimeSeconds,
                targetDistance: targetDistance,
                loggedCalories: loggedCalories,
                targetReps: targetReps,
                targetWeight: targetWeight,
                supersetGroupId: supersetGroupId,
                supersetLabel: supersetLabel,
                supersetOrder: supersetOrder,
                preferredSwapLibraryIds: preferredSwapLibraryIds,
                targetRestSeconds: targetRestSeconds,
                prescribedReps: prescribedReps,
                prescribedWeight: prescribedWeight,
                prescribedSetCount: prescribedSetCount,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ExercisesTable, Exercise>(table),
                  $$ExercisesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({dateKey = false, workoutSetsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (workoutSetsRefs) db.workoutSets],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (dateKey) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.dateKey,
                        referencedTable: $$ExercisesTableReferences
                            ._dateKeyTable(db),
                        referencedColumn: $$ExercisesTableReferences
                            ._dateKeyTable(db)
                            .dateKey,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (workoutSetsRefs)
                    await $_getPrefetchedData<
                      Exercise,
                      $ExercisesTable,
                      WorkoutSet
                    >(
                      currentTable: table,
                      referencedTable: $$ExercisesTableReferences
                          ._workoutSetsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$ExercisesTableReferences(
                            db,
                            table,
                            p0,
                          ).workoutSetsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.exerciseId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ExercisesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExercisesTable,
      Exercise,
      $$ExercisesTableFilterComposer,
      $$ExercisesTableOrderingComposer,
      $$ExercisesTableAnnotationComposer,
      $$ExercisesTableCreateCompanionBuilder,
      $$ExercisesTableUpdateCompanionBuilder,
      (Exercise, $$ExercisesTableReferences),
      Exercise,
      PrefetchHooks Function({bool dateKey, bool workoutSetsRefs})
    >;
typedef $$WorkoutSetsTableCreateCompanionBuilder =
    WorkoutSetsCompanion Function({
      required String id,
      required String exerciseId,
      required int sortOrder,
      Value<String> reps,
      Value<String> weight,
      Value<String?> durationSeconds,
      Value<bool> checked,
      Value<bool> isWarmup,
      Value<String?> difficulty,
      Value<int> rowid,
    });
typedef $$WorkoutSetsTableUpdateCompanionBuilder =
    WorkoutSetsCompanion Function({
      Value<String> id,
      Value<String> exerciseId,
      Value<int> sortOrder,
      Value<String> reps,
      Value<String> weight,
      Value<String?> durationSeconds,
      Value<bool> checked,
      Value<bool> isWarmup,
      Value<String?> difficulty,
      Value<int> rowid,
    });

final class $$WorkoutSetsTableReferences
    extends BaseReferences<_$AppDatabase, $WorkoutSetsTable, WorkoutSet> {
  $$WorkoutSetsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ExercisesTable _exerciseIdTable(_$AppDatabase db) =>
      db.exercises.createAlias('sets__exercise_id__exercises__id');

  $$ExercisesTableProcessedTableManager get exerciseId {
    final $_column = $_itemColumn<String>('exercise_id')!;

    final manager = $$ExercisesTableTableManager(
      $_db,
      $_db.exercises,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_exerciseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$WorkoutSetsTableFilterComposer
    extends Composer<_$AppDatabase, $WorkoutSetsTable> {
  $$WorkoutSetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reps => $composableBuilder(
    column: $table.reps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get weight => $composableBuilder(
    column: $table.weight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get checked => $composableBuilder(
    column: $table.checked,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isWarmup => $composableBuilder(
    column: $table.isWarmup,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnFilters(column),
  );

  $$ExercisesTableFilterComposer get exerciseId {
    final $$ExercisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableFilterComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WorkoutSetsTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkoutSetsTable> {
  $$WorkoutSetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reps => $composableBuilder(
    column: $table.reps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get weight => $composableBuilder(
    column: $table.weight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get checked => $composableBuilder(
    column: $table.checked,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isWarmup => $composableBuilder(
    column: $table.isWarmup,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnOrderings(column),
  );

  $$ExercisesTableOrderingComposer get exerciseId {
    final $$ExercisesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableOrderingComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WorkoutSetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkoutSetsTable> {
  $$WorkoutSetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<String> get reps =>
      $composableBuilder(column: $table.reps, builder: (column) => column);

  GeneratedColumn<String> get weight =>
      $composableBuilder(column: $table.weight, builder: (column) => column);

  GeneratedColumn<String> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get checked =>
      $composableBuilder(column: $table.checked, builder: (column) => column);

  GeneratedColumn<bool> get isWarmup =>
      $composableBuilder(column: $table.isWarmup, builder: (column) => column);

  GeneratedColumn<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => column,
  );

  $$ExercisesTableAnnotationComposer get exerciseId {
    final $$ExercisesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableAnnotationComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WorkoutSetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WorkoutSetsTable,
          WorkoutSet,
          $$WorkoutSetsTableFilterComposer,
          $$WorkoutSetsTableOrderingComposer,
          $$WorkoutSetsTableAnnotationComposer,
          $$WorkoutSetsTableCreateCompanionBuilder,
          $$WorkoutSetsTableUpdateCompanionBuilder,
          (WorkoutSet, $$WorkoutSetsTableReferences),
          WorkoutSet,
          PrefetchHooks Function({bool exerciseId})
        > {
  $$WorkoutSetsTableTableManager(_$AppDatabase db, $WorkoutSetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkoutSetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkoutSetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkoutSetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> exerciseId = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<String> reps = const Value.absent(),
                Value<String> weight = const Value.absent(),
                Value<String?> durationSeconds = const Value.absent(),
                Value<bool> checked = const Value.absent(),
                Value<bool> isWarmup = const Value.absent(),
                Value<String?> difficulty = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkoutSetsCompanion(
                id: id,
                exerciseId: exerciseId,
                sortOrder: sortOrder,
                reps: reps,
                weight: weight,
                durationSeconds: durationSeconds,
                checked: checked,
                isWarmup: isWarmup,
                difficulty: difficulty,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String exerciseId,
                required int sortOrder,
                Value<String> reps = const Value.absent(),
                Value<String> weight = const Value.absent(),
                Value<String?> durationSeconds = const Value.absent(),
                Value<bool> checked = const Value.absent(),
                Value<bool> isWarmup = const Value.absent(),
                Value<String?> difficulty = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkoutSetsCompanion.insert(
                id: id,
                exerciseId: exerciseId,
                sortOrder: sortOrder,
                reps: reps,
                weight: weight,
                durationSeconds: durationSeconds,
                checked: checked,
                isWarmup: isWarmup,
                difficulty: difficulty,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WorkoutSetsTable, WorkoutSet>(table),
                  $$WorkoutSetsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({exerciseId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (exerciseId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.exerciseId,
                        referencedTable: $$WorkoutSetsTableReferences
                            ._exerciseIdTable(db),
                        referencedColumn: $$WorkoutSetsTableReferences
                            ._exerciseIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$WorkoutSetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WorkoutSetsTable,
      WorkoutSet,
      $$WorkoutSetsTableFilterComposer,
      $$WorkoutSetsTableOrderingComposer,
      $$WorkoutSetsTableAnnotationComposer,
      $$WorkoutSetsTableCreateCompanionBuilder,
      $$WorkoutSetsTableUpdateCompanionBuilder,
      (WorkoutSet, $$WorkoutSetsTableReferences),
      WorkoutSet,
      PrefetchHooks Function({bool exerciseId})
    >;
typedef $$LocalSettingsTableCreateCompanionBuilder =
    LocalSettingsCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$LocalSettingsTableUpdateCompanionBuilder =
    LocalSettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$LocalSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalSettingsTable> {
  $$LocalSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalSettingsTable> {
  $$LocalSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalSettingsTable> {
  $$LocalSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$LocalSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalSettingsTable,
          LocalSetting,
          $$LocalSettingsTableFilterComposer,
          $$LocalSettingsTableOrderingComposer,
          $$LocalSettingsTableAnnotationComposer,
          $$LocalSettingsTableCreateCompanionBuilder,
          $$LocalSettingsTableUpdateCompanionBuilder,
          (
            LocalSetting,
            BaseReferences<_$AppDatabase, $LocalSettingsTable, LocalSetting>,
          ),
          LocalSetting,
          PrefetchHooks Function()
        > {
  $$LocalSettingsTableTableManager(_$AppDatabase db, $LocalSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => LocalSettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => LocalSettingsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalSettingsTable, LocalSetting>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalSettingsTable,
                    LocalSetting
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalSettingsTable,
      LocalSetting,
      $$LocalSettingsTableFilterComposer,
      $$LocalSettingsTableOrderingComposer,
      $$LocalSettingsTableAnnotationComposer,
      $$LocalSettingsTableCreateCompanionBuilder,
      $$LocalSettingsTableUpdateCompanionBuilder,
      (
        LocalSetting,
        BaseReferences<_$AppDatabase, $LocalSettingsTable, LocalSetting>,
      ),
      LocalSetting,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$DaysTableTableManager get days => $$DaysTableTableManager(_db, _db.days);
  $$ExercisesTableTableManager get exercises =>
      $$ExercisesTableTableManager(_db, _db.exercises);
  $$WorkoutSetsTableTableManager get workoutSets =>
      $$WorkoutSetsTableTableManager(_db, _db.workoutSets);
  $$LocalSettingsTableTableManager get localSettings =>
      $$LocalSettingsTableTableManager(_db, _db.localSettings);
}
