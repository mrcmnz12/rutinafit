import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Campo numérico con botones "-"/"+" además de teclado — se puede
/// tocar +/- para ajustar de a poco, o tocar el número y escribirlo
/// directo. Usado en todos los lugares donde se ingresa peso,
/// repeticiones, series o tiempo.
class NumberStepperField extends StatelessWidget {
  const NumberStepperField({
    super.key,
    required this.label,
    required this.controller,
    this.step = 1,
    this.min = 0,
    this.decimal = false,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final double step;
  final double min;
  final bool decimal;
  final VoidCallback? onChanged;

  double? _current() => double.tryParse(controller.text.trim().replaceAll(',', '.'));

  String _format(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  void _apply(double v) {
    if (v < min) v = min;
    controller.text = decimal ? _format(v) : v.round().toString();
    controller.selection = TextSelection.collapsed(offset: controller.text.length);
    onChanged?.call();
  }

  void _inc() => _apply((_current() ?? (min - step)) + step);
  void _dec() => _apply((_current() ?? (min + step)) - step);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return TextField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      textAlign: TextAlign.center,
      onChanged: (_) => onChanged?.call(),
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: const OutlineInputBorder(),
        prefixIcon: _StepButton(icon: Icons.remove, onTap: _dec, colors: colors),
        suffixIcon: _StepButton(icon: Icons.add, onTap: _inc, colors: colors),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap, required this.colors});
  final IconData icon;
  final VoidCallback onTap;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 18, color: colors.textSecondary),
      splashRadius: 18,
      onPressed: onTap,
    );
  }
}
