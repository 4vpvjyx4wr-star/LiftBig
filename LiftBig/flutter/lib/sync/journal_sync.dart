import '../journal/journal_repository.dart';
import '../model/journal_day.dart';
import 'day_merge.dart';
import 'day_remote.dart';
import 'firestore_limits.dart';

class SyncResult {
  const SyncResult({
    this.uploaded = 0,
    this.downloaded = 0,
    this.skippedReason,
    this.settingsDownloaded = false,
  });

  final int uploaded;
  final int downloaded;
  final String? skippedReason;

  /// True when a newer account snapshot was written onto this phone.
  final bool settingsDownloaded;

  bool get skipped => skippedReason != null;
}

/// Pushes and pulls one day at a time. The newer stamp wins between content
/// and a tombstone. Equal stamps keep the phone's copy.
class JournalSync {
  JournalSync({
    required this.journal,
    required this.remote,
    this.premadeTemplateIds = const {},
  });

  final JournalRepository journal;
  final DayRemote remote;

  /// Workout and plan ids that already ship on the device. They are left out
  /// of the cloud settings document.
  final Set<String> premadeTemplateIds;

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
    var skippedDays = 0;
    var skippedExercises = 0;
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
      final upload = planDayUpload(day);
      final stored = upload.storedDay;
      if (upload.documents.isEmpty || stored == null) {
        skippedDays += 1;
      } else {
        final remoteDay = remoteDays[key];
        final needsUpload =
            remoteTombs.containsKey(key) ||
            remoteDay == null ||
            !sameDayContent(remoteDay, stored);
        if (!needsUpload) {
          skippedExercises += upload.skippedExercises;
        } else {
          try {
            await remote.replaceDayDocuments(day.dateKey, upload.documents);
            uploaded += 1;
            skippedExercises += upload.skippedExercises;
          } catch (error) {
            if (!isDocumentTooLarge(error)) rethrow;
            skippedDays += 1;
          }
        }
      }
      if (localTombs.containsKey(key)) {
        await journal.runWithoutLocalWriteNotice(
          () => journal.clearTombstone(key),
        );
      }
    }

    final premadeIds = premadeTemplateIds;
    final localSettings = await journal.localCloudSettings();
    final remoteSettings = cloudSettingsFromDocuments(
      await remote.fetchSettingsDocuments(),
    );
    final chosenSettings = chooseNewerSettings(localSettings, remoteSettings);
    var skippedSettings = false;
    var settingsDownloaded = false;
    if (chosenSettings != null) {
      if (chosenSettings.side == MergeSide.remote) {
        await journal.runWithoutLocalWriteNotice(
          () => journal.applyCloudSettings(chosenSettings.settings),
        );
        downloaded += 1;
        settingsDownloaded = true;
      } else {
        final localComparable = cloudComparableSettings(
          chosenSettings.settings,
          premadeIds,
        );
        final remoteComparable = remoteSettings == null
            ? null
            : cloudComparableSettings(remoteSettings, premadeIds);
        if (remoteComparable == null ||
            !sameSettingsContent(remoteComparable, localComparable)) {
          final upload = planSettingsUpload(localComparable);
          if (upload.excluded || upload.documents.isEmpty) {
            skippedSettings = true;
          } else {
            try {
              await remote.replaceSettingsDocuments(upload.documents);
              uploaded += 1;
            } catch (error) {
              if (!isDocumentTooLarge(error)) rethrow;
              skippedSettings = true;
            }
          }
        }
      }
    }

    return SyncResult(
      uploaded: uploaded,
      downloaded: downloaded,
      settingsDownloaded: settingsDownloaded,
      skippedReason: _skippedReason(
        skippedDays: skippedDays,
        skippedExercises: skippedExercises,
        skippedSettings: skippedSettings,
      ),
    );
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

String? _skippedReason({
  required int skippedDays,
  required int skippedExercises,
  required bool skippedSettings,
}) {
  final parts = <String>[];
  if (skippedDays == 1) {
    parts.add('Skipped 1 day that is too large to sync.');
  } else if (skippedDays > 1) {
    parts.add('Skipped $skippedDays days that are too large to sync.');
  }
  if (skippedExercises == 1) {
    parts.add('Skipped 1 exercise that is too large to sync.');
  } else if (skippedExercises > 1) {
    parts.add(
      'Skipped $skippedExercises exercises that are too large to sync.',
    );
  }
  if (skippedSettings) {
    parts.add('Skipped saved plans that are too large to sync.');
  }
  if (parts.isEmpty) return null;
  return parts.join(' ');
}
