import 'dart:convert';

import '../journal/journal_repository.dart';
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

/// One side's winner between day content and a tombstone.
class DaySnapshot {
  const DaySnapshot.content(this.day) : deletedAt = null, dateKey = null;

  const DaySnapshot.deleted(this.dateKey, this.deletedAt) : day = null;

  final JournalDay? day;
  final String? deletedAt;
  final String? dateKey;

  bool get isDeleted => day == null;

  String get stamp => day?.updatedAt ?? deletedAt!;
}

class ChosenSnapshot {
  const ChosenSnapshot(this.snapshot, this.side);

  final DaySnapshot snapshot;
  final MergeSide side;
}

/// Newer stamp wins. An equal stamp between content and a tombstone keeps
/// the day. Callers then compare the two sides.
DaySnapshot? resolveDaySnapshot(JournalDay? day, DayTombstone? tombstone) {
  if (day == null && tombstone == null) return null;
  if (day == null) {
    return DaySnapshot.deleted(tombstone!.dateKey, tombstone.deletedAt);
  }
  if (tombstone == null) return DaySnapshot.content(day);
  if (tombstone.deletedAt.compareTo(day.updatedAt) > 0) {
    return DaySnapshot.deleted(tombstone.dateKey, tombstone.deletedAt);
  }
  return DaySnapshot.content(day);
}

/// Newer `updatedAt` wins. Equal stamps keep the local snapshot.
ChosenSnapshot? chooseNewerSnapshot(DaySnapshot? local, DaySnapshot? remote) {
  if (local == null && remote == null) return null;
  if (local == null) return ChosenSnapshot(remote!, MergeSide.remote);
  if (remote == null) return ChosenSnapshot(local, MergeSide.local);
  if (remote.stamp.compareTo(local.stamp) > 0) {
    return ChosenSnapshot(remote, MergeSide.remote);
  }
  return ChosenSnapshot(local, MergeSide.local);
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

/// Keeps a real height or body weight from either side.
///
/// A blank value must not replace a number. Theme and the other preferences
/// still follow [primary].
CloudSettings preserveBodyMeasurements(
  CloudSettings primary,
  CloudSettings? fallback,
) {
  final preferences = Map<String, String>.from(primary.preferences);
  final height = _keptMeasurement(
    preferences[SettingKeys.heightInches],
    fallback?.preferences[SettingKeys.heightInches],
  );
  final bodyText = _keptMeasurement(
    preferences[SettingKeys.bodyWeightLbs],
    fallback?.preferences[SettingKeys.bodyWeightLbs] ??
        fallback?.bodyWeightLbs?.toString(),
  );
  final resolvedBody = bodyText ?? primary.bodyWeightLbs?.toString();
  if (height == null) {
    preferences.remove(SettingKeys.heightInches);
  } else {
    preferences[SettingKeys.heightInches] = height;
  }
  if (resolvedBody == null || resolvedBody.trim().isEmpty) {
    preferences.remove(SettingKeys.bodyWeightLbs);
  } else {
    preferences[SettingKeys.bodyWeightLbs] = resolvedBody;
  }
  final parsedBody = double.tryParse(resolvedBody?.trim() ?? '');
  return CloudSettings(
    updatedAt: primary.updatedAt,
    weightUnit: primary.weightUnit,
    bodyWeightLbs: parsedBody == null || parsedBody <= 0 ? null : parsedBody,
    templatesJson: primary.templatesJson,
    settingsJson: primary.settingsJson,
    preferences: preferences,
  );
}

String? _keptMeasurement(String? primary, String? fallback) {
  final current = primary?.trim() ?? '';
  if (current.isNotEmpty) return primary;
  final previous = fallback?.trim() ?? '';
  if (previous.isNotEmpty) return fallback;
  return null;
}
