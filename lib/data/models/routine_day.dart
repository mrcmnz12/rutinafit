/// La rutina asignada a un cupo de la rotación de gym. `exerciseIds` viene
/// ordenado (se guarda con `position` en routine_day_exercises).
///
/// `dayKey` sigue siendo el identificador estable de la fila en la base
/// (histórico: nació como clave de día de la semana), pero ya NO
/// representa un día fijo: el orden real en que se sugieren las rutinas
/// lo da [rotationOrder]. Los días marcados como descanso (`isRest`)
/// quedan fuera de la rotación.
class RoutineDay {
  final String dayKey;
  final String name;
  final String objective;
  final bool isRest;
  final String warmup;
  final int? rotationOrder;
  final List<String> exerciseIds;

  const RoutineDay({
    required this.dayKey,
    required this.name,
    required this.objective,
    required this.isRest,
    required this.warmup,
    this.rotationOrder,
    this.exerciseIds = const [],
  });

  RoutineDay copyWith({String? name, String? objective, int? rotationOrder, List<String>? exerciseIds}) {
    return RoutineDay(
      dayKey: dayKey,
      name: name ?? this.name,
      objective: objective ?? this.objective,
      isRest: isRest,
      warmup: warmup,
      rotationOrder: rotationOrder ?? this.rotationOrder,
      exerciseIds: exerciseIds ?? this.exerciseIds,
    );
  }

  factory RoutineDay.fromMap(Map<String, Object?> map, {List<String> exerciseIds = const []}) {
    return RoutineDay(
      dayKey: map['day_key'] as String,
      name: map['name'] as String,
      objective: map['objective'] as String? ?? '',
      isRest: (map['is_rest'] as int) == 1,
      warmup: map['warmup'] as String? ?? '',
      rotationOrder: map['rotation_order'] as int?,
      exerciseIds: exerciseIds,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'day_key': dayKey,
      'name': name,
      'objective': objective,
      'is_rest': isRest ? 1 : 0,
      'warmup': warmup,
      'rotation_order': rotationOrder,
    };
  }
}

const List<String> kDowOrder = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];

const Map<String, String> kDowLabel = {
  'mon': 'Lunes', 'tue': 'Martes', 'wed': 'Miércoles', 'thu': 'Jueves',
  'fri': 'Viernes', 'sat': 'Sábado', 'sun': 'Domingo',
};

const Map<String, String> kDowShort = {
  'mon': 'L', 'tue': 'M', 'wed': 'M', 'thu': 'J', 'fri': 'V', 'sat': 'S', 'sun': 'D',
};

/// Orden de rotación por defecto para instalaciones nuevas (mismo orden
/// que usaba la app antes de que la rotación fuera reordenable a mano).
const List<String> kTrainingOrder = ['mon', 'tue', 'thu', 'fri'];
