import '../../core/db/database_helper.dart';
import '../../core/db/db_constants.dart';
import '../models/session.dart';

/// Acceso a datos de las sesiones registradas. Desde la migración a
/// v2 puede haber más de una sesión por fecha (gym + una o más
/// actividades), así que las consultas por fecha devuelven listas.
class SessionRepository {
  SessionRepository(this._dbHelper);
  final DatabaseHelper _dbHelper;

  Future<List<TrainingSession>> getAll() async {
    final db = await _dbHelper.database;
    final rows = await db.query(DbTables.sessions, orderBy: 'date ASC, id ASC');
    return rows.map(TrainingSession.fromMap).toList();
  }

  Future<List<TrainingSession>> getByDate(String date) async {
    final db = await _dbHelper.database;
    final rows = await db.query(DbTables.sessions, where: 'date = ?', whereArgs: [date], orderBy: 'id ASC');
    return rows.map(TrainingSession.fromMap).toList();
  }

  Future<bool> hasRoutineSessionOn(String date) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      DbTables.sessions,
      where: 'date = ? AND kind = ?',
      whereArgs: [date, SessionKind.routine],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<bool> hasActivitySessionOn(String date, String activityId) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      DbTables.sessions,
      where: 'date = ? AND kind = ? AND activity_id = ?',
      whereArgs: [date, SessionKind.activity, activityId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  /// Registra la sesión de gym de una fecha si todavía no existe una ese
  /// día (una sesión de rutina por fecha — guardar dos veces el mismo
  /// día no duplica ni pisa la ya registrada).
  Future<void> registerRoutineSession(String date, String dayKey) async {
    if (await hasRoutineSessionOn(date)) return;
    final db = await _dbHelper.database;
    await db.insert(DbTables.sessions, {
      'date': date,
      'day_key': dayKey,
      'kind': SessionKind.routine,
      'activity_id': null,
    });
  }

  /// Registra una sesión de actividad libre (fútbol, zumba, etc.) en una
  /// fecha, si esa misma actividad no estaba ya registrada ese día.
  Future<void> registerActivitySession(String date, String activityId) async {
    if (await hasActivitySessionOn(date, activityId)) return;
    final db = await _dbHelper.database;
    await db.insert(DbTables.sessions, {
      'date': date,
      'day_key': null,
      'kind': SessionKind.activity,
      'activity_id': activityId,
    });
  }

  /// Borra una sesión puntual por id (usado por "Eliminar esta sesión"
  /// en el registro diario).
  Future<void> deleteById(int id) async {
    final db = await _dbHelper.database;
    await db.delete(DbTables.sessions, where: 'id = ?', whereArgs: [id]);
  }
}
