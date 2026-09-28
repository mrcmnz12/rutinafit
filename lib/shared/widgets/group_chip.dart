import 'package:flutter/material.dart';

/// Etiqueta del grupo muscular que aparece sobre la miniatura/imagen de
/// un ejercicio (ej. "Pecho").
class GroupChip extends StatelessWidget {
  const GroupChip({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.35), borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
    );
  }
}
