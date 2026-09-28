import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/activity.dart';
import '../../data/models/routine_day.dart';
import '../../providers/activity_provider.dart';
import '../../providers/routine_provider.dart';
import '../../providers/weekday_routine_pref_provider.dart';
import '../../providers/weekly_activity_provider.dart';
import '../../shared/widgets/empty_note.dart';
import 'activities_screen.dart';

/// "Configurar semana": por cada día real (lunes..domingo), define qué
/// rutina de gym se PREFIERE ese día y qué actividades adicionales le
/// quedan fijas. Nada de esto es restrictivo:
///
/// - Rutina preferida: es solo un empujón para la sugerencia de ese día
///   puntual. Si hoy es martes y martes tiene una preferencia guardada,
///   se sugiere esa; si no hay preferencia (o entrenas otro día), la
///   sugerencia sigue viniendo de la rotación automática de siempre
///   (la siguiente después de la última que hiciste) — nunca se
///   bloquea poder entrenar cualquier rutina cualquier día.
/// - Actividades: igual que antes (fútbol, zumba, etc.), fijas a un día
///   real de la semana; esto vivía dentro de "Editar rutinas" y se
///   movió acá para juntar toda la planificación semanal en un solo
///   lugar.
class WeekPlanScreen extends StatelessWidget {
  const WeekPlanScreen({super.key});

  Future<void> _pickPreferredRoutine(BuildContext context, String realWeekday, List<RoutineDay> rotation, String? current) async {
    final chosen = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        final colors = Theme.of(context).extension<AppColors>()!;
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Rutina preferida — ${kDowLabel[realWeekday]}',
                  style: TextStyle(fontWeight: FontWeight.w700, color: colors.textPrimary),
                ),
              ),
              ListTile(
                leading: Icon(Icons.autorenew, color: colors.textSecondary),
                title: const Text('Según la rotación (sin preferencia)'),
                subtitle: const Text('Se sugiere la siguiente después de la última que hiciste'),
                selected: current == null,
                onTap: () => Navigator.of(context).pop('__clear__'),
              ),
              const Divider(height: 1),
              for (final day in rotation)
                ListTile(
                  title: Text(day.name),
                  subtitle: Text('${day.objective} · ${day.exerciseIds.length} ejercicios'),
                  selected: current == day.dayKey,
                  onTap: () => Navigator.of(context).pop(day.dayKey),
                ),
            ],
          ),
        );
      },
    );
    if (chosen == null || !context.mounted) return;
    final prefs = context.read<WeekdayRoutinePrefProvider>();
    if (chosen == '__clear__') {
      await prefs.clearPreference(realWeekday);
    } else {
      await prefs.setPreference(realWeekday, chosen);
    }
  }

  Future<void> _pickActivityToAdd(BuildContext context, String dayKey, List<Activity> catalog, Set<String> already) async {
    final candidates = catalog.where((a) => !already.contains(a.id)).toList();
    final chosen = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        final colors = Theme.of(context).extension<AppColors>()!;
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Agregar actividad — ${kDowLabel[dayKey]}',
                  style: TextStyle(fontWeight: FontWeight.w700, color: colors.textPrimary),
                ),
              ),
              if (candidates.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const EmptyNote('Ya agregaste todas las actividades del catálogo a este día'),
                      const SizedBox(height: 10),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ActivitiesScreen()));
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Crear una actividad nueva'),
                      ),
                    ],
                  ),
                ),
              for (final a in candidates)
                ListTile(
                  leading: _Dot(color: _colorFromHex(a.color)),
                  title: Text(a.name),
                  subtitle: Text('${a.durationMinutes} min'),
                  onTap: () => Navigator.of(context).pop(a.id),
                ),
            ],
          ),
        );
      },
    );
    if (chosen != null && context.mounted) {
      await context.read<WeeklyActivityProvider>().addToDay(dayKey, chosen);
    }
  }

  @override
  Widget build(BuildContext context) {
    final routines = context.watch<RoutineProvider>();
    final weekdayPrefs = context.watch<WeekdayRoutinePrefProvider>();
    final weeklyActivities = context.watch<WeeklyActivityProvider>();
    final activities = context.watch<ActivityProvider>();
    final colors = Theme.of(context).extension<AppColors>()!;

    final rotation = routines.rotation;

    if (routines.loading || weekdayPrefs.loading || weeklyActivities.loading || activities.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Configurar semana')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Solo es una sugerencia por día: si un día tiene rutina o actividad definida acá, aparece resaltada, pero nada te impide entrenar otra cosa cualquier día. El catálogo de actividades (crear, editar, eliminar) vive en Ajustes > Catálogo de actividades.',
            style: TextStyle(fontSize: 12, color: colors.textMuted),
          ),
          const SizedBox(height: 16),
          for (final dayKey in kDowOrder)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _DayPlanCard(
                dayKey: dayKey,
                preferredDay: _resolvePreferredDay(routines, weekdayPrefs.preferenceForDay(dayKey)),
                activities: weeklyActivities.forDay(dayKey),
                colors: colors,
                onPickRoutine: () => _pickPreferredRoutine(context, dayKey, rotation, weekdayPrefs.preferenceForDay(dayKey)),
                onAddActivity: () => _pickActivityToAdd(
                  context,
                  dayKey,
                  activities.all,
                  weeklyActivities.forDay(dayKey).map((a) => a.id).toSet(),
                ),
                onRemoveActivity: (activityId) => context.read<WeeklyActivityProvider>().removeFromDay(dayKey, activityId),
              ),
            ),
        ],
      ),
    );
  }
}

