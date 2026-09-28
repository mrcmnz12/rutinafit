import 'package:sqflite/sqflite.dart';

import '../../core/db/database_helper.dart';
import '../../core/db/db_constants.dart';
import 'seed_data.dart';

/// Inserta los datos de arranque (SeedData) solo la primera vez que la
/// app corre con una base vacía. En corridas siguientes no hace nada:
/// nunca pisa datos que el usuario ya generó usando la app de verdad.
class DatabaseSeeder {
  DatabaseSeeder(this._dbHelper);

  final DatabaseHelper _dbHelper;

  Future<void> seedIfEmpty() async {
    final db = await _dbHelper.database;
    final count = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM ${DbTables.routineDays}'),
        ) ??
        0;
    if (count > 0) return;

    final batch = db.batch();

    for (final day in SeedData.routineDays.values) {
      batch.insert(DbTables.routineDays, day.toMap());
    }
    for (final ex in SeedData.exercises) {
      batch.insert(DbTables.exercises, ex.toMap());
    }
    SeedData.routineDays.forEach((dayKey, day) {
      for (var i = 0; i < day.exerciseIds.length; i++) {
        batch.insert(DbTables.routineDayExercises, {
          'day_key': dayKey,
          'exercise_id': day.exerciseIds[i],
          'position': i,
        });
      }
    });
    for (final s in SeedData.sessions) {
      batch.insert(DbTables.sessions, s.toMap());
    }
    for (final b in SeedData.bodyWeightLog) {
      batch.insert(DbTables.bodyWeightEntries, b.toMap());
    }
    for (final ex in SeedData.exercises) {
      for (final log in SeedData.generateLogFor(ex)) {
        batch.insert(DbTables.exerciseLogs, log.toMap());
      }
    }
    for (final activity in SeedData.activities) {
      batch.insert(DbTables.activities, activity.toMap());
    }

    await batch.commit(noResult: true);
  }
}
