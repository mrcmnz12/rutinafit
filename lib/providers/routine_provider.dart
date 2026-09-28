import 'package:flutter/foundation.dart';

import '../data/models/routine_day.dart';
import '../data/repositories/routine_repository.dart';

/// Estado de las rutinas de gym. Única fuente de verdad para la UI de
/// "Editar rutinas" y de qué ejercicios contiene cada una.
class RoutineProvider extends ChangeNotifier {
  RoutineProvider(this._repo);
  final RoutineRepository _repo;

  Map<String, RoutineDay> _days = {};
  bool _loading = false;

  Map<String, RoutineDay> get days => _days;
  bool get loading => _loading;
  RoutineDay? dayOf(String key) => _days[key];

  /// Rutinas de gym (sin las de descanso) en el orden de rotación
  /// actual — la primera es "la próxima". Es la lista que se reordena
  /// a mano en "Editar rutinas".
  List<RoutineDay> get rotation {
    final list = _days.values.where((d) => !d.isRest).toList();
    list.sort((a, b) {
      final ao = a.rotationOrder;
      final bo = b.rotationOrder;
      if (ao == null && bo == null) return a.dayKey.compareTo(b.dayKey);
      if (ao == null) return 1;
      if (bo == null) return -1;
      return ao.compareTo(bo);
    });
    return list;
  }

  List<String> get rotationDayKeys => rotation.map((d) => d.dayKey).toList();

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _days = await _repo.getAllDays();
    _loading = false;
    notifyListeners();
  }

  Future<void> updateNameObjective(String dayKey, {String? name, String? objective}) async {
    await _repo.updateNameObjective(dayKey, name: name, objective: objective);
    await load();
  }

  /// Reordena la rotación de gym a como quedó la lista en pantalla
  /// después de subir/bajar una rutina.
  Future<void> reorderRotation(List<String> orderedDayKeys) async {
    await _repo.updateRotationOrder(orderedDayKeys);
    await load();
  }

  /// Intercambia todo el contenido de dos días.
  Future<void> swapDays(String a, String b) async {
    await _repo.swapDays(a, b);
    await load();
  }

  Future<void> addExercise(String dayKey, String exerciseId) async {
    await _repo.addExerciseToDay(dayKey, exerciseId);
    await load();
  }

  Future<void> removeExercise(String dayKey, String exerciseId) async {
    await _repo.removeExerciseFromDay(dayKey, exerciseId);
    await load();
  }
}
