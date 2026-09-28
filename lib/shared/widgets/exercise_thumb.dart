import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/data/bundled_exercise_images.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/exercise.dart';
import 'group_chip.dart';

/// Miniatura de un ejercicio para tarjetas/listas: la primera imagen
/// cargada si existe, o un ícono de respaldo con el color del grupo
/// muscular — igual que `thumb()` en la maqueta.
class ExerciseThumb extends StatelessWidget {
  const ExerciseThumb({super.key, required this.exercise, this.height = 90, this.borderRadius = 16});
  final Exercise exercise;
  /// Alto fijo en dp. Si es `null`, el widget llena el espacio disponible
  /// (uso pensado para envolverlo en un `AspectRatio`, que sí es seguro
  /// dentro de layouts que piden dimensiones intrínsecas).
  final double? height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    final groupColor = c.forMuscleGroup(exercise.muscleGroup);
    final path = exercise.image1Path;
    // Sin foto propia del usuario, se usa la imagen de referencia
    // empaquetada con la app (si este ejercicio tiene una).
    final bundledPath = path == null ? bundledExerciseImagePath(exercise.id) : null;
    final iconSize = (height ?? 90) * 0.34;

    final content = Stack(
      children: [
        Positioned.fill(
          child: path != null
              ? Image.file(File(path), fit: BoxFit.cover)
              : bundledPath != null
                  ? Image.asset(bundledPath, fit: BoxFit.cover)
                  : Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [groupColor, Colors.black.withValues(alpha: 0.35)],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    exercise.measureType == MeasureType.time ? Icons.timer_outlined : Icons.fitness_center,
                    color: Colors.white.withValues(alpha: 0.9),
                    size: iconSize,
                  ),
                ),
        ),
        Positioned(top: 7, left: 7, child: GroupChip(label: exercise.muscleGroup)),
      ],
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: height != null ? SizedBox(width: double.infinity, height: height, child: content) : content,
    );
  }
}
