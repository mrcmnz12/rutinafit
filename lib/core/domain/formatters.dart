import '../../data/models/exercise.dart';
import '../../data/models/exercise_log.dart';

/// Texto de resumen ("Último: 46 kg × 10") reutilizado en tarjetas y
/// listas de ejercicios.
String exerciseSummaryText(Exercise ex, ExerciseLogEntry? last) {
  if (last == null) return 'Sin registros aún';
  if (ex.measureType == MeasureType.time) return 'Último: ${last.seconds} s';
  final w = ex.isBodyweight ? 'Peso corporal' : '${_fmtNum(last.weightKg)} kg';
  return 'Último: $w × ${last.reps}${ex.suffix}';
}

/// Texto de lo hecho EN UN DÍA puntual ("3x8 - 120kg"), a diferencia de
/// [exerciseSummaryText] que muestra el último registro histórico. Se usa en
/// el registro diario, donde interesa lo que se hizo ese día específico
/// (incluidas las series), no el valor más reciente en general.
String exerciseDayLogText(Exercise ex, ExerciseLogEntry entry) {
  final sets = entry.setsDone?.toString() ?? '—';
  if (ex.measureType == MeasureType.time) {
    return '${sets}x${entry.seconds?.toString() ?? '—'}s';
  }
  final reps = entry.reps?.toString() ?? '—';
  final setsReps = '${sets}x$reps${ex.suffix}';
  if (ex.isBodyweight) return setsReps;
  return '$setsReps - ${_fmtNum(entry.weightKg)}kg';
}

/// Ej. "3 × 8–10" o "3 × 8–10 s" para ejercicios de tiempo.
String exerciseSetsRepsLabel(Exercise ex) {
  final range = ex.repHigh != ex.repLow ? '${ex.repLow}–${ex.repHigh}' : '${ex.repLow}';
  final unit = ex.measureType == MeasureType.time ? ' s' : '';
  return '${ex.setsLabel} × $range$unit';
}

String _fmtNum(double? v) {
  if (v == null) return '—';
  return v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
}
