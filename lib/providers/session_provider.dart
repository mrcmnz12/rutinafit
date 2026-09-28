import 'package:flutter/foundation.dart';

import '../core/utils/date_utils.dart';
import '../data/models/session.dart';
import '../data/repositories/session_repository.dart';

/// Estado del historial de sesiones (rutinas de gym y actividades). De
/// acá salen la recomendación de "próxima rutina" y los datos que se
/// muestran en Inicio. Puede haber más de una sesión por fecha.
class SessionProvider extends ChangeNotifier {
  SessionProvider(this._repo);
  final SessionRepository _repo;

  List<TrainingSession> _all = [];
  bool _loading = false;

  List<TrainingSession> get all => _all;
  bool get loading => _loading;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _all = await _repo.getAll();
    _loading = false;
    notifyListeners();
  }

  List<TrainingSession> sessionsOn(String date) => _all.where((s) => s.date == date).toList();

  bool hasSessionOn(String date) => _all.any((s) => s.date == date);

  bool hasRoutineSessionOn(String date) => _all.any((s) => s.date == date && s.isRoutine);

  /// `dayKey` de la rutina de gym ya registrada en esa fecha, si hay
  /// una — para no seguir sugiriendo "la siguiente" cuando hoy ya se
  /// entrenó.
  String? routineDayKeyOn(String date) {
    for (final s in _all) {
      if (s.date == date && s.isRoutine) return s.dayKey;
    }
    return null;
  }

  bool hasActivitySessionOn(String date, String activityId) =>
      _all.any((s) => s.date == date && s.isActivity && s.activityId == activityId);

  /// Última sesión de rutina de gym registrada (para calcular la
  /// siguiente sugerida), sin importar si ese día también se registró
  /// una actividad.
  TrainingSession? get lastRoutineSession {
    TrainingSession? found;
    for (final s in _all) {
      if (!s.isRoutine) continue;
      if (found == null || s.date.compareTo(found.date) >= 0) found = s;
    }
    return found;
  }

  /// La sesión más reciente registrada, de cualquier tipo — usada para
  /// "días sin entrenar".
  TrainingSession? get lastSession => _all.isEmpty ? null : _all.last;

  Future<void> registerRoutineSession(String date, String dayKey) async {
    if (hasRoutineSessionOn(date)) return;
    await _repo.registerRoutineSession(date, dayKey);
    await load();
  }

  Future<void> registerActivitySession(String date, String activityId) async {
    if (hasActivitySessionOn(date, activityId)) return;
    await _repo.registerActivitySession(date, activityId);
    await load();
  }

  /// Deja de marcar una actividad como hecha en una fecha (si estaba
  /// registrada); no hace nada si no lo estaba.
  Future<void> unregisterActivitySession(String date, String activityId) async {
    final match = _all.where((s) => s.date == date && s.isActivity && s.activityId == activityId);
    if (match.isEmpty) return;
    await deleteSessionById(match.first.id!);
  }

  /// Borra una sesión puntual (routine o activity) — "Eliminar esta
  /// sesión" en el registro diario.
  Future<void> deleteSessionById(int id) async {
    await _repo.deleteById(id);
    await load();
  }

  /// Próxima rutina de gym sugerida, según la rotación reordenable
  /// vigente (ya no según el día real de la semana): el siguiente cupo
  /// de la rotación después del de la última sesión de gym registrada.
  /// Sin historial todavía, sugiere el primero de la rotación.
  String? recommendedDay(List<String> rotationOrder) {
    if (rotationOrder.isEmpty) return null;
    final last = lastRoutineSession;
    if (last == null) return rotationOrder.first;
    final idx = rotationOrder.indexOf(last.dayKey ?? '');
    if (idx == -1) return rotationOrder.first;
    return rotationOrder[(idx + 1) % rotationOrder.length];
  }

  /// Días completos transcurridos desde la última sesión (de cualquier
  /// tipo) hasta hoy. `null` si todavía no hay ninguna sesión registrada.
  int? daysSinceLastSession() {
    final last = lastSession;
    if (last == null) return null;
    final diff = daysBetween(last.date, todayIso());
    return diff < 0 ? 0 : diff;
  }

  /// Sesiones de gym consecutivas sin más de 4 días de hueco entre una y
  /// la siguiente.
  int currentStreak() {
    final routineSessions = _all.where((s) => s.isRoutine).toList();
    if (routineSessions.isEmpty) return 0;
    var streak = 0;
    for (var i = routineSessions.length - 1; i >= 0; i--) {
      streak++;
      if (i > 0) {
        final gap = daysBetween(routineSessions[i - 1].date, routineSessions[i].date);
        if (gap > 4) break;
      }
    }
    return streak;
  }
}
