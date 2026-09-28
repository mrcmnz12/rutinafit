import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/data/bundled_exercise_images.dart';
import '../../core/domain/formatters.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/activity.dart';
import '../../data/models/exercise.dart';
import '../../data/models/exercise_log.dart';
import '../../data/models/session.dart';
import '../../providers/activity_provider.dart';
import '../../providers/exercise_log_provider.dart';
import '../../providers/exercise_provider.dart';
import '../../providers/routine_provider.dart';
import '../../providers/session_provider.dart';
import '../../shared/widgets/empty_note.dart';
import '../../shared/widgets/exercise_evolution_charts.dart';
import '../../shared/widgets/expandable_section.dart';
import '../../shared/widgets/pill.dart';

/// Detalle de un día marcado en el calendario de Inicio: qué se
/// registró ese día — puede ser una rutina de gym, una o más
/// actividades, o ambas — cada una en su propio bloque, con su propio
/// menú para eliminar solo esa sesión.
class DayLogScreen extends StatefulWidget {
  const DayLogScreen({super.key, required this.date});
  final String date;

  @override
  State<DayLogScreen> createState() => _DayLogScreenState();
}

class _DayLogScreenState extends State<DayLogScreen> {
  List<ExerciseLogEntry> _entries = [];
  bool _loading = true;
  String? _expandedExerciseId;

  void _toggleExpanded(String exerciseId) {
    setState(() => _expandedExerciseId = _expandedExerciseId == exerciseId ? null : exerciseId);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final logProvider = context.read<ExerciseLogProvider>();
    final entries = await logProvider.getForDate(widget.date);
    if (!mounted) return;
    setState(() {
      _entries = entries;
      _loading = false;
    });
  }

  ExerciseLogEntry? _entryFor(String exerciseId) {
    for (final e in _entries) {
      if (e.exerciseId == exerciseId) return e;
    }
    return null;
  }