/// null si ese día no tiene preferencia guardada, o si la guardada
/// apunta a una rutina que ya no existe (no debería pasar, pero
/// `dayOf` responde null en vez de reventar si pasara).
RoutineDay? _resolvePreferredDay(RoutineProvider routines, String? preferredKey) {
  if (preferredKey == null) return null;
  return routines.dayOf(preferredKey);
}

class _DayPlanCard extends StatelessWidget {
  const _DayPlanCard({
    required this.dayKey,
    required this.preferredDay,
    required this.activities,
    required this.colors,
    required this.onPickRoutine,
    required this.onAddActivity,
    required this.onRemoveActivity,
  });

  final String dayKey;
  final RoutineDay? preferredDay;
  final List<Activity> activities;
  final AppColors colors;
  final VoidCallback onPickRoutine;
  final VoidCallback onAddActivity;
  final ValueChanged<String> onRemoveActivity;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: colors.surface1, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(kDowLabel[dayKey]!, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: colors.textPrimary)),
          const SizedBox(height: 10),
          Text('RUTINA PREFERIDA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: colors.textMuted, letterSpacing: 0.3)),
          const SizedBox(height: 6),
          Material(
            color: colors.surface2,
            borderRadius: BorderRadius.circular(11),
            child: InkWell(
              borderRadius: BorderRadius.circular(11),
              onTap: onPickRoutine,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(11), border: Border.all(color: colors.border)),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        preferredDay?.name ?? 'Según la rotación',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: preferredDay != null ? colors.textPrimary : colors.textMuted,
                          fontStyle: preferredDay != null ? FontStyle.normal : FontStyle.italic,
                        ),
                      ),
                    ),
                    Icon(Icons.expand_more, size: 18, color: colors.textMuted),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('ACTIVIDADES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: colors.textMuted, letterSpacing: 0.3)),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: onAddActivity,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(color: colors.surface2, borderRadius: BorderRadius.circular(8), border: Border.all(color: colors.border)),
                  child: Icon(Icons.add, size: 13, color: colors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (activities.isEmpty)
            Text('Sin actividades fijas', style: TextStyle(fontSize: 11, color: colors.textMuted, fontStyle: FontStyle.italic))
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final a in activities)
                  Container(
                    padding: const EdgeInsets.fromLTRB(9, 4, 7, 4),
                    decoration: BoxDecoration(color: colors.surface2, borderRadius: BorderRadius.circular(20), border: Border.all(color: colors.border)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _Dot(color: _colorFromHex(a.color)),
                        const SizedBox(width: 5),
                        Text(a.name, style: TextStyle(fontSize: 11, color: colors.textPrimary)),
                        InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => onRemoveActivity(a.id),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Icon(Icons.close, size: 13, color: colors.textMuted),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
  }
}

Color _colorFromHex(String hex) {
  final clean = hex.replaceAll('#', '');
  return Color(int.parse('FF$clean', radix: 16));
}
