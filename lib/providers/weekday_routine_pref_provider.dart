import 'package:flutter/foundation.dart';

import '../data/repositories/weekday_routine_pref_repository.dart';

/// Estado de la rutina de gym preferida (opcional) por día real de la
/// semana. Es solo un empujón para la sugerencia del día — nunca
/// bloquea nada: si hoy no tiene preferencia guardada, la sugerencia
/// sigue viniendo de la rotación automática de siempre.
class WeekdayRoutinePrefProvider extends ChangeNotifier {
  WeekdayRoutinePrefProvider(this._repo);
  final WeekdayRoutinePrefRepository _repo;

  Map<String, String> _byDay = {};
  bool _loading = false;

  bool get loading => _loading;

  /// dayKey de la rutina preferida para ese día real, o null si ese día
  /// no tiene preferencia configurada.
  String? preferenceForDay(String realWeekday) => _byDay[realWeekday];

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _byDay = await _repo.getAll();
    _loading = false;
    notifyListeners();
  }

  Future<void> setPreference(String realWeekday, String routineDayKey) async {
    await _repo.setPreference(realWeekday, routineDayKey);
    await load();
  }

  Future<void> clearPreference(String realWeekday) async {
    await _repo.clearPreference(realWeekday);
    await load();
  }
}
