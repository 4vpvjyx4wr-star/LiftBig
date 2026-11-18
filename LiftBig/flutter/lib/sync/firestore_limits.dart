import 'dart:convert';

import '../journal/journal_repository.dart';
import '../model/journal_day.dart';

/// Cloud Firestore rejects a document larger than this.
const firestoreMaxDocumentBytes = 1048576;

/// Stay under the published cap so a small formula miss still writes.
const firestoreDocumentSafetyBytes = 64;

const _plannerMaxBytes =
    firestoreMaxDocumentBytes - firestoreDocumentSafetyBytes;

/// Longer than a Firebase Auth uid, so a planned document still fits a real path.
const _plannerUid =
    'uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu'
    'uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu';

/// Document size from the Firestore storage-size rules.
///
/// [pathSegments] is the collection and document ids, for example
/// `users`, uid, `settings`, `app`.
int firestoreDocumentSize(
  Map<String, Object?> fields, {
  required List<String> pathSegments,
}) {
  var size = _documentNameSize(pathSegments) + 32;
  for (final entry in fields.entries) {
    size += _stringSize(entry.key);
    size += firestoreValueSize(entry.value);
  }
  return size;
}

int firestoreValueSize(Object? value) {
  if (value == null) return 1;
  if (value is bool) return 1;
  if (value is int) return 8;
  if (value is double) return 8;
  if (value is String) return _stringSize(value);
  if (value is List) {
    var size = 0;
    for (final item in value) {
      size += firestoreValueSize(item);
    }
    return size;
  }
  if (value is Map) {
    var size = 32;
    for (final entry in value.entries) {
      size += _stringSize('${entry.key}');
      size += firestoreValueSize(entry.value);
    }
    return size;
  }
  return _stringSize('$value');
}

int _stringSize(String value) => utf8.encode(value).length + 1;

int _documentNameSize(List<String> pathSegments) {
  var size = 16;
  for (final segment in pathSegments) {
    size += _stringSize(segment);
  }
  return size;
}

List<String> _settingsPath(String docId) => [
  'users',
  _plannerUid,
  'settings',
  docId,
];

List<String> _dayPath(String dateKey) => [
  'users',
  _plannerUid,
  'days',
  dateKey,
];

int settingsDocumentSize(String docId, Map<String, Object?> fields) {
  return firestoreDocumentSize(fields, pathSegments: _settingsPath(docId));
}

bool dayDocumentExceedsLimit(JournalDay day) {
  return firestoreDocumentSize(
        day.toMap(),
        pathSegments: _dayPath(day.dateKey),
      ) >
      firestoreMaxDocumentBytes;
}

/// Split parts aim for this size so they stay clear of the 1 MiB cap.
const dayPartTargetBytes = 900 * 1024;

/// Hard cap for a part created by a split. The single-document path still
/// allows a day that already fits in one document.
const _dayWriteMaxBytes =
    firestoreMaxDocumentBytes - firestoreDocumentSafetyBytes;

final _dayPartId = RegExp(r'^(\d{4}-\d{2}-\d{2})__(\d+)$');

/// Part 1 keeps the calendar id. Later parts use `dateKey__2`, `dateKey__3`, …
String dayPartDocId(String dateKey, int partNumber) {
  if (partNumber <= 1) return dateKey;
  return '${dateKey}__$partNumber';
}

int dayPartNumber(String docId) {
  final match = _dayPartId.firstMatch(docId);
  if (match == null) return 1;
  final number = int.tryParse(match.group(2)!) ?? 1;
  return number < 1 ? 1 : number;
}

String dayDateKeyFromDocId(String docId) {
  final match = _dayPartId.firstMatch(docId);
  if (match == null) return docId;
  return match.group(1)!;
}

int plannedDayDocumentSize(String docId, Map<String, Object?> fields) {
  return firestoreDocumentSize(fields, pathSegments: _dayPath(docId));
}

class DayUpload {
  const DayUpload({required this.documents, this.skippedExercises = 0});

  /// Document id to fields, under `users/{uid}/days`.
  final Map<String, Map<String, Object?>> documents;

  /// Exercises left out because one of them could not fit in a document.
  final int skippedExercises;

  JournalDay? get storedDay =>
      documents.isEmpty ? null : journalDayFromPartDocuments(documents);
}

