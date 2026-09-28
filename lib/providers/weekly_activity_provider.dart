import 'package:flutter/foundation.dart';

import '../data/models/activity.dart';
import '../data/repositories/weekly_activity_repository.dart';

/// Estado de qué actividades quedan fijas a qué día real de la semana.
class WeeklyActivityProvider extends ChangeNotifier {
  WeeklyActivityProvider(this._repo);
  final WeeklyActivityRepository _repo;

  Map<String, List<Activity>> _byDay = {};
  bool _loading = false;

  bool get loading => _loading;
  List<Activity> forDay(String dayKey) => _byDay[dayKey] ?? const [];

  /// Actividades fijas al día real de hoy (dowKeyOf(todayIso())).
  List<Activity> forDayKey(String dayKey) => forDay(dayKey);

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _byDay = await _repo.getAllByDay();
    _loading = false;
    notifyListeners();
  }

  Future<void> addToDay(String dayKey, String activityId) async {
    await _repo.addToDay(dayKey, activityId);
    await load();
  }

  Future<void> removeFromDay(String dayKey, String activityId) async {
    await _repo.removeFromDay(dayKey, activityId);
    await load();
  }
}
