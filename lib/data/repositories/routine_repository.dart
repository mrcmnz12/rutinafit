import 'package:sqflite/sqflite.dart';

import '../../core/db/database_helper.dart';
import '../../core/db/db_constants.dart';
import '../models/routine_day.dart';

/// Acceso a datos de las rutinas de gym y a qué ejercicios contiene cada
/// una (routine_day_exercises).
class RoutineRepository {
  RoutineRepository(this._dbHelper);
  final DatabaseHelper _dbHelper;

  Future<Map<String, RoutineDay>> getAllDays() async {
    final db = await _dbHelper.database;
    final dayRows = await db.query(DbTables.routineDays);
    final exRows = await db.query(DbTables.routineDayExercises, orderBy: 'day_key, position');

    final idsByDay = <String, List<String>>{};
    for (final row in exRows) {
      final dayKey = row['day_key'] as String;
      idsByDay.putIfAbsent(dayKey, () => []).add(row['exercise_id'] as String);
    }

    final result = <String, RoutineDay>{};
    for (final row in dayRows) {
      final day = RoutineDay.fromMap(row, exerciseIds: idsByDay[row['day_key']] ?? const []);
      result[day.dayKey] = day;
    }
    return result;
  }

  Future<RoutineDay?> getDay(String dayKey) async {
    final days = await getAllDays();
    return days[dayKey];
  }

  Future<void> updateNameObjective(String dayKey, {String? name, String? objective}) async {
    final db = await _dbHelper.database;
    final values = <String, Object?>{};
    if (name != null && name.trim().isNotEmpty) values['name'] = name.trim();
    if (objective != null && objective.trim().isNotEmpty) values['objective'] = objective.trim();
    if (values.isEmpty) return;
    await db.update(DbTables.routineDays, values, where: 'day_key = ?', whereArgs: [dayKey]);
  }

  /// Reasigna el orden de rotación de gym: la posición de cada `dayKey`
  /// en la lista pasa a ser su `rotation_order` (0 = próxima). Solo
  /// toca esa columna — nombre, objetivo, calentamiento y ejercicios de
  /// cada rutina no se ven afectados.
  Future<void> updateRotationOrder(List<String> orderedDayKeys) async {
    final db = await _dbHelper.database;
    final batch = db.batch();
    for (var i = 0; i < orderedDayKeys.length; i++) {
      batch.update(DbTables.routineDays, {'rotation_order': i}, where: 'day_key = ?', whereArgs: [orderedDayKeys[i]]);
    }
    await batch.commit(noResult: true);
  }

  /// Intercambia TODO el contenido de dos días (nombre, objetivo, si es
  /// descanso, calentamiento y ejercicios asignados) — el orden de
  /// rotación de cada fila (`rotation_order`) NO se toca, para que
  /// intercambiar contenido no reordene sin querer la rotación.
  Future<void> swapDays(String dayA, String dayB) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      final rowsA = await txn.query(DbTables.routineDays, where: 'day_key = ?', whereArgs: [dayA], limit: 1);
      final rowsB = await txn.query(DbTables.routineDays, where: 'day_key = ?', whereArgs: [dayB], limit: 1);
      if (rowsA.isEmpty || rowsB.isEmpty) return;

      Future<void> applyContent(String targetDay, Map<String, Object?> content) async {
        await txn.update(
          DbTables.routineDays,
          {'name': content['name'], 'objective': content['objective'], 'is_rest': content['is_rest'], 'warmup': content['warmup']},
          where: 'day_key = ?',
          whereArgs: [targetDay],
        );
      }

      await applyContent(dayA, rowsB.first);
      await applyContent(dayB, rowsA.first);

      final exA = await txn.query(DbTables.routineDayExercises, where: 'day_key = ?', whereArgs: [dayA]);
      final exB = await txn.query(DbTables.routineDayExercises, where: 'day_key = ?', whereArgs: [dayB]);

      await txn.delete(DbTables.routineDayExercises, where: 'day_key = ?', whereArgs: [dayA]);
      await txn.delete(DbTables.routineDayExercises, where: 'day_key = ?', whereArgs: [dayB]);

      for (final row in exB) {
        await txn.insert(DbTables.routineDayExercises, {'day_key': dayA, 'exercise_id': row['exercise_id'], 'position': row['position']});
      }
      for (final row in exA) {
        await txn.insert(DbTables.routineDayExercises, {'day_key': dayB, 'exercise_id': row['exercise_id'], 'position': row['position']});
      }
    });
  }

  Future<void> addExerciseToDay(String dayKey, String exerciseId) async {
    final db = await _dbHelper.database;
    final countRow = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM ${DbTables.routineDayExercises} WHERE day_key = ?',
      [dayKey],
    )) ?? 0;
    await db.insert(
      DbTables.routineDayExercises,
      {'day_key': dayKey, 'exercise_id': exerciseId, 'position': countRow},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> removeExerciseFromDay(String dayKey, String exerciseId) async {
    final db = await _dbHelper.database;
    await db.delete(
      DbTables.routineDayExercises,
      where: 'day_key = ? AND exercise_id = ?',
      whereArgs: [dayKey, exerciseId],
    );
  }
}
