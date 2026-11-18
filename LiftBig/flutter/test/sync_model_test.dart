import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liftbig/data/app_database.dart';
import 'package:liftbig/health/health_workout.dart';
import 'package:liftbig/journal/app_settings.dart';
import 'package:liftbig/journal/journal_repository.dart';
import 'package:liftbig/model/journal_day.dart';
import 'package:liftbig/rest/rest_timer_state.dart';
import 'package:liftbig/sync/day_merge.dart';
import 'package:liftbig/sync/day_remote.dart';
import 'package:liftbig/sync/firestore_limits.dart';
import 'package:liftbig/sync/journal_sync.dart';
import 'package:liftbig/sync/sync_controller.dart';
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
        sets: [JournalSet(id: 's', sortOrder: 0, reps: '5', weight: weight)],
      ),
    ],
  );
}

class MemoryRemote extends DayRemote {
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
    await journal.applyRemoteDeletion('2026-10-01', '2026-10-01T08:00:00.000Z');
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
    expect(
      remote.days['2026-10-01']!.exercises.single.sets.single.weight,
      '205',
    );
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
      (await localEdit.getDay('2026-10-01'))!
          .exercises
          .single
          .sets
          .single
          .weight,
      '225',
    );
    expect(
      (await localEdit.allTombstones()).containsKey('2026-10-01'),
      isFalse,
    );
    expect(
      oldTomb.days['2026-10-01']!.exercises.single.sets.single.weight,
      '225',
    );
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
    expect(
      remote.days['2026-10-01']!.exercises.single.sets.single.weight,
      '185',
    );
    expect(remote.tombstones.containsKey('2026-10-01'), isFalse);
  });

  test('moving a day tombstones the old date', () async {
    final journal = JournalRepository(AppDatabase(NativeDatabase.memory()));
    addTearDown(journal.db.close);
    await journal.replaceDay(sampleDay(dateKey: '2026-10-03', weight: '155'));
    expect(await journal.moveDay('2026-10-03', '2026-10-04'), 'moved');
    expect(await journal.getDay('2026-10-03'), isNull);
    expect(await journal.getDay('2026-10-04'), isNotNull);
    expect((await journal.allTombstones()).containsKey('2026-10-03'), isTrue);
    expect((await journal.allTombstones()).containsKey('2026-10-04'), isFalse);
  });

  test(
    'weight unit and body weight stamp settings for the cloud document',
    () async {
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
      expect(afterUnit.preferences.containsKey('rest_timer_chrome'), isFalse);
      expect(afterUnit.preferences.containsKey('color_theme_id'), isFalse);
      expect(
        afterUnit.preferences.containsKey('rest_timer_ring_until_stopped'),
        isFalse,
      );
      expect(
        afterUnit.preferences.containsKey('health_workout_writes'),
        isFalse,
      );
      expect(afterUnit.preferences.containsKey('rest_timer_state'), isFalse);

      await journal.setColorThemeId('forest');
      await journal.saveRestTimerAlertSettings(
        const RestTimerAlertSettings(
          soundEnabled: true,
          vibrationEnabled: true,
          notificationEnabled: true,
          ringUntilStopped: true,
        ),
      );
      final afterTheme = await journal.localCloudSettings();
      expect(afterTheme!.preferences['color_theme_id'], 'forest');
      expect(afterTheme.preferences['rest_timer_ring_until_stopped'], 'true');

      await journal.setBodyWeightLbs(180);
      final afterBody = await journal.localCloudSettings();
      expect(afterBody!.bodyWeightLbs, 180);
      expect(afterBody.preferences['body_weight_lbs'], isNotEmpty);
      expect(afterBody.preferences['color_theme_id'], 'forest');
      expect(afterBody.preferences['rest_timer_ring_until_stopped'], 'true');
      expect(afterBody.updatedAt.compareTo(afterUnit.updatedAt) >= 0, isTrue);
      expect(afterBody.preferences.containsKey('height_inches'), isFalse);
      expect(afterBody.preferences.containsKey('auto_fill_sets'), isFalse);
      expect(
        afterBody.preferences.containsKey('daily_lift_reminder_enabled'),
        isFalse,
      );
    },
  );

  test('cloud sync restores theme, preferences, and the tester Pro flag', () async {
    final phone = JournalRepository(AppDatabase(NativeDatabase.memory()));
    addTearDown(phone.db.close);
    await phone.setSyncEnabled(true);
    await phone.setColorThemeId('forest');
    await phone.setWeightUnit(WeightUnit.kg);
    await phone.setShowPlateGraphicEnabled(false);
    await phone.saveRestTimerAnchored(true);
    await phone.setProTesterUnlock();
    await phone.saveRestTimerState(
      const RestTimerSnapshot(
        active: true,
        exerciseId: 'live',
        exerciseName: 'LIVE',
        fullSeconds: 30,
        paused: false,
        endAtEpochMs: 1,
      ),
    );
    await phone.saveHealthWorkoutWrites({
      '2026-10-01': const StoredHealthWrite(
        uuid: 'health-uuid',
        minutes: 40,
        meters: 0,
        kcal: 200,
      ),
    });

    final remote = MemoryRemote();
    final uploaded = await JournalSync(journal: phone, remote: remote).sync();
    expect(uploaded.uploaded, greaterThan(0));
    final cloud = remote.settings!;
    expect(cloud.preferences['color_theme_id'], 'forest');
    expect(cloud.preferences['weight_unit'], 'kg');
    expect(cloud.preferences['show_plate_graphic'], 'false');
    expect(cloud.preferences['rest_timer_chrome'], 'anchored');
    expect(cloud.preferences['pro_tester_unlock'], 'true');
    expect(cloud.preferences.containsKey('sync_enabled'), isFalse);
    expect(cloud.preferences.containsKey('rest_timer_state'), isFalse);
    expect(cloud.preferences.containsKey('health_workout_writes'), isFalse);
    expect(cloud.preferences.containsKey('rest_timer_tile_offset'), isFalse);

    final fresh = JournalRepository(AppDatabase(NativeDatabase.memory()));
    addTearDown(fresh.db.close);
    final restored = await JournalSync(journal: fresh, remote: remote).sync();
    expect(restored.downloaded, greaterThan(0));
    expect(await fresh.loadColorThemeId(), 'forest');
    expect(await fresh.storedWeightUnit(), WeightUnit.kg);
    expect(await fresh.showPlateGraphicEnabled(), isFalse);
    expect(await fresh.loadRestTimerAnchored(), isTrue);
    expect(await fresh.proTesterUnlockEnabled(), isTrue);
    expect(await fresh.isSyncEnabled(), isFalse);
    expect(await fresh.loadRestTimerState(), isNull);
    expect(await fresh.loadHealthWorkoutWrites(), isEmpty);

    final notPro = JournalRepository(AppDatabase(NativeDatabase.memory()));
    addTearDown(notPro.db.close);
    final denied = MemoryRemote()
      ..settings = CloudSettings(
        updatedAt: '2026-11-02T00:00:00.000Z',
        preferences: const {
          'color_theme_id': 'forest',
          'pro_tester_unlock': 'false',
        },
      );
    await JournalSync(journal: notPro, remote: denied).sync();
    expect(await notPro.loadColorThemeId(), 'forest');
    expect(await notPro.proTesterUnlockEnabled(), isFalse);
  });

  test(
    'theme and ring round-trip and sign-out leaves them on the phone',
    () async {
      final phone = JournalRepository(AppDatabase(NativeDatabase.memory()));
      addTearDown(phone.db.close);
      await phone.setColorThemeId('forest');
      await phone.saveRestTimerAlertSettings(
        const RestTimerAlertSettings(
          soundEnabled: true,
          vibrationEnabled: true,
          notificationEnabled: true,
          ringUntilStopped: true,
        ),
      );

      final remote = MemoryRemote();
      await JournalSync(journal: phone, remote: remote).sync();
      expect(remote.settings!.preferences['color_theme_id'], 'forest');
      expect(
        remote.settings!.preferences['rest_timer_ring_until_stopped'],
        'true',
      );

      final fresh = JournalRepository(AppDatabase(NativeDatabase.memory()));
      addTearDown(fresh.db.close);
      await JournalSync(journal: fresh, remote: remote).sync();
      expect(await fresh.loadColorThemeId(), 'forest');
      expect(
        (await fresh.loadRestTimerAlertSettings()).ringUntilStopped,
        isTrue,
      );

      await phone.setColorThemeId('loud');
      final partial = MemoryRemote()
        ..settings = const CloudSettings(
          updatedAt: '2099-01-01T00:00:00.000Z',
          preferences: {'weight_unit': 'kg'},
        );
      await JournalSync(journal: phone, remote: partial).sync();
      expect(await phone.loadColorThemeId(), 'loud');
      expect(
        (await phone.loadRestTimerAlertSettings()).ringUntilStopped,
        isTrue,
      );
      expect(await phone.storedWeightUnit(), WeightUnit.kg);

      final sync = SyncController(journal: phone, firebaseReady: false);
      await sync.signOut();
      expect(await phone.loadColorThemeId(), 'loud');
      expect(
        (await phone.loadRestTimerAlertSettings()).ringUntilStopped,
        isTrue,
      );
      expect(sync.preferenceReloadToken, 1);
    },
  );

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

  test('firestore document size matches the documented example', () {
    final size = firestoreDocumentSize(
      {
        'type': 'Personal',
        'done': false,
        'priority': 1,
        'description': 'Learn Cloud Firestore',
      },
      pathSegments: ['users', 'jeff', 'tasks', 'my_task_id'],
    );
    expect(size, 147);
  });

  test('premade catalog entries stay out of the cloud settings document', () {
    const raw = '''
{"templates":[{"id":"catalog-workout","name":"Push"},{"id":"custom-1","name":"MY-CUSTOM-PLAN"}],"folders":[{"id":"catalog-folder","name":"Catalog"},{"id":"custom-folder","name":"Mine"}]}
''';
    final settings = CloudSettings(
      updatedAt: '2026-11-01T00:00:00.000Z',
      weightUnit: 'lb',
      templatesJson: raw.trim(),
      preferences: {'templates_json': raw.trim(), 'weight_unit': 'lb'},
    );
    final comparable = cloudComparableSettings(settings, {
      'catalog-workout',
      'catalog-folder',
    });
    expect(comparable.templatesJson, contains('MY-CUSTOM-PLAN'));
    expect(comparable.templatesJson, isNot(contains('catalog-workout')));
    expect(comparable.templatesJson, isNot(contains('catalog-folder')));
    expect(comparable.preferences.containsKey('templates_json'), isFalse);
    expect(comparable.preferences['weight_unit'], 'lb');
    final upload = planSettingsUpload(comparable);
    final stored = jsonEncode(upload.documents);
    expect(stored, contains('MY-CUSTOM-PLAN'));
    expect(stored, isNot(contains('catalog-workout')));
    expect(upload.excluded, isFalse);
  });

  test(
    'a payload over 1 MiB is split or excluded and smaller days still upload',
    () async {
      final journal = JournalRepository(AppDatabase(NativeDatabase.memory()));
      addTearDown(journal.db.close);
      await journal.replaceDay(
        sampleDay(dateKey: '2026-10-01', updatedAt: '2026-10-01T10:00:00.000Z'),
      );
      await journal.replaceDay(
        JournalDay(
          dateKey: '2026-10-02',
          updatedAt: '2026-10-02T10:00:00.000Z',
          notes: 'n' * 1100000,
          exercises: const [],
        ),
      );
      final templates = jsonEncode({
        'templates': [
          {
            'id': 'custom-plan',
            'name': 'MY-CUSTOM-PLAN',
            'notes': 'x' * 1200000,
          },
        ],
        'folders': [
          {'id': 'custom-folder', 'name': 'MY-CUSTOM-PLAN'},
        ],
      });
      await journal.saveTemplatesJson(templates);

      final remote = _LimitedRemote();
      final result = await JournalSync(journal: journal, remote: remote).sync();

      expect(remote.days.containsKey('2026-10-01'), isTrue);
      expect(remote.days.containsKey('2026-10-02'), isFalse);
      expect(result.uploaded, greaterThan(0));
      expect(result.skippedReason, contains('too large'));
      expect(remote.docs.length, greaterThan(1));
      expect(remote.settings?.templatesJson, contains('MY-CUSTOM-PLAN'));
      expect(remote.settings?.templatesJson, contains('custom-folder'));
      for (final entry in remote.docs.entries) {
        expect(
          settingsDocumentSize(entry.key, entry.value),
          lessThanOrEqualTo(firestoreMaxDocumentBytes),
        );
      }

      final again = await JournalSync(journal: journal, remote: remote).sync();
      expect(remote.days.containsKey('2026-10-01'), isTrue);
      expect(remote.days.containsKey('2026-10-02'), isFalse);
      expect(again.uploaded, 0);
      expect(again.skippedReason, contains('too large'));
    },
  );

  test(
    'an oversized day is split into part documents and reads back',
    () async {
      final day = _bulkyDay();
      expect(dayDocumentExceedsLimit(day), isTrue);
      final upload = planDayUpload(day);

      expect(upload.skippedExercises, 0);
      expect(upload.documents.length, greaterThan(1));
      expect(upload.documents.containsKey(day.dateKey), isTrue);
      expect(upload.documents.containsKey('${day.dateKey}__2'), isTrue);
      for (final entry in upload.documents.entries) {
        expect(entry.value['dateKey'], day.dateKey);
        expect(
          entry.key == day.dateKey || entry.key.startsWith('${day.dateKey}__'),
          isTrue,
        );
        expect(
          plannedDayDocumentSize(entry.key, entry.value),
          lessThanOrEqualTo(dayPartTargetBytes),
        );
      }
      final readBack = daysFromStoredDocs([
        for (final entry in upload.documents.entries)
          StoredDayDocument(entry.key, entry.value),
      ]);
      expect(readBack.keys, [day.dateKey]);
      expect(sameDayContent(readBack[day.dateKey]!, day), isTrue);
      expect(
        readBack[day.dateKey]!.exercises.map(
          (exercise) => exercise.sets.single.weight,
        ),
        ['100', '101', '102'],
      );
      expect(
        readBack[day.dateKey]!.exercises.map(
          (exercise) => exercise.sets.single.reps,
        ),
        ['5', '6', '7'],
      );

      final small = sampleDay();
      final smallUpload = planDayUpload(small);
      expect(dayDocumentExceedsLimit(small), isFalse);
      expect(smallUpload.documents.keys.toList(), [small.dateKey]);
      expect(smallUpload.documents[small.dateKey], small.toMap());

      var store = applyDayDocumentWrite(
        const {},
        planReplaceDayDocuments(
          dateKey: day.dateKey,
          existing: const {},
          documents: upload.documents,
        ),
      );
      expect(store.length, greaterThan(1));
      final shrunk = sampleDay(
        dateKey: day.dateKey,
        updatedAt: '2026-10-02T12:00:00.000Z',
        weight: '135',
      );
      store = applyDayDocumentWrite(
        store,
        planReplaceDayDocuments(
          dateKey: shrunk.dateKey,
          existing: store,
          documents: planDayUpload(shrunk).documents,
        ),
      );
      expect(store.keys.toList(), [shrunk.dateKey]);
      expect(
        sameDayContent(
          daysFromStoredDocs(_asDocs(store))[shrunk.dateKey]!,
          shrunk,
        ),
        isTrue,
      );

      store = applyDayDocumentWrite(
        store,
        planTombstoneDocuments(
          tombstone: DayTombstone(
            dateKey: shrunk.dateKey,
            deletedAt: '2026-10-02T13:00:00.000Z',
          ),
          existing: store,
        ),
      );
      expect(store.keys.toList(), [shrunk.dateKey]);
      expect(store[shrunk.dateKey]!['deleted'], isTrue);
      expect(daysFromStoredDocs(_asDocs(store)), isEmpty);
      expect(
        tombstonesFromStoredDocs(_asDocs(store))[shrunk.dateKey]?.deletedAt,
        '2026-10-02T13:00:00.000Z',
      );

      final journal = JournalRepository(AppDatabase(NativeDatabase.memory()));
      addTearDown(journal.db.close);
      await journal.replaceDay(day);
      await journal.replaceDay(small);
      final remote = _PartRemote();
      final first = await JournalSync(journal: journal, remote: remote).sync();
      expect(first.skippedReason, isNull);
      expect(remote.dayDocs.keys.where((id) => id.startsWith(small.dateKey)), [
        small.dateKey,
      ]);
      expect(
        remote.dayDocs.keys
            .where(
              (id) => id.startsWith('${day.dateKey}__') || id == day.dateKey,
            )
            .length,
        greaterThan(1),
      );
      final synced = daysFromStoredDocs(_asDocs(remote.dayDocs))[day.dateKey]!;
      expect(synced.exercises.map((exercise) => exercise.id), [
        'ex0',
        'ex1',
        'ex2',
      ]);
      expect(synced.exercises.map((exercise) => exercise.sets.single.weight), [
        '100',
        '101',
        '102',
      ]);

      final again = await JournalSync(journal: journal, remote: remote).sync();
      expect(again.uploaded, 0);
      expect(again.skippedReason, isNull);

      await journal.replaceDay(shrunk);
      await JournalSync(journal: journal, remote: remote).sync();
      expect(remote.dayDocs.containsKey('${day.dateKey}__2'), isFalse);
      expect(remote.dayDocs.containsKey(day.dateKey), isTrue);

      await journal.deleteDay(day.dateKey);
      await JournalSync(journal: journal, remote: remote).sync();
      expect(remote.dayDocs.keys.where((id) => id.startsWith(day.dateKey)), [
        day.dateKey,
      ]);
      expect(remote.dayDocs[day.dateKey]!['deleted'], isTrue);
      expect(
        daysFromStoredDocs(_asDocs(remote.dayDocs)).containsKey(day.dateKey),
        isFalse,
      );
    },
  );

  test('an exercise that cannot fit in one document is skipped', () async {
    final day = JournalDay(
      dateKey: '2026-10-03',
      updatedAt: '2026-10-03T10:00:00.000Z',
      exercises: [
        JournalExercise(
          id: 'huge',
          sortOrder: 0,
          name: 'Too Big',
          notes: 'z' * 1100000,
          sets: [
            JournalSet(id: 'huge-set', sortOrder: 0, reps: '1', weight: '500'),
          ],
        ),
        JournalExercise(
          id: 'kept',
          sortOrder: 1,
          name: 'Bench Press',
          sets: [
            JournalSet(id: 'kept-set', sortOrder: 0, reps: '5', weight: '185'),
          ],
        ),
      ],
    );
    expect(dayDocumentExceedsLimit(day), isTrue);
    final upload = planDayUpload(day);
    expect(upload.skippedExercises, 1);
    expect(upload.documents.keys.toList(), [day.dateKey]);
    final stored = upload.storedDay!;
    expect(stored.exercises.single.id, 'kept');
    expect(stored.exercises.single.sets.single.weight, '185');
    expect(stored.exercises.single.sets.single.reps, '5');

    final journal = JournalRepository(AppDatabase(NativeDatabase.memory()));
    addTearDown(journal.db.close);
    await journal.replaceDay(day);
    final remote = MemoryRemote();
    final result = await JournalSync(journal: journal, remote: remote).sync();
    expect(
      result.skippedReason,
      'Skipped 1 exercise that is too large to sync.',
    );
    expect(
      remote.days[day.dateKey]!.exercises.single.sets.single.weight,
      '185',
    );

    final again = await JournalSync(journal: journal, remote: remote).sync();
    expect(again.uploaded, 0);
    expect(again.skippedReason, contains('too large'));
  });

  test('a local journal edit syncs on its own after a short delay', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final journal = JournalRepository(AppDatabase(NativeDatabase.memory()));
    addTearDown(journal.db.close);
    final remote = _CountingRemote()
      ..days['2026-10-08'] = sampleDay(
        dateKey: '2026-10-08',
        updatedAt: '2026-10-08T12:00:00.000Z',
        weight: '135',
      );
    final sync = SyncController(
      journal: journal,
      firebaseReady: true,
      autoSyncDelay: const Duration(milliseconds: 40),
      remoteForUid: (_) => remote,
    );
    addTearDown(sync.dispose);
    sync.debugSignIn('user-1');
    await sync.load();
    await sync.setEnabled(true);

    expect(remote.fetches, 1);
    expect(
      (await journal.getDay('2026-10-08'))!.exercises.single.sets.single.weight,
      '135',
    );
    await Future<void>.delayed(const Duration(milliseconds: 160));
    expect(remote.fetches, 1);

    sync.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await _waitFor(() => remote.fetches >= 2 && !sync.busy);
    expect(remote.fetches, 2);

    var notices = 0;
    journal.addLocalWriteListener(() => notices++);
    await journal.replaceDay(
      sampleDay(dateKey: '2026-10-09', updatedAt: '2026-10-09T12:00:00.000Z'),
    );
    expect(notices, 1);
    expect(remote.days.containsKey('2026-10-09'), isFalse);
    await _waitFor(() => remote.days.containsKey('2026-10-09'));
    expect(remote.days.containsKey('2026-10-09'), isTrue);
    expect(remote.fetches, 3);
  });
}

