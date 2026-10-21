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
      data['dateKey'] = doc.id;
      final day = JournalDay.fromMap(data);
      if (day == null || day.updatedAt.isEmpty) continue;
      days[doc.id] = day;
    }
    return days;
  }

  @override
  Future<void> putDay(JournalDay day) {
    return _days.doc(day.dateKey).set(day.toMap());
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
}
