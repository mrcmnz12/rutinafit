import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/data/bundled_exercise_images.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/exercise.dart';
import 'group_chip.dart';

/// Imagen principal de la pantalla de detalle de ejercicio. Con las 2
/// imágenes cargadas se divide en mitades verticales, cada una centrada
/// en su espacio; con una sola imagen se muestra completa; sin ninguna,
/// el ícono de respaldo por grupo muscular.
class HeroExerciseImage extends StatelessWidget {
  const HeroExerciseImage({super.key, required this.exercise});
  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    final groupColor = c.forMuscleGroup(exercise.muscleGroup);
    final img1 = exercise.image1Path;
    final img2 = exercise.image2Path;
    // Sin fotos propias del usuario, se usa la imagen de referencia
    // empaquetada con la app (si este ejercicio tiene una).
    final bundledPath = img1 == null ? bundledExerciseImagePath(exercise.id) : null;

    Widget body;
    if (img1 != null && img2 != null) {
      body = Row(
        children: [
          Expanded(child: Image.file(File(img1), fit: BoxFit.cover, height: double.infinity)),
          Expanded(child: Image.file(File(img2), fit: BoxFit.cover, height: double.infinity)),
        ],
      );
    } else if (img1 != null) {
      body = Image.file(File(img1), fit: BoxFit.cover, width: double.infinity, height: double.infinity);
    } else if (bundledPath != null) {
      body = Image.asset(bundledPath, fit: BoxFit.cover, width: double.infinity, height: double.infinity);
    } else {
      body = Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [groupColor, Colors.black.withValues(alpha: 0.35)]),
        ),
        alignment: Alignment.center,
        child: Icon(
          exercise.measureType == MeasureType.time ? Icons.timer_outlined : Icons.fitness_center,
          color: Colors.white.withValues(alpha: 0.9),
          size: 40,
        ),
      );
    }

    // Cuadrada y a todo el ancho disponible: antes tenía una altura fija
    // de 180 que, en imágenes verticales, recortaba demasiado la foto.
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 1,
        child: Stack(
          children: [
            Positioned.fill(child: body),
            Positioned(top: 7, left: 7, child: GroupChip(label: exercise.muscleGroup)),
          ],
        ),
      ),
    );
  }
}
