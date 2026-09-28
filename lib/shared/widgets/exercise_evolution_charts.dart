import 'package:flutter/material.dart';

import '../../core/utils/date_utils.dart';
import '../../data/models/exercise.dart';
import '../../data/models/exercise_log.dart';
import 'line_chart.dart';
import 'section_card.dart';

/// Puntos para el gráfico principal: peso (o reps si es de peso corporal) o
/// tiempo, según el tipo de medición del ejercicio.
List<ChartPoint> mainChartPoints(Exercise ex, List<ExerciseLogEntry> logs) {
  final points = <ChartPoint>[];
  for (final l in logs) {
    double? value;
    if (ex.measureType == MeasureType.time) {
      value = l.seconds?.toDouble();
    } else if (ex.isBodyweight) {
      value = l.reps?.toDouble();
    } else {
      value = l.weightKg;
    }
    if (value == null) continue;
    points.add(ChartPoint(label: formatShort(l.date), fullDate: l.date, value: value));
  }
  return points;
}

/// Puntos de evolución de repeticiones (no aplica a ejercicios de tiempo).
List<ChartPoint> repsChartPoints(List<ExerciseLogEntry> logs) {
  final points = <ChartPoint>[];
  for (final l in logs) {
    if (l.reps == null) continue;
    points.add(ChartPoint(label: formatShort(l.date), fullDate: l.date, value: l.reps!.toDouble()));
  }
  return points;
}

/// Puntos de evolución de series hechas.
List<ChartPoint> setsChartPoints(List<ExerciseLogEntry> logs) {
  final points = <ChartPoint>[];
  for (final l in logs) {
    if (l.setsDone == null) continue;
    points.add(ChartPoint(label: formatShort(l.date), fullDate: l.date, value: l.setsDone!.toDouble()));
  }
  return points;
}

/// Los gráficos de evolución de un ejercicio (peso/tiempo, repeticiones y
/// series), cada uno en su propia `SectionCard`. Se usa tanto en el detalle
/// del ejercicio como, dentro de un desplegable, en el registro diario — así
/// ambas pantallas muestran exactamente los mismos gráficos.
class ExerciseEvolutionCharts extends StatelessWidget {
  const ExerciseEvolutionCharts({super.key, required this.exercise, required this.logs});
  final Exercise exercise;
  final List<ExerciseLogEntry> logs;

  @override
  Widget build(BuildContext context) {
    final showRepsChart = exercise.measureType != MeasureType.time && !exercise.isBodyweight;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SectionCard(
          title: exercise.measureType == MeasureType.time ? 'Evolución de tiempo' : 'Evolución de peso',
          child: EvolutionLineChart(
            points: mainChartPoints(exercise, logs),
            unit: exercise.measureType == MeasureType.time ? 's' : (exercise.isBodyweight ? 'reps' : 'kg'),
          ),
        ),
        if (showRepsChart) ...[
          const SizedBox(height: 14),
          SectionCard(
            title: 'Evolución de repeticiones',
            child: EvolutionLineChart(points: repsChartPoints(logs), unit: 'reps'),
          ),
        ],
        const SizedBox(height: 14),
        SectionCard(
          title: 'Evolución de series',
          child: EvolutionLineChart(points: setsChartPoints(logs), unit: 'series'),
        ),
      ],
    );
  }
}
