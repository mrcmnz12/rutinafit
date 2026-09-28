import 'package:flutter/material.dart';

import '../../core/app_version.dart';
import '../../core/theme/app_colors.dart';
import '../exercises/exercises_list_screen.dart';
import '../onboarding/onboarding_screen.dart';
import 'activities_screen.dart';
import 'settings_appearance_screen.dart';
import 'settings_routines_screen.dart';
import 'week_plan_screen.dart';

/// Ajustes: menú de primer nivel, igual que `screenConfig()` en la
/// maqueta — un menú de opciones desde el que se navega a cada sección
/// concreta, en vez de mostrar todo junto en una sola pantalla larga.
/// A diferencia de la maqueta (que solo tiene "Editar rutinas" y
/// "Ajustes de la app"), acá se agrega también "Editar ejercicios" para
/// que todo el mantenimiento de la app viva en un mismo lugar.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SettingsMenuRow(
            icon: Icons.checklist_rtl,
            title: 'Editar rutinas',
            subtitle: 'Rotación de gym: nombre, objetivo y ejercicios',
            colors: colors,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsRoutinesScreen()),
            ),
          ),
          const SizedBox(height: 10),
          _SettingsMenuRow(
            icon: Icons.event_repeat,
            title: 'Configurar semana',
            subtitle: 'Rutina preferida y actividades por día — no es obligatorio',
            colors: colors,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const WeekPlanScreen()),
            ),
          ),
          const SizedBox(height: 10),
          _SettingsMenuRow(
            icon: Icons.directions_run,
            title: 'Catálogo de actividades',
            subtitle: 'Fútbol, zumba, spinning... agregar, editar y eliminar',
            colors: colors,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ActivitiesScreen()),
            ),
          ),
          const SizedBox(height: 10),
          _SettingsMenuRow(
            icon: Icons.fitness_center,
            title: 'Editar ejercicios',
            subtitle: 'Catálogo completo: agregar, parámetros, imágenes y video',
            colors: colors,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ExercisesListScreen()),
            ),
          ),
          const SizedBox(height: 10),
          _SettingsMenuRow(
            icon: Icons.tune,
            title: 'Ajustes de la app',
            subtitle: 'Color, modo claro / oscuro y más',
            colors: colors,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsAppearanceScreen()),
            ),
          ),
          const SizedBox(height: 10),
          _SettingsMenuRow(
            icon: Icons.help_outline,
            title: 'Ver tutorial',
            subtitle: 'Repasa los 5 pasos de bienvenida de la app',
            colors: colors,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const OnboardingScreen(fromSettings: true)),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text('RutinaFit v$kAppVersion', style: TextStyle(fontSize: 11, color: colors.textMuted)),
          ),
        ],
      ),
    );
  }
}

/// Fila de menú — igual que `.cfg-row` en la maqueta: icono en círculo,
/// título + descripción, flecha.
class _SettingsMenuRow extends StatelessWidget {
  const _SettingsMenuRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.colors,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final AppColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colors.surface1,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(color: colors.accentSoft, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: colors.accent, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(fontSize: 11, color: colors.textMuted)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
