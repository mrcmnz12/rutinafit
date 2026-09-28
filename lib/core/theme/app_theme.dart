import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Arma el ThemeData de Flutter para una combinación modo+paleta,
/// mapeando los tokens de AppColors tanto al ColorScheme de Material
/// (para que los widgets estándar se vean consistentes) como a una
/// ThemeExtension (para los tokens propios de RutinaFit).
class AppTheme {
  AppTheme._();

  static ThemeData build(String mode, String paletteKey) {
    final colors = AppColors.forModeAndPalette(mode, paletteKey);
    final brightness = mode == 'dark' ? Brightness.dark : Brightness.light;
    final base = ThemeData(brightness: brightness, useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: colors.bgPlane,
      textTheme: base.textTheme.apply(bodyColor: colors.textPrimary, displayColor: colors.textPrimary),
      colorScheme: base.colorScheme.copyWith(
        primary: colors.accent,
        onPrimary: colors.accentInk,
        secondary: colors.accent,
        onSecondary: colors.accentInk,
        error: colors.critical,
        surface: colors.surface1,
        onSurface: colors.textPrimary,
      ),
      cardColor: colors.surface1,
      dividerColor: colors.border,
      appBarTheme: AppBarTheme(
        backgroundColor: colors.screenBg,
        foregroundColor: colors.textPrimary,
        elevation: 0,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors.screenBg,
        selectedItemColor: colors.accent,
        unselectedItemColor: colors.textMuted,
        type: BottomNavigationBarType.fixed,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.accent,
          foregroundColor: colors.accentInk,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
      ),
      // Mismo shape/padding que ElevatedButton: Material 3 por defecto le
      // da a OutlinedButton una forma de píldora (StadiumBorder), que se
      // veía distinta al lado de un ElevatedButton (esquinas redondeadas)
      // en el mismo par Cancelar/Guardar. Solo se homologa la forma —el
      // color se deja heredar del ColorScheme, sin cambiarlo.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface2,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.accent)),
      ),
      extensions: [colors],
    );
  }
}
