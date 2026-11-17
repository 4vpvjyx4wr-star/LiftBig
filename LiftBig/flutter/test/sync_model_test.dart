import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liftbig/data/app_database.dart';
import 'package:liftbig/journal/journal_repository.dart';
import 'package:liftbig/model/journal_day.dart';
import 'package:liftbig/sync/day_remote.dart';
import 'package:liftbig/sync/journal_sync.dart';
import 'package:liftbig/utils/weight_units.dart';

JournalDay sampleDay({
  String dateKey = '2026-10-01',
  String updatedAt = '2026-10-01T10:00:00.000Z',
  String weight = '185',
}) {
  return JournalDay(
    dateKey: dateKey,
    updatedAt: updatedAt,
    exercises: [
      JournalExercise(
        id: 'ex',
        sortOrder: 0,
        name: 'Bench Press',
        sets: [
          JournalSet(id: 's', sortOrder: 0, reps: '5', weight: weight),
        ],
      ),
    ],
  );
}

class MemoryRemote implements DayRemote {
  final Map<String, JournalDay> days = {};
  final Map<String, DayTombstone> tombstones = {};
  CloudSettings? settings;

  @override
  Future<Map<String, JournalDay>> fetchDays() async => Map.of(days);

  @override
  Future<Map<String, DayTombstone>> fetchTombstones() async =>
      Map.of(tombstones);

  @override
  Future<void> putDay(JournalDay day) async {
    days[day.dateKey] = day;
    tombstones.remove(day.dateKey);
  }

  @override
  Future<void> putTombstone(DayTombstone tombstone) async {
    tombstones[tombstone.dateKey] = tombstone;
    days.remove(tombstone.dateKey);
  }

  @override
  Future<CloudSettings?> fetchSettings() async => settings;

  @override
  Future<void> putSettings(CloudSettings value) async {
    settings = value;
  }

  @override
  Future<void> deleteAll() async {
    days.clear();
    tombstones.clear();
    settings = null;
  }
}

