import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/routine_day.dart';
import '../../providers/routine_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/weekday_routine_pref_provider.dart';
import 'routine_day_screen.dart';

/// Pestaña "Rutinas": lista para EMPEZAR cualquier rutina de gym de la
/// rotación (no solo la sugerida del día, que es lo único que ofrece el
/// botón "Comenzar" de Inicio). Muestra la rotación tal cual funciona
/// — sin amarrar cada rutina a un día de la semana — con 2 marcas
/// deducidas de las sesiones registradas: "Sugerida" (la próxima según
/// la rotación) y "Última realizada" (la que corresponde a la sesión de
/// gym más reciente). Editar el contenido de una rutina o reordenar la
/// rotación se hace en Ajustes > Editar rutinas; acá solo se ve y se
/// empieza.
class RoutinesListScreen extends StatelessWidget {
  const RoutinesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final routines = context.watch<RoutineProvider>();
    final sessions = context.watch<SessionProvider>();
    final weekdayPrefs = context.watch<WeekdayRoutinePrefProvider>();
    final colors = Theme.of(context).extension<AppColors>()!;

    final rotation = routines.rotation;

    if (routines.loading || sessions.loading || weekdayPrefs.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final today = todayIso();
    // Misma regla que en Inicio: si hoy tiene una rutina preferida
    // configurada (Ajustes > Configurar semana), esa es la sugerida;
    // si no, se cae a la rotación automática de siempre.
    final preferredKey = weekdayPrefs.preferenceForDay(dowKeyOf(today));
    final recommendedKey = (preferredKey != null && routines.dayOf(preferredKey) != null)
        ? preferredKey
        : sessions.recommendedDay(routines.rotationDayKeys);
    final lastRoutine = sessions.lastRoutineSession;

    return Scaffold(
      appBar: AppBar(title: const Text('Rutinas')),
      body: rotation.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Todavía no hay rutinas de gym configuradas.\nAgrégalas desde Ajustes > Editar rutinas.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: colors.textMuted),
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Se van alternando en este orden cada vez que entrenas — no dependen del día de la semana.',
                  style: TextStyle(fontSize: 12, color: colors.textMuted),
                ),
                const SizedBox(height: 14),
                for (final day in rotation)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _RoutineDayRow(
                      day: day,
                      isSuggested: day.dayKey == recommendedKey,
                      lastDoneLabel: (lastRoutine != null && lastRoutine.dayKey == day.dayKey)
                          ? _relativeLabel(daysBetween(lastRoutine.date, today))
                          : null,
                      colors: colors,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => RoutineDayScreen(dayKey: day.dayKey)),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  String _relativeLabel(int daysAgo) {
    if (daysAgo <= 0) return 'hoy';
    if (daysAgo == 1) return 'ayer';
    return 'hace $daysAgo días';
  }
}

class _RoutineDayRow extends StatelessWidget {
  const _RoutineDayRow({
    required this.day,
    required this.isSuggested,
    required this.lastDoneLabel,
    required this.colors,
    required this.onTap,
  });

  final RoutineDay day;
  final bool isSuggested;
  final String? lastDoneLabel;
  final AppColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSuggested ? colors.accentSoft : colors.surface1,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isSuggested ? colors.accent : colors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Text(
                          day.name,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: colors.textPrimary),
                        ),
                        if (isSuggested) _Pill(text: 'SUGERIDA', bg: colors.goodBg, fg: colors.goodText),
                        if (lastDoneLabel != null) _Pill(text: 'ÚLTIMA REALIZADA', bg: colors.surface2, fg: colors.textSecondary),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${day.objective} · ${day.exerciseIds.length} ejercicios',
                      style: TextStyle(fontSize: 13, color: colors.textSecondary),
                    ),
                    if (lastDoneLabel != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Hecha por última vez: $lastDoneLabel',
                        style: TextStyle(fontSize: 11.5, color: colors.textMuted),
                      ),
                    ],
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

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.bg, required this.fg});
  final String text;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(
        text,
        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}
