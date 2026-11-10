import 'dart:convert';

import '../date_key.dart';
import '../ids.dart';
import '../model/journal_day.dart';

/// Result of reading a LiftBig JSON backup exported by the Vue app.
class ParsedBackup {
  const ParsedBackup({
    required this.days,
    required this.skippedDays,
    this.templatesJson,
    this.settingsJson,
    this.weightUnit,
    this.bodyWeightLbs,
    this.settingsUpdatedAt,
  });

  final List<JournalDay> days;
  final int skippedDays;
  final String? templatesJson;
  final String? settingsJson;
  final String? weightUnit;
  final double? bodyWeightLbs;
  final String? settingsUpdatedAt;
}

class BackupParseException implements Exception {
  BackupParseException(this.message);

  final String message;

  @override
  String toString() => message;
}

const missingBackupMessage =
    'Missing LiftBig backup data. Expected liftbig_local_storage and/or '
    'liftbig_workouts, liftbig_templates, liftbig_settings.';

/// Parse `liftbig_local_storage` and/or the typed workout, template, and
/// settings fields. Weights stay as the stored pound strings.
ParsedBackup parseLiftBigBackup(String text, {DateTime? now}) {
  final Object? decoded;
  try {
    decoded = jsonDecode(text);
  } catch (_) {
    throw BackupParseException('File is not valid JSON.');
  }
  final root = _asMap(decoded);
  if (root == null) {
    throw BackupParseException('Backup must be a JSON object.');
  }

  final inner = _asMap(root['data']);
  final bundle =
      _asMap(root['liftbig_local_storage']) ??
      _asMap(inner?['liftbig_local_storage']);

  final workoutsRaw = _field(bundle, root, inner, 'liftbig_workouts');
  final templatesRaw = _field(
    bundle,
    root,
    inner,
    'liftbig_templates',
    alternateKey: 'liftbig_plans',
  );
  final settingsRaw = _field(bundle, root, inner, 'liftbig_settings');
  final stampsRaw = _field(bundle, root, inner, 'liftbig_day_stamps');

  if (workoutsRaw == null && templatesRaw == null && settingsRaw == null) {
    throw BackupParseException(missingBackupMessage);
  }

  final fallbackStamp = _string(root['exportedAt']) ??
      (now ?? DateTime.now()).toUtc().toIso8601String();
  final stamps = _stringMap(_decodeMaybe(stampsRaw));
  final workouts = _asMap(_decodeMaybe(workoutsRaw)) ?? const {};

  final days = <JournalDay>[];
  var skipped = 0;
  for (final entry in workouts.entries) {
    final dateKey = entry.key;
    if (!isValidDateKey(dateKey)) {
      skipped += 1;
      continue;
    }
    final day = _parseDay(
      dateKey,
      entry.value,
      _stampForDay(dateKey, entry.value, stamps, fallbackStamp),
    );
    if (day == null) {
      skipped += 1;
      continue;
    }
    days.add(day);
  }
  days.sort((a, b) => a.dateKey.compareTo(b.dateKey));

  final settingsMap = _asMap(_decodeMaybe(settingsRaw));
  final weightUnit = _string(settingsMap?['weightUnit']);
  final bodyRaw = settingsMap?['bodyWeightLbs'];
  final bodyWeightLbs = bodyRaw is num && bodyRaw > 0 ? bodyRaw.toDouble() : null;

  return ParsedBackup(
    days: days,
    skippedDays: skipped,
    // liftbig_templates stays the backup key. Folder objects in it are Plans.
    templatesJson: _jsonText(templatesRaw),
    settingsJson: _jsonText(settingsRaw),
    weightUnit: weightUnit == 'lb' || weightUnit == 'kg' ? weightUnit : null,
    bodyWeightLbs: bodyWeightLbs,
    settingsUpdatedAt: templatesRaw != null || settingsRaw != null
        ? fallbackStamp
        : null,
  );
}

/// Drops backup days that must not replace a newer local copy of that date.
///
/// A day stays in the result when this phone has no row for it, or when the
/// backup stamp is strictly newer. An equal stamp keeps the local day, same
/// as the cloud merge. Templates and settings stay on the backup. Dropped
/// days are not counted as unrecognized.
ParsedBackup dropStaleBackupDays(
  ParsedBackup backup,
  Map<String, String> localUpdatedAt,
) {
  final kept = <JournalDay>[
    for (final day in backup.days)
      if (_backupDayIsNewer(day.updatedAt, localUpdatedAt[day.dateKey])) day,
  ];
  if (kept.length == backup.days.length) return backup;
  return ParsedBackup(
    days: kept,
    skippedDays: backup.skippedDays,
    templatesJson: backup.templatesJson,
    settingsJson: backup.settingsJson,
    weightUnit: backup.weightUnit,
    bodyWeightLbs: backup.bodyWeightLbs,
    settingsUpdatedAt: backup.settingsUpdatedAt,
  );
}

