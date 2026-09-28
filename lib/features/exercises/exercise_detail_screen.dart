import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/exercise.dart';
import '../../data/models/exercise_log.dart';
import '../../providers/exercise_log_provider.dart';
import '../../providers/exercise_provider.dart';
import '../../providers/routine_provider.dart';
import '../../shared/widgets/exercise_evolution_charts.dart';
import '../../shared/widgets/expandable_section.dart';
import '../../shared/widgets/hero_exercise_image.dart';
import '../../shared/widgets/number_stepper_field.dart';
import '../../shared/widgets/pill.dart';
import '../../shared/widgets/section_card.dart';
import '../../shared/widgets/stat_tile.dart';
import '../../shared/widgets/two_column_layout.dart';

/// Pantalla única de un ejercicio, con dos modos:
///
/// - `dayKey != null` (abierta desde la rutina de hoy): modo registro —
///   "Registrar serie de hoy", imágenes y video de solo lectura.
/// - `dayKey == null` (abierta desde Ejercicios o desde Ajustes): modo
///   edición — parámetros (series/reps/descanso) e imágenes/video
///   editables. Es el único lugar de la app donde se editan esos campos.
///
/// En ambos modos se muestra, como en la maqueta: una fila de cifras
/// (series hechas / último peso o tiempo / últimas reps / fecha), la nota
/// de tendones si aplica, y al final los gráficos de evolución.
class ExerciseDetailScreen extends StatefulWidget {
  const ExerciseDetailScreen({super.key, required this.exerciseId, this.dayKey});
  final String exerciseId;
  final String? dayKey;

  bool get logMode => dayKey != null;

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  final _setsDoneCtrl = TextEditingController();
  final _repsCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _secondsCtrl = TextEditingController();
  int _pain = 1;

  late final TextEditingController _setsLabelCtrl;
  late final TextEditingController _repLowCtrl;
  late final TextEditingController _repHighCtrl;
  late final TextEditingController _restLabelCtrl;
  late final TextEditingController _videoCtrl;

  bool _initialized = false;
  bool _savingImage = false;

  @override
  void initState() {
    super.initState();
    _setsLabelCtrl = TextEditingController();
    _repLowCtrl = TextEditingController();
    _repHighCtrl = TextEditingController();
    _restLabelCtrl = TextEditingController();
    _videoCtrl = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _setsDoneCtrl.dispose();
    _repsCtrl.dispose();
    _weightCtrl.dispose();
    _secondsCtrl.dispose();
    _setsLabelCtrl.dispose();
    _repLowCtrl.dispose();
    _repHighCtrl.dispose();
    _restLabelCtrl.dispose();
    _videoCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final logProvider = context.read<ExerciseLogProvider>();
    await logProvider.loadFor(widget.exerciseId);
    if (!mounted) return;

    final exercises = context.read<ExerciseProvider>();
    final ex = exercises.byId(widget.exerciseId);
    if (ex == null) return;

    _setsLabelCtrl.text = ex.setsLabel;
    _repLowCtrl.text = '${ex.repLow}';
    _repHighCtrl.text = '${ex.repHigh}';
    _restLabelCtrl.text = ex.restLabel;
    _videoCtrl.text = ex.videoUrl ?? '';

    if (widget.logMode) {
      final today = todayIso();
      ExerciseLogEntry? todayEntry;
      for (final e in logProvider.logsFor(widget.exerciseId)) {
        if (e.date == today) todayEntry = e;
      }
      final last = todayEntry ?? logProvider.lastFor(widget.exerciseId);
      _setsDoneCtrl.text = todayEntry?.setsDone?.toString() ?? ex.setsLabel.replaceAll(RegExp('[^0-9]'), '');
      _repsCtrl.text = (todayEntry?.reps ?? last?.reps ?? ex.repHigh).toString();
      _weightCtrl.text = (todayEntry?.weightKg ?? last?.weightKg ?? ex.baseWeight)?.toString() ?? '';
      _secondsCtrl.text = (todayEntry?.seconds ?? last?.seconds ?? ex.baseSeconds)?.toString() ?? '';
      _pain = todayEntry?.pain ?? 1;
    }

    setState(() => _initialized = true);
  }

