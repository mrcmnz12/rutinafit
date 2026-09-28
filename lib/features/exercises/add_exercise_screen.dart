import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/exercise.dart';
import '../../providers/exercise_provider.dart';
import '../../shared/widgets/section_card.dart';

/// Grupos musculares que la app ya sabe colorear (ver
/// `AppColors.forMuscleGroup`). Un ejercicio nuevo debe usar uno de
/// estos para que su miniatura y sus chips se vean consistentes con el
/// resto del catálogo.
const List<String> kMuscleGroups = ['Pecho', 'Espalda', 'Hombro', 'Brazos', 'Piernas', 'Pantorrilla', 'Core'];

/// Formulario para agregar un ejercicio nuevo al catálogo. Al guardar
/// queda disponible de inmediato para agregarlo a cualquier día de
/// rutina — usa el mismo `ExerciseProvider`/tabla que los ejercicios del
/// seed, así que no hace falta ningún paso extra.
class AddExerciseScreen extends StatefulWidget {
  const AddExerciseScreen({super.key});

  @override
  State<AddExerciseScreen> createState() => _AddExerciseScreenState();
}

class _AddExerciseScreenState extends State<AddExerciseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _setsLabelCtrl = TextEditingController(text: '3');
  final _repLowCtrl = TextEditingController();
  final _repHighCtrl = TextEditingController();
  final _restLabelCtrl = TextEditingController(text: '60 s');
  final _suffixCtrl = TextEditingController();

  String _muscleGroup = kMuscleGroups.first;
  MeasureType _measureType = MeasureType.repsWeight;
  bool _isBodyweight = false;
  bool _hasPainNote = false;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _setsLabelCtrl.dispose();
    _repLowCtrl.dispose();
    _repHighCtrl.dispose();
    _restLabelCtrl.dispose();
    _suffixCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final ex = await context.read<ExerciseProvider>().addExercise(
            name: _nameCtrl.text.trim(),
            muscleGroup: _muscleGroup,
            measureType: _measureType,
            setsLabel: _setsLabelCtrl.text.trim(),
            repLow: int.tryParse(_repLowCtrl.text.trim()) ?? 0,
            repHigh: int.tryParse(_repHighCtrl.text.trim()) ?? int.tryParse(_repLowCtrl.text.trim()) ?? 0,
            restLabel: _restLabelCtrl.text.trim(),
            isBodyweight: _measureType == MeasureType.repsWeight && _isBodyweight,
            suffix: _suffixCtrl.text.trim(),
            hasPainNote: _hasPainNote,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${ex.name} agregado al catálogo')));
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Suma/resta 1 al valor entero del controlador (mínimo 0) — botones
  /// -/+ junto al teclado para los campos de reps/segundos mín-máx.
  void _stepCtrl(TextEditingController ctrl, int delta) {
    final current = int.tryParse(ctrl.text.trim()) ?? 0;
    final next = (current + delta).clamp(0, 999999);
    setState(() => ctrl.text = next.toString());
  }

  Widget _stepButton(IconData icon, VoidCallback onTap) {
    return IconButton(icon: Icon(icon, size: 18), splashRadius: 18, onPressed: onTap);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final isTime = _measureType == MeasureType.time;

    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo ejercicio')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SectionCard(
              title: 'Datos básicos',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nombre', isDense: true, border: OutlineInputBorder()),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Obligatorio' : null,
                  ),
                  const SizedBox(height: 12),
                  Text('Grupo muscular', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: colors.textMuted, letterSpacing: 0.3)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: kMuscleGroups.map((g) {
                      final selected = g == _muscleGroup;
                      return ChoiceChip(
                        label: Text(g),
                        selected: selected,
                        onSelected: (_) => setState(() => _muscleGroup = g),
                        selectedColor: colors.accentSoft,
                        backgroundColor: colors.surface2,
                        labelStyle: TextStyle(color: selected ? colors.accent : colors.textSecondary, fontWeight: FontWeight.w600, fontSize: 12),
                        side: BorderSide(color: selected ? colors.accent : colors.border),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  Text('Tipo de medición', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: colors.textMuted, letterSpacing: 0.3)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: _ToggleButton(
                          label: 'Peso y reps',
                          selected: !isTime,
                          colors: colors,
                          onTap: () => setState(() => _measureType = MeasureType.repsWeight),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ToggleButton(
                          label: 'Tiempo',
                          selected: isTime,
                          colors: colors,
                          onTap: () => setState(() => _measureType = MeasureType.time),
                        ),
                      ),
                    ],
                  ),
                  if (!isTime) ...[
                    const SizedBox(height: 10),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _isBodyweight,
                      onChanged: (v) => setState(() => _isBodyweight = v),
                      title: Text('Peso corporal (sin carga externa)', style: TextStyle(fontSize: 12.5, color: colors.textPrimary)),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            SectionCard(
              title: 'Series y descanso',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _setsLabelCtrl,
                    decoration: const InputDecoration(labelText: 'Series (ej. "3" o "3–4")', isDense: true, border: OutlineInputBorder()),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Obligatorio' : null,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _repLowCtrl,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            labelText: isTime ? 'Seg. mín' : 'Reps mín',
                            isDense: true,
                            border: const OutlineInputBorder(),
                            prefixIcon: _stepButton(Icons.remove, () => _stepCtrl(_repLowCtrl, -1)),
                            suffixIcon: _stepButton(Icons.add, () => _stepCtrl(_repLowCtrl, 1)),
                          ),
                          validator: (v) => (v == null || int.tryParse(v.trim()) == null) ? 'Número' : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _repHighCtrl,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            labelText: isTime ? 'Seg. máx' : 'Reps máx',
                            isDense: true,
                            border: const OutlineInputBorder(),
                            prefixIcon: _stepButton(Icons.remove, () => _stepCtrl(_repHighCtrl, -1)),
                            suffixIcon: _stepButton(Icons.add, () => _stepCtrl(_repHighCtrl, 1)),
                          ),
                          validator: (v) => (v == null || int.tryParse(v.trim()) == null) ? 'Número' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _restLabelCtrl,
                    decoration: const InputDecoration(labelText: 'Descanso (ej. "90 s")', isDense: true, border: OutlineInputBorder()),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Obligatorio' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _suffixCtrl,
                    decoration: const InputDecoration(labelText: 'Sufijo opcional (ej. "/lado")', isDense: true, border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 6),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _hasPainNote,
                    onChanged: (v) => setState(() => _hasPainNote = v),
                    title: Text('Mostrar nota de tendones', style: TextStyle(fontSize: 12.5, color: colors.textPrimary)),
                    subtitle: Text('Aviso para priorizar reps limpias con menos peso', style: TextStyle(fontSize: 11, color: colors.textMuted)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Guardando...' : 'Guardar ejercicio'),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Las imágenes y el video se agregan después, desde la edición del ejercicio ya guardado.',
              style: TextStyle(fontSize: 11, color: colors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  const _ToggleButton({required this.label, required this.selected, required this.colors, required this.onTap});
  final String label;
  final bool selected;
  final AppColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? colors.accentSoft : colors.surface1,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? colors.accent : colors.borderStrong, width: 1.5),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: selected ? colors.accent : colors.textSecondary),
        ),
      ),
    );
  }
}
