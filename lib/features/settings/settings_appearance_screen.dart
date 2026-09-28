import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/palettes.dart';
import '../../providers/theme_provider.dart';
import '../../shared/widgets/section_card.dart';

/// "Ajustes de la app" — modo claro/oscuro y paleta de color, igual que
/// `screenConfigApp()` en la maqueta: filas de paleta completas (par de
/// muestras + nombre + check), no puntitos.
class SettingsAppearanceScreen extends StatelessWidget {
  const SettingsAppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final colors = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes de la app')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            title: 'Modo',
            child: Row(
              children: [
                Expanded(child: _ModeButton(label: 'Oscuro', selected: theme.isDark, colors: colors, onTap: () => theme.setThemeMode('dark'))),
                const SizedBox(width: 10),
                Expanded(child: _ModeButton(label: 'Claro', selected: !theme.isDark, colors: colors, onTap: () => theme.setThemeMode('light'))),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SectionCard(
            title: 'Color',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Elige un color de acento. Cada fila muestra el tono oscuro y el claro que usaría la app.',
                  style: TextStyle(fontSize: 11, color: colors.textMuted),
                ),
                const SizedBox(height: 10),
                Column(
                  children: kPaletteOrder.map((key) {
                    final def = kPalettes[key]!;
                    final selected = theme.paletteKey == key;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _PaletteRow(
                        label: def.label,
                        darkSwatch: def.dark,
                        lightSwatch: def.light,
                        selected: selected,
                        colors: colors,
                        onTap: () => theme.setPaletteKey(key),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Botón de modo (Oscuro/Claro) — mismo look que `.mode-btn` de la
/// maqueta: borde y texto de color acento cuando está seleccionado.
class _ModeButton extends StatelessWidget {
  const _ModeButton({required this.label, required this.selected, required this.colors, required this.onTap});
  final String label;
  final bool selected;
  final AppColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? colors.accentSoft : colors.surface1,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? colors.accent : colors.borderStrong, width: 1.5),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: selected ? colors.accent : colors.textSecondary),
        ),
      ),
    );
  }
}

/// Fila de paleta — igual que `.palette-row` de la maqueta: par de
/// muestras (oscuro/claro), nombre y check circular cuando está activa.
class _PaletteRow extends StatelessWidget {
  const _PaletteRow({
    required this.label,
    required this.darkSwatch,
    required this.lightSwatch,
    required this.selected,
    required this.colors,
    required this.onTap,
  });

  final String label;
  final Color darkSwatch;
  final Color lightSwatch;
  final bool selected;
  final AppColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? colors.accentSoft : colors.surface1,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: selected ? colors.accent : colors.border, width: 1.5),
        ),
        child: Row(
          children: [
            _Swatch(color: darkSwatch),
            const SizedBox(width: 4),
            _Swatch(color: lightSwatch),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: colors.textPrimary)),
            ),
            if (selected)
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(color: colors.accent, shape: BoxShape.circle),
                child: Icon(Icons.check, size: 12, color: colors.accentInk),
              ),
          ],
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.black.withValues(alpha: 0.18)),
      ),
    );
  }
}
