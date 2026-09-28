import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class ChartPoint {
  const ChartPoint({required this.label, required this.fullDate, required this.value});
  final String label; // eje x corto, ej. "21 sep"
  final String fullDate; // iso yyyy-MM-dd
  final double value;
}

/// Gráfico de línea de evolución (peso, reps, tiempo, peso corporal).
/// Una sola línea, relleno degradado hacia abajo, punto final destacado,
/// y un caption que muestra el punto tocado o, por defecto, el último.
///
/// Nota para quien depure esto en Android Studio: la API de fl_chart ha
/// tenido pequeños cambios entre versiones 0.6x (ej. nombres de
/// parámetros de tooltip). Si `flutter pub get` resuelve una versión con
/// firmas distintas a las usadas acá, el propio analizador de Dart marca
/// exactamente la línea a ajustar.
class EvolutionLineChart extends StatefulWidget {
  const EvolutionLineChart({super.key, required this.points, required this.unit});
  final List<ChartPoint> points;
  final String unit;

  @override
  State<EvolutionLineChart> createState() => _EvolutionLineChartState();
}

class _EvolutionLineChartState extends State<EvolutionLineChart> {
  int? _activeIndex;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    final points = widget.points;

    if (points.length < 2) {
      return Text(
        'Necesitas al menos 2 registros para ver la evolución.',
        style: TextStyle(color: c.textMuted, fontSize: 11.5),
      );
    }

    final spots = [for (var i = 0; i < points.length; i++) FlSpot(i.toDouble(), points[i].value)];
    final minY = points.map((p) => p.value).reduce((a, b) => a < b ? a : b);
    final maxY = points.map((p) => p.value).reduce((a, b) => a > b ? a : b);
    final span = (maxY - minY).abs();
    final pad = span == 0 ? 1.0 : span * 0.15;
    final lowY = minY - pad;
    final highY = maxY + pad;

    final shownIndex = (_activeIndex ?? points.length - 1).clamp(0, points.length - 1);
    final shown = points[shownIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 130,
          child: LineChart(
            LineChartData(
              minY: lowY,
              maxY: highY,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: (highY - lowY) / 2,
                getDrawingHorizontalLine: (_) => FlLine(color: c.chartGrid, strokeWidth: 1),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border(bottom: BorderSide(color: c.chartAxis, width: 1)),
              ),
              titlesData: const FlTitlesData(show: false),
              lineTouchData: LineTouchData(
                touchCallback: (event, response) {
                  if (!event.isInterestedForInteractions) return;
                  final spot = response?.lineBarSpots?.first;
                  if (spot == null) return;
                  setState(() => _activeIndex = spot.x.round());
                },
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: false,
                  color: c.chartLine,
                  barWidth: 2,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, bar, index) {
                      final isLast = index == points.length - 1;
                      return FlDotCirclePainter(
                        radius: isLast ? 5 : 3.4,
                        color: c.chartLine,
                        strokeWidth: isLast ? 2 : 0,
                        strokeColor: c.screenBg,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [c.chartFillTop, c.chartFillBottom],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text('${shown.label}  ·  ${_fmt(shown.value)} ${widget.unit}', style: TextStyle(color: c.textMuted, fontSize: 11)),
      ],
    );
  }

  String _fmt(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
}