/// Stamp map wins, then a stamp written on the day, then [fallbackStamp].
String _stampForDay(
  String dateKey,
  Object? raw,
  Map<String, String> stamps,
  String fallbackStamp,
) {
  final recorded = stamps[dateKey];
  if (recorded != null) return recorded;
  final onDay = _string(_asMap(raw)?['updatedAt']);
  if (onDay != null) return onDay;
  return fallbackStamp;
}

bool _backupDayIsNewer(String backupStamp, String? localStamp) {
  if (localStamp == null || localStamp.isEmpty) return true;
  return backupStamp.compareTo(localStamp) > 0;
}

JournalDay? _parseDay(String dateKey, Object? raw, String updatedAt) {
  if (raw is List) {
    final exercises = _parseExercises(raw);
    return JournalDay(
      dateKey: dateKey,
      updatedAt: updatedAt,
      exercises: exercises,
    );
  }
  final map = _asMap(raw);
  if (map == null || map['exercises'] is! List) return null;
  return JournalDay(
    dateKey: dateKey,
    notes: _string(map['notes']),
    isRestDay: map['isRestDay'] == true,
    // Vue backups still use planName, planFolderName, and planNotes.
    workoutName: _string(map['planName']),
    planName: _string(map['planFolderName']),
    workoutNotes: _string(map['planNotes']),
    chosenRestSeconds: _wholeNumber(map['chosenRestSeconds']),
    updatedAt: updatedAt,
    exercises: _parseExercises(map['exercises'] as List),
  );
}

List<JournalExercise> _parseExercises(List<Object?> raw) {
  final exercises = <JournalExercise>[];
  for (var index = 0; index < raw.length; index++) {
    final map = _asMap(raw[index]);
    if (map == null) continue;
    final name = _string(map['name']);
    if (name == null) continue;
    final setsRaw = map['sets'];
    if (setsRaw is! List) continue;
    exercises.add(
      JournalExercise(
        id: _string(map['id']) ?? newId(),
        sortOrder: index,
        name: name,
        libraryId: _string(map['libraryId']),
        notes: _string(map['notes']),
        isCircuit: map['isCircuit'] == true,
        isCardio: map['isCardio'] == true,
        isCore: map['isCore'] == true,
        targetDuration: _string(map['targetDuration']),
        targetTimeSeconds: _string(map['targetTimeSeconds']),
        targetDistance: _string(map['targetDistance']),
        loggedCalories: _string(map['loggedCalories']),
        targetReps: _string(map['targetReps']),
        targetWeight: _string(map['targetWeight']),
        supersetGroupId: _string(map['supersetGroupId']),
        supersetLabel: _string(map['supersetLabel']),
        supersetOrder: map['supersetOrder'] is num
            ? (map['supersetOrder'] as num).round()
            : null,
        preferredSwapLibraryIds: map['preferredSwapLibraryIds'] is List
            ? (map['preferredSwapLibraryIds'] as List).whereType<String>().toList()
            : const [],
        targetRestSeconds: _wholeNumber(map['targetRestSeconds']),
        prescribedReps: _string(map['prescribedReps']),
        prescribedWeight: _string(map['prescribedWeight']),
        prescribedSetCount: _wholeNumber(map['prescribedSetCount']),
        sets: _parseSets(setsRaw),
      ),
    );
  }
  return exercises;
}

List<JournalSet> _parseSets(List<Object?> raw) {
  final sets = <JournalSet>[];
  for (var index = 0; index < raw.length; index++) {
    final map = _asMap(raw[index]);
    if (map == null) continue;
    sets.add(
      JournalSet(
        id: _string(map['id']) ?? newId(),
        sortOrder: index,
        reps: _textField(map['reps']),
        weight: _textField(map['weight']),
        durationSeconds: _string(map['durationSeconds']) ??
            (map['durationSeconds'] is num
                ? (map['durationSeconds'] as num).toString()
                : null),
        checked: map['checked'] == true,
        isWarmup: map['isWarmup'] == true,
        difficulty: canonicalSetDifficulty(map['difficulty']),
      ),
    );
  }
  return sets;
}

