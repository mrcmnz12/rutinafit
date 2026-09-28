import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/domain/formatters.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/exercise.dart';
import '../../providers/exercise_log_provider.dart';
import '../../providers/exercise_provider.dart';
import '../../shared/widgets/empty_note.dart';
import '../../shared/widgets/exercise_thumb.dart';
import '../../data/models/exercise_log.dart';
import 'add_exercise_screen.dart';
import 'exercise_detail_screen.dart';

/// Catálogo completo de ejercicios. Tocar uno abre su pantalla de
/// detalle en modo edición (sin dayKey): ahí se editan series/reps/
/// descanso, imágenes y video — el único lugar de la app que lo hace.
class ExercisesListScreen extends StatefulWidget {
  const ExercisesListScreen({super.key});

  @override
  State<ExercisesListScreen> createState() => _ExercisesListScreenState();
}

class _ExercisesListScreenState extends State<ExercisesListScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exercises = context.watch<ExerciseProvider>();
    final logProvider = context.watch<ExerciseLogProvider>();
    final colors = Theme.of(context).extension<AppColors>()!;

    if (exercises.loading && exercises.all.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final q = _query.trim().toLowerCase();
    final list = q.isEmpty
        ? exercises.all
        : exercises.all
            .where((e) => e.name.toLowerCase().contains(q) || e.muscleGroup.toLowerCase().contains(q))
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ejercicios'),
        actions: [
          IconButton(
            tooltip: 'Nuevo ejercicio',
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AddExerciseScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o grupo muscular',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: colors.surface1,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: colors.border)),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
              ),
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: EmptyNote('No se encontraron ejercicios', centered: true),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) => _ExerciseRow(
                      exercise: list[index],
                      lastLog: logProvider.lastFor(list[index].id),
                      colors: colors,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({required this.exercise, required this.lastLog, required this.colors});
  final Exercise exercise;
  final ExerciseLogEntry? lastLog;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colors.surface1,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ExerciseDetailScreen(exerciseId: exercise.id)),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.border)),
          child: Row(
            children: [
              SizedBox(width: 64, height: 64, child: ExerciseThumb(exercise: exercise, height: 64, borderRadius: 12)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(exercise.name, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: colors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(exerciseSetsRepsLabel(exercise), style: TextStyle(fontSize: 12, color: colors.textSecondary)),
                    const SizedBox(height: 2),
                    Text(
                      exerciseSummaryText(exercise, lastLog),
                      style: TextStyle(fontSize: 11.5, color: colors.accent, fontWeight: FontWeight.w600),
                    ),
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
