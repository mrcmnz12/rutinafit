import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/exercise.dart';
import '../../providers/exercise_provider.dart';
import '../../shared/widgets/empty_note.dart';
import '../../shared/widgets/exercise_thumb.dart';
import '../exercises/exercise_detail_screen.dart' show exerciseSetsLine;

/// Selector para agregar, solo por hoy, un ejercicio adicional a la rutina
/// que se está haciendo — sin modificar la rutina configurada, por si algún
/// día sobra tiempo y se quiere sumar algo extra. Devuelve el [Exercise]
/// elegido (o `null` si se cancela) vía `Navigator.pop`.
class PickExtraExerciseScreen extends StatefulWidget {
  const PickExtraExerciseScreen({super.key, required this.excludeIds});

  /// Ejercicios que no se muestran porque ya están en el día (configurados
  /// o ya agregados como extra hoy).
  final Set<String> excludeIds;

  @override
  State<PickExtraExerciseScreen> createState() => _PickExtraExerciseScreenState();
}

class _PickExtraExerciseScreenState extends State<PickExtraExerciseScreen> {
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
    final colors = Theme.of(context).extension<AppColors>()!;

    final q = _query.trim().toLowerCase();
    final list = exercises.all.where((e) => !widget.excludeIds.contains(e.id)).where((e) {
      if (q.isEmpty) return true;
      return e.name.toLowerCase().contains(q) || e.muscleGroup.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Agregar ejercicio de hoy')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
            child: Text(
              'Se agrega solo a lo hecho hoy — la rutina configurada no cambia.',
              style: TextStyle(fontSize: 11.5, color: colors.textMuted),
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: EmptyNote('No hay más ejercicios para agregar', centered: true),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final ex = list[index];
                      return Material(
                        color: colors.surface1,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => Navigator.of(context).pop(ex),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.border)),
                            child: Row(
                              children: [
                                SizedBox(width: 52, height: 52, child: ExerciseThumb(exercise: ex, height: 52, borderRadius: 12)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(ex.name, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: colors.textPrimary)),
                                      const SizedBox(height: 2),
                                      Text('${ex.muscleGroup} · ${exerciseSetsLine(ex)}', style: TextStyle(fontSize: 11.5, color: colors.textSecondary)),
                                    ],
                                  ),
                                ),
                                Icon(Icons.add_circle_outline, color: colors.accent),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