/// Bundle string wins when the key is present. Otherwise use the typed field
/// on the backup root, then the same field nested under `data`.
Object? _field(
  Map<String, Object?>? bundle,
  Map<String, Object?> root,
  Map<String, Object?>? inner,
  String key, {
  String? alternateKey,
}) {
  if (bundle != null && bundle.containsKey(key)) return bundle[key];
  if (alternateKey != null &&
      bundle != null &&
      bundle.containsKey(alternateKey)) {
    return bundle[alternateKey];
  }
  if (root.containsKey(key)) return root[key];
  if (alternateKey != null && root.containsKey(alternateKey)) {
    return root[alternateKey];
  }
  if (inner != null && inner.containsKey(key)) return inner[key];
  if (alternateKey != null && inner != null && inner.containsKey(alternateKey)) {
    return inner[alternateKey];
  }
  return null;
}

Object? _decodeMaybe(Object? value) {
  if (value is! String) return value;
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;
  try {
    return jsonDecode(trimmed);
  } catch (_) {
    return null;
  }
}

Map<String, Object?>? _asMap(Object? value) {
  final decoded = value is String ? _decodeMaybe(value) : value;
  if (decoded is Map) {
    return decoded.map((key, item) => MapEntry(key.toString(), item));
  }
  return null;
}

Map<String, String> _stringMap(Object? value) {
  final map = _asMap(value);
  if (map == null) return const {};
  final out = <String, String>{};
  for (final entry in map.entries) {
    final stamp = _string(entry.value);
    if (stamp != null) out[entry.key] = stamp;
  }
  return out;
}

String? _jsonText(Object? value) {
  if (value == null) return null;
  if (value is String) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
  try {
    return jsonEncode(value);
  } catch (_) {
    return null;
  }
}

String? _string(Object? value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

String _textField(Object? value) {
  if (value is String) return value;
  if (value is num) return value.toString();
  return '';
}

int? _wholeNumber(Object? value) {
  if (value is num) return value.round();
  if (value is String) return int.tryParse(value.trim());
  return null;
}

/// JSON the import path can read again. Day headers use the Vue backup names.
String encodeLiftBigBackup({
  required List<JournalDay> days,
  String? templatesJson,
  String? settingsJson,
  String? weightUnit,
  double? bodyWeightLbs,
  DateTime? now,
}) {
  final exportedAt = (now ?? DateTime.now()).toUtc().toIso8601String();
  final workouts = <String, Object?>{};
  final stamps = <String, String>{};
  for (final day in days) {
    final stamp = day.updatedAt.trim();
    if (stamp.isNotEmpty) stamps[day.dateKey] = stamp;
    workouts[day.dateKey] = {
      'notes': day.notes,
      'isRestDay': day.isRestDay,
      'planName': day.workoutName,
      'planFolderName': day.planName,
      'planNotes': day.workoutNotes,
      'chosenRestSeconds': day.chosenRestSeconds,
      if (stamp.isNotEmpty) 'updatedAt': stamp,
      'exercises': [
        for (final exercise in day.exercises) exercise.toMap(),
      ],
    };
  }
  Object? templates = templatesJson;
  Object? settings = settingsJson;
  if (templatesJson != null) {
    try {
      templates = jsonDecode(templatesJson);
    } catch (_) {}
  }
  if (settingsJson != null) {
    try {
      settings = jsonDecode(settingsJson);
    } catch (_) {}
  }
  if (settings is Map) {
    final map = Map<String, Object?>.from(settings);
    if (weightUnit != null) map['weightUnit'] = weightUnit;
    if (bodyWeightLbs != null) map['bodyWeightLbs'] = bodyWeightLbs;
    settings = map;
  } else if (weightUnit != null || bodyWeightLbs != null) {
    settings = {
      if (weightUnit != null) 'weightUnit': weightUnit,
      if (bodyWeightLbs != null) 'bodyWeightLbs': bodyWeightLbs,
    };
  }
  return jsonEncode({
    'formatVersion': 2,
    'exportedAt': exportedAt,
    'app': 'LiftBig',
    'liftbig_workouts': workouts,
    'liftbig_day_stamps': stamps,
    'liftbig_templates': templates,
    'liftbig_settings': settings,
  });
}
