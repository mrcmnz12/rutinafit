import 'package:sqflite/sqflite.dart';

import '../../core/db/database_helper.dart';
import '../../core/db/db_constants.dart';

/// Acceso a datos de la rutina de gym PREFERIDA (opcional, no
/// restrictiva) para cada día real de la semana. Solo existe fila para
/// los días que el usuario configuró explícitamente en "Configurar
/// semana" — la ausencia de fila significa "sin preferencia, usa la
/// rotación automática", no "descanso".
class WeekdayRoutinePrefRepository {
  WeekdayRoutinePrefRepository(this._dbHelper);
  final DatabaseHelper _dbHelper;

  /// Mapa día real -> dayKey de la rutina preferida, solo con los días
  /// que tienen una preferencia guardada.
  Future<Map<String, String>> getAll() async {
    final db = await _dbHelper.database;
    final rows = await db.query(DbTables.weekdayRoutinePrefs);
    return {for (final row in rows) row['real_weekday'] as String: row['routine_day_key'] as String};
  }

  Future<void> setPreference(String realWeekday, String routineDayKey) async {
    final db = await _dbHelper.database;
    await db.insert(
      DbTables.weekdayRoutinePrefs,
      {'real_weekday': realWeekday, 'routine_day_key': routineDayKey},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> clearPreference(String realWeekday) async {
    final db = await _dbHelper.database;
    await db.delete(DbTables.weekdayRoutinePrefs, where: 'real_weekday = ?', whereArgs: [realWeekday]);
  }
}
