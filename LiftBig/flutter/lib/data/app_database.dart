import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Days, Exercises, WorkoutSets, LocalSettings])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  AppDatabase.defaults()
    : super(
        driftDatabase(
          name: 'liftbig',
          web: DriftWebOptions(
            sqlite3Wasm: Uri.parse('sqlite3.wasm'),
            driftWorker: Uri.parse('drift_worker.js'),
            onResult: (result) {},
          ),
        ),
      );

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        // plan_name must move first so plan_folder_name can take that name.
        await migrator.renameColumn(days, 'plan_name', days.workoutName);
        await migrator.renameColumn(days, 'plan_folder_name', days.planName);
        await migrator.renameColumn(days, 'plan_notes', days.workoutNotes);
      }
      if (from < 3) {
        await migrator.addColumn(workoutSets, workoutSets.difficulty);
      }
      if (from < 4) {
        await migrator.addColumn(exercises, exercises.prescribedReps);
        await migrator.addColumn(exercises, exercises.prescribedWeight);
        await migrator.addColumn(exercises, exercises.prescribedSetCount);
        await migrator.addColumn(days, days.chosenRestSeconds);
        await migrator.addColumn(days, days.healthEnergyKcal);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
