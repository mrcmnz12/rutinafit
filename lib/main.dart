import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/db/database_helper.dart';
import 'data/repositories/activity_repository.dart';
import 'data/repositories/bodyweight_repository.dart';
import 'data/repositories/exercise_log_repository.dart';
import 'data/repositories/exercise_repository.dart';
import 'data/repositories/routine_repository.dart';
import 'data/repositories/session_repository.dart';
import 'data/repositories/settings_repository.dart';
import 'data/repositories/weekday_routine_pref_repository.dart';
import 'data/repositories/weekly_activity_repository.dart';
import 'data/seed/database_seeder.dart';
import 'providers/activity_provider.dart';
import 'providers/bodyweight_provider.dart';
import 'providers/exercise_log_provider.dart';
import 'providers/exercise_provider.dart';
import 'providers/onboarding_provider.dart';
import 'providers/routine_provider.dart';
import 'providers/session_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/weekday_routine_pref_provider.dart';
import 'providers/weekly_activity_provider.dart';

/// Punto de entrada. Fija la orientación en vertical (la app no está
/// pensada para horizontal — tablas y listas se verían recortadas),
/// prepara la base SQLite local (creándola y sembrándola con datos de
/// ejemplo solo si está vacía — nunca pisa datos reales del usuario),
/// arma los repositorios y providers, y los deja disponibles a toda la
/// app vía Provider antes de dibujar nada.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final dbHelper = DatabaseHelper.instance;
  await DatabaseSeeder(dbHelper).seedIfEmpty();

  final exerciseRepo = ExerciseRepository(dbHelper);
  final routineRepo = RoutineRepository(dbHelper);
  final sessionRepo = SessionRepository(dbHelper);
  final exerciseLogRepo = ExerciseLogRepository(dbHelper);
  final bodyWeightRepo = BodyWeightRepository(dbHelper);
  final settingsRepo = SettingsRepository(dbHelper);
  final activityRepo = ActivityRepository(dbHelper);
  final weeklyActivityRepo = WeeklyActivityRepository(dbHelper);
  final weekdayRoutinePrefRepo = WeekdayRoutinePrefRepository(dbHelper);
  // settingsRepo ya existe arriba: onboarding usa la misma tabla clave-valor que el tema.

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RoutineProvider(routineRepo)..load()),
        ChangeNotifierProvider(create: (_) => ExerciseProvider(exerciseRepo)..load()),
        ChangeNotifierProvider(create: (_) => SessionProvider(sessionRepo)..load()),
        ChangeNotifierProvider(create: (_) => ExerciseLogProvider(exerciseLogRepo)..loadToday()),
        ChangeNotifierProvider(create: (_) => BodyWeightProvider(bodyWeightRepo)..load()),
        ChangeNotifierProvider(create: (_) => ThemeProvider(settingsRepo)..load()),
        ChangeNotifierProvider(create: (_) => ActivityProvider(activityRepo)..load()),
        ChangeNotifierProvider(create: (_) => WeeklyActivityProvider(weeklyActivityRepo)..load()),
        ChangeNotifierProvider(create: (_) => WeekdayRoutinePrefProvider(weekdayRoutinePrefRepo)..load()),
        ChangeNotifierProvider(create: (_) => OnboardingProvider(settingsRepo)..load()),
      ],
      child: const RutinaFitApp(),
    ),
  );
}