  Future<void> _saveTodayEntry(Exercise ex) async {
    final setsDone = int.tryParse(_setsDoneCtrl.text.trim());
    final entry = ExerciseLogEntry(
      exerciseId: ex.id,
      date: todayIso(),
      setsDone: setsDone,
      reps: ex.measureType == MeasureType.repsWeight ? int.tryParse(_repsCtrl.text.trim()) : null,
      weightKg: ex.measureType == MeasureType.repsWeight && !ex.isBodyweight
          ? double.tryParse(_weightCtrl.text.trim())
          : null,
      seconds: ex.measureType == MeasureType.time ? int.tryParse(_secondsCtrl.text.trim()) : null,
      pain: _pain,
    );
    await context.read<ExerciseLogProvider>().saveEntry(entry);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _saveParams() async {
    final repLow = int.tryParse(_repLowCtrl.text.trim()) ?? 0;
    final repHigh = int.tryParse(_repHighCtrl.text.trim()) ?? repLow;
    await context.read<ExerciseProvider>().updateParams(
          widget.exerciseId,
          setsLabel: _setsLabelCtrl.text.trim(),
          repLow: repLow,
          repHigh: repHigh,
          restLabel: _restLabelCtrl.text.trim(),
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Parámetros guardados')));
    }
  }

  Future<void> _saveVideo() async {
    final url = _videoCtrl.text.trim();
    await context.read<ExerciseProvider>().setVideoUrl(widget.exerciseId, url.isEmpty ? null : url);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Video guardado')));
    }
  }

