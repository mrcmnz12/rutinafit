import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Texto secundario chico, para notas/ayuda dentro de una tarjeta.
class EmptyNote extends StatelessWidget {
  const EmptyNote(this.text, {super.key, this.centered = false});
  final String text;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    return Text(
      text,
      textAlign: centered ? TextAlign.center : TextAlign.left,
      style: TextStyle(fontSize: 11.5, color: c.textMuted),
    );
  }
}
