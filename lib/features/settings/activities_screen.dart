import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/activity.dart';
import '../../providers/activity_provider.dart';
import '../../shared/widgets/empty_note.dart';
import '../../shared/widgets/number_stepper_field.dart';

/// Catálogo de actividades adicionales (fútbol, zumba, spinning, etc.):
/// agregar, editar (nombre, color, duración) y eliminar. Lo que se
/// asigna a cada día de la semana vive en "Editar rutinas" — acá solo
/// se mantiene el catálogo en sí.
class ActivitiesScreen extends StatelessWidget {
  const ActivitiesScreen({super.key});

  Future<void> _openForm(BuildContext context, {Activity? editing}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ActivityFormSheet(editing: editing),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Activity activity) async {
    final colors = Theme.of(context).extension<AppColors>()!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar actividad'),
        content: Text('Se va a quitar "${activity.name}" del catálogo y de cualquier día donde esté asignada. Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('Eliminar', style: TextStyle(color: colors.critical, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<ActivityProvider>().delete(activity.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activities = context.watch<ActivityProvider>();
    final colors = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo de actividades'),
        actions: [
          IconButton(
            tooltip: 'Nueva actividad',
            icon: const Icon(Icons.add),
            onPressed: () => _openForm(context),
          ),
        ],
      ),
      body: activities.loading && activities.all.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              children: [
                Text(
                  'Estas son las actividades que puedes asignar a un día de la semana desde "Editar rutinas".',
                  style: TextStyle(fontSize: 12, color: colors.textMuted),
                ),
                const SizedBox(height: 14),
                if (activities.all.isEmpty)
                  const EmptyNote('Todavía no hay actividades en el catálogo. Toca "+" para crear la primera.', centered: true)
                else
                  for (final a in activities.all)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: colors.surface1, borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.border)),
                        child: Row(
                          children: [
                            Container(width: 12, height: 12, decoration: BoxDecoration(color: _colorFromHex(a.color), shape: BoxShape.circle)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(a.name, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: colors.textPrimary)),
                                  const SizedBox(height: 2),
                                  Text('${a.durationMinutes} min por sesión', style: TextStyle(fontSize: 11.5, color: colors.textSecondary)),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Editar',
                              icon: Icon(Icons.edit_outlined, color: colors.accent, size: 20),
                              onPressed: () => _openForm(context, editing: a),
                            ),
                            IconButton(
                              tooltip: 'Eliminar',
                              icon: Icon(Icons.delete_outline, color: colors.critical, size: 20),
                              onPressed: () => _confirmDelete(context, a),
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
            ),
    );
  }
}

class _ActivityFormSheet extends StatefulWidget {
  const _ActivityFormSheet({this.editing});
  final Activity? editing;

  @override
  State<_ActivityFormSheet> createState() => _ActivityFormSheetState();
}

class _ActivityFormSheetState extends State<_ActivityFormSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _durationCtrl;
  late String _color;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final editing = widget.editing;
    _nameCtrl = TextEditingController(text: editing?.name ?? '');
    _durationCtrl = TextEditingController(text: '${editing?.durationMinutes ?? 45}');
    _color = editing?.color ?? kActivityColorOptions.first;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    final duration = int.tryParse(_durationCtrl.text.trim()) ?? 45;
    setState(() => _saving = true);
    final provider = context.read<ActivityProvider>();
    if (widget.editing != null) {
      await provider.update(widget.editing!.id, name: name, color: _color, durationMinutes: duration);
    } else {
      await provider.create(name: name, color: _color, durationMinutes: duration);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 20, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.editing != null ? 'Editar actividad' : 'Nueva actividad',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: colors.textPrimary),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            autofocus: widget.editing == null,
            decoration: const InputDecoration(labelText: 'Nombre', isDense: true, border: OutlineInputBorder()),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 16),
          Text('Color', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: colors.textMuted, letterSpacing: 0.3)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final c in kActivityColorOptions)
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => setState(() => _color = c),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: _colorFromHex(c),
                      shape: BoxShape.circle,
                      border: Border.all(color: c == _color ? colors.textPrimary : Colors.transparent, width: 2.5),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          NumberStepperField(label: 'Duración (min)', controller: _durationCtrl, step: 15, min: 5),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'Guardando...' : 'Guardar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Color _colorFromHex(String hex) {
  final clean = hex.replaceAll('#', '');
  return Color(int.parse('FF$clean', radix: 16));
}
