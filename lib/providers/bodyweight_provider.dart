import 'package:flutter/foundation.dart';

import '../data/models/bodyweight_entry.dart';
import '../data/repositories/bodyweight_repository.dart';

/// Estado del historial de peso corporal.
class BodyWeightProvider extends ChangeNotifier {
  BodyWeightProvider(this._repo);
  final BodyWeightRepository _repo;

  List<BodyWeightEntry> _all = [];
  bool _loading = false;

  List<BodyWeightEntry> get all => _all;
  bool get loading => _loading;
  BodyWeightEntry? get last => _all.isEmpty ? null : _all.last;
  BodyWeightEntry? get first => _all.isEmpty ? null : _all.first;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _all = await _repo.getAll();
    _loading = false;
    notifyListeners();
  }

  Future<void> logToday(String date, double kg) async {
    await _repo.upsert(date, kg);
    await load();
  }

  /// Borra el registro de peso de una fecha puntual.
  Future<void> deleteEntry(String date) async {
    await _repo.delete(date);
    await load();
  }
}
