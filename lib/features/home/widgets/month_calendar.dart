import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart';

/// Qué se registró un día puntual — puede haber gym y actividad el
/// mismo día, así que son dos flags independientes (no una sola
/// etiqueta como antes).
class CalendarDayMarks {
  const CalendarDayMarks({this.gym = false, this.activity = false});
  final bool gym;
  final bool activity;

  bool get hasAny => gym || activity;
}

/// Grilla de un mes con hasta 2 puntos de color en los días registrados
/// (uno por gym, otro por actividad). Tocar un día con algo registrado
/// dispara [onDayTap]; los demás días no son interactivos.
///
/// Navegable: arranca en [initialYear]/[initialMonth] (o el mes actual
/// si no se pasan) y trae flechas para moverse a meses anteriores —
/// `marksByDate` ya trae el historial completo (lo arma quien llama a
/// este widget a partir de todas las sesiones), así que cambiar de mes
/// acá adentro no necesita volver a cargar nada. No se puede navegar a
/// meses futuros al de hoy.
class MonthCalendar extends StatefulWidget {
  const MonthCalendar({
    super.key,
    this.initialYear,
    this.initialMonth,
    required this.marksByDate,
    required this.onDayTap,
  });

  final int? initialYear;
  final int? initialMonth; // 1-12
  final Map<String, CalendarDayMarks> marksByDate;
  final void Function(String iso) onDayTap;

  @override
  State<MonthCalendar> createState() => _MonthCalendarState();
}

class _MonthCalendarState extends State<MonthCalendar> {
  late int _year;
  late int _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = widget.initialYear ?? now.year;
    _month = widget.initialMonth ?? now.month;
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _year == now.year && _month == now.month;
  }

  void _goTo(int deltaMonths) {
    setState(() {
      final total = (_year * 12 + (_month - 1)) + deltaMonths;
      _year = total ~/ 12;
      _month = (total % 12) + 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    final firstOfMonth = DateTime(_year, _month, 1);
    final daysInMonth = DateTime(_year, _month + 1, 0).day;
    final leadingEmpty = (firstOfMonth.weekday - 1) % 7; // semana empieza lunes
    final today = todayIso();

    final cells = <Widget>[];
    for (final d in const ['L', 'M', 'M', 'J', 'V', 'S', 'D']) {
      cells.add(Center(child: Text(d, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: c.textMuted))));
    }
    for (var i = 0; i < leadingEmpty; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (var day = 1; day <= daysInMonth; day++) {
      final iso = isoDate(DateTime(_year, _month, day));
      final marks = widget.marksByDate[iso] ?? const CalendarDayMarks();
      cells.add(_DayCell(
        day: day,
        isToday: iso == today,
        marks: marks,
        colors: c,
        onTap: marks.hasAny ? () => widget.onDayTap(iso) : null,
      ));
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _NavArrow(icon: Icons.chevron_left, colors: c, onTap: () => _goTo(-1)),
            Text(
              '${monthNameEs(_month)} $_year',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: c.textPrimary),
            ),
            _NavArrow(icon: Icons.chevron_right, colors: c, onTap: _isCurrentMonth ? null : () => _goTo(1)),
          ],
        ),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 5,
          crossAxisSpacing: 5,
          children: cells,
        ),
      ],
    );
  }
}

class _NavArrow extends StatelessWidget {
  const _NavArrow({required this.icon, required this.colors, this.onTap});
  final IconData icon;
  final AppColors colors;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 22, color: enabled ? colors.textSecondary : colors.textMuted.withValues(alpha: 0.35)),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.day, required this.isToday, required this.marks, required this.colors, this.onTap});
  final int day;
  final bool isToday;
  final CalendarDayMarks marks;
  final AppColors colors;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            color: c.surface2,
            borderRadius: BorderRadius.circular(9),
            border: isToday ? Border.all(color: c.accent, width: 2) : null,
          ),
          alignment: Alignment.center,
          // Numero y puntos en columna (no superpuestos): la franja de
          // puntos ocupa su propio espacio fijo debajo del numero en vez
          // de posicionarse encima con un Stack, que en celdas chicas
          // los hacia solaparse.
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$day', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: isToday ? c.textPrimary : c.textSecondary)),
              const SizedBox(height: 3),
              SizedBox(
                height: 5,
                child: !marks.hasAny
                    ? null
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (marks.gym) Container(width: 5, height: 5, decoration: BoxDecoration(color: c.dotTorso, shape: BoxShape.circle)),
                          if (marks.gym && marks.activity) const SizedBox(width: 3),
                          if (marks.activity) Container(width: 5, height: 5, decoration: BoxDecoration(color: c.dotPiernas, shape: BoxShape.circle)),
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
