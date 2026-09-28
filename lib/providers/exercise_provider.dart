import 'package:flutter/foundation.dart';

import '../data/models/exercise.dart';
import '../data/repositories/exercise_repository.dart';

/// Estado del catálogo de ejercicios. Cubre tanto la definición (series,
/// reps, descanso, imágenes, video) como su edición — el único lugar de
/// la app que escribe esos campos, para no tener dos fuentes de verdad.
class ExerciseProvider extends ChangeNotifier {
  ExerciseProvider(this._repo);
  final ExerciseRepository _repo;

  List<Exercise> _all = [];
  bool _loading = false;

  List<Exercise> get all => _all;
  bool get loading => _loading;

  Exercise? byId(String id) {
    for (final e in _all) {
      if (e.id == id) return e;
    }
    return null;
  }

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _all = await _repo.getAll();
    _loading = false;
    notifyListeners();
  }

  /// Crea un ejercicio nuevo en el catálogo y recarga la lista. Al vivir
  /// en la misma tabla y pasar por `RoutineProvider`/`ExerciseProvider`
  /// como cualquier otro, queda disponible de inmediato en el selector
  /// "Agregar ejercicio" de cualquier día de rutina — sin pasos extra.
  Future<Exercise> addExercise({
    required String name,
    required String muscleGroup,
    required MeasureType measureType,
    required String setsLabel,
    required int repLow,
    required int repHigh,
    required String restLabel,
    bool isBodyweight = false,
    String suffix = '',
    bool hasPainNote = false,
    double? baseWeight,
    int? baseSeconds,
  }) async {
    final id = _uniqueIdFor(name);
    final ex = Exercise(
      id: id,
      name: name,
      muscleGroup: muscleGroup,
      measureType: measureType,
      setsLabel: setsLabel,
      repLow: repLow,
      repHigh: repHigh,
      restLabel: restLabel,
      isBodyweight: isBodyweight,
      suffix: suffix,
      hasPainNote: hasPainNote,
      baseWeight: baseWeight,
      baseSeconds: baseSeconds,
    );
    await _repo.insert(ex);
    await load();
    return ex;
  }

  /// Genera un id legible ("curl-biceps-polea") a partir del nombre y le
  /// agrega un sufijo numérico si ya existe uno igual en el catálogo.
  String _uniqueIdFor(String name) {
    final base = _slugify(name);
    final existing = _all.map((e) => e.id).toSet();
    if (!existing.contains(base)) return base;
    var i = 2;
    while (existing.contains('$base-$i')) {
      i++;
    }
    return '$base-$i';
  }

  static const Map<String, String> _accentMap = {
    'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ü': 'u', 'ñ': 'n',
    'Á': 'a', 'É': 'e', 'Í': 'i', 'Ó': 'o', 'Ú': 'u', 'Ü': 'u', 'Ñ': 'n',
  };

  String _slugify(String input) {
    final lower = input.trim().toLowerCase();
    final noAccents = lower.split('').map((ch) => _accentMap[ch] ?? ch).join();
    final slug = noAccents
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    return slug.isEmpty ? 'ejercicio' : slug;
  }

  Future<void> updateParams(
    String id, {
    required String setsLabel,
    required int repLow,
    required int repHigh,
    required String restLabel,
  }) async {
    await _repo.updateParams(id, setsLabel: setsLabel, repLow: repLow, repHigh: repHigh, restLabel: restLabel);
    await load();
  }

  Future<void> setImage(String id, {required int slot, String? path}) async {
    await _repo.updateImage(id, slot: slot, path: path);
    await load();
  }

  Future<void> setVideoUrl(String id, String? url) async {
    await _repo.updateVideoUrl(id, url);
    await load();
  }
}
