import 'package:flutter/foundation.dart';

import '../data/models/activity.dart';
import '../data/repositories/activity_repository.dart';

/// Estado del catálogo de actividades adicionales (fútbol, zumba, etc.).
class ActivityProvider extends ChangeNotifier {
  ActivityProvider(this._repo);
  final ActivityRepository _repo;

  List<Activity> _all = [];
  bool _loading = false;

  List<Activity> get all => _all;
  bool get loading => _loading;

  Activity? byId(String id) {
    for (final a in _all) {
      if (a.id == id) return a;
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

  Future<void> create({required String name, required String color, required int durationMinutes}) async {
    final id = '${name.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-')}-${DateTime.now().millisecondsSinceEpoch}';
    await _repo.create(Activity(
      id: id,
      name: name.trim(),
      color: color,
      durationMinutes: durationMinutes,
      sortOrder: _all.length,
    ));
    await load();
  }

  Future<void> update(String id, {String? name, String? color, int? durationMinutes}) async {
    await _repo.update(id, name: name, color: color, durationMinutes: durationMinutes);
    await load();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    await load();
  }
}