JournalDay _bulkyDay() {
  return JournalDay(
    dateKey: '2026-10-02',
    updatedAt: '2026-10-02T10:00:00.000Z',
    notes: 'session',
    exercises: [
      for (var index = 0; index < 3; index++)
        JournalExercise(
          id: 'ex$index',
          sortOrder: index,
          name: 'Lift $index',
          notes: 'n' * 400000,
          sets: [
            JournalSet(
              id: 's$index',
              sortOrder: 0,
              reps: '${5 + index}',
              weight: '${100 + index}',
            ),
          ],
        ),
    ],
  );
}

List<StoredDayDocument> _asDocs(Map<String, Map<String, Object?>> docs) {
  return [
    for (final entry in docs.entries) StoredDayDocument(entry.key, entry.value),
  ];
}

Future<void> _waitFor(bool Function() ready) async {
  final deadline = DateTime.now().add(const Duration(seconds: 2));
  while (!ready()) {
    if (DateTime.now().isAfter(deadline)) return;
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

class _LimitedRemote extends MemoryRemote {
  final Map<String, Map<String, Object?>> docs = {};

  @override
  Future<Map<String, Map<String, Object?>>> fetchSettingsDocuments() async {
    return Map<String, Map<String, Object?>>.from(docs);
  }

  @override
  Future<void> replaceSettingsDocuments(
    Map<String, Map<String, Object?>> documents,
  ) async {
    for (final entry in documents.entries) {
      if (settingsDocumentSize(entry.key, entry.value) >
          firestoreMaxDocumentBytes) {
        throw StateError(
          'settings/${entry.key} cannot be written because its size exceeds the maximum allowed size of 1,048,576 bytes',
        );
      }
    }
    docs
      ..clear()
      ..addAll(documents);
    settings = cloudSettingsFromDocuments(documents);
  }

  @override
  Future<void> putDay(JournalDay day) async {
    if (dayDocumentExceedsLimit(day)) {
      throw StateError(
        'days/${day.dateKey} cannot be written because its size exceeds the maximum allowed size of 1,048,576 bytes',
      );
    }
    await super.putDay(day);
  }
}

class _PartRemote extends MemoryRemote {
  final Map<String, Map<String, Object?>> dayDocs = {};

  @override
  Future<Map<String, JournalDay>> fetchDays() async {
    return daysFromStoredDocs(_asDocs(dayDocs));
  }

  @override
  Future<Map<String, DayTombstone>> fetchTombstones() async {
    return tombstonesFromStoredDocs(_asDocs(dayDocs));
  }

  @override
  Future<void> replaceDayDocuments(
    String dateKey,
    Map<String, Map<String, Object?>> documents,
  ) async {
    final next = applyDayDocumentWrite(
      dayDocs,
      planReplaceDayDocuments(
        dateKey: dateKey,
        existing: dayDocs,
        documents: documents,
      ),
    );
    dayDocs
      ..clear()
      ..addAll(next);
  }

  @override
  Future<void> putTombstone(DayTombstone tombstone) async {
    final next = applyDayDocumentWrite(
      dayDocs,
      planTombstoneDocuments(tombstone: tombstone, existing: dayDocs),
    );
    dayDocs
      ..clear()
      ..addAll(next);
  }

  @override
  Future<void> deleteAll() async {
    await super.deleteAll();
    dayDocs.clear();
  }
}

class _CountingRemote extends MemoryRemote {
  int fetches = 0;

  @override
  Future<Map<String, JournalDay>> fetchDays() async {
    fetches += 1;
    return super.fetchDays();
  }
}
