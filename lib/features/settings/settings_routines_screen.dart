import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/routine_day.dart';
import '../../providers/routine_provider.dart';
import 'routine_day_edit_screen.dart';

/// "Editar rutinas": la rotación de rutinas de gym — NO está atada a un
/// día de la semana (la app siempre sugirió "la próxima" según lo
/// último entrenado, sin importar qué día real fuera). Acá se ve y se
/// reordena tal cual funciona, en vez de etiquetarla con días que en la
/// práctica no aplicaban.
///
/// Qué rutina se PREFIERE cada día real de la semana, y las actividades
/// adicionales (fútbol, zumba, etc.), viven aparte, en "Ajustes >
/// Configurar semana" — esta pantalla es solo el contenido de cada
/// rutina y su orden de rotación.
class SettingsRoutinesScreen extends StatelessWidget {
  const SettingsRoutinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final routines = context.watch<RoutineProvider>();
    final colors = Theme.of(context).extension<AppColors>()!;

    final rotation = routines.rotation;

    if (routines.loading || rotation.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Editar rutinas')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Rotación de rutinas de gym', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: colors.textPrimary)),
          const SizedBox(height: 2),
          Text(
            'Se van alternando en este orden cada vez que entrenas — no dependen del día de la semana. Para preferir una rutina en un día puntual, usa Ajustes > Configurar semana.',
            style: TextStyle(fontSize: 12, color: colors.textMuted),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < rotation.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _RotationRow(
                day: rotation[i],
                isNext: i == 0,
                colors: colors,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => RoutineDayEditScreen(dayKey: rotation[i].dayKey)),
                ),
                onMoveUp: i == 0
                    ? null
                    : () {
                        final order = rotation.map((d) => d.dayKey).toList();
                        final tmp = order[i];
                        order[i] = order[i - 1];
                        order[i - 1] = tmp;
                        routines.reorderRotation(order);
                      },
                onMoveDown: i == rotation.length - 1
                    ? null
                    : () {
                        final order = rotation.map((d) => d.dayKey).toList();
                        final tmp = order[i];
                        order[i] = order[i + 1];
                        order[i + 1] = tmp;
                        routines.reorderRotation(order);
                      },
              ),
            ),
        ],
      ),
    );
  }
}

class _RotationRow extends StatelessWidget {
  const _RotationRow({
    required this.day,
    required this.isNext,
    required this.colors,
    required this.onTap,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  final RoutineDay day;
  final bool isNext;
  final AppColors colors;
  final VoidCallback onTap;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colors.surface1,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.border)),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(day.name, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w700, fontSize: 13.5)),
                        if (isNext) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: colors.goodBg, borderRadius: BorderRadius.circular(6)),
                            child: Text('PRÓXIMA', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: colors.goodText, letterSpacing: 0.3)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text('${day.objective} · ${day.exerciseIds.length} ejercicios', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_up),
                    iconSize: 20,
                    splashRadius: 18,
                    color: colors.textSecondary,
                    onPressed: onMoveUp,
                  ),
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down),
                    iconSize: 20,
                    splashRadius: 18,
                    color: colors.textSecondary,
                    onPressed: onMoveDown,
                  ),
                ],
              ),
              Icon(Icons.chevron_right, color: colors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
