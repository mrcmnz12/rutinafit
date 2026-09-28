import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/domain/formatters.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/exercise.dart';
import '../../providers/exercise_log_provider.dart';
import '../../providers/exercise_provider.dart';
import '../../providers/routine_provider.dart';
import '../../data/models/exercise_log.dart';
import '../../providers/session_provider.dart';
import '../../shared/widgets/exercise_thumb.dart';
import '../../shared/widgets/two_column_layout.dart';
import '../exercises/exercise_detail_screen.dart';
import 'pick_extra_exercise_screen.dart';

/// Pantalla de un día de rutina: único lugar donde se registra "lo hecho
/// hoy" por ejercicio. Al completar todos los ejercicios del día marca la
/// sesión como hecha automáticamente (igual que la maqueta).
class RoutineDayScreen extends StatefulWidget {
  const RoutineDayScreen({super.key, required this.dayKey});
  final String dayKey;

  @override
  State<RoutineDayScreen> createState() => _RoutineDayScreenState();
}

class _RoutineDayScreenState extends State<RoutineDayScreen> {
  final Map<String, bool> _done = {};
  // Ejercicios extra agregados solo a la sesión de hoy (no a la rutina
  // configurada). _pendingExtraIds son los recién elegidos que todavía no
  // tienen ningún registro guardado hoy; _loggedExtraIds se recalcula desde
  // la base de datos cada vez que se recarga, así que sobrevive a que se
  // cierre y reabra la pantalla (o la app) sin necesitar guardar nada aparte.
  final List<String> _pendingExtraIds = [];
  List<String> _loggedExtraIds = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDoneStatus());
  }

  Future<void> _loadDoneStatus() async {
    if (!mounted) return;
    setState(() => _loading = true);

    final routines = context.read<RoutineProvider>();
    final logProvider = context.read<ExerciseLogProvider>();
    final sessions = context.read<SessionProvider>();

    final day = routines.dayOf(widget.dayKey);
    if (day == null) {
      setState(() => _loading = false);
      return;
    }

    final today = todayIso();
    // Cualquier registro de hoy para un ejercicio que no es parte de este
    // día de rutina es un "extra" — así no hace falta guardar por separado
    // qué se agregó, se deduce de lo ya registrado.
    final todayEntries = await logProvider.getForDate(today);
    final loggedExtraIds = todayEntries.map((e) => e.exerciseId).where((id) => !day.exerciseIds.contains(id)).toSet().toList();

    final allIds = {...day.exerciseIds, ...loggedExtraIds, ..._pendingExtraIds};
    await Future.wait(allIds.map((id) => logProvider.loadFor(id)));

    if (!mounted) return;
    final doneMap = <String, bool>{};
    for (final id in allIds) {
      doneMap[id] = logProvider.lastFor(id)?.date == today;
    }

    setState(() {
      _done
        ..clear()
        ..addAll(doneMap);
      _loggedExtraIds = loggedExtraIds;
      // Ya tiene registro hoy -> pasa a "logueado", para no duplicar tarjeta.
      _pendingExtraIds.removeWhere(loggedExtraIds.contains);
      _loading = false;
    });

    await _maybeAutoComplete(day.exerciseIds, sessions, today);
  }

  Future<void> _maybeAutoComplete(List<String> configuredIds, SessionProvider sessions, String today) async {
    if (configuredIds.isEmpty) return;
    final allDone = configuredIds.every((id) => _done[id] == true);
    if (allDone && !sessions.hasRoutineSessionOn(today)) {
      await sessions.registerRoutineSession(today, widget.dayKey);
    }
  }

  Future<void> _addExtraExercise(List<String> configuredIds) async {
    final excludeIds = <String>{...configuredIds, ..._loggedExtraIds, ..._pendingExtraIds};
    final picked = await Navigator.of(context).push<Exercise>(
      MaterialPageRoute(builder: (_) => PickExtraExerciseScreen(excludeIds: excludeIds)),
    );
    if (picked == null || !mounted) return;
    setState(() => _pendingExtraIds.add(picked.id));
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ExerciseDetailScreen(exerciseId: picked.id, dayKey: widget.dayKey)),
    );
    await _loadDoneStatus();
  }

  @override
  Widget build(BuildContext context) {
    final routines = context.watch<RoutineProvider>();
    final sessions = context.watch<SessionProvider>();
    final exercises = context.watch<ExerciseProvider>();
    final logProvider = context.watch<ExerciseLogProvider>();
    final colors = Theme.of(context).extension<AppColors>()!;

    final day = routines.dayOf(widget.dayKey);
    if (day == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final today = todayIso();
    final sessionToday = sessions.hasRoutineSessionOn(today);
    final configuredDone = day.exerciseIds.isNotEmpty && day.exerciseIds.every((id) => _done[id] == true);

    final pending = day.exerciseIds.where((id) => _done[id] != true).toList();
    final finished = day.exerciseIds.where((id) => _done[id] == true).toList();
    final ordered = [...pending, ...finished];
    final extraIds = {..._loggedExtraIds, ..._pendingExtraIds}.toList();

    return Scaffold(
      appBar: AppBar(title: Text(day.name)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDoneStatus,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(day.objective, style: TextStyle(fontSize: 13, color: colors.textSecondary)),
                  if (day.warmup.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.surface2,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: colors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Calentamiento', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colors.textMuted)),
                          const SizedBox(height: 4),
                          Text(day.warmup, style: TextStyle(fontSize: 13, color: colors.textPrimary)),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  if (configuredDone)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colors.goodBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: colors.goodText),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '¡Rutina completada hoy!',
                              style: TextStyle(color: colors.goodText, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (!sessionToday)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () async {
                          await sessions.registerRoutineSession(today, widget.dayKey);
                          if (mounted) setState(() {});
                        },
                        child: const Text('Marcar rutina de hoy como hecha'),
                      ),
                    ),
                  const SizedBox(height: 16),
                  TwoColumnLayout(
                    spacing: 12,
                    runSpacing: 12,
                    children: ordered.map((id) {
                      final ex = exercises.byId(id);
                      if (ex == null) return const SizedBox.shrink();
                      final isDone = _done[id] == true;
                      return _ExerciseCard(
                        exercise: ex,
                        isDone: isDone,
                        lastLog: logProvider.lastFor(id),
                        colors: colors,
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ExerciseDetailScreen(exerciseId: id, dayKey: widget.dayKey),
                            ),
                          );
                          await _loadDoneStatus();
                        },
                      );
                    }).toList(),
                  ),
                  if (extraIds.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text('Agregado hoy', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(
                      'Ejercicios extra hechos solo en la sesión de hoy — no forman parte de la rutina configurada.',
                      style: TextStyle(fontSize: 11, color: colors.textMuted),
                    ),
                    const SizedBox(height: 10),
                    TwoColumnLayout(
                      spacing: 12,
                      runSpacing: 12,
                      children: extraIds.map((id) {
                        final ex = exercises.byId(id);
                        if (ex == null) return const SizedBox.shrink();
                        final isDone = _done[id] == true;
                        return _ExerciseCard(
                          exercise: ex,
                          isDone: isDone,
                          lastLog: logProvider.lastFor(id),
                          colors: colors,
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ExerciseDetailScreen(exerciseId: id, dayKey: widget.dayKey),
                              ),
                            );
                            await _loadDoneStatus();
                          },
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _addExtraExercise(day.exerciseIds),
                      icon: const Icon(Icons.add),
                      label: const Text('Agregar ejercicio de hoy'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    required this.exercise,
    required this.isDone,
    required this.lastLog,
    required this.colors,
    required this.onTap,
  });

  final Exercise exercise;
  final bool isDone;
  final ExerciseLogEntry? lastLog;
  final AppColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colors.surface1,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border),
          ),
          // La miniatura va a sangre (sin padding), igual que `.ex-thumb`
          // dentro de `.ex-card` en la maqueta; solo el texto lleva padding
          // propio. Antes el padding envolvia todo y, sumado a una relacion
          // de aspecto forzada en el grid, dejaba las tarjetas con espacio
          // vacio de sobra (mas grandes de lo necesario).
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    // AspectRatio (no LayoutBuilder): soporta dimensiones
                    // intrinsecas, necesario porque esta tarjeta vive dentro
                    // de un IntrinsicHeight (TwoColumnLayout).
                    child: AspectRatio(
                      aspectRatio: 4 / 3, // igual que `.ex-thumb` en la maqueta
                      child: Opacity(
                        opacity: isDone ? 0.58 : 1.0,
                        child: ExerciseThumb(exercise: exercise, height: null, borderRadius: 0),
                      ),
                    ),
                  ),
                  if (isDone)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(color: colors.good, shape: BoxShape.circle),
                        child: const Icon(Icons.check, color: Colors.white, size: 15),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(9, 8, 9, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      exercise.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: colors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      exerciseSetsRepsLabel(exercise),
                      style: TextStyle(fontSize: 10.5, color: colors.textSecondary),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      exerciseSummaryText(exercise, lastLog),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 10.5, color: colors.accent, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