/// One document when the day fits. Otherwise sibling part documents.
///
/// Each part is valid day JSON. [dateKey] inside every part is the calendar
/// day, not the suffixed document id. An exercise that cannot fit in its own
/// part is omitted and counted on [DayUpload.skippedExercises].
DayUpload planDayUpload(JournalDay day) {
  final whole = day.toMap();
  if (plannedDayDocumentSize(day.dateKey, whole) <= firestoreMaxDocumentBytes) {
    return DayUpload(documents: {day.dateKey: whole});
  }

  final shell = _dayPartMap(day, const [], full: true);
  if (plannedDayDocumentSize(day.dateKey, shell) > _dayWriteMaxBytes) {
    return const DayUpload(documents: {});
  }

  final kept = <JournalExercise>[];
  var skipped = 0;
  for (final exercise in day.exercises) {
    if (_exerciseFitsInAPart(day, exercise)) {
      kept.add(exercise);
    } else {
      skipped += 1;
    }
  }

  if (kept.isEmpty) {
    return DayUpload(
      documents: {day.dateKey: shell},
      skippedExercises: skipped,
    );
  }

  final keptDay = day.copyWith(exercises: kept);
  final keptMap = keptDay.toMap();
  if (plannedDayDocumentSize(day.dateKey, keptMap) <=
      firestoreMaxDocumentBytes) {
    return DayUpload(
      documents: {day.dateKey: keptMap},
      skippedExercises: skipped,
    );
  }

  final packed = _packParts(keptDay);
  skipped += packed.skipped;
  if (packed.parts.isEmpty) {
    return DayUpload(
      documents: {day.dateKey: shell},
      skippedExercises: skipped,
    );
  }

  final documents = <String, Map<String, Object?>>{};
  for (var i = 0; i < packed.parts.length; i++) {
    documents[dayPartDocId(day.dateKey, i + 1)] = packed.parts[i];
  }
  return DayUpload(documents: documents, skippedExercises: skipped);
}

bool _exerciseFitsInAPart(JournalDay day, JournalExercise exercise) {
  final conservativeId = dayPartDocId(day.dateKey, 999);
  final full = _dayPartMap(day, [exercise], full: true);
  if (plannedDayDocumentSize(conservativeId, full) <= _dayWriteMaxBytes) {
    return true;
  }
  final minimal = _dayPartMap(day, [exercise], full: false);
  return plannedDayDocumentSize(conservativeId, minimal) <= _dayWriteMaxBytes;
}

class _PackResult {
  const _PackResult(this.parts, {this.skipped = 0});

  final List<Map<String, Object?>> parts;
  final int skipped;
}

class _PartBucket {
  _PartBucket(this.full, this.exercises);

  final bool full;
  List<JournalExercise> exercises;
}

_PackResult _packParts(JournalDay day) {
  final buckets = <_PartBucket>[];
  var skipped = 0;

  bool within(
    int partNumber,
    bool full,
    List<JournalExercise> exercises,
    int maxBytes,
  ) {
    return plannedDayDocumentSize(
          dayPartDocId(day.dateKey, partNumber),
          _dayPartMap(day, exercises, full: full),
        ) <=
        maxBytes;
  }

  bool startPart(JournalExercise exercise) {
    final partNumber = buckets.length + 1;
    if (within(partNumber, true, [exercise], dayPartTargetBytes)) {
      buckets.add(_PartBucket(true, [exercise]));
      return true;
    }
    final continuationNumber = partNumber == 1 ? 2 : partNumber;
    final minimalUnderTarget = within(continuationNumber, false, [
      exercise,
    ], dayPartTargetBytes);
    if (partNumber == 1 && minimalUnderTarget) {
      buckets.add(_PartBucket(true, <JournalExercise>[]));
      buckets.add(_PartBucket(false, [exercise]));
      return true;
    }
    if (minimalUnderTarget) {
      buckets.add(_PartBucket(false, [exercise]));
      return true;
    }
    final minimalUnderCap = within(continuationNumber, false, [
      exercise,
    ], _dayWriteMaxBytes);
    if (partNumber == 1 && minimalUnderCap) {
      buckets.add(_PartBucket(true, <JournalExercise>[]));
      buckets.add(_PartBucket(false, [exercise]));
      return true;
    }
    if (within(partNumber, true, [exercise], _dayWriteMaxBytes)) {
      buckets.add(_PartBucket(true, [exercise]));
      return true;
    }
    if (minimalUnderCap) {
      buckets.add(_PartBucket(false, [exercise]));
      return true;
    }
    return false;
  }

  for (final exercise in day.exercises) {
    if (buckets.isNotEmpty) {
      final last = buckets.last;
      final combined = [...last.exercises, exercise];
      if (within(buckets.length, last.full, combined, dayPartTargetBytes)) {
        last.exercises = combined;
        continue;
      }
    }
    if (!startPart(exercise)) skipped += 1;
  }

  if (buckets.isEmpty) {
    return _PackResult(const [], skipped: skipped);
  }
  return _PackResult([
    for (var i = 0; i < buckets.length; i++)
      _dayPartMap(day, buckets[i].exercises, full: i == 0 || buckets[i].full),
  ], skipped: skipped);
}

