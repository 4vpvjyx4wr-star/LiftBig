import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/journal_day.dart';
import 'day_remote.dart';

/// `users/{uid}/days/{dateKey}` and `users/{uid}/settings/app`.
class FirestoreDayRemote implements DayRemote {
  FirestoreDayRemote(this.uid, {FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final String uid;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _days => _firestore
      .collection('users')
      .doc(uid)
      .collection('days');

  DocumentReference<Map<String, dynamic>> get _settings => _firestore
      .collection('users')
      .doc(uid)
      .collection('settings')
      .doc('app');

  @override
  Future<Map<String, JournalDay>> fetchDays() async {
    final snapshot = await _days.get();
    final days = <String, JournalDay>{};
    for (final doc in snapshot.docs) {
      final data = Map<String, Object?>.from(doc.data());
      if (data['deleted'] == true) continue;
      data['dateKey'] = doc.id;
      final day = JournalDay.fromMap(data);
      if (day == null || day.updatedAt.isEmpty) continue;
      days[doc.id] = day;
    }
    return days;
  }

  @override
  Future<Map<String, DayTombstone>> fetchTombstones() async {
    final snapshot = await _days.get();
    final tombstones = <String, DayTombstone>{};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (data['deleted'] != true) continue;
      final deletedAt = data['updatedAt'];
      if (deletedAt is! String || deletedAt.isEmpty) continue;
      tombstones[doc.id] = DayTombstone(dateKey: doc.id, deletedAt: deletedAt);
    }
    return tombstones;
  }

  @override
  Future<void> putDay(JournalDay day) {
    return _days.doc(day.dateKey).set(day.toMap());
  }

  @override
  Future<void> putTombstone(DayTombstone tombstone) {
    return _days.doc(tombstone.dateKey).set({
      'deleted': true,
      'updatedAt': tombstone.deletedAt,
      'dateKey': tombstone.dateKey,
    });
  }

  @override
  Future<CloudSettings?> fetchSettings() async {
    final snapshot = await _settings.get();
    final data = snapshot.data();
    if (data == null) return null;
    return CloudSettings.fromMap(Map<String, Object?>.from(data));
  }

  @override
  Future<void> putSettings(CloudSettings settings) {
    return _settings.set(settings.toMap());
  }

  @override
  Future<void> deleteAll() async {
    while (true) {
      final snapshot = await _days.limit(450).get();
      if (snapshot.docs.isEmpty) break;
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      if (snapshot.docs.length < 450) break;
    }
    await _settings.delete();
  }
}