  Future<void> _openVideo(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo abrir el video')));
      }
    }
  }

  Future<void> _pickImage(Exercise ex, int slot) async {
    setState(() => _savingImage = true);
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (picked == null) return;

      final docsDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(p.join(docsDir.path, 'app_images'));
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }
      final ext = p.extension(picked.path);
      final fileName = '${ex.id}_slot${slot}_${DateTime.now().millisecondsSinceEpoch}$ext';
      final destPath = p.join(imagesDir.path, fileName);
      await File(picked.path).copy(destPath);

      final oldPath = slot == 1 ? ex.image1Path : ex.image2Path;
      if (!mounted) return;
      await context.read<ExerciseProvider>().setImage(ex.id, slot: slot, path: destPath);
      await _deleteIfExists(oldPath);
    } finally {
      if (mounted) setState(() => _savingImage = false);
    }
  }

  Future<void> _removeImage(Exercise ex, int slot) async {
    final oldPath = slot == 1 ? ex.image1Path : ex.image2Path;
    await context.read<ExerciseProvider>().setImage(ex.id, slot: slot, path: null);
    await _deleteIfExists(oldPath);
  }

  Future<void> _deleteIfExists(String? path) async {
    if (path == null) return;
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {
      // Si no se puede borrar el archivo viejo no es crítico: el registro
      // en la base de datos ya quedó actualizado.
    }
  }

  @override
  Widget build(BuildContext context) {
    final exercises = context.watch<ExerciseProvider>();
    final routines = context.watch<RoutineProvider>();
    final logProvider = context.watch<ExerciseLogProvider>();
    final colors = Theme.of(context).extension<AppColors>()!;

    final ex = exercises.byId(widget.exerciseId);
    if (ex == null || !_initialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final daysCount = routines.days.values.where((d) => d.exerciseIds.contains(ex.id)).length;
    final logs = logProvider.logsFor(ex.id);
    final last = logs.isNotEmpty ? logs.last : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(ex.name),
        // Igual que en la maqueta: grupo muscular · series · reps · descanso
        // como subtítulo de la barra superior.
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(26),
          child: Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 10),
            child: Text(
              '${ex.muscleGroup} · ${exerciseSetsLine(ex)} · ${ex.restLabel} descanso',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: colors.textMuted),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.logMode) HeroExerciseImage(exercise: ex) else _EditableImages(exercise: ex, colors: colors, saving: _savingImage, onPick: _pickImage, onRemove: _removeImage),
          const SizedBox(height: 14),
          _StatRow(exercise: ex, last: last, colors: colors),
          if (ex.hasPainNote) ...[
            const SizedBox(height: 14),
            _WarmBox(colors: colors),
          ],
          const SizedBox(height: 14),
          if (widget.logMode)
            _TodayLogCard(
              exercise: ex,
              colors: colors,
              setsDoneCtrl: _setsDoneCtrl,
              repsCtrl: _repsCtrl,
              weightCtrl: _weightCtrl,
              secondsCtrl: _secondsCtrl,
              pain: _pain,
              onPainChanged: (v) => setState(() => _pain = v),
              onSave: () => _saveTodayEntry(ex),
            )
          else
            _ParamsCard(
              exercise: ex,
              colors: colors,
              daysCount: daysCount,
              setsLabelCtrl: _setsLabelCtrl,
              repLowCtrl: _repLowCtrl,
              repHighCtrl: _repHighCtrl,
              restLabelCtrl: _restLabelCtrl,
              onSave: _saveParams,
            ),
          const SizedBox(height: 14),
          SectionCard(
            title: 'Video',
            child: widget.logMode
                ? (ex.videoUrl == null || ex.videoUrl!.isEmpty)
                    ? Text('Sin video vinculado', style: TextStyle(fontSize: 12.5, color: colors.textMuted))
                    : OutlinedButton.icon(
                        onPressed: () => _openVideo(ex.videoUrl!),
                        icon: const Icon(Icons.play_circle_outline),
                        label: const Text('Ver video'),
                      )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _videoCtrl,
                        decoration: const InputDecoration(hintText: 'https://...', border: OutlineInputBorder()),
                        keyboardType: TextInputType.url,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          ElevatedButton(onPressed: _saveVideo, child: const Text('Guardar video')),
                          const SizedBox(width: 10),
                          if (_videoCtrl.text.trim().isNotEmpty)
                            OutlinedButton(onPressed: () => _openVideo(_videoCtrl.text.trim()), child: const Text('Ver')),
                        ],
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 14),
          // Gráficos de evolución (peso/tiempo, repeticiones y series) — en
          // un desplegable en vez de siempre visibles, igual que en el
          // registro diario, para no alargar la pantalla de entrada.
          ExpandableSection(
            padding: const EdgeInsets.all(14),
            header: Row(
              children: [
                Icon(Icons.show_chart, size: 18, color: colors.textMuted),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Evolución', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.textPrimary)),
                      const SizedBox(height: 2),
                      Text('Peso, repeticiones y series a lo largo del tiempo', style: TextStyle(fontSize: 11, color: colors.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
            builder: (context) => ExerciseEvolutionCharts(exercise: ex, logs: logs),
          ),
        ],
      ),
    );
  }
}

/// "3 × 8–10" o "3 × 20–40 s" — usado en el subtítulo de la barra superior.
String exerciseSetsLine(Exercise ex) {
  final range = ex.repHigh != ex.repLow ? '${ex.repLow}–${ex.repHigh}' : '${ex.repLow}';
  final unit = ex.measureType == MeasureType.time ? ' s' : ' reps';
  return '${ex.setsLabel} series · $range$unit${ex.suffix}';
}

/// Fila de cifras (series hechas / peso o tiempo / reps / fecha) igual que
/// el `.statrow` de la maqueta — visible en ambos modos.
class _StatRow extends StatelessWidget {
  const _StatRow({required this.exercise, required this.last, required this.colors});
  final Exercise exercise;
  final ExerciseLogEntry? last;
  final AppColors colors;

  String _fmtNum(double? v) {
    if (v == null) return '—';
    return v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      StatTile(value: last?.setsDone?.toString() ?? '—', label: 'Series hechas'),
    ];
    if (exercise.measureType == MeasureType.time) {
      tiles.add(StatTile(value: last != null ? '${last!.seconds ?? '—'} s' : '—', label: 'Último tiempo'));
    } else {
      tiles.add(StatTile(
        value: last != null ? (exercise.isBodyweight ? '—' : '${_fmtNum(last!.weightKg)} kg') : '—',
        label: 'Último peso',
      ));
      tiles.add(StatTile(
        value: last != null ? '${last!.reps ?? '—'}${exercise.suffix}' : '—',
        label: 'Últimas reps',
      ));
    }
    tiles.add(StatTile(value: last != null ? formatShort(last!.date) : '—', label: 'Fecha'));

