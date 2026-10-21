import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:liftbig/backup/backup_parser.dart';
import 'package:liftbig/ui/import_sheet.dart';

void main() {
  test('reads liftbig-backup.json from the documents directory', () async {
    final documents = await Directory.systemTemp.createTemp('liftbig-docs');
    addTearDown(() => documents.delete(recursive: true));
    await File('${documents.path}/liftbig-backup.json').writeAsString(
      '{"liftbig_workouts":{"2026-01-02":{"exercises":[{"id":"e","name":"Squat","sets":[{"id":"s","reps":"5","weight":"225"}]}]}}}',
    );

    final text = await readSavedBackupFile(documents);
    final parsed = parseLiftBigBackup(text);

    expect(parsed.days.single.exercises.single.name, 'Squat');
    expect(parsed.days.single.exercises.single.sets.single.weight, '225');
  });

  test('missing liftbig-backup.json names the file to copy in', () async {
    final documents = await Directory.systemTemp.createTemp('liftbig-empty');
    addTearDown(() => documents.delete(recursive: true));

    expect(
      () => readSavedBackupFile(documents),
      throwsA(
        isA<MissingSavedBackup>().having(
          (error) => error.message,
          'message',
          missingSavedBackupMessage,
        ),
      ),
    );
  });
}
