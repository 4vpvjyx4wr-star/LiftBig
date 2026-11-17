import '../journal/journal_repository.dart';
import '../model/journal_day.dart';
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

/// Pushes and pulls one day at a time. The newer stamp wins between content
/// and a tombstone. Equal stamps keep the phone's copy.
class JournalSync {
  JournalSync({required this.journal, required this.remote});

  final JournalRepository journal;
  final DayRemote remote;

  Future<SyncResult> sync() async {
    final localDays = {
      for (final day in await journal.allDays()) day.dateKey: day,
    };
    final localTombs = await journal.allTombstones();
    final remoteDays = await remote.fetchDays();
    final remoteTombs = await remote.fetchTombstones();
    final keys = {
      ...localDays.keys,
      ...localTombs.keys,
      ...remoteDays.keys,
      ...remoteTombs.keys,
    };

    var uploaded = 0;
    var downloaded = 0;
    for (final key in keys) {
      final chosen = chooseNewerSnapshot(
        resolveDaySnapshot(localDays[key], localTombs[key]),
        resolveDaySnapshot(remoteDays[key], remoteTombs[key]),
      );
      if (chosen == null) continue;
      if (chosen.side == MergeSide.remote) {
        await _applyRemote(key, chosen.snapshot);
        downloaded += 1;
        continue;
      }
      if (chosen.snapshot.isDeleted) {
        final stamp = chosen.snapshot.deletedAt!;
        final remoteTomb = remoteTombs[key];
        final remoteAlready =
            remoteTomb != null &&
            remoteTomb.deletedAt == stamp &&
            !remoteDays.containsKey(key);
        if (!remoteAlready) {
          await remote.putTombstone(
            DayTombstone(dateKey: key, deletedAt: stamp),
          );
          uploaded += 1;
        }
        final localTomb = localTombs[key];
        final localAlready =
            !localDays.containsKey(key) &&
            localTomb != null &&
            localTomb.deletedAt == stamp;
        if (!localAlready) {
          await journal.runWithoutLocalWriteNotice(
            () => journal.applyRemoteDeletion(key, stamp),
          );
        }
        continue;
      }
      final day = chosen.snapshot.day!;
      final remoteDay = remoteDays[key];
      final needsUpload =
          remoteTombs.containsKey(key) ||
          remoteDay == null ||
          !sameDayContent(remoteDay, day);
      if (needsUpload) {
        await remote.putDay(day);
        uploaded += 1;
      }
      if (localTombs.containsKey(key)) {
        await journal.runWithoutLocalWriteNotice(
          () => journal.clearTombstone(key),
        );
      }
    }

    final localSettings = await journal.localCloudSettings();
    final remoteSettings = await remote.fetchSettings();
    final chosenSettings = chooseNewerSettings(localSettings, remoteSettings);
    if (chosenSettings != null) {
      if (chosenSettings.side == MergeSide.remote) {
        await journal.runWithoutLocalWriteNotice(
          () => journal.applyCloudSettings(chosenSettings.settings),
        );
        downloaded += 1;
      } else if (remoteSettings == null ||
          !sameSettingsContent(remoteSettings, chosenSettings.settings)) {
        await remote.putSettings(chosenSettings.settings);
        uploaded += 1;
      }
    }

    return SyncResult(uploaded: uploaded, downloaded: downloaded);
  }

  Future<void> _applyRemote(String key, DaySnapshot snapshot) {
    return journal.runWithoutLocalWriteNotice(() async {
      if (snapshot.isDeleted) {
        await journal.applyRemoteDeletion(key, snapshot.deletedAt!);
        return;
      }
      await journal.replaceDay(snapshot.day!);
    });
  }
}
