import '../models/bodyweight_entry.dart';
import '../models/exercise.dart';
import '../models/exercise_log.dart';
import '../models/routine_day.dart';
import '../models/activity.dart';
import '../models/session.dart';

/// Datos de arranque: la rutina real que Mauricio ya estaba usando,
/// portada 1:1 desde la maqueta (rutinafit.html — versión Artifact).
/// Se insertan una sola vez, la primera vez que la app corre con una
/// base de datos vacía (ver AppDatabaseSeeder).
class SeedData {
  SeedData._();

  static const Map<String, RoutineDay> routineDays = {
    'mon': RoutineDay(
      dayKey: 'mon',
      name: 'Torso A',
      rotationOrder: 0,
      objective: 'Pecho + espalda + hombros + tríceps',
      isRest: false,
      warmup: '5 min caminata inclinada suave · 10 círculos de hombros · '
          '10 retracciones escapulares · 1 serie ligera del primer ejercicio.',
      exerciseIds: [
        'press-pecho', 'remo-pecho-apoyado', 'press-inclinado',
        'jalon-pecho', 'elevaciones-laterales', 'triceps-cuerda',
      ],
    ),
    'tue': RoutineDay(
      dayKey: 'tue',
      name: 'Piernas A + Core',
      rotationOrder: 1,
      objective: 'Piernas + estabilidad',
      isRest: false,
      warmup: '5 min bicicleta o caminata · 8–10 sentadillas sin peso · '
          '8 bird-dogs/lado · 8 dead bugs/lado.',
      exerciseIds: [
        'prensa', 'curl-femoral-sentado', 'extension-cuadriceps',
        'curl-femoral-acostado', 'pantorrilla', 'dead-bug', 'plancha-lateral',
      ],
    ),
    'wed': RoutineDay(dayKey: 'wed', name: 'Descanso', objective: 'Recuperación', isRest: true, warmup: ''),
    'thu': RoutineDay(
      dayKey: 'thu',
      name: 'Torso B',
      rotationOrder: 2,
      objective: 'Espalda + pecho + brazos',
      isRest: false,
      warmup: '5 min caminata inclinada suave · 10 círculos de hombros · '
          '10 retracciones escapulares · 1 serie ligera del primer ejercicio.',
      exerciseIds: [
        'jalon-pecho', 'remo-pecho-apoyado', 'press-pecho',
        'reverse-pec-deck', 'curl-biceps-polea', 'curl-martillo', 'triceps-cuerda',
      ],
    ),
    'fri': RoutineDay(
      dayKey: 'fri',
      name: 'Piernas B + Core',
      rotationOrder: 3,
      objective: 'Glúteos + isquiotibiales + abdomen',
      isRest: false,
      warmup: '5 min bicicleta o caminata · 8–10 sentadillas sin peso · '
          '8 bird-dogs/lado · 8 dead bugs/lado.',
      exerciseIds: [
        'prensa-pies-altos', 'sentadilla-goblet', 'extension-cuadriceps',
        'abduccion-cadera', 'curl-femoral-sentado', 'pallof-press', 'plancha',
      ],
    ),
    'sat': RoutineDay(dayKey: 'sat', name: 'Descanso', objective: 'Opcional: caminar 30–45 min', isRest: true, warmup: ''),
    'sun': RoutineDay(dayKey: 'sun', name: 'Descanso', objective: 'Recuperación', isRest: true, warmup: ''),
  };