    return TwoColumnLayout(spacing: 10, runSpacing: 10, children: tiles);
  }
}

/// Nota de tendones — misma redacción y estilo (caja punteada) que en la
/// maqueta, para ejercicios marcados con `hasPainNote`.
class _WarmBox extends StatelessWidget {
  const _WarmBox({required this.colors});
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.borderStrong),
      ),
      child: RichText(
        text: TextSpan(
          style: TextStyle(fontSize: 11.5, color: colors.textSecondary, height: 1.5),
          children: [
            TextSpan(text: 'Nota de tendones — ', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w700)),
            const TextSpan(
              text: 'prioriza reps limpias con menos peso antes que reps forzadas con más peso. '
                  'Si el antebrazo duele, reduce carga o cambia el ejercicio.',
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayLogCard extends StatelessWidget {
  const _TodayLogCard({
    required this.exercise,
    required this.colors,
    required this.setsDoneCtrl,
    required this.repsCtrl,
    required this.weightCtrl,
    required this.secondsCtrl,
    required this.pain,
    required this.onPainChanged,
    required this.onSave,
  });

  final Exercise exercise;
  final AppColors colors;
  final TextEditingController setsDoneCtrl;
  final TextEditingController repsCtrl;
  final TextEditingController weightCtrl;
  final TextEditingController secondsCtrl;
  final int pain;
  final ValueChanged<int> onPainChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Registrar serie de hoy',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${exercise.setsLabel} × ${exercise.repsLabel} · descanso ${exercise.restLabel}',
              style: TextStyle(fontSize: 12.5, color: colors.textSecondary)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: NumberStepperField(label: 'Series hechas', controller: setsDoneCtrl, step: 1, min: 0),
              ),
              const SizedBox(width: 10),
              if (exercise.measureType == MeasureType.repsWeight)
                Expanded(child: NumberStepperField(label: 'Reps', controller: repsCtrl, step: 1, min: 0))
              else
                Expanded(child: NumberStepperField(label: 'Segundos', controller: secondsCtrl, step: 5, min: 0)),
            ],
          ),
          if (exercise.measureType == MeasureType.repsWeight && !exercise.isBodyweight) ...[
            const SizedBox(height: 10),
            NumberStepperField(label: 'Peso (kg)', controller: weightCtrl, step: 0.5, min: 0, decimal: true),
          ],
          const SizedBox(height: 14),
          Text('Escala de dolor', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: colors.textMuted, letterSpacing: 0.3)),
          const SizedBox(height: 6),
          _PainSelector(pain: pain, onChanged: onPainChanged, colors: colors),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(onPressed: onSave, child: const Text('Guardar serie')),
          ),
        ],
      ),
    );
  }
}

