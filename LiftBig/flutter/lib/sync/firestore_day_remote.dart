import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/journal_day.dart';
import 'day_remote.dart';
import 'firestore_limits.dart';

/// `users/{uid}/days/{dateKey}` and `users/{uid}/settings/{docId}`.
///
/// A day that fits stays on `days/{dateKey}`. A larger day is split into
/// sibling documents `days/{dateKey}`, `days/{dateKey}__2`, and so on. The
/// `dateKey` field on every part is the calendar day.
///
/// Preferences live on `settings/app`. Saved plans that do not fit in that
/// document are split across `settings/templates_0`, `templates_1`, and so on.
class FirestoreDayRemote implements DayRemote {
  FirestoreDayRemote(this.uid, {FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final String uid;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _days =>
      _firestore.collection('users').doc(uid).collection('days');

  CollectionReference<Map<String, dynamic>> get _settings =>
      _firestore.collection('users').doc(uid).collection('settings');

  @override
  Future<Map<String, JournalDay>> fetchDays() async {
    final snapshot = await _days.get();
    return daysFromStoredDocs([
      for (final doc in snapshot.docs)
        StoredDayDocument(doc.id, Map<String, Object?>.from(doc.data())),
    ]);
  }

  @override
  Future<Map<String, DayTombstone>> fetchTombstones() async {
    final snapshot = await _days.get();
    return tombstonesFromStoredDocs([
      for (final doc in snapshot.docs)
        StoredDayDocument(doc.id, Map<String, Object?>.from(doc.data())),
    ]);
  }

  @override
  Future<void> putDay(JournalDay day) async {
    final upload = planDayUpload(day);
    if (upload.documents.isEmpty) {
      throw StateError(
        'days/${day.dateKey} cannot be written because its size exceeds the maximum allowed size of 1,048,576 bytes',
      );
    }
    await replaceDayDocuments(day.dateKey, upload.documents);
  }

  @override
  Future<void> replaceDayDocuments(
    String dateKey,
    Map<String, Map<String, Object?>> documents,
  ) async {
    final existing = await _docsForDate(dateKey);
    await _applyDayWrite(
      planReplaceDayDocuments(
        dateKey: dateKey,
        existing: existing,
        documents: documents,
      ),
    );
  }

  @override
  Future<void> putTombstone(DayTombstone tombstone) async {
    final existing = await _docsForDate(tombstone.dateKey);
    await _applyDayWrite(
      planTombstoneDocuments(tombstone: tombstone, existing: existing),
    );
  }

  Future<Map<String, Map<String, Object?>>> _docsForDate(String dateKey) async {
    final snapshot = await _days.where('dateKey', isEqualTo: dateKey).get();
    return {
      for (final doc in snapshot.docs)
        doc.id: Map<String, Object?>.from(doc.data()),
    };
  }

  Future<void> _applyDayWrite(DayDocumentWrite write) {
    return _commitWrites([
      for (final id in write.deleteIds)
        (WriteBatch batch) => batch.delete(_days.doc(id)),
      for (final entry in write.upserts.entries)
        (WriteBatch batch) =>
            _days.doc(entry.key).set(Map<String, dynamic>.from(entry.value)),
    ]);
  }

  @override
  Future<CloudSettings?> fetchSettings() async {
    return cloudSettingsFromDocuments(await fetchSettingsDocuments());
  }

  @override
  Future<Map<String, Map<String, Object?>>> fetchSettingsDocuments() async {
    final snapshot = await _settings.get();
    return {
      for (final doc in snapshot.docs)
        doc.id: Map<String, Object?>.from(doc.data()),
    };
  }

  @override
  Future<void> putSettings(CloudSettings settings) {
    final upload = planSettingsUpload(settings);
    if (upload.documents.isEmpty) {
      throw StateError(
        'settings/app cannot be written because its size exceeds the maximum allowed size of 1,048,576 bytes',
      );
    }
    return replaceSettingsDocuments(upload.documents);
  }

  @override
  Future<void> replaceSettingsDocuments(
    Map<String, Map<String, Object?>> documents,
  ) async {
    final existing = await _settings.get();
    final keep = documents.keys.toSet();
    await _commitWrites([
      for (final doc in existing.docs)
        if (!keep.contains(doc.id))
          (WriteBatch batch) => batch.delete(doc.reference),
      for (final entry in documents.entries)
        (WriteBatch batch) => _settings
            .doc(entry.key)
            .set(Map<String, dynamic>.from(entry.value)),
    ]);
  }

  Future<void> _commitWrites(
    List<void Function(WriteBatch batch)> writes,
  ) async {
    const limit = 450;
    for (var start = 0; start < writes.length; start += limit) {
      final batch = _firestore.batch();
      final end = start + limit < writes.length ? start + limit : writes.length;
      for (var index = start; index < end; index++) {
        writes[index](batch);
      }
      await batch.commit();
    }
  }

  @override
  Future<void> deleteAll() async {
    await _deleteCollection(_days);
    await _deleteCollection(_settings);
  }

  Future<void> _deleteCollection(
    CollectionReference<Map<String, dynamic>> collection,
  ) async {
    while (true) {
      final snapshot = await collection.limit(450).get();
      if (snapshot.docs.isEmpty) break;
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      if (snapshot.docs.length < 450) break;
    }
  }
}
