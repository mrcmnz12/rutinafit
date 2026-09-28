import 'package:flutter/foundation.dart';

import '../core/db/db_constants.dart';
import '../data/repositories/settings_repository.dart';

/// Estado del tema visual: modo claro/oscuro y paleta de color elegida.
/// Se persiste en app_settings para que sobreviva a reinicios de la app.
class ThemeProvider extends ChangeNotifier {
  ThemeProvider(this._repo);
  final SettingsRepository _repo;

  String _themeMode = 'dark';
  String _paletteKey = 'naranja';

  String get themeMode => _themeMode;
  String get paletteKey => _paletteKey;
  bool get isDark => _themeMode == 'dark';

  Future<void> load() async {
    _themeMode = await _repo.getValue(SettingsKeys.themeMode) ?? 'dark';
    _paletteKey = await _repo.getValue(SettingsKeys.paletteKey) ?? 'naranja';
    notifyListeners();
  }

  Future<void> setThemeMode(String mode) async {
    _themeMode = mode;
    notifyListeners();
    await _repo.setValue(SettingsKeys.themeMode, mode);
  }

  Future<void> setPaletteKey(String key) async {
    _paletteKey = key;
    notifyListeners();
    await _repo.setValue(SettingsKeys.paletteKey, key);
  }
}
