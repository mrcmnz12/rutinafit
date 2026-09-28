import '../../core/db/database_helper.dart';
import '../../core/db/db_constants.dart';
import '../models/activity.dart';

/// Acceso a datos del catálogo de actividades adicionales.
class ActivityRepository {
  ActivityRepository(this._dbHelper);
  final DatabaseHelper _dbHelper;

  Future<List<Activity>> getAll() async {
    final db = await _dbHelper.database;
    final rows = await db.query(DbTables.activities, orderBy: 'sort_order ASC');
    return rows.map(Activity.fromMap).toList();
  }

  Future<void> create(Activity activity) async {
    final db = await _dbHelper.database;
    await db.insert(DbTables.activities, activity.toMap());
  }

  Future<void> update(String id, {String? name, String? color, int? durationMinutes}) async {
    final db = await _dbHelper.database;
    final values = <String, Object?>{};
    if (name != null && name.trim().isNotEmpty) values['name'] = name.trim();
    if (color != null) values['color'] = color;
    if (durationMinutes != null) values['duration_minutes'] = durationMinutes;
    if (values.isEmpty) return;
    await db.update(DbTables.activities, values, where: 'id = ?', whereArgs: [id]);
  }

  /// Borra la actividad del catálogo. Las asignaciones a días de la
  /// semana se borran en cascada (ON DELETE CASCADE); las sesiones ya
  /// registradas en el historial NO se tocan — `activity_id` no tiene
  /// llave foránea a propósito, así el historial pasado nunca se pierde
  /// ni se bloquea por borrar algo del catálogo actual.
  Future<void> delete(String id) async {
    final db = await _dbHelper.database;
    await db.delete(DbTables.activities, where: 'id = ?', whereArgs: [id]);
  }
}
