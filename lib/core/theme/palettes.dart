import 'package:flutter/material.dart';

/// Una paleta de acento, con su variante para modo oscuro y otra para
/// modo claro — portado 1:1 desde los 7 colores de la maqueta.
class PaletteDef {
  const PaletteDef({required this.label, required this.dark, required this.light});
  final String label;
  final Color dark;
  final Color light;
}

const Map<String, PaletteDef> kPalettes = {
  'gris': PaletteDef(label: 'Escala de grises', dark: Color(0xFFC9C8C2), light: Color(0xFF4B4A45)),
  'verde': PaletteDef(label: 'Verdes', dark: Color(0xFF3ECF7E), light: Color(0xFF188A4C)),
  'rosa': PaletteDef(label: 'Rosas', dark: Color(0xFFF472A8), light: Color(0xFFC2357A)),
  'naranja': PaletteDef(label: 'Naranjas', dark: Color(0xFFD95926), light: Color(0xFFB3540F)),
  'amarillo': PaletteDef(label: 'Amarillos', dark: Color(0xFFE8B93A), light: Color(0xFF8A6A12)),
  'azul': PaletteDef(label: 'Azules', dark: Color(0xFF4C93E6), light: Color(0xFF1F5FB0)),
  'morado': PaletteDef(label: 'Morados', dark: Color(0xFF9D7BEF), light: Color(0xFF6B3FC4)),
};

const List<String> kPaletteOrder = ['gris', 'verde', 'rosa', 'naranja', 'amarillo', 'azul', 'morado'];

/// Tokens neutros y de estado que dependen del modo (claro/oscuro) pero
/// no de la paleta de acento elegida — incluye los colores por grupo
/// muscular, que hoy son fijos por modo (ver docs/ARQUITECTURA.md, punto
/// abierto: "colores por grupo según paleta").
class ModeTokens {
  const ModeTokens({
    required this.bgPlane, required this.screenBg,
    required this.surface1, required this.surface2, required this.surface3,
    required this.border, required this.borderStrong,
    required this.textPrimary, required this.textSecondary, required this.textMuted,
    required this.chartGrid, required this.chartAxis, required this.accentInk,
    required this.good, required this.warning, required this.critical,
    required this.goodText, required this.warnText, required this.badText,
    required this.dotTorso, required this.dotPiernas,
    required this.grpPecho, required this.grpEspalda, required this.grpHombro,
    required this.grpBrazos, required this.grpPiernas, required this.grpPantorrilla, required this.grpCore,
  });

  final Color bgPlane, screenBg, surface1, surface2, surface3;
  final Color border, borderStrong;
  final Color textPrimary, textSecondary, textMuted;
  final Color chartGrid, chartAxis, accentInk;
  final Color good, warning, critical;
  final Color goodText, warnText, badText;
  final Color dotTorso, dotPiernas;
  final Color grpPecho, grpEspalda, grpHombro, grpBrazos, grpPiernas, grpPantorrilla, grpCore;
}

const Map<String, ModeTokens> kModeTokens = {
  'dark': ModeTokens(
    bgPlane: Color(0xFF0D0D0E), screenBg: Color(0xFF131316),
    surface1: Color(0xFF1C1D21), surface2: Color(0xFF232429), surface3: Color(0xFF2A2C32),
    border: Color(0x14FFFFFF), borderStrong: Color(0x24FFFFFF),
    textPrimary: Color(0xFFF5F4F2), textSecondary: Color(0xFFA9A8A3), textMuted: Color(0xFF75746F),
    chartGrid: Color(0xFF2C2C2A), chartAxis: Color(0xFF43433F), accentInk: Color(0xFF181812),
    good: Color(0xFF0CA30C), warning: Color(0xFFE8A324), critical: Color(0xFFE05A5A),
    goodText: Color(0xFF7FDA7F), warnText: Color(0xFFFFD57A), badText: Color(0xFFFF9D9D),
    dotTorso: Color(0xFFD95926), dotPiernas: Color(0xFF199E70),
    grpPecho: Color(0xFFD95926), grpEspalda: Color(0xFF3987E5), grpHombro: Color(0xFFC98500),
    grpBrazos: Color(0xFFD55181), grpPiernas: Color(0xFF199E70), grpPantorrilla: Color(0xFF008300), grpCore: Color(0xFF9085E9),
  ),
  'light': ModeTokens(
    bgPlane: Color(0xFFEFEEE9), screenBg: Color(0xFFFCFCFB),
    surface1: Color(0xFFFFFFFF), surface2: Color(0xFFF1F0EC), surface3: Color(0xFFE7E5DE),
    border: Color(0x1A0B0B0B), borderStrong: Color(0x2E0B0B0B),
    textPrimary: Color(0xFF0B0B0B), textSecondary: Color(0xFF52514E), textMuted: Color(0xFF898781),
    chartGrid: Color(0xFFE1E0D9), chartAxis: Color(0xFFC3C2B7), accentInk: Color(0xFFFDFAF6),
    good: Color(0xFF0CA30C), warning: Color(0xFFA3690A), critical: Color(0xFFC23B3B),
    goodText: Color(0xFF0C7A24), warnText: Color(0xFF8A5A00), badText: Color(0xFFA53232),
    dotTorso: Color(0xFFEB6834), dotPiernas: Color(0xFF1BAF7A),
    grpPecho: Color(0xFFEB6834), grpEspalda: Color(0xFF2A78D6), grpHombro: Color(0xFFC9880A),
    grpBrazos: Color(0xFFC2557D), grpPiernas: Color(0xFF1BAF7A), grpPantorrilla: Color(0xFF1A7A1A), grpCore: Color(0xFF4A3AA7),
  ),
};