Map<String, Object?> _dayPartMap(
  JournalDay day,
  List<JournalExercise> exercises, {
  required bool full,
}) {
  if (full) return day.copyWith(exercises: exercises).toMap();
  return {
    'dateKey': day.dateKey,
    'notes': null,
    'isRestDay': day.isRestDay,
    'workoutName': day.workoutName,
    'planName': day.planName,
    'workoutNotes': null,
    'chosenRestSeconds': day.chosenRestSeconds,
    'healthEnergyKcal': day.healthEnergyKcal,
    'updatedAt': day.updatedAt,
    'exercises': [for (final exercise in exercises) exercise.toMap()],
  };
}

/// Joins part documents into the calendar day they belong to.
///
/// [documents] is keyed by document id. Part order follows `__2`, `__3`, …
/// Metadata comes from the first part so later parts can omit large notes.
JournalDay? journalDayFromPartDocuments(
  Map<String, Map<String, Object?>> documents,
) {
  if (documents.isEmpty) return null;
  final ids = documents.keys.toList()
    ..sort((a, b) {
      final byPart = dayPartNumber(a).compareTo(dayPartNumber(b));
      if (byPart != 0) return byPart;
      return a.compareTo(b);
    });
  JournalDay? head;
  final exercises = <JournalExercise>[];
  for (final id in ids) {
    final day = JournalDay.fromMap(documents[id]!);
    if (day == null) continue;
    head ??= day;
    exercises.addAll(day.exercises);
  }
  if (head == null) return null;
  if (exercises.length == head.exercises.length) return head;
  return head.copyWith(exercises: exercises);
}

class StoredDayDocument {
  const StoredDayDocument(this.id, this.data);

  final String id;
  final Map<String, Object?> data;
}

Map<String, JournalDay> daysFromStoredDocs(Iterable<StoredDayDocument> docs) {
  final grouped = <String, Map<String, Map<String, Object?>>>{};
  for (final doc in docs) {
    if (doc.data['deleted'] == true) continue;
    final data = Map<String, Object?>.from(doc.data);
    final dateKey = _dateField(data['dateKey']) ?? dayDateKeyFromDocId(doc.id);
    data['dateKey'] = dateKey;
    grouped.putIfAbsent(dateKey, () => {})[doc.id] = data;
  }
  final days = <String, JournalDay>{};
  for (final entry in grouped.entries) {
    final day = journalDayFromPartDocuments(entry.value);
    if (day == null || day.updatedAt.isEmpty) continue;
    days[entry.key] = day;
  }
  return days;
}

Map<String, DayTombstone> tombstonesFromStoredDocs(
  Iterable<StoredDayDocument> docs,
) {
  final tombstones = <String, DayTombstone>{};
  for (final doc in docs) {
    if (doc.data['deleted'] != true) continue;
    if (_dayPartId.hasMatch(doc.id)) continue;
    final deletedAt = doc.data['updatedAt'];
    if (deletedAt is! String || deletedAt.isEmpty) continue;
    final dateKey = _dateField(doc.data['dateKey']) ?? doc.id;
    tombstones[dateKey] = DayTombstone(dateKey: dateKey, deletedAt: deletedAt);
  }
  return tombstones;
}

class DayDocumentWrite {
  const DayDocumentWrite({required this.upserts, required this.deleteIds});

  final Map<String, Map<String, Object?>> upserts;
  final List<String> deleteIds;
}

DayDocumentWrite planReplaceDayDocuments({
  required String dateKey,
  required Map<String, Map<String, Object?>> existing,
  required Map<String, Map<String, Object?>> documents,
}) {
  return DayDocumentWrite(
    upserts: documents,
    deleteIds: [
      for (final entry in existing.entries)
        if (!documents.containsKey(entry.key) &&
            _storedDocBelongsToDay(entry.key, entry.value, dateKey))
          entry.key,
    ],
  );
}

