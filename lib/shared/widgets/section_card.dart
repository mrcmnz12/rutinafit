import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Tarjeta de sección reutilizada en toda la app: título opcional +
/// contenido, con el fondo/borde estándar (surface1 + border).
class SectionCard extends StatelessWidget {
  const SectionCard({super.key, this.title, this.trailing, required this.child});
  final String? title;
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: c.surface1, borderRadius: BorderRadius.circular(18), border: Border.all(color: c.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title!, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.textPrimary)),
                if (trailing != null) trailing!,
              ],
            ),
          if (title != null) const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
