import 'package:sqflite/sqflite.dart';

import '../../core/db/database_helper.dart';
import '../../core/db/db_constants.dart';

/// Preferencias simples clave-valor (tema, paleta). Pensado para crecer
/// sin migraciones: una fila nueva por clave, no una columna nueva.
class SettingsRepository {
  SettingsRepository(this._dbHelper);
  final DatabaseHelper _dbHelper;

  Future<String?> getValue(String key) async {
    final db = await _dbHelper.database;
    final rows = await db.query(DbTables.appSettings, where: 'key = ?', whereArgs: [key], limit: 1);
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Future<void> setValue(String key, String value) async {
    final db = await _dbHelper.database;
    await db.insert(
      DbTables.appSettings,
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