DayDocumentWrite planTombstoneDocuments({
  required DayTombstone tombstone,
  required Map<String, Map<String, Object?>> existing,
}) {
  return DayDocumentWrite(
    upserts: {
      tombstone.dateKey: {
        'deleted': true,
        'updatedAt': tombstone.deletedAt,
        'dateKey': tombstone.dateKey,
      },
    },
    deleteIds: [
      for (final entry in existing.entries)
        if (entry.key != tombstone.dateKey &&
            _storedDocBelongsToDay(entry.key, entry.value, tombstone.dateKey))
          entry.key,
    ],
  );
}

Map<String, Map<String, Object?>> applyDayDocumentWrite(
  Map<String, Map<String, Object?>> existing,
  DayDocumentWrite write,
) {
  final next = Map<String, Map<String, Object?>>.from(existing);
  for (final id in write.deleteIds) {
    next.remove(id);
  }
  next.addAll(write.upserts);
  return next;
}

bool _storedDocBelongsToDay(
  String docId,
  Map<String, Object?> data,
  String dateKey,
) {
  if (_dateField(data['dateKey']) == dateKey) return true;
  if (docId == dateKey) return true;
  final match = _dayPartId.firstMatch(docId);
  return match != null && match.group(1) == dateKey;
}

String? _dateField(Object? value) {
  if (value is! String || value.trim().isEmpty) return null;
  return value;
}

bool _fits(String docId, Map<String, Object?> fields) {
  return settingsDocumentSize(docId, fields) <= _plannerMaxBytes;
}

bool isDocumentTooLarge(Object error) {
  final text = error.toString();
  return text.contains('maximum allowed size') ||
      (text.contains('longer than') && text.contains('bytes'));
}

/// Cloud form of settings. Premade catalog workouts stay on the device.
/// Saved plans are stored once, as `templatesJson`, not also inside preferences.
CloudSettings cloudComparableSettings(
  CloudSettings settings,
  Set<String> premadeIds,
) {
  final raw =
      settings.templatesJson ?? settings.preferences[SettingKeys.templatesJson];
  final templates = templatesWithoutPremadeCatalog(raw, premadeIds);
  final preferences = Map<String, String>.from(settings.preferences)
    ..remove(SettingKeys.templatesJson);
  return CloudSettings(
    updatedAt: settings.updatedAt,
    weightUnit: settings.weightUnit,
    bodyWeightLbs: settings.bodyWeightLbs,
    templatesJson: templates,
    settingsJson: settings.settingsJson,
    preferences: preferences,
  );
}

/// Drops premade workouts and folders. Custom plans stay in the JSON.
String? templatesWithoutPremadeCatalog(String? raw, Set<String> premadeIds) {
  if (raw == null || raw.isEmpty || premadeIds.isEmpty) return raw;
  final Object? decoded;
  try {
    decoded = jsonDecode(raw);
  } catch (_) {
    return raw;
  }
  if (decoded is List) {
    final kept = [
      for (final item in decoded)
        if (!_isPremadeEntry(item, premadeIds)) item,
    ];
    if (kept.length == decoded.length) return raw;
    return jsonEncode(kept);
  }
  if (decoded is Map) {
    final map = Map<String, Object?>.from(decoded);
    var changed = false;
    for (final key in ['templates', 'folders']) {
      final list = map[key];
      if (list is! List) continue;
      final kept = [
        for (final item in list)
          if (!_isPremadeEntry(item, premadeIds)) item,
      ];
      if (kept.length != list.length) {
        map[key] = kept;
        changed = true;
      }
    }
    if (!changed) return raw;
    return jsonEncode(map);
  }
  return raw;
}

bool _isPremadeEntry(Object? item, Set<String> premadeIds) {
  if (item is! Map) return false;
  final id = item['id'];
  return id is String && premadeIds.contains(id);
}

class SettingsUpload {
  const SettingsUpload({required this.documents, this.excluded = false});

  /// Document id to fields, under `users/{uid}/settings`.
  final Map<String, Map<String, Object?>> documents;

  /// True when a field could not be stored under the size cap.
  final bool excluded;
}