  Future<void> _deleteRoutineSession(TrainingSession session) async {
    final colors = Theme.of(context).extension<AppColors>()!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar rutina'),
        content: const Text(
          'Se van a borrar todos los ejercicios registrados este día y la rutina dejará de aparecer como entrenada. Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('Eliminar', style: TextStyle(color: colors.critical, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await context.read<ExerciseLogProvider>().deleteForDate(widget.date);
    if (!mounted) return;
    await context.read<SessionProvider>().deleteSessionById(session.id!);
    if (!mounted) return;
    await _load();
    _afterDelete();
  }

  Future<void> _deleteActivitySession(TrainingSession session, String label) async {
    final colors = Theme.of(context).extension<AppColors>()!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar actividad'),
        content: Text('Se va a borrar "$label" de este día. Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('Eliminar', style: TextStyle(color: colors.critical, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await context.read<SessionProvider>().deleteSessionById(session.id!);
    _afterDelete();
  }

  void _afterDelete() {
    if (!mounted) return;
    final stillHasSessions = context.read<SessionProvider>().sessionsOn(widget.date).isNotEmpty;
    if (!stillHasSessions) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final sessions = context.watch<SessionProvider>();
    final routines = context.watch<RoutineProvider>();
    final exercises = context.watch<ExerciseProvider>();
    final activities = context.watch<ActivityProvider>();
    final colors = Theme.of(context).extension<AppColors>()!;

    final daySessions = sessions.sessionsOn(widget.date);
    final routineSessions = daySessions.where((s) => s.isRoutine).toList();
    final activitySessions = daySessions.where((s) => s.isActivity).toList();
    final multi = daySessions.length > 1;

    return Scaffold(
      appBar: AppBar(title: Text(formatShort(widget.date))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : daySessions.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: EmptyNote('No hay nada registrado para este día', centered: true),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    for (final session in routineSessions) ...[
                      _SessionHeader(
                        label: multi ? 'Rutina · Gym' : null,
                        title: routines.dayOf(session.dayKey ?? '')?.name ?? 'Rutina',
                        onDelete: () => _deleteRoutineSession(session),
                        colors: colors,
                      ),
                      _RoutineBody(
                        session: session,
                        routines: routines,
                        exercises: exercises,
                        entries: _entries,
                        entryFor: _entryFor,
                        expandedExerciseId: _expandedExerciseId,
                        onToggle: _toggleExpanded,
                        colors: colors,
                      ),
                      const SizedBox(height: 18),
                    ],
                    for (final session in activitySessions) ...[
                      _SessionHeader(
                        label: multi ? 'Actividad' : null,
                        title: activities.byId(session.activityId ?? '')?.name ?? 'Actividad',
                        onDelete: () => _deleteActivitySession(session, activities.byId(session.activityId ?? '')?.name ?? 'esta actividad'),
                        colors: colors,
                      ),
                      _ActivityBody(activity: activities.byId(session.activityId ?? ''), colors: colors),
                      const SizedBox(height: 18),
                    ],
                  ],
                ),
    );
  }
}

/// Encabezado de un bloque de sesión, con su propio menú "⋮ → Eliminar
/// esta sesión" — así cada sesión se borra por separado sin afectar a
/// las demás del mismo día.
class _SessionHeader extends StatelessWidget {
  const _SessionHeader({required this.title, required this.onDelete, required this.colors, this.label});
  final String? label;
  final String title;
  final VoidCallback onDelete;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (label != null)
                Text(label!.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: .3, color: colors.textMuted)),
              Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: colors.textPrimary)),
            ],
          ),
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'delete') onDelete();
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, size: 18, color: colors.critical),
                  const SizedBox(width: 10),
                  const Text('Eliminar esta sesión'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RoutineBody extends StatelessWidget {
  const _RoutineBody({
    required this.session,
    required this.routines,
    required this.exercises,
    required this.entries,
    required this.entryFor,
    required this.expandedExerciseId,
    required this.onToggle,
    required this.colors,
  });

  final TrainingSession session;
  final RoutineProvider routines;
  final ExerciseProvider exercises;
  final List<ExerciseLogEntry> entries;
  final ExerciseLogEntry? Function(String) entryFor;
  final String? expandedExerciseId;
  final ValueChanged<String> onToggle;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final day = routines.dayOf(session.dayKey ?? '');
    if (day == null) {
      return Text('Rutina eliminada', style: TextStyle(fontSize: 13, color: colors.textMuted));
    }
    final configuredIds = day.exerciseIds.toSet();
    final extraEntries = entries.where((e) => !configuredIds.contains(e.exerciseId)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 2),
        Text(day.objective, style: TextStyle(fontSize: 13, color: colors.textSecondary)),
        const SizedBox(height: 14),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: day.exerciseIds.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final id = day.exerciseIds[index];
            final ex = exercises.byId(id);
            if (ex == null) return const SizedBox.shrink();
            final entry = entryFor(id);
            return _DayExerciseRow(
              exercise: ex,
              entry: entry,
              colors: colors,
              expanded: expandedExerciseId == id,
              onToggle: () => onToggle(id),
            );
          },
        ),
        if (extraEntries.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text('Agregado ese día', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.textPrimary)),
          const SizedBox(height: 2),
          Text(
            'Ejercicios extra hechos esa sesión, fuera de la rutina configurada.',
            style: TextStyle(fontSize: 11, color: colors.textMuted),
          ),
          const SizedBox(height: 10),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: extraEntries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final entry = extraEntries[index];
              final ex = exercises.byId(entry.exerciseId);
              if (ex == null) return const SizedBox.shrink();
              return _DayExerciseRow(
                exercise: ex,
                entry: entry,
                colors: colors,
                expanded: expandedExerciseId == ex.id,
                onToggle: () => onToggle(ex.id),
              );
            },
          ),
        ],
      ],
    );
  }
}

