import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/bodyweight_entry.dart';
import '../../providers/bodyweight_provider.dart';
import '../../shared/widgets/empty_note.dart';
import '../../shared/widgets/line_chart.dart';
import '../../shared/widgets/number_stepper_field.dart';
import '../../shared/widgets/section_card.dart';
import '../../shared/widgets/stat_tile.dart';
import 'widgets/bodyweight_calendar.dart';

/// Pantalla de peso corporal: registrar el peso de hoy y ver su
/// evolución en el tiempo.
class BodyWeightScreen extends StatefulWidget {
  const BodyWeightScreen({super.key});

  @override
  State<BodyWeightScreen> createState() => _BodyWeightScreenState();
}

class _BodyWeightScreenState extends State<BodyWeightScreen> {
  final _weightCtrl = TextEditingController();

  @override
  void dispose() {
    _weightCtrl.dispose();
    super.dispose();
  }

  Future<void> _save(BodyWeightProvider provider) async {
    final kg = double.tryParse(_weightCtrl.text.trim().replaceAll(',', '.'));
    if (kg == null || kg <= 0) return;
    await provider.logToday(todayIso(), kg);
    _weightCtrl.clear();
    if (mounted) FocusScope.of(context).unfocus();
  }

  Future<void> _confirmDelete(BodyWeightProvider provider, BodyWeightEntry entry) async {
    final colors = Theme.of(context).extension<AppColors>()!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar registro de peso'),
        content: Text(
          'Se va a borrar el registro de ${formatShort(entry.date)} (${entry.kg} kg). Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('Eliminar', style: TextStyle(color: colors.critical, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await provider.deleteEntry(entry.date);
  }

  @override
  Widget build(BuildContext context) {
    final bodyWeight = context.watch<BodyWeightProvider>();
    final colors = Theme.of(context).extension<AppColors>()!;

    if (bodyWeight.loading && bodyWeight.all.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final last = bodyWeight.last;
    final first = bodyWeight.first;
    final delta = (last != null && first != null && bodyWeight.all.length > 1) ? last.kg - first.kg : null;
    final loggedToday = last?.date == todayIso();

    final points = [
      for (final e in bodyWeight.all) ChartPoint(label: formatShort(e.date), fullDate: e.date, value: e.kg),
    ];
    final entriesByDate = {for (final e in bodyWeight.all) e.date: e};

    return Scaffold(
      appBar: AppBar(title: const Text('Peso corporal')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(child: StatTile(value: last != null ? '${last.kg} kg' : '—', label: 'Peso actual')),
              const SizedBox(width: 10),
              Expanded(
                child: StatTile(
                  value: delta == null ? '—' : '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)} kg',
                  label: 'Desde el primer registro',
                  valueColor: delta == null
                      ? null
                      : (delta > 0 ? colors.warning : (delta < 0 ? colors.good : colors.textPrimary)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SectionCard(
            title: 'Registrar peso de hoy',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (loggedToday) ...[
                  Text('Ya registraste tu peso hoy (${last!.kg} kg). Guardar de nuevo lo reemplaza.',
                      style: TextStyle(fontSize: 11.5, color: colors.textMuted)),
                  const SizedBox(height: 8),
                ],
                Row(
                  children: [
                    Expanded(
                      child: NumberStepperField(
                        label: 'Peso (kg)',
                        controller: _weightCtrl,
                        step: 0.5,
                        min: 0,
                        decimal: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(onPressed: () => _save(bodyWeight), child: const Text('Guardar')),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SectionCard(
            title: 'Evolución',
            child: points.isEmpty
                ? const EmptyNote('Aún no hay registros de peso.')
                : EvolutionLineChart(points: points, unit: 'kg'),
          ),
          if (bodyWeight.all.isNotEmpty) ...[
            const SizedBox(height: 14),
            SectionCard(
              title: 'Calendario',
              trailing: Text('toca un día registrado', style: TextStyle(fontSize: 11, color: colors.textMuted)),
              child: BodyWeightCalendar(
                entriesByDate: entriesByDate,
                onDelete: (entry) => _confirmDelete(bodyWeight, entry),
              ),
            ),
          ],
          if (bodyWeight.all.isNotEmpty) ...[
            const SizedBox(height: 14),
            SectionCard(
              title: 'Historial',
              child: Column(
                children: [
                  for (final e in bodyWeight.all.reversed.take(20))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(formatShort(e.date), style: TextStyle(fontSize: 12.5, color: colors.textSecondary)),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('${e.kg} kg', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: colors.textPrimary)),
                              const SizedBox(width: 4),
                              InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () => _confirmDelete(bodyWeight, e),
                                child: Padding(
                                  padding: const EdgeInsets.all(6),
                                  child: Icon(Icons.delete_outline, size: 17, color: colors.textMuted),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
