import 'package:sqflite/sqflite.dart';

import '../../core/db/database_helper.dart';
import '../../core/db/db_constants.dart';
import '../models/exercise_log.dart';

/// Acceso a datos de lo registrado por ejercicio y fecha.
class ExerciseLogRepository {
  ExerciseLogRepository(this._dbHelper);
  final DatabaseHelper _dbHelper;

  Future<List<ExerciseLogEntry>> getForExercise(String exerciseId) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      DbTables.exerciseLogs,
      where: 'exercise_id = ?',
      whereArgs: [exerciseId],
      orderBy: 'date ASC',
    );
    return rows.map(ExerciseLogEntry.fromMap).toList();
  }

  Future<ExerciseLogEntry?> getLastForExercise(String exerciseId) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      DbTables.exerciseLogs,
      where: 'exercise_id = ?',
      whereArgs: [exerciseId],
      orderBy: 'date DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ExerciseLogEntry.fromMap(rows.first);
  }

  Future<ExerciseLogEntry?> getForExerciseOnDate(String exerciseId, String date) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      DbTables.exerciseLogs,
      where: 'exercise_id = ? AND date = ?',
      whereArgs: [exerciseId, date],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ExerciseLogEntry.fromMap(rows.first);
  }

  Future<bool> isDoneOn(String exerciseId, String date) async =>
      (await getForExerciseOnDate(exerciseId, date)) != null;

  /// Todo lo registrado en una fecha (para la pantalla de "log de un día
  /// pasado"), sin importar el ejercicio.
  Future<List<ExerciseLogEntry>> getForDate(String date) async {
    final db = await _dbHelper.database;
    final rows = await db.query(DbTables.exerciseLogs, where: 'date = ?', whereArgs: [date]);
    return rows.map(ExerciseLogEntry.fromMap).toList();
  }

  /// Inserta o reemplaza la entrada de (exercise_id, date) — guardar de
  /// nuevo el mismo ejercicio el mismo día actualiza esa fila en vez de
  /// duplicarla, igual que en la maqueta.
  Future<void> upsert(ExerciseLogEntry entry) async {
    final db = await _dbHelper.database;
    await db.insert(
      DbTables.exerciseLogs,
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Borra todo lo registrado en una fecha (usado por "Eliminar rutina" en
  /// el registro diario). Devuelve los ids de los ejercicios afectados,
  /// para que quien llame pueda refrescar solo lo que corresponde en vez
  /// de recargar todo el caché en memoria.
  Future<List<String>> deleteForDate(String date) async {
    final db = await _dbHelper.database;
    final rows = await db.query(DbTables.exerciseLogs, columns: ['exercise_id'], where: 'date = ?', whereArgs: [date]);
    final exerciseIds = rows.map((r) => r['exercise_id'] as String).toSet().toList();
    await db.delete(DbTables.exerciseLogs, where: 'date = ?', whereArgs: [date]);
    return exerciseIds;
  }
}
