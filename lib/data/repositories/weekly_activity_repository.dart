import 'package:sqflite/sqflite.dart';

import '../../core/db/database_helper.dart';
import '../../core/db/db_constants.dart';
import '../models/activity.dart';

/// Acceso a datos de qué actividades quedan fijas a qué día real de la
/// semana (lunes..domingo).
class WeeklyActivityRepository {
  WeeklyActivityRepository(this._dbHelper);
  final DatabaseHelper _dbHelper;

  /// Todas las actividades semanales, agrupadas por día y ya unidas con
  /// el catálogo (nombre/color/duración), en el orden en que se
  /// agregaron a cada día.
  Future<Map<String, List<Activity>>> getAllByDay() async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery('''
      SELECT wa.day_key AS day_key, a.id AS id, a.name AS name, a.color AS color,
             a.duration_minutes AS duration_minutes, a.sort_order AS sort_order
      FROM ${DbTables.weeklyActivities} wa
      JOIN ${DbTables.activities} a ON a.id = wa.activity_id
      ORDER BY wa.day_key, wa.position
    ''');
    final result = <String, List<Activity>>{};
    for (final row in rows) {
      final dayKey = row['day_key'] as String;
      result.putIfAbsent(dayKey, () => []).add(Activity.fromMap(row));
    }
    return result;
  }

  Future<void> addToDay(String dayKey, String activityId) async {
    final db = await _dbHelper.database;
    final countRow = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM ${DbTables.weeklyActivities} WHERE day_key = ?',
      [dayKey],
    )) ?? 0;
    await db.insert(
      DbTables.weeklyActivities,
      {'day_key': dayKey, 'activity_id': activityId, 'position': countRow},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> removeFromDay(String dayKey, String activityId) async {
    final db = await _dbHelper.database;
    await db.delete(
      DbTables.weeklyActivities,
      where: 'day_key = ? AND activity_id = ?',
      whereArgs: [dayKey, activityId],
    );
  }
}
