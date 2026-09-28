import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Tarjeta pequeña de una sola cifra (peso actual, series hechas, etc.).
/// Alto FIJO — igual que las tarjetas de resumen de Inicio — para que 2
/// o más de estas en una fila queden siempre parejas, sin importar si
/// alguna etiqueta es más larga y le tocaría envolver a 2 líneas.
class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.value, required this.label, this.valueColor});
  final String value;
  final String label;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    return Container(
      height: 78,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: c.surface1, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: valueColor ?? c.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: c.textMuted, letterSpacing: 0.3),
          ),
        ],
      ),
    );
  }
}
