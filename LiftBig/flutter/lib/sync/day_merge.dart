import 'dart:convert';

import '../model/journal_day.dart';

enum MergeSide { local, remote }

class ChosenDay {
  const ChosenDay(this.day, this.side);

  final JournalDay day;
  final MergeSide side;
}

class ChosenSettings {
  const ChosenSettings(this.settings, this.side);

  final CloudSettings settings;
  final MergeSide side;
}

/// Newer `updatedAt` wins. Equal stamps keep the local day, matching the Vue
/// rule where the remote copy wins only when its stamp is strictly greater.
ChosenDay? chooseNewerDay(JournalDay? local, JournalDay? remote) {
  if (local == null && remote == null) return null;
  if (local == null) return ChosenDay(remote!, MergeSide.remote);
  if (remote == null) return ChosenDay(local, MergeSide.local);
  if (remote.updatedAt.compareTo(local.updatedAt) > 0) {
    return ChosenDay(remote, MergeSide.remote);
  }
  return ChosenDay(local, MergeSide.local);
}

ChosenSettings? chooseNewerSettings(
  CloudSettings? local,
  CloudSettings? remote,
) {
  if (local == null && remote == null) return null;
  if (local == null) return ChosenSettings(remote!, MergeSide.remote);
  if (remote == null) return ChosenSettings(local, MergeSide.local);
  if (remote.updatedAt.compareTo(local.updatedAt) > 0) {
    return ChosenSettings(remote, MergeSide.remote);
  }
  return ChosenSettings(local, MergeSide.local);
}

/// True when two day maps would store the same journal content.
bool sameDayContent(JournalDay left, JournalDay right) {
  return jsonEncode(left.toMap()) == jsonEncode(right.toMap());
}

bool sameSettingsContent(CloudSettings left, CloudSettings right) {
  return jsonEncode(left.toMap()) == jsonEncode(right.toMap());
}