/// Selector discreto de dolor (leve / atento / detener) — igual que los 3
/// botones `.pain-opt` de la maqueta, en vez de un slider continuo.
class _PainSelector extends StatelessWidget {
  const _PainSelector({required this.pain, required this.onChanged, required this.colors});
  final int pain;
  final ValueChanged<int> onChanged;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final level = painLevelFor(pain);
    return Row(
      children: [
        Expanded(child: _painOption(level == PainLevel.good, '0–2', 'leve', 1, colors.good, colors.goodBg, colors.goodText)),
        const SizedBox(width: 8),
        Expanded(child: _painOption(level == PainLevel.warn, '3–4', 'atento', 3, colors.warning, colors.warnBg, colors.warnText)),
        const SizedBox(width: 8),
        Expanded(child: _painOption(level == PainLevel.bad, '5+', 'detener', 6, colors.critical, colors.badBg, colors.badText)),
      ],
    );
  }

  Widget _painOption(bool selected, String range, String label, int value, Color borderOn, Color bgOn, Color textOn) {
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
        decoration: BoxDecoration(
          color: selected ? bgOn : colors.surface2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? borderOn : colors.border, width: 1.5),
        ),
        child: Column(
          children: [
            Text(range, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: selected ? textOn : colors.textSecondary)),
            Text(label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: selected ? textOn : colors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _NumField extends StatelessWidget {
  const _NumField({required this.label, required this.controller, required this.colors});
  final String label;
  final TextEditingController controller;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class _ParamsCard extends StatelessWidget {
  const _ParamsCard({
    required this.exercise,
    required this.colors,
    required this.daysCount,
    required this.setsLabelCtrl,
    required this.repLowCtrl,
    required this.repHighCtrl,
    required this.restLabelCtrl,
    required this.onSave,
  });

  final Exercise exercise;
  final AppColors colors;
  final int daysCount;
  final TextEditingController setsLabelCtrl;
  final TextEditingController repLowCtrl;
  final TextEditingController repHighCtrl;
  final TextEditingController restLabelCtrl;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final unitLabel = exercise.measureType == MeasureType.time ? 'Seg. mín' : 'Reps mín';
    final unitLabelHigh = exercise.measureType == MeasureType.time ? 'Seg. máx' : 'Reps máx';

    return SectionCard(
      title: 'Parámetros del ejercicio',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (daysCount > 1) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: colors.warnBg, borderRadius: BorderRadius.circular(10)),
              child: Text(
                'Se usa en más de un día ($daysCount). Cambiar estos parámetros los actualiza en todos.',
                style: TextStyle(fontSize: 11.5, color: colors.warnText),
              ),
            ),
            const SizedBox(height: 12),
          ],
          _NumField(label: 'Series (ej. "3" o "3–4")', controller: setsLabelCtrl, colors: colors),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: NumberStepperField(label: unitLabel, controller: repLowCtrl, step: 1, min: 0)),
              const SizedBox(width: 10),
              Expanded(child: NumberStepperField(label: unitLabelHigh, controller: repHighCtrl, step: 1, min: 0)),
            ],
          ),
          const SizedBox(height: 10),
          _NumField(label: 'Descanso (ej. "90 s")', controller: restLabelCtrl, colors: colors),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(onPressed: onSave, child: const Text('Guardar parámetros')),
          ),
        ],
      ),
    );
  }
}

class _EditableImages extends StatelessWidget {
  const _EditableImages({
    required this.exercise,
    required this.colors,
    required this.saving,
    required this.onPick,
    required this.onRemove,
  });

  final Exercise exercise;
  final AppColors colors;
  final bool saving;
  final Future<void> Function(Exercise ex, int slot) onPick;
  final Future<void> Function(Exercise ex, int slot) onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _ImageSlot(exercise: exercise, slot: 1, path: exercise.image1Path, colors: colors, saving: saving, onPick: onPick, onRemove: onRemove)),
        const SizedBox(width: 10),
        Expanded(child: _ImageSlot(exercise: exercise, slot: 2, path: exercise.image2Path, colors: colors, saving: saving, onPick: onPick, onRemove: onRemove)),
      ],
    );
  }
}

class _ImageSlot extends StatelessWidget {
  const _ImageSlot({
    required this.exercise,
    required this.slot,
    required this.path,
    required this.colors,
    required this.saving,
    required this.onPick,
    required this.onRemove,
  });

  final Exercise exercise;
  final int slot;
  final String? path;
  final AppColors colors;
  final bool saving;
  final Future<void> Function(Exercise ex, int slot) onPick;
  final Future<void> Function(Exercise ex, int slot) onRemove;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        children: [
          Container(
            height: 140,
            width: double.infinity,
            color: colors.surface2,
            child: path != null
                ? Image.file(File(path!), fit: BoxFit.cover, width: double.infinity, height: 140)
                : Icon(Icons.add_photo_alternate_outlined, color: colors.textMuted, size: 30),
          ),
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(onTap: saving ? null : () => onPick(exercise, slot)),
            ),
          ),
          if (path != null)
            Positioned(
              top: 6,
              right: 6,
              child: InkWell(
                onTap: saving ? null : () => onRemove(exercise, slot),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                  child: const Icon(Icons.close, color: Colors.white, size: 15),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
