import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/domain/formatters.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/exercise.dart';
import '../../providers/exercise_provider.dart';
import '../../providers/routine_provider.dart';
import '../../shared/widgets/empty_note.dart';
import '../../shared/widgets/exercise_thumb.dart';
import '../../shared/widgets/section_card.dart';
import '../exercises/exercise_detail_screen.dart';

/// Edición de un día de rutina: nombre/objetivo y qué ejercicios
/// contiene. El botón "editar" de cada ejercicio lleva a la pantalla
/// única de edición (ExerciseDetailScreen sin dayKey) — no hay un
/// segundo formulario acá. Ya no existe "intercambiar día": ese
/// concepto asumía días de semana fijos, que dejaron de aplicar con la
/// rotación (ver RoutineProvider.reorderRotation, usado en
/// SettingsRoutinesScreen).
class RoutineDayEditScreen extends StatefulWidget {
  const RoutineDayEditScreen({super.key, required this.dayKey});
  final String dayKey;

  @override
  State<RoutineDayEditScreen> createState() => _RoutineDayEditScreenState();
}

class _RoutineDayEditScreenState extends State<RoutineDayEditScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _objectiveCtrl;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _objectiveCtrl = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  void _init() {
    final day = context.read<RoutineProvider>().dayOf(widget.dayKey);
    if (day == null) return;
    _nameCtrl.text = day.name;
    _objectiveCtrl.text = day.objective;
    setState(() => _initialized = true);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _objectiveCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveNameObjective() async {
    await context.read<RoutineProvider>().updateNameObjective(
          widget.dayKey,
          name: _nameCtrl.text.trim(),
          objective: _objectiveCtrl.text.trim(),
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Guardado')));
    }
  }

  Future<void> _pickExerciseToAdd(RoutineProvider routines, List<Exercise> candidates) async {
    final chosen = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final colors = Theme.of(context).extension<AppColors>()!;
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return ListView(
              controller: scrollController,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Agregar ejercicio', style: TextStyle(fontWeight: FontWeight.w700, color: colors.textPrimary)),
                ),
                if (candidates.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: EmptyNote('Todos los ejercicios ya están en este día', centered: true),
                  ),
                for (final ex in candidates)
                  ListTile(
                    leading: SizedBox(width: 44, height: 44, child: ExerciseThumb(exercise: ex, height: 44, borderRadius: 10)),
                    title: Text(ex.name),
                    subtitle: Text(exerciseSetsRepsLabel(ex)),
                    onTap: () => Navigator.of(context).pop(ex.id),
                  ),
              ],
            );
          },
        );
      },
    );
    if (chosen != null) {
      await routines.addExercise(widget.dayKey, chosen);
    }
  }

  @override
  Widget build(BuildContext context) {
    final routines = context.watch<RoutineProvider>();
    final exercises = context.watch<ExerciseProvider>();
    final colors = Theme.of(context).extension<AppColors>()!;

    final day = routines.dayOf(widget.dayKey);
    if (day == null || !_initialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final dayExercises = day.exerciseIds.map(exercises.byId).whereType<Exercise>().toList();
    final candidates = exercises.all.where((e) => !day.exerciseIds.contains(e.id)).toList();

    return Scaffold(
      appBar: AppBar(title: Text('Editar ${day.name}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            title: 'Nombre y objetivo',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Nombre', isDense: true, border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: _objectiveCtrl, decoration: const InputDecoration(labelText: 'Objetivo', isDense: true, border: OutlineInputBorder())),
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _saveNameObjective, child: const Text('Guardar'))),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (!day.isRest) ...[
            SectionCard(
              title: 'Ejercicios (${dayExercises.length})',
              trailing: TextButton.icon(
                onPressed: () => _pickExerciseToAdd(routines, candidates),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Agregar'),
              ),
              child: dayExercises.isEmpty
                  ? const EmptyNote('Este día todavía no tiene ejercicios')
                  : Column(
                      children: [
                        for (final ex in dayExercises)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Row(
                              children: [
                                SizedBox(width: 42, height: 42, child: ExerciseThumb(exercise: ex, height: 42, borderRadius: 10)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(ex.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.textPrimary)),
                                      Text(exerciseSetsRepsLabel(ex), style: TextStyle(fontSize: 11.5, color: colors.textSecondary)),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Editar',
                                  icon: Icon(Icons.edit_outlined, color: colors.accent, size: 20),
                                  onPressed: () => Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => ExerciseDetailScreen(exerciseId: ex.id)),
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Quitar de este día',
                                  icon: Icon(Icons.remove_circle_outline, color: colors.critical, size: 20),
                                  onPressed: () => routines.removeExercise(widget.dayKey, ex.id),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}
