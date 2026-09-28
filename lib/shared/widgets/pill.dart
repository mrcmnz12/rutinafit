import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

enum PainLevel { good, warn, bad }

PainLevel painLevelFor(int pain) => pain >= 5 ? PainLevel.bad : (pain >= 3 ? PainLevel.warn : PainLevel.good);

/// Chip de la escala de dolor (0-2 leve, 3-4 atento, 5+ detener) — misma
/// escala y mismos colores de estado que la maqueta.
class PainPill extends StatelessWidget {
  const PainPill({super.key, required this.pain});
  final int pain;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    final level = painLevelFor(pain);
    final bg = switch (level) { PainLevel.bad => c.badBg, PainLevel.warn => c.warnBg, PainLevel.good => c.goodBg };
    final fg = switch (level) { PainLevel.bad => c.badText, PainLevel.warn => c.warnText, PainLevel.good => c.goodText };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text('Dolor $pain/10', style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 10.5)),
    );
  }
}
