/// Lo registrado para un ejercicio en una fecha puntual. Único por
/// (exercise_id, date): guardar de nuevo el mismo día reemplaza la entrada,
/// igual que en la maqueta.
class ExerciseLogEntry {
  final int? id;
  final String exerciseId;
  final String date;
  final int? setsDone;
  final int? reps;
  final double? weightKg;
  final int? seconds;
  final int pain; // 1 leve · 3 atento · 6 detener

  const ExerciseLogEntry({
    this.id,
    required this.exerciseId,
    required this.date,
    this.setsDone,
    this.reps,
    this.weightKg,
    this.seconds,
    this.pain = 1,
  });

  factory ExerciseLogEntry.fromMap(Map<String, Object?> map) {
    return ExerciseLogEntry(
      id: map['id'] as int?,
      exerciseId: map['exercise_id'] as String,
      date: map['date'] as String,
      setsDone: map['sets_done'] as int?,
      reps: map['reps'] as int?,
      weightKg: (map['weight_kg'] as num?)?.toDouble(),
      seconds: map['seconds'] as int?,
      pain: map['pain'] as int? ?? 1,
    );
  }

  Map<String, Object?> toMap() {
    final map = <String, Object?>{
      'exercise_id': exerciseId,
      'date': date,
      'sets_done': setsDone,
      'reps': reps,
      'weight_kg': weightKg,
      'seconds': seconds,
      'pain': pain,
    };
    if (id != null) map['id'] = id;
    return map;
  }
}
