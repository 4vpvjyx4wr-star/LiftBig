import '../model/journal_day.dart';
import 'firestore_limits.dart';

/// Cloud copy of the journal. Implementations must only touch the signed-in user.
abstract class DayRemote {
  Future<Map<String, JournalDay>> fetchDays();

  Future<Map<String, DayTombstone>> fetchTombstones();

  Future<void> putDay(JournalDay day);

  /// Writes the documents for one calendar day and deletes leftover parts.
  ///
  /// Keys are document ids under `users/{uid}/days`. A day that fits uses
  /// [dateKey]. A split day also uses `[dateKey]__2`, `[dateKey]__3`, and so
  /// on. The default reassembles the parts and stores one [JournalDay].
  Future<void> replaceDayDocuments(
    String dateKey,
    Map<String, Map<String, Object?>> documents,
  ) async {
    final day = journalDayFromPartDocuments(documents);
    if (day == null) return;
    await putDay(day);
  }

  /// Writes `{deleted: true, updatedAt}` and removes that date's content,
  /// including every split part.
  Future<void> putTombstone(DayTombstone tombstone);

  Future<CloudSettings?> fetchSettings();

  Future<void> putSettings(CloudSettings settings);

  /// Every document under `users/{uid}/settings`, keyed by document id.
  Future<Map<String, Map<String, Object?>>> fetchSettingsDocuments() async {
    final settings = await fetchSettings();
    if (settings == null) return const {};
    return {'app': settings.toMap()};
  }

  /// Replaces this user's settings documents. Keys are document ids.
  ///
  /// The default stores one [CloudSettings] value. Remotes that can write
  /// more than one document override this and keep each map under 1 MiB.
  Future<void> replaceSettingsDocuments(
    Map<String, Map<String, Object?>> documents,
  ) async {
    final settings = cloudSettingsFromDocuments(documents);
    if (settings == null) return;
    await putSettings(settings);
  }

  /// Deletes this user's day documents and settings documents.
  Future<void> deleteAll();
}