  static const List<Exercise> exercises = [
    Exercise(id: 'press-pecho', name: 'Press pecho máquina', muscleGroup: 'Pecho', measureType: MeasureType.repsWeight, setsLabel: '3', repLow: 8, repHigh: 10, restLabel: '90 s', baseWeight: 46),
    Exercise(id: 'remo-pecho-apoyado', name: 'Remo pecho apoyado', muscleGroup: 'Espalda', measureType: MeasureType.repsWeight, setsLabel: '3', repLow: 8, repHigh: 12, restLabel: '90 s', baseWeight: 52),
    Exercise(id: 'press-inclinado', name: 'Press inclinado máquina', muscleGroup: 'Pecho', measureType: MeasureType.repsWeight, setsLabel: '3', repLow: 10, repHigh: 10, restLabel: '75 s', baseWeight: 32),
    Exercise(id: 'jalon-pecho', name: 'Jalón al pecho', muscleGroup: 'Espalda', measureType: MeasureType.repsWeight, setsLabel: '3–4', repLow: 8, repHigh: 12, restLabel: '75 s', baseWeight: 48),
    Exercise(id: 'elevaciones-laterales', name: 'Elevaciones laterales', muscleGroup: 'Hombro', measureType: MeasureType.repsWeight, setsLabel: '3', repLow: 12, repHigh: 15, restLabel: '60 s', baseWeight: 8),
    Exercise(id: 'triceps-cuerda', name: 'Tríceps en cuerda', muscleGroup: 'Brazos', measureType: MeasureType.repsWeight, setsLabel: '2–3', repLow: 10, repHigh: 15, restLabel: '60 s', baseWeight: 20),
    Exercise(id: 'prensa', name: 'Prensa', muscleGroup: 'Piernas', measureType: MeasureType.repsWeight, setsLabel: '4', repLow: 8, repHigh: 12, restLabel: '90 s', baseWeight: 120),
    Exercise(id: 'curl-femoral-sentado', name: 'Curl femoral sentado', muscleGroup: 'Piernas', measureType: MeasureType.repsWeight, setsLabel: '3–4', repLow: 10, repHigh: 12, restLabel: '75 s', baseWeight: 38),
    Exercise(id: 'extension-cuadriceps', name: 'Extensión de cuádriceps', muscleGroup: 'Piernas', measureType: MeasureType.repsWeight, setsLabel: '3', repLow: 10, repHigh: 15, restLabel: '60 s', baseWeight: 34),
    Exercise(id: 'curl-femoral-acostado', name: 'Curl femoral acostado', muscleGroup: 'Piernas', measureType: MeasureType.repsWeight, setsLabel: '3', repLow: 10, repHigh: 15, restLabel: '60 s', baseWeight: 30),
    Exercise(id: 'pantorrilla', name: 'Pantorrilla en máquina', muscleGroup: 'Pantorrilla', measureType: MeasureType.repsWeight, setsLabel: '3', repLow: 12, repHigh: 15, restLabel: '60 s', baseWeight: 60),
    Exercise(id: 'dead-bug', name: 'Dead bug', muscleGroup: 'Core', measureType: MeasureType.repsWeight, setsLabel: '3', repLow: 8, repHigh: 12, restLabel: '45 s', isBodyweight: true, suffix: '/lado', baseWeight: 0),
    Exercise(id: 'plancha-lateral', name: 'Plancha lateral', muscleGroup: 'Core', measureType: MeasureType.time, setsLabel: '2', repLow: 20, repHigh: 40, restLabel: '45 s', suffix: '/lado', baseSeconds: 22),
    Exercise(id: 'reverse-pec-deck', name: 'Reverse pec deck', muscleGroup: 'Hombro', measureType: MeasureType.repsWeight, setsLabel: '3', repLow: 12, repHigh: 15, restLabel: '60 s', baseWeight: 18),
    Exercise(id: 'curl-biceps-polea', name: 'Curl bíceps en polea', muscleGroup: 'Brazos', measureType: MeasureType.repsWeight, setsLabel: '2–3', repLow: 10, repHigh: 12, restLabel: '60 s', baseWeight: 10, hasPainNote: true),
    Exercise(id: 'curl-martillo', name: 'Curl martillo con cuerda', muscleGroup: 'Brazos', measureType: MeasureType.repsWeight, setsLabel: '2', repLow: 12, repHigh: 15, restLabel: '60 s', baseWeight: 9),
    Exercise(id: 'prensa-pies-altos', name: 'Prensa (pies altos)', muscleGroup: 'Piernas', measureType: MeasureType.repsWeight, setsLabel: '4', repLow: 10, repHigh: 12, restLabel: '90 s', baseWeight: 110),
    Exercise(id: 'sentadilla-goblet', name: 'Sentadilla goblet', muscleGroup: 'Piernas', measureType: MeasureType.repsWeight, setsLabel: '3', repLow: 8, repHigh: 12, restLabel: '90 s', baseWeight: 16),
    Exercise(id: 'abduccion-cadera', name: 'Abducción de cadera', muscleGroup: 'Piernas', measureType: MeasureType.repsWeight, setsLabel: '3', repLow: 12, repHigh: 15, restLabel: '60 s', baseWeight: 25),
    Exercise(id: 'pallof-press', name: 'Pallof press', muscleGroup: 'Core', measureType: MeasureType.repsWeight, setsLabel: '3', repLow: 10, repHigh: 12, restLabel: '45 s', suffix: '/lado', baseWeight: 12),
    Exercise(id: 'plancha', name: 'Plancha', muscleGroup: 'Core', measureType: MeasureType.time, setsLabel: '2–3', repLow: 30, repHigh: 45, restLabel: '45 s', baseSeconds: 32),
  ];

