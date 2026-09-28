import 'package:sqflite/sqflite.dart';

import '../../core/db/database_helper.dart';
import '../../core/db/db_constants.dart';
import '../models/exercise.dart';

/// Acceso a datos del catálogo de ejercicios. Todas las queries usan
/// placeholders (`?`) — nunca se arma SQL concatenando texto del usuario.
class ExerciseRepository {
  ExerciseRepository(this._dbHelper);
  final DatabaseHelper _dbHelper;

  Future<List<Exercise>> getAll() async {
    final db = await _dbHelper.database;
    final rows = await db.query(DbTables.exercises, orderBy: 'name COLLATE NOCASE');
    return rows.map(Exercise.fromMap).toList();
  }

  Future<bool> idExists(String id) async {
    final db = await _dbHelper.database;
    final rows = await db.query(DbTables.exercises, where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isNotEmpty;
  }

  /// Crea un ejercicio nuevo en el catálogo. Al usar `insert` con
  /// placeholders (via `ex.toMap()`) queda disponible de inmediato para
  /// agregarlo a cualquier día de rutina, igual que los del seed.
  Future<void> insert(Exercise ex) async {
    final db = await _dbHelper.database;
    await db.insert(DbTables.exercises, ex.toMap(), conflictAlgorithm: ConflictAlgorithm.abort);
  }

  Future<Exercise?> getById(String id) async {
    final db = await _dbHelper.database;
    final rows = await db.query(DbTables.exercises, where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return Exercise.fromMap(rows.first);
  }

  Future<List<Exercise>> search(String query) async {
    final db = await _dbHelper.database;
    final q = '%${query.trim()}%';
    final rows = await db.query(
      DbTables.exercises,
      where: 'name LIKE ? OR muscle_group LIKE ?',
      whereArgs: [q, q],
      orderBy: 'name COLLATE NOCASE',
    );
    return rows.map(Exercise.fromMap).toList();
  }

  /// Edita la definición del ejercicio (series/reps/descanso) — la única
  /// pantalla de la app que escribe estos campos.
  Future<void> updateParams(
    String id, {
    required String setsLabel,
    required int repLow,
    required int repHigh,
    required String restLabel,
  }) async {
    final db = await _dbHelper.database;
    await db.update(
      DbTables.exercises,
      {'sets_label': setsLabel, 'rep_low': repLow, 'rep_high': repHigh, 'rest_label': restLabel},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateImage(String id, {required int slot, String? path}) async {
    assert(slot == 1 || slot == 2);
    final db = await _dbHelper.database;
    final column = slot == 1 ? 'image1_path' : 'image2_path';
    await db.update(DbTables.exercises, {column: path}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateVideoUrl(String id, String? url) async {
    final db = await _dbHelper.database;
    await db.update(DbTables.exercises, {'video_url': url}, where: 'id = ?', whereArgs: [id]);
  }
}
