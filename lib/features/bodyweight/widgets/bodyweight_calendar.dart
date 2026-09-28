import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/bodyweight_entry.dart';

/// Calendario de un mes con el día resaltado donde hay un registro de
/// peso. Tocar uno de esos días lo selecciona y muestra abajo el peso
/// de ese día con un botón para eliminar el registro (reutiliza el
/// diálogo de confirmación de la pantalla — acá solo se dispara
/// [onDelete] con la entrada elegida). Navegable como el calendario de
/// Inicio, no hacia meses futuros.
class BodyWeightCalendar extends StatefulWidget {
  const BodyWeightCalendar({super.key, required this.entriesByDate, required this.onDelete});

  final Map<String, BodyWeightEntry> entriesByDate;
  final void Function(BodyWeightEntry entry) onDelete;

  @override
  State<BodyWeightCalendar> createState() => _BodyWeightCalendarState();
}

class _BodyWeightCalendarState extends State<BodyWeightCalendar> {
  late int _year;
  late int _month;
  String? _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
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

  void _selectDay(String iso) {
    setState(() => _selectedDate = _selectedDate == iso ? null : iso);
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    final firstOfMonth = DateTime(_year, _month, 1);
    final daysInMonth = DateTime(_year, _month + 1, 0).day;
    final leadingEmpty = (firstOfMonth.weekday - 1) % 7; // semana empieza lunes
    final today = todayIso();

    // Si el registro seleccionado se borró (o cambiamos de mes), no
    // queda un panel de detalle mostrando algo que ya no existe.
    final selectedEntry = _selectedDate != null ? widget.entriesByDate[_selectedDate] : null;

    final cells = <Widget>[];
    for (final d in const ['L', 'M', 'M', 'J', 'V', 'S', 'D']) {
      cells.add(Center(child: Text(d, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: c.textMuted))));
    }
    for (var i = 0; i < leadingEmpty; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (var day = 1; day <= daysInMonth; day++) {
      final iso = isoDate(DateTime(_year, _month, day));
      final hasEntry = widget.entriesByDate.containsKey(iso);
      cells.add(_WeightDayCell(
        day: day,
        isToday: iso == today,
        hasEntry: hasEntry,
        isSelected: iso == _selectedDate,
        colors: c,
        onTap: hasEntry ? () => _selectDay(iso) : null,
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
        if (selectedEntry != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${formatShort(selectedEntry.date)} · ${selectedEntry.kg} kg',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.textPrimary),
                ),
                TextButton.icon(
                  onPressed: () => widget.onDelete(selectedEntry),
                  style: TextButton.styleFrom(foregroundColor: c.critical, padding: const EdgeInsets.symmetric(horizontal: 8)),
                  icon: const Icon(Icons.delete_outline, size: 17),
                  label: const Text('Eliminar'),
                ),
              ],
            ),
          ),
        ],
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

class _WeightDayCell extends StatelessWidget {
  const _WeightDayCell({
    required this.day,
    required this.isToday,
    required this.hasEntry,
    required this.isSelected,
    required this.colors,
    this.onTap,
  });
  final int day;
  final bool isToday;
  final bool hasEntry;
  final bool isSelected;
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
            color: isSelected ? c.accentSoft : (hasEntry ? c.accentSoft.withValues(alpha: 0.5) : c.surface2),
            borderRadius: BorderRadius.circular(9),
            border: isToday
                ? Border.all(color: c.accent, width: 2)
                : (isSelected ? Border.all(color: c.accent, width: 1.4) : null),
          ),
          alignment: Alignment.center,
          child: Text(
            '$day',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: hasEntry ? FontWeight.w700 : FontWeight.w600,
              color: hasEntry ? c.accentInk : (isToday ? c.textPrimary : c.textSecondary),
            ),
          ),
        ),
      ),
    );
  }
}
