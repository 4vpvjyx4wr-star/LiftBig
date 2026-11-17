import '../model/journal_day.dart';

/// Cloud copy of the journal. Implementations must only touch the signed-in user.
abstract class DayRemote {
  Future<Map<String, JournalDay>> fetchDays();

  Future<Map<String, DayTombstone>> fetchTombstones();

  Future<void> putDay(JournalDay day);

  /// Writes `{deleted: true, updatedAt}` and removes that date's content.
  Future<void> putTombstone(DayTombstone tombstone);

  Future<CloudSettings?> fetchSettings();

  Future<void> putSettings(CloudSettings settings);

  /// Deletes this user's day documents and settings document.
  Future<void> deleteAll();
}
