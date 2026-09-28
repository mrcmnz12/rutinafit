/// Nombres de tablas y llaves de configuración centralizados: evita
/// strings mágicos repetidos en los repositorios y facilita migrar el
/// esquema más adelante (una sola fuente de verdad para nombres).
class DbTables {
  static const routineDays = 'routine_days';
  static const exercises = 'exercises';
  static const routineDayExercises = 'routine_day_exercises';
  static const sessions = 'sessions';
  static const exerciseLogs = 'exercise_logs';
  static const bodyWeightEntries = 'bodyweight_entries';
  static const appSettings = 'app_settings';
  static const activities = 'activities';
  static const weeklyActivities = 'weekly_activities';
  static const weekdayRoutinePrefs = 'weekday_routine_prefs';
}

class SettingsKeys {
  static const themeMode = 'theme_mode'; // 'dark' | 'light'
  static const paletteKey = 'palette_key'; // 'gris' | 'verde' | 'rosa' | ...
  static const onboardingSeen = 'onboarding_seen'; // 'true' una vez que se completó o saltó
}

/// Tipos de sesión guardados en `sessions.kind`.
class SessionKind {
  static const routine = 'routine';
  static const activity = 'activity';
}
