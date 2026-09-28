import 'package:flutter/foundation.dart';

import '../core/utils/date_utils.dart';
import '../data/models/exercise_log.dart';
import '../data/repositories/exercise_log_repository.dart';

/// Estado de lo registrado por ejercicio. A diferencia de RoutineProvider
/// o ExerciseProvider no mantiene todo en memoria (puede crecer mucho con
/// el tiempo): cachea por ejercicio lo último consultado y notifica a
/// quien esté escuchando cuando cambia.
class ExerciseLogProvider extends ChangeNotifier {
  ExerciseLogProvider(this._repo);
  final ExerciseLogRepository _repo;

  final Map<String, List<ExerciseLogEntry>> _byExercise = {};

  // Ids de ejercicios con algún registro guardado HOY — para que Inicio
  // sepa si una rutina quedó "a medias" (algo registrado pero la sesión
  // todavía no se marcó como completa) y ofrezca "Continuar" en vez de
  // "Comenzar". Se recalcula desde la base en cada mutación en vez de
  // intentar llevarlo a mano, así no se puede desincronizar.
  Set<String> _todayExerciseIds = {};
  Set<String> get todayExerciseIds => _todayExerciseIds;

  List<ExerciseLogEntry> logsFor(String exerciseId) => _byExercise[exerciseId] ?? const [];

  ExerciseLogEntry? lastFor(String exerciseId) {
    final logs = _byExercise[exerciseId];
    if (logs == null || logs.isEmpty) return null;
    return logs.last;
  }

  Future<void> loadFor(String exerciseId) async {
    _byExercise[exerciseId] = await _repo.getForExercise(exerciseId);
    notifyListeners();
  }

  Future<void> loadToday() async {
    final entries = await _repo.getForDate(todayIso());
    _todayExerciseIds = entries.map((e) => e.exerciseId).toSet();
    notifyListeners();
  }

  Future<bool> isDoneOn(String exerciseId, String date) => _repo.isDoneOn(exerciseId, date);

  Future<List<ExerciseLogEntry>> getForDate(String date) => _repo.getForDate(date);

  Future<void> saveEntry(ExerciseLogEntry entry) async {
    await _repo.upsert(entry);
    await loadFor(entry.exerciseId);
    await loadToday();
  }

  /// Borra todo lo registrado en una fecha ("Eliminar rutina" en el
  /// registro diario) y refresca el caché de los ejercicios afectados para
  /// que cualquier pantalla que ya los tenía cargados (detalle, tarjetas
  /// con "último registro", etc.) deje de mostrar lo borrado.
  Future<void> deleteForDate(String date) async {
    final affectedIds = await _repo.deleteForDate(date);
    for (final id in affectedIds) {
      if (_byExercise.containsKey(id)) {
        await loadFor(id);
      }
    }
    await loadToday();
  }
}
