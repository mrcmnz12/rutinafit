import 'package:flutter/foundation.dart';

import '../core/db/db_constants.dart';
import '../data/repositories/settings_repository.dart';

/// Si ya se mostró el tutorial de bienvenida — se guarda en app_settings
/// (misma tabla clave-valor que el tema) para que no vuelva a aparecer
/// solo después de completarlo o saltarlo una vez. "Ver tutorial" en
/// Ajustes lo vuelve a mostrar bajo demanda sin tocar esta marca.
class OnboardingProvider extends ChangeNotifier {
  OnboardingProvider(this._repo);
  final SettingsRepository _repo;

  bool _loading = true;
  bool _seen = false;

  bool get loading => _loading;
  bool get seen => _seen;

  Future<void> load() async {
    final value = await _repo.getValue(SettingsKeys.onboardingSeen);
    _seen = value == 'true';
    _loading = false;
    notifyListeners();
  }

  Future<void> markSeen() async {
    if (_seen) return;
    _seen = true;
    notifyListeners();
    await _repo.setValue(SettingsKeys.onboardingSeen, 'true');
  }
}