class _ActivityBody extends StatelessWidget {
  const _ActivityBody({required this.activity, required this.colors});
  final Activity? activity;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    if (activity == null) {
      return Text('Esta actividad ya no está en el catálogo', style: TextStyle(fontSize: 12.5, color: colors.textMuted));
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: colors.surface1, borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.border)),
      child: Row(
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: _colorFromHex(activity!.color), shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Text('${activity!.durationMinutes} min', style: TextStyle(fontSize: 12.5, color: colors.textSecondary)),
        ],
      ),
    );
  }
}

/// Fila de un ejercicio dentro del registro diario. Muestra lo hecho ese
/// día puntual (no el último registro histórico) y, al tocarla, despliega
/// un "spoiler" con la evolución del ejercicio (peso/tiempo, repeticiones y
/// series) — reutilizando el historial completo, que se carga recién al
/// abrir el desplegable para no pedirlo de más.
class _DayExerciseRow extends StatefulWidget {
  const _DayExerciseRow({
    required this.exercise,
    required this.entry,
    required this.colors,
    required this.expanded,
    required this.onToggle,
  });
  final Exercise exercise;
  final ExerciseLogEntry? entry;
  final AppColors colors;

  /// Controlado desde la pantalla (patrón acordeón: solo una fila abierta a
  /// la vez entre todos los ejercicios del día, incluidos los extra).
  final bool expanded;
  final VoidCallback onToggle;

  @override
  State<_DayExerciseRow> createState() => _DayExerciseRowState();
}

class _DayExerciseRowState extends State<_DayExerciseRow> {
  bool _loadingHistory = false;
  bool _historyRequested = false;

  // Se dispara desde el propio didUpdateWidget de esta fila (no desde
  // ExpandableSection) para que el único setState que se llama sea el de
  // este mismo State — llamar setState de un ancestro desde el
  // didUpdateWidget de un descendiente, dentro de una lista con scroll,
  // rompía una aserción interna de Flutter (SelectionKeepAlive/`!_dirty`).
  @override
  void didUpdateWidget(covariant _DayExerciseRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.expanded && !oldWidget.expanded && !_historyRequested) {
      _historyRequested = true;
      _loadHistory();
    }
  }

  Future<void> _loadHistory() async {
    setState(() => _loadingHistory = true);
    await context.read<ExerciseLogProvider>().loadFor(widget.exercise.id);
    if (mounted) setState(() => _loadingHistory = false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final ex = widget.exercise;
    final entry = widget.entry;
    final logProvider = context.watch<ExerciseLogProvider>();

    return ExpandableSection(
      expanded: widget.expanded,
      onToggle: widget.onToggle,
      header: Row(
        children: [
          Builder(builder: (context) {
            final bundledPath = bundledExerciseImagePath(ex.id);
            return ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 38,
                height: 38,
                child: bundledPath != null
                    ? Image.asset(bundledPath, fit: BoxFit.cover)
                    : Container(
                        color: colors.forMuscleGroup(ex.muscleGroup).withValues(alpha: 0.18),
                        alignment: Alignment.center,
                        child: Icon(Icons.fitness_center, size: 18, color: colors.forMuscleGroup(ex.muscleGroup)),
                      ),
              ),
            );
          }),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(ex.name, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: colors.textPrimary)),
                const SizedBox(height: 2),
                Text(
                  entry == null ? 'Sin registro ese día' : exerciseDayLogText(ex, entry),
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
              ],
            ),
          ),
          if (entry != null) ...[
            const SizedBox(width: 8),
            PainPill(pain: entry.pain),
          ],
        ],
      ),
      builder: (context) {
        if (_loadingHistory) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Center(child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))),
          );
        }
        final logs = logProvider.logsFor(ex.id);
        return ExerciseEvolutionCharts(exercise: ex, logs: logs);
      },
    );
  }
}

Color _colorFromHex(String hex) {
  final clean = hex.replaceAll('#', '');
  return Color(int.parse('FF$clean', radix: 16));
}
