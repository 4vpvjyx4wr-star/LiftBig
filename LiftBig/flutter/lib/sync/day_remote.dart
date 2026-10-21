import '../model/journal_day.dart';

/// Cloud copy of the journal. Implementations must only touch the signed-in user.
abstract class DayRemote {
  Future<Map<String, JournalDay>> fetchDays();

  Future<void> putDay(JournalDay day);

  Future<CloudSettings?> fetchSettings();

  Future<void> putSettings(CloudSettings settings);
}
