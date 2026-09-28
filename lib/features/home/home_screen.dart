import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/activity.dart';
import '../../data/models/routine_day.dart';
import '../../providers/activity_provider.dart';
import '../../providers/bodyweight_provider.dart';
import '../../providers/exercise_log_provider.dart';
import '../../providers/routine_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/weekday_routine_pref_provider.dart';
import '../../providers/weekly_activity_provider.dart';
import '../../shared/widgets/empty_note.dart';
import '../../shared/widgets/section_card.dart';
import '../routines/day_log_screen.dart';
import '../routines/routine_day_screen.dart';
import '../settings/activities_screen.dart';
import 'widgets/month_calendar.dart';

/// Alto fijo compartido por las 2 tarjetas de arriba (rutina sugerida
/// y actividad de hoy) para que queden siempre parejas, sin importar
/// cuánto texto tenga cada una.
const double kHeroCardHeight = 168;

/// Pantalla de inicio. Orden de arriba a abajo (a pedido de Mauricio):
/// 1) rutina de gym sugerida y actividad(es) de hoy, una al lado de la
///    otra para no ocupar tanto espacio; 2) 3 tarjetas resumen de
///    tamaño fijo; 3) calendario del mes con hasta 2 puntos por día,
///    donde tocar un día lleva a su registro.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    final routines = context.watch<RoutineProvider>();
    final sessions = context.watch<SessionProvider>();
    final bodyWeight = context.watch<BodyWeightProvider>();
    final activities = context.watch<ActivityProvider>();
    final weeklyActivities = context.watch<WeeklyActivityProvider>();
    final weekdayPrefs = context.watch<WeekdayRoutinePrefProvider>();
    final exerciseLogs = context.watch<ExerciseLogProvider>();

    if (routines.loading ||
        sessions.loading ||
        bodyWeight.loading ||
        activities.loading ||
        weeklyActivities.loading ||
        weekdayPrefs.loading ||
        routines.days.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final today = todayIso();
    // La rutina preferida para el día real de hoy (si se configuró una
    // en Ajustes > Configurar semana) manda sobre la sugerencia
    // automática; si no hay preferencia para hoy, se sigue usando la
    // rotación de siempre. No es restrictivo: solo cambia cuál rutina
    // aparece resaltada como sugerida.
    final rotationKeys = routines.rotationDayKeys;
    final preferredKey = weekdayPrefs.preferenceForDay(dowKeyOf(today));
    // Si hoy ya se registró una rutina de gym, la tarjeta se queda
    // mostrando esa misma (no la "siguiente" de la rotación) y el
    // botón pasa a indicar que ya está hecha.
    final doneDayKeyToday = sessions.routineDayKeyOn(today);
    // Si no hay ninguna completada todavía, pero ya se registró algún
    // ejercicio hoy de una rutina puntual (se empezó y se dejó a
    // medias), esa es la que se sigue ofreciendo — con "Continuar" en
    // vez de "Comenzar" — en lugar de saltar a la sugerencia de
    // siempre. Se busca en el orden de la rotación: la primera rutina
    // cuyo catálogo de ejercicios cruce con algo ya registrado hoy.
    String? inProgressDayKey;
    if (doneDayKeyToday == null) {
      for (final day in routines.rotation) {
        if (day.exerciseIds.any(exerciseLogs.todayExerciseIds.contains)) {
          inProgressDayKey = day.dayKey;
          break;
        }
      }
    }
    final recDayKey = doneDayKeyToday ??
        inProgressDayKey ??
        ((preferredKey != null && routines.dayOf(preferredKey) != null)
            ? preferredKey
            : sessions.recommendedDay(rotationKeys));
    final recDay = recDayKey != null ? routines.dayOf(recDayKey) : null;
    final routineDoneToday = doneDayKeyToday != null;
    final routineInProgress = inProgressDayKey != null;

    final todaysActivities = weeklyActivities.forDay(dowKeyOf(today));

    final lastWeight = bodyWeight.last;
    final daysSince = sessions.daysSinceLastSession();
    final lastSession = sessions.lastSession;
    var lastLabel = '—';
    if (lastSession != null) {
      lastLabel = lastSession.isRoutine
          ? (routines.dayOf(lastSession.dayKey ?? '')?.name ?? '—')
          : (activities.byId(lastSession.activityId ?? '')?.name ?? '—');
    }

    final marksByDate = <String, CalendarDayMarks>{};
    for (final s in sessions.all) {
      final prev = marksByDate[s.date] ?? const CalendarDayMarks();
      marksByDate[s.date] = CalendarDayMarks(gym: prev.gym || s.isRoutine, activity: prev.activity || s.isActivity);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('RutinaFit'), automaticallyImplyLeading: false),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _SuggestedRoutineCard(recDay: recDay, recDayKey: recDayKey, done: routineDoneToday, inProgress: routineInProgress, colors: c)),
              const SizedBox(width: 10),
              Expanded(child: _TodayActivitiesCard(activities: todaysActivities, sessions: sessions, today: today, colors: c)),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: _FixedStatCard(label: 'Peso actual', value: lastWeight != null ? '${lastWeight.kg} kg' : '—', colors: c)),
              const SizedBox(width: 8),
              Expanded(
                child: _FixedStatCard(
                  label: 'Sin entrenar',
                  value: daysSince == null ? '—' : '$daysSince día${daysSince == 1 ? '' : 's'}',
                  colors: c,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: _FixedStatCard(label: 'Último entreno', value: lastLabel, colors: c)),
            ],
          ),
          const SizedBox(height: 18),
          SectionCard(
            title: 'Calendario',
            trailing: Text('toca un día registrado', style: TextStyle(fontSize: 11, color: c.textMuted)),
            child: Column(
              children: [
                MonthCalendar(
                  marksByDate: marksByDate,
                  onDayTap: (iso) =>
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => DayLogScreen(date: iso))),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _Legend(color: c.dotTorso, label: 'Gym'),
                    const SizedBox(width: 14),
                    _Legend(color: c.dotPiernas, label: 'Actividad'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}

/// Tarjeta de resumen de tamaño FIJO — el valor se trunca con "..." en
/// vez de estirar la tarjeta, para que las 3 queden siempre parejas.
class _FixedStatCard extends StatelessWidget {
  const _FixedStatCard({required this.label, required this.value, required this.colors});
  final String label;
  final String value;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: colors.surface1, borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: colors.textMuted, letterSpacing: 0.2),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: colors.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _SuggestedRoutineCard extends StatelessWidget {
  const _SuggestedRoutineCard({
    required this.recDay,
    required this.recDayKey,
    required this.done,
    required this.inProgress,
    required this.colors,
  });
  final RoutineDay? recDay;
  final String? recDayKey;
  final bool done;
  final bool inProgress;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    if (recDay == null || recDayKey == null) {
      return _EmptyMiniCard(colors: colors, text: 'No hay rutinas de gym configuradas');
    }
    return Container(
      height: kHeroCardHeight,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(color: colors.surface1, border: Border.all(color: colors.borderStrong), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: colors.accentSoft, borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.fitness_center, color: colors.accent, size: 17),
              ),
              const SizedBox(height: 8),
              Text(recDay!.name, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: colors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text('${recDay!.exerciseIds.length} ejercicios', style: TextStyle(fontSize: 10, color: colors.textSecondary)),
            ],
          ),
          SizedBox(
            width: double.infinity,
            child: done
                ? ElevatedButton.icon(
                    onPressed: null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.goodBg,
                      foregroundColor: colors.goodText,
                      disabledBackgroundColor: colors.goodBg,
                      disabledForegroundColor: colors.goodText,
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                    ),
                    icon: const Icon(Icons.check, size: 14),
                    label: const Text('Hecha'),
                  )
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 9), textStyle: const TextStyle(fontSize: 11.5)),
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => RoutineDayScreen(dayKey: recDayKey!))),
                    child: Text(inProgress ? 'Continuar →' : 'Comenzar →'),
                  ),
          ),
        ],
      ),
    );
  }
}