void main() {
  test('newer tombstone deletes both copies', () async {
    final journal = JournalRepository(AppDatabase(NativeDatabase.memory()));
    addTearDown(journal.db.close);
    await journal.replaceDay(
      sampleDay(updatedAt: '2026-10-01T10:00:00.000Z', weight: '185'),
    );
    final remote = MemoryRemote()
      ..tombstones['2026-10-01'] = const DayTombstone(
        dateKey: '2026-10-01',
        deletedAt: '2026-10-01T12:00:00.000Z',
      );

    await JournalSync(journal: journal, remote: remote).sync();

    expect(await journal.getDay('2026-10-01'), isNull);
    expect(
      (await journal.allTombstones())['2026-10-01']?.deletedAt,
      '2026-10-01T12:00:00.000Z',
    );
    expect(remote.days.containsKey('2026-10-01'), isFalse);
    expect(
      remote.tombstones['2026-10-01']?.deletedAt,
      '2026-10-01T12:00:00.000Z',
    );

    final other = JournalRepository(AppDatabase(NativeDatabase.memory()));
    addTearDown(other.db.close);
    await other.replaceDay(
      sampleDay(
        dateKey: '2026-10-02',
        updatedAt: '2026-10-02T08:00:00.000Z',
        weight: '135',
      ),
    );
    await other.deleteDay('2026-10-02');
    final olderRemote = MemoryRemote()
      ..days['2026-10-02'] = sampleDay(
        dateKey: '2026-10-02',
        updatedAt: '2026-10-02T08:00:00.000Z',
        weight: '135',
      );
    await JournalSync(journal: other, remote: olderRemote).sync();
    expect(await other.getDay('2026-10-02'), isNull);
    expect(olderRemote.days.containsKey('2026-10-02'), isFalse);
    expect(olderRemote.tombstones.containsKey('2026-10-02'), isTrue);
  });

  test('a newer edit beats an older tombstone', () async {
    final journal = JournalRepository(AppDatabase(NativeDatabase.memory()));
    addTearDown(journal.db.close);
    await journal.applyRemoteDeletion(
      '2026-10-01',
      '2026-10-01T08:00:00.000Z',
    );
    final remote = MemoryRemote()
      ..days['2026-10-01'] = sampleDay(
        updatedAt: '2026-10-01T12:00:00.000Z',
        weight: '205',
      );

    var notices = 0;
    journal.addLocalWriteListener(() => notices++);
    final first = await JournalSync(journal: journal, remote: remote).sync();

    expect(first.downloaded, 1);
    expect(first.uploaded, 0);
    expect(notices, 0);
    final restored = await journal.getDay('2026-10-01');
    expect(restored!.exercises.single.sets.single.weight, '205');
    expect(await journal.allTombstones(), isEmpty);
    expect(remote.days['2026-10-01']!.exercises.single.sets.single.weight, '205');
    expect(remote.tombstones.containsKey('2026-10-01'), isFalse);

    final localEdit = JournalRepository(AppDatabase(NativeDatabase.memory()));
    addTearDown(localEdit.db.close);
    await localEdit.replaceDay(
      sampleDay(updatedAt: '2026-10-01T15:00:00.000Z', weight: '225'),
    );
    final oldTomb = MemoryRemote()
      ..tombstones['2026-10-01'] = const DayTombstone(
        dateKey: '2026-10-01',
        deletedAt: '2026-10-01T09:00:00.000Z',
      );
    await JournalSync(journal: localEdit, remote: oldTomb).sync();
    expect(
      (await localEdit.getDay('2026-10-01'))!.exercises.single.sets.single.weight,
      '225',
    );
    expect((await localEdit.allTombstones()).containsKey('2026-10-01'), isFalse);
    expect(oldTomb.days['2026-10-01']!.exercises.single.sets.single.weight, '225');
    expect(oldTomb.tombstones.containsKey('2026-10-01'), isFalse);
  });

  test('equal stamps keep the local copy', () async {
    const stamp = '2026-10-01T12:00:00.000Z';
    final journal = JournalRepository(AppDatabase(NativeDatabase.memory()));
    addTearDown(journal.db.close);
    await journal.replaceDay(sampleDay(updatedAt: stamp, weight: '185'));
    final remote = MemoryRemote()
      ..tombstones['2026-10-01'] = const DayTombstone(
        dateKey: '2026-10-01',
        deletedAt: stamp,
      );

    await JournalSync(journal: journal, remote: remote).sync();

    expect(
      (await journal.getDay('2026-10-01'))!.exercises.single.sets.single.weight,
      '185',
    );
    expect((await journal.allTombstones()).containsKey('2026-10-01'), isFalse);
    expect(remote.days['2026-10-01']!.exercises.single.sets.single.weight, '185');
    expect(remote.tombstones.containsKey('2026-10-01'), isFalse);
  });

  test('moving a day tombstones the old date', () async {
    final journal = JournalRepository(AppDatabase(NativeDatabase.memory()));
    addTearDown(journal.db.close);
    await journal.replaceDay(
      sampleDay(dateKey: '2026-10-03', weight: '155'),
    );
    expect(await journal.moveDay('2026-10-03', '2026-10-04'), 'moved');
    expect(await journal.getDay('2026-10-03'), isNull);
    expect(await journal.getDay('2026-10-04'), isNotNull);
    expect((await journal.allTombstones()).containsKey('2026-10-03'), isTrue);
    expect((await journal.allTombstones()).containsKey('2026-10-04'), isFalse);
  });

  test('weight unit and body weight stamp settings for the cloud document', () async {
    final journal = JournalRepository(AppDatabase(NativeDatabase.memory()));
    addTearDown(journal.db.close);
    expect(await journal.localCloudSettings(), isNull);

    await journal.setSyncEnabled(true);
    expect(await journal.localCloudSettings(), isNull);

    await journal.setWeightUnit(WeightUnit.kg);
    final afterUnit = await journal.localCloudSettings();
    expect(afterUnit, isNotNull);
    expect(afterUnit!.updatedAt, isNotEmpty);
    expect(afterUnit.weightUnit, 'kg');
    expect(afterUnit.preferences['weight_unit'], 'kg');
    expect(afterUnit.preferences.containsKey('sync_enabled'), isFalse);
    expect(afterUnit.preferences.containsKey('pro_tester_unlock'), isFalse);
    expect(afterUnit.preferences.containsKey('health_workout_writes'), isFalse);
    expect(afterUnit.preferences.containsKey('rest_timer_state'), isFalse);

    await journal.setBodyWeightLbs(180);
    final afterBody = await journal.localCloudSettings();
    expect(afterBody!.bodyWeightLbs, 180);
    expect(afterBody.preferences['body_weight_lbs'], isNotEmpty);
    expect(afterBody.updatedAt.compareTo(afterUnit.updatedAt) >= 0, isTrue);
    expect(afterBody.preferences.containsKey('height_inches'), isTrue);
    expect(afterBody.preferences.containsKey('color_theme_id'), isTrue);
    expect(afterBody.preferences.containsKey('auto_fill_sets'), isTrue);
    expect(afterBody.preferences.containsKey('daily_lift_reminder_enabled'), isTrue);
  });

  test('applying a remote day does not mark that day dirty', () async {
    final journal = JournalRepository(AppDatabase(NativeDatabase.memory()));
    addTearDown(journal.db.close);
    var notices = 0;
    journal.addLocalWriteListener(() => notices++);
    final remote = MemoryRemote()
      ..days['2026-10-05'] = sampleDay(
        dateKey: '2026-10-05',
        updatedAt: '2026-10-05T18:00:00.000Z',
        weight: '225',
      );

    final first = await JournalSync(journal: journal, remote: remote).sync();
    expect(first.downloaded, 1);
    expect(first.uploaded, 0);
    expect(notices, 0);
    expect(
      (await journal.getDay('2026-10-05'))!.exercises.single.sets.single.weight,
      '225',
    );

    final second = await JournalSync(journal: journal, remote: remote).sync();
    expect(second.uploaded, 0);
    expect(second.downloaded, 0);
    expect(notices, 0);
    expect(remote.days['2026-10-05']!.updatedAt, '2026-10-05T18:00:00.000Z');
  });
}
