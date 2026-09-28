import 'package:flutter/material.dart';

import 'palettes.dart';

/// Todos los tokens de color que la UI necesita más allá de lo que cubre
/// el ColorScheme de Material (grupos musculares, chips de dolor,
/// gráficos). Se leen con `Theme.of(context).extension<AppColors>()!`.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.bgPlane, required this.screenBg,
    required this.surface1, required this.surface2, required this.surface3,
    required this.border, required this.borderStrong,
    required this.textPrimary, required this.textSecondary, required this.textMuted,
    required this.chartGrid, required this.chartAxis,
    required this.good, required this.warning, required this.critical,
    required this.goodBg, required this.warnBg, required this.badBg,
    required this.goodText, required this.warnText, required this.badText,
    required this.dotTorso, required this.dotPiernas,
    required this.grpPecho, required this.grpEspalda, required this.grpHombro,
    required this.grpBrazos, required this.grpPiernas, required this.grpPantorrilla, required this.grpCore,
    required this.accent, required this.accentInk, required this.accentSoft,
    required this.chartLine, required this.chartFillTop, required this.chartFillBottom,
  });

  final Color bgPlane, screenBg, surface1, surface2, surface3;
  final Color border, borderStrong;
  final Color textPrimary, textSecondary, textMuted;
  final Color chartGrid, chartAxis;
  final Color good, warning, critical;
  final Color goodBg, warnBg, badBg;
  final Color goodText, warnText, badText;
  final Color dotTorso, dotPiernas;
  final Color grpPecho, grpEspalda, grpHombro, grpBrazos, grpPiernas, grpPantorrilla, grpCore;
  final Color accent, accentInk, accentSoft;
  final Color chartLine, chartFillTop, chartFillBottom;

  factory AppColors.forModeAndPalette(String mode, String paletteKey) {
    final m = kModeTokens[mode] ?? kModeTokens['dark']!;
    final palette = kPalettes[paletteKey] ?? kPalettes['naranja']!;
    final accent = mode == 'dark' ? palette.dark : palette.light;
    final bgAlpha = mode == 'dark' ? 0.16 : 0.13;
    final warnAlpha = mode == 'dark' ? 0.18 : 0.14;
    final badAlpha = mode == 'dark' ? 0.20 : 0.13;
    final accentSoftAlpha = mode == 'dark' ? 0.18 : 0.13;

    return AppColors(
      bgPlane: m.bgPlane, screenBg: m.screenBg,
      surface1: m.surface1, surface2: m.surface2, surface3: m.surface3,
      border: m.border, borderStrong: m.borderStrong,
      textPrimary: m.textPrimary, textSecondary: m.textSecondary, textMuted: m.textMuted,
      chartGrid: m.chartGrid, chartAxis: m.chartAxis,
      good: m.good, warning: m.warning, critical: m.critical,
      goodBg: m.good.withValues(alpha: bgAlpha),
      warnBg: m.warning.withValues(alpha: warnAlpha),
      badBg: m.critical.withValues(alpha: badAlpha),
      goodText: m.goodText, warnText: m.warnText, badText: m.badText,
      dotTorso: m.dotTorso, dotPiernas: m.dotPiernas,
      grpPecho: m.grpPecho, grpEspalda: m.grpEspalda, grpHombro: m.grpHombro,
      grpBrazos: m.grpBrazos, grpPiernas: m.grpPiernas, grpPantorrilla: m.grpPantorrilla, grpCore: m.grpCore,
      accent: accent, accentInk: m.accentInk,
      accentSoft: accent.withValues(alpha: accentSoftAlpha),
      chartLine: accent, chartFillTop: accent.withValues(alpha: 0.28), chartFillBottom: accent.withValues(alpha: 0.0),
    );
  }

  /// Color de la tarjeta/ícono de un ejercicio según su grupo muscular.
  Color forMuscleGroup(String group) {
    switch (group) {
      case 'Pecho': return grpPecho;
      case 'Espalda': return grpEspalda;
      case 'Hombro': return grpHombro;
      case 'Brazos': return grpBrazos;
      case 'Piernas': return grpPiernas;
      case 'Pantorrilla': return grpPantorrilla;
      case 'Core': return grpCore;
      default: return accent;
    }
  }

  @override
  AppColors copyWith() => this; // se reconstruye entero desde modo+paleta, nunca parcialmente

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    // Transición instantánea: cambiar de tema es una acción explícita del
    // usuario, no vale la pena animar decenas de tokens de color.
    return t < 0.5 ? this : other;
  }
}