class _TodayActivitiesCard extends StatelessWidget {
  const _TodayActivitiesCard({required this.activities, required this.sessions, required this.today, required this.colors});
  final List<Activity> activities;
  final SessionProvider sessions;
  final String today;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      return _EmptyActivityCard(today: today, colors: colors);
    }
    // Caso normal: una sola actividad ese día — mismo layout que la
    // tarjeta de rutina sugerida (icono arriba, botón pegado abajo) para
    // que ambas queden visualmente parejas.
    if (activities.length == 1) {
      return _ActivityHeroCard(activity: activities.first, sessions: sessions, today: today, colors: colors);
    }
    // Si hubiera más de una actividad el mismo día, el bloque se apila
    // y se centra verticalmente; si no entra, se desplaza en vez de
    // desbordar la tarjeta.
    return Container(
      height: kHeroCardHeight,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(color: colors.surface1, border: Border.all(color: colors.borderStrong), borderRadius: BorderRadius.circular(16)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < activities.length; i++) ...[
                    if (i > 0) const SizedBox(height: 10),
                    _ActivityRow(activity: activities[i], sessions: sessions, today: today, colors: colors),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Tarjeta de la única actividad del día: mismo esqueleto que
/// _SuggestedRoutineCard (icono en caja arriba, nombre + duración,
/// botón de ancho completo pegado abajo) para que las 2 tarjetas de
/// arriba de Inicio se vean como un mismo sistema. El icono usa el
/// color propio de la actividad (el mismo que se eligió en el
/// catálogo) en vez de un color fijo, para diferenciarla del gym.
class _ActivityHeroCard extends StatelessWidget {
  const _ActivityHeroCard({required this.activity, required this.sessions, required this.today, required this.colors});
  final Activity activity;
  final SessionProvider sessions;
  final String today;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final done = sessions.hasActivitySessionOn(today, activity.id);
    final activityColor = _colorFromHex(activity.color);
    return Container(
      height: kHeroCardHeight,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(color: colors.surface1, border: Border.all(color: colors.borderStrong), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: activityColor.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.directions_run, color: activityColor, size: 18),
              ),
              const SizedBox(height: 8),
              Text(activity.name, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: colors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text('${activity.durationMinutes} min', style: TextStyle(fontSize: 10, color: colors.textSecondary)),
            ],
          ),
          SizedBox(
            width: double.infinity,
            child: _ActivityDoneButton(
              done: done,
              colors: colors,
              onTap: () => done
                  ? sessions.unregisterActivitySession(today, activity.id)
                  : sessions.registerActivitySession(today, activity.id),
            ),
          ),
        ],
      ),
    );
  }
}

