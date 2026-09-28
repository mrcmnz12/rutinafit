import 'package:sqflite/sqflite.dart';

import '../../core/db/database_helper.dart';
import '../../core/db/db_constants.dart';
import '../models/bodyweight_entry.dart';

/// Acceso a datos del historial de peso corporal.
class BodyWeightRepository {
  BodyWeightRepository(this._dbHelper);
  final DatabaseHelper _dbHelper;

  Future<List<BodyWeightEntry>> getAll() async {
    final db = await _dbHelper.database;
    final rows = await db.query(DbTables.bodyWeightEntries, orderBy: 'date ASC');
    return rows.map(BodyWeightEntry.fromMap).toList();
  }

  Future<BodyWeightEntry?> getLast() async {
    final db = await _dbHelper.database;
    final rows = await db.query(DbTables.bodyWeightEntries, orderBy: 'date DESC', limit: 1);
    if (rows.isEmpty) return null;
    return BodyWeightEntry.fromMap(rows.first);
  }

  /// Inserta o reemplaza el registro de una fecha (una sola pesada por día).
  Future<void> upsert(String date, double kg) async {
    final db = await _dbHelper.database;
    await db.insert(
      DbTables.bodyWeightEntries,
      {'date': date, 'kg': kg},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Borra el registro de peso de una fecha puntual.
  Future<void> delete(String date) async {
    final db = await _dbHelper.database;
    await db.delete(DbTables.bodyWeightEntries, where: 'date = ?', whereArgs: [date]);
  }
}
