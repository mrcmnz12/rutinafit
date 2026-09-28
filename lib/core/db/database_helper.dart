import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'db_constants.dart';

/// Punto único de acceso a la base SQLite local del dispositivo.
///
/// Nota de seguridad: sqflite guarda la base en el almacenamiento privado
/// de la app (sandbox de Android/iOS), no accesible a otras apps sin root.
/// Todas las queries de los repositorios usan placeholders (`?`) — nunca
/// se concatenan valores del usuario dentro del SQL — para evitar
/// inyección incluso si en el futuro se agregan campos de texto libre.
class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static const _dbName = 'rutinafit.db';
  static const _dbVersion = 3;

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();

    batch.execute('''
      CREATE TABLE ${DbTables.routineDays} (
        day_key TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        objective TEXT NOT NULL DEFAULT '',
        is_rest INTEGER NOT NULL DEFAULT 0,
        warmup TEXT NOT NULL DEFAULT '',
        rotation_order INTEGER
      )
    ''');

    batch.execute('''
      CREATE TABLE ${DbTables.exercises} (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        muscle_group TEXT NOT NULL,
        measure_type TEXT NOT NULL CHECK (measure_type IN ('reps_weight','time')),
        sets_label TEXT NOT NULL DEFAULT '3',
        rep_low INTEGER NOT NULL DEFAULT 0,
        rep_high INTEGER NOT NULL DEFAULT 0,
        rest_label TEXT NOT NULL DEFAULT '',
        is_bodyweight INTEGER NOT NULL DEFAULT 0,
        suffix TEXT NOT NULL DEFAULT '',
        has_pain_note INTEGER NOT NULL DEFAULT 0,
        base_weight REAL,
        base_seconds INTEGER,
        image1_path TEXT,
        image2_path TEXT,
        video_url TEXT
      )
    ''');

    batch.execute('''
      CREATE TABLE ${DbTables.routineDayExercises} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        day_key TEXT NOT NULL REFERENCES ${DbTables.routineDays}(day_key) ON DELETE CASCADE,
        exercise_id TEXT NOT NULL REFERENCES ${DbTables.exercises}(id) ON DELETE CASCADE,
        position INTEGER NOT NULL DEFAULT 0,
        UNIQUE(day_key, exercise_id)
      )
    ''');

    batch.execute('''
      CREATE TABLE ${DbTables.sessions} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        day_key TEXT REFERENCES ${DbTables.routineDays}(day_key),
        kind TEXT NOT NULL DEFAULT '${SessionKind.routine}',
        activity_id TEXT
      )
    ''');

    batch.execute('''
      CREATE TABLE ${DbTables.exerciseLogs} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        exercise_id TEXT NOT NULL REFERENCES ${DbTables.exercises}(id) ON DELETE CASCADE,
        date TEXT NOT NULL,
        sets_done INTEGER,
        reps INTEGER,
        weight_kg REAL,
        seconds INTEGER,
        pain INTEGER NOT NULL DEFAULT 1,
        UNIQUE(exercise_id, date)
      )
    ''');

    batch.execute('''
      CREATE TABLE ${DbTables.bodyWeightEntries} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL UNIQUE,
        kg REAL NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE ${DbTables.appSettings} (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    batch.execute('''
      CREATE TABLE ${DbTables.activities} (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        color TEXT NOT NULL,
        duration_minutes INTEGER NOT NULL DEFAULT 30,
        sort_order INTEGER NOT NULL DEFAULT 0
      )
    ''');

    batch.execute('''
      CREATE TABLE ${DbTables.weeklyActivities} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        day_key TEXT NOT NULL,
        activity_id TEXT NOT NULL REFERENCES ${DbTables.activities}(id) ON DELETE CASCADE,
        position INTEGER NOT NULL DEFAULT 0
      )
    ''');

    batch.execute('''
      CREATE TABLE ${DbTables.weekdayRoutinePrefs} (
        real_weekday TEXT PRIMARY KEY,
        routine_day_key TEXT NOT NULL REFERENCES ${DbTables.routineDays}(day_key)
      )
    ''');

    batch.execute('CREATE INDEX idx_logs_exercise ON ${DbTables.exerciseLogs}(exercise_id)');
    batch.execute('CREATE INDEX idx_logs_date ON ${DbTables.exerciseLogs}(date)');
    batch.execute('CREATE INDEX idx_rde_day ON ${DbTables.routineDayExercises}(day_key)');
    batch.execute('CREATE INDEX idx_sessions_date ON ${DbTables.sessions}(date)');
    batch.execute('CREATE INDEX idx_weekly_activities_day ON ${DbTables.weeklyActivities}(day_key)');

    await batch.commit(noResult: true);
  }

  /// Migraciones del esquema. Siempre ADITIVAS: nunca se borra una tabla
  /// ni una fila existente del usuario. `sessions` se recrea porque
  /// SQLite no permite quitar un UNIQUE con ALTER TABLE, pero se copia
  /// fila por fila antes de borrar la tabla vieja, así que ningún
  /// historial se pierde — solo deja de estar limitado a una sesión por
  /// fecha (necesario para poder registrar gym + una actividad el mismo
  /// día).
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.transaction((txn) async {
        // 1) Rutinas de gym pasan de "día de la semana fijo" a una
        // rotación reordenable explícita. Se rellena con el orden que ya
        // usaba `kTrainingOrder` en el código, así que el orden visible
        // no cambia para nadie que actualice la app.
        await txn.execute('ALTER TABLE ${DbTables.routineDays} ADD COLUMN rotation_order INTEGER');
        const legacyOrder = ['mon', 'tue', 'thu', 'fri'];
        for (var i = 0; i < legacyOrder.length; i++) {
          await txn.update(
            DbTables.routineDays,
            {'rotation_order': i},
            where: 'day_key = ?',
            whereArgs: [legacyOrder[i]],
          );
        }

        // 2) Catálogo de actividades adicionales (fútbol, zumba, etc.).
        await txn.execute('''
          CREATE TABLE IF NOT EXISTS ${DbTables.activities} (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            color TEXT NOT NULL,
            duration_minutes INTEGER NOT NULL DEFAULT 30,
            sort_order INTEGER NOT NULL DEFAULT 0
          )
        ''');

        // 3) Qué actividades quedan fijas a qué día real de la semana.
        await txn.execute('''
          CREATE TABLE IF NOT EXISTS ${DbTables.weeklyActivities} (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            day_key TEXT NOT NULL,
            activity_id TEXT NOT NULL REFERENCES ${DbTables.activities}(id) ON DELETE CASCADE,
            position INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await txn.execute(
          'CREATE INDEX IF NOT EXISTS idx_weekly_activities_day ON ${DbTables.weeklyActivities}(day_key)',
        );

        // 4) `sessions`: de "una fila por fecha" a varias (gym + una o
        // más actividades el mismo día). Se recrea sin el UNIQUE(date) y
        // con las columnas nuevas, copiando cada fila existente tal cual
        // (mismo id, fecha y day_key, kind = 'routine').
        await txn.execute('''
          CREATE TABLE sessions_new (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL,
            day_key TEXT REFERENCES ${DbTables.routineDays}(day_key),
            kind TEXT NOT NULL DEFAULT '${SessionKind.routine}',
            activity_id TEXT
          )
        ''');
        await txn.execute('''
          INSERT INTO sessions_new (id, date, day_key, kind, activity_id)
          SELECT id, date, day_key, '${SessionKind.routine}', NULL FROM ${DbTables.sessions}
        ''');
        await txn.execute('DROP TABLE ${DbTables.sessions}');
        await txn.execute('ALTER TABLE sessions_new RENAME TO ${DbTables.sessions}');
        await txn.execute('CREATE INDEX IF NOT EXISTS idx_sessions_date ON ${DbTables.sessions}(date)');
      });
    }

    if (oldVersion < 3) {
      // 5) Rutina preferida (opcional, no restrictiva) por día real de la
      // semana: si hoy es martes y martes tiene una preferencia guardada,
      // se sugiere esa rutina; si no hay preferencia para el día, se
      // sigue usando la rotación automática de siempre. Solo existe fila
      // para los días que el usuario configuró — sin fila = sin
      // preferencia, así que instalaciones existentes quedan igual que
      // antes hasta que el usuario configure algo en "Configurar semana".
      await db.execute('''
        CREATE TABLE IF NOT EXISTS ${DbTables.weekdayRoutinePrefs} (
          real_weekday TEXT PRIMARY KEY,
          routine_day_key TEXT NOT NULL REFERENCES ${DbTables.routineDays}(day_key)
        )
      ''');
    }
  }

  /// Solo para tests: cierra y descarta la conexión abierta.
  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }
}
