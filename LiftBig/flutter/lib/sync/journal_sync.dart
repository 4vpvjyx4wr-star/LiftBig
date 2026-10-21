import '../journal/journal_repository.dart';
import 'day_merge.dart';
import 'day_remote.dart';

class SyncResult {
  const SyncResult({
    this.uploaded = 0,
    this.downloaded = 0,
    this.skippedReason,
  });

  final int uploaded;
  final int downloaded;
  final String? skippedReason;

  bool get skipped => skippedReason != null;
}

/// Pushes and pulls one day at a time. The newer `updatedAt` wins.
class JournalSync {
  JournalSync({required this.journal, required this.remote});

  final JournalRepository journal;
  final DayRemote remote;

  Future<SyncResult> sync() async {
    final localDays = await journal.allDays();
    final remoteDays = await remote.fetchDays();
    final localByKey = {for (final day in localDays) day.dateKey: day};
    final keys = {...localByKey.keys, ...remoteDays.keys};

    var uploaded = 0;
    var downloaded = 0;
    for (final key in keys) {
      final chosen = chooseNewerDay(localByKey[key], remoteDays[key]);
      if (chosen == null) continue;
      if (chosen.side == MergeSide.remote) {
        await journal.replaceDay(chosen.day);
        downloaded += 1;
        continue;
      }
      final remoteDay = remoteDays[key];
      if (remoteDay == null || !sameDayContent(remoteDay, chosen.day)) {
        await remote.putDay(chosen.day);
        uploaded += 1;
      }
    }

    final localSettings = await journal.localCloudSettings();
    final remoteSettings = await remote.fetchSettings();
    final chosenSettings = chooseNewerSettings(localSettings, remoteSettings);
    if (chosenSettings != null) {
      if (chosenSettings.side == MergeSide.remote) {
        await journal.applyCloudSettings(chosenSettings.settings);
        downloaded += 1;
      } else if (remoteSettings == null ||
          !sameSettingsContent(remoteSettings, chosenSettings.settings)) {
        await remote.putSettings(chosenSettings.settings);
        uploaded += 1;
      }
    }

    return SyncResult(uploaded: uploaded, downloaded: downloaded);
  }
}