/// Splits an oversized settings payload across `settings` documents.
///
/// `app` keeps preferences. Saved plans that do not fit there go to
/// `templates_0`, `templates_1`, and so on. Each document stays under 1 MiB.
SettingsUpload planSettingsUpload(CloudSettings settings) {
  final app = <String, Object?>{
    'updatedAt': settings.updatedAt,
    if (settings.weightUnit != null) 'weightUnit': settings.weightUnit,
    if (settings.bodyWeightLbs != null) 'bodyWeightLbs': settings.bodyWeightLbs,
    'preferences': settings.preferences,
  };
  final extras = <String, String>{};
  final templates = settings.templatesJson;
  if (templates != null && templates.isNotEmpty) {
    extras['templatesJson'] = templates;
  }
  final settingsJson = settings.settingsJson;
  if (settingsJson != null && settingsJson.isNotEmpty) {
    extras['settingsJson'] = settingsJson;
  }

  final inline = Map<String, Object?>.from(app);
  for (final entry in extras.entries) {
    inline[entry.key] = entry.value;
  }
  if (_fits('app', inline)) {
    return SettingsUpload(documents: {'app': inline});
  }

  final documents = <String, Map<String, Object?>>{
    'app': Map<String, Object?>.from(app),
  };
  final overflow = <String, String>{};
  for (final entry in extras.entries) {
    final trial = Map<String, Object?>.from(documents['app']!)
      ..[entry.key] = entry.value;
    if (_fits('app', trial)) {
      documents['app'] = trial;
    } else {
      overflow[entry.key] = entry.value;
    }
  }

  var excluded = false;
  for (final entry in overflow.entries) {
    final parts = _chunkField(
      field: entry.key,
      value: entry.value,
      updatedAt: settings.updatedAt,
    );
    if (parts == null) {
      excluded = true;
      continue;
    }
    documents.addAll(parts);
    documents['app']![_partCountKey(entry.key)] = parts.length;
  }

  final appDoc = documents['app']!;
  if (!_fits('app', appDoc)) {
    return const SettingsUpload(documents: {}, excluded: true);
  }
  return SettingsUpload(documents: documents, excluded: excluded);
}

String _partCountKey(String field) {
  return field == 'templatesJson'
      ? 'templatesPartCount'
      : 'settingsJsonPartCount';
}

String _partDocId(String field, int index) {
  final prefix = field == 'templatesJson' ? 'templates' : 'settings_json';
  return '${prefix}_$index';
}

Map<String, Map<String, Object?>>? _chunkField({
  required String field,
  required String value,
  required String updatedAt,
}) {
  final bytes = utf8.encode(value);
  final documents = <String, Map<String, Object?>>{};
  var start = 0;
  var index = 0;
  while (start < bytes.length) {
    final docId = _partDocId(field, index);
    final budget = _chunkUtf8Budget(
      docId: docId,
      updatedAt: updatedAt,
      index: index,
    );
    if (budget < 1) return null;
    var end = start + budget;
    if (end > bytes.length) end = bytes.length;
    if (end < bytes.length) {
      while (end > start && (bytes[end] & 0xC0) == 0x80) {
        end -= 1;
      }
      if (end == start) return null;
    }
    documents[docId] = {
      'updatedAt': updatedAt,
      'index': index,
      'data': utf8.decode(bytes.sublist(start, end)),
    };
    if (!_fits(docId, documents[docId]!)) return null;
    start = end;
    index += 1;
  }
  if (documents.isEmpty) return null;
  return documents;
}

int _chunkUtf8Budget({
  required String docId,
  required String updatedAt,
  required int index,
}) {
  final shell = <String, Object?>{
    'updatedAt': updatedAt,
    'index': index,
    'data': '',
  };
  final used = settingsDocumentSize(docId, shell);
  final room = _plannerMaxBytes - used;
  if (room < 1) return 0;
  return room;
}

/// Joins `app` with `templates_*` and `settings_json_*` parts.
CloudSettings? cloudSettingsFromDocuments(
  Map<String, Map<String, Object?>> documents,
) {
  final app = documents['app'];
  if (app == null) return null;
  final settings = CloudSettings.fromMap(app);
  if (settings == null) return null;
  final templates = _joinField(
    documents,
    'templatesJson',
    settings.templatesJson,
  );
  final settingsJson = _joinField(
    documents,
    'settingsJson',
    settings.settingsJson,
  );
  if (templates == settings.templatesJson &&
      settingsJson == settings.settingsJson) {
    return settings;
  }
  return CloudSettings(
    updatedAt: settings.updatedAt,
    weightUnit: settings.weightUnit,
    bodyWeightLbs: settings.bodyWeightLbs,
    templatesJson: templates,
    settingsJson: settingsJson,
    preferences: settings.preferences,
  );
}

String? _joinField(
  Map<String, Map<String, Object?>> documents,
  String field,
  String? inline,
) {
  final count = _asInt(documents['app']?[_partCountKey(field)]);
  if (count == null || count <= 0) return inline;
  final buffer = StringBuffer();
  for (var index = 0; index < count; index++) {
    final data = documents[_partDocId(field, index)]?['data'];
    if (data is! String) return inline;
    buffer.write(data);
  }
  return buffer.toString();
}

int? _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return null;
}