/// Botón "Marcar hecho" / "Hecho" — un ElevatedButton/OutlinedButton de
/// verdad (no un InkWell+Container armado a mano) para que tenga
/// exactamente la misma forma y el mismo comportamiento de tamaño de
/// Material que el resto de los botones de la app (p. ej. "Comenzar"):
/// así quedan siempre alineados abajo en las tarjetas de Inicio.
class _ActivityDoneButton extends StatelessWidget {
  const _ActivityDoneButton({required this.done, required this.colors, required this.onTap});
  final bool done;
  final AppColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (done) {
      return ElevatedButton.icon(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.goodBg,
          foregroundColor: colors.goodText,
          padding: const EdgeInsets.symmetric(vertical: 9),
          textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
        ),
        icon: const Icon(Icons.check, size: 14),
        label: const Text('Hecho'),
      );
    }
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.textPrimary,
        side: BorderSide(color: colors.border),
        padding: const EdgeInsets.symmetric(vertical: 9),
        textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
      ),
      child: const Text('Marcar hecho'),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.activity, required this.sessions, required this.today, required this.colors});
  final Activity activity;
  final SessionProvider sessions;
  final String today;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final done = sessions.hasActivitySessionOn(today, activity.id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: _colorFromHex(activity.color), shape: BoxShape.circle)),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(activity.name, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: colors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text('${activity.durationMinutes} min', style: TextStyle(fontSize: 10, color: colors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          child: _ActivityDoneButton(
            done: done,
            colors: colors,
            onTap: () => done
                ? sessions.unregisterActivitySession(today, activity.id)
                : sessions.registerActivitySession(today, activity.id),
          ),
        ),
      ],
    );
  }
}

class _EmptyMiniCard extends StatelessWidget {
  const _EmptyMiniCard({required this.colors, required this.text});
  final AppColors colors;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: kHeroCardHeight,
      padding: const EdgeInsets.all(13),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: colors.surface1, border: Border.all(color: colors.border), borderRadius: BorderRadius.circular(16)),
      child: Text(text, textAlign: TextAlign.center, style: TextStyle(fontSize: 11.5, color: colors.textMuted)),
    );
  }
}

/// Estado vacío de la tarjeta de actividad: no hay ninguna actividad
/// fija programada para hoy (ni por Ajustes > Configurar semana ni
/// registrada aparte). En vez de dejar la tarjeta muda, ofrece
/// agregar una del catálogo directo para HOY — eso la fija a este día
/// real de la semana (mismo mecanismo que "Configurar semana"; se
/// puede quitar cuando se quiera desde ahí).
class _EmptyActivityCard extends StatelessWidget {
  const _EmptyActivityCard({required this.today, required this.colors});
  final String today;
  final AppColors colors;

  Future<void> _pickActivity(BuildContext context) async {
    final catalog = context.read<ActivityProvider>().all;
    final dowKey = dowKeyOf(today);
    final chosen = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        final c = Theme.of(context).extension<AppColors>()!;
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Agregar actividad de hoy', style: TextStyle(fontWeight: FontWeight.w700, color: c.textPrimary)),
              ),
              if (catalog.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const EmptyNote('Todavía no hay actividades en el catálogo'),
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
              for (final a in catalog)
                ListTile(
                  leading: Container(width: 10, height: 10, decoration: BoxDecoration(color: _colorFromHex(a.color), shape: BoxShape.circle)),
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
      await context.read<WeeklyActivityProvider>().addToDay(dowKey, chosen);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mismo esqueleto que las otras 2 tarjetas de arriba: contenido
    // arriba, botón de ancho completo pegado abajo con spaceBetween —
    // así los 3 botones ("Comenzar", "Marcar hecho" y este) quedan
    // siempre a la misma altura, sin importar cuánto contenido tenga
    // cada tarjeta arriba.
    return Container(
      height: kHeroCardHeight,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(color: colors.surface1, border: Border.all(color: colors.border), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.event_busy, size: 22, color: colors.textMuted),
              const SizedBox(height: 6),
              Text(
                'Sin actividad física programada',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: colors.textMuted),
              ),
            ],
          ),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 9), textStyle: const TextStyle(fontSize: 11.5)),
              onPressed: () => _pickActivity(context),
              child: const Text('Agregar actividad'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 5),
      Text(label, style: TextStyle(fontSize: 11, color: c.textSecondary)),
    ]);
  }
}

Color _colorFromHex(String hex) {
  final clean = hex.replaceAll('#', '');
  return Color(int.parse('FF$clean', radix: 16));
}