  /// Historial de sesiones ya registradas antes del primer uso real — solo
  /// para que la demo/QA en Android Studio no arranque vacía. En producción
  /// esto lo genera el uso normal de la app.
  static const List<TrainingSession> sessions = [
    TrainingSession(date: '2026-08-31', dayKey: 'mon'), TrainingSession(date: '2026-09-01', dayKey: 'tue'),
    TrainingSession(date: '2026-09-03', dayKey: 'thu'), TrainingSession(date: '2026-09-04', dayKey: 'fri'),
    TrainingSession(date: '2026-09-07', dayKey: 'mon'), TrainingSession(date: '2026-09-08', dayKey: 'tue'),
    TrainingSession(date: '2026-09-10', dayKey: 'thu'), TrainingSession(date: '2026-09-11', dayKey: 'fri'),
    TrainingSession(date: '2026-09-14', dayKey: 'mon'), TrainingSession(date: '2026-09-15', dayKey: 'tue'),
    TrainingSession(date: '2026-09-17', dayKey: 'thu'), TrainingSession(date: '2026-09-18', dayKey: 'fri'),
    TrainingSession(date: '2026-09-21', dayKey: 'mon'),
  ];

  static const List<BodyWeightEntry> bodyWeightLog = [
    BodyWeightEntry(date: '2026-08-24', kg: 84.6),
    BodyWeightEntry(date: '2026-08-31', kg: 84.2),
    BodyWeightEntry(date: '2026-09-07', kg: 83.7),
    BodyWeightEntry(date: '2026-09-14', kg: 83.3),
    BodyWeightEntry(date: '2026-09-21', kg: 82.9),
  ];

  /// Para cada ejercicio, en qué días de rutina aparece (equivalente al
  /// campo `days` del mockup), derivado de routineDays — una sola fuente
  /// de verdad, sin duplicar la relación en otro lugar.
  static Map<String, List<String>> exerciseDayMembership() {
    final map = <String, List<String>>{};
    routineDays.forEach((dayKey, day) {
      for (final exId in day.exerciseIds) {
        map.putIfAbsent(exId, () => []).add(dayKey);
      }
    });
    return map;
  }

  /// Genera un historial de logs determinístico para un ejercicio, igual
  /// que `generateLog()` en la maqueta: progresión leve de peso/tiempo
  /// cada 3 sesiones, y una serie con dolor "atento" de ejemplo cuando el
  /// ejercicio tiene nota de tendones.
  static List<ExerciseLogEntry> generateLogFor(Exercise ex) {
    final days = exerciseDayMembership()[ex.id] ?? const <String>[];
    final relevant = sessions.where((s) => days.contains(s.dayKey)).toList();
    double weight = ex.baseWeight ?? 0;
    final result = <ExerciseLogEntry>[];

    for (var i = 0; i < relevant.length; i++) {
      final s = relevant[i];
      final cyclePos = i % 3;
      final pain = (ex.hasPainNote && i == 1) ? 3 : 1;

      if (ex.measureType == MeasureType.time) {
        final seconds = (ex.baseSeconds ?? 20) + i * 3;
        result.add(ExerciseLogEntry(exerciseId: ex.id, date: s.date, seconds: seconds, pain: pain));
        continue;
      }

      if (i > 0 && cyclePos == 0) {
        weight = _round1(weight + ((ex.baseWeight ?? 0) < 40 ? 2 : 5));
      }
      var reps = ex.repLow + cyclePos;
      if (reps > ex.repHigh) reps = ex.repHigh;

      result.add(ExerciseLogEntry(
        exerciseId: ex.id,
        date: s.date,
        weightKg: ex.isBodyweight ? null : weight,
        reps: reps,
        pain: pain,
      ));
    }
    return result;
  }

  static double _round1(double n) => (n * 10).round() / 10;

  /// Catálogo inicial de actividades adicionales — el usuario puede
  /// editarlas, borrarlas o agregar las suyas desde "Gestionar catálogo".
  /// No se asignan a ningún día por defecto: eso lo decide el usuario.
  static const List<Activity> activities = [
    Activity(id: 'futbol', name: 'Fútbol', color: '#2e9e77', durationMinutes: 60, sortOrder: 0),
    Activity(id: 'zumba', name: 'Zumba', color: '#d9536a', durationMinutes: 45, sortOrder: 1),
    Activity(id: 'spinning', name: 'Spinning', color: '#3e7fc1', durationMinutes: 45, sortOrder: 2),
    Activity(id: 'cardio-libre', name: 'Cardio libre', color: '#d98a2b', durationMinutes: 30, sortOrder: 3),
  ];
}
