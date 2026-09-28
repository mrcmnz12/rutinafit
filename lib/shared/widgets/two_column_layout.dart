import 'package:flutter/material.dart';

/// Grilla de 2 columnas cuyo alto se ajusta al contenido de cada fila,
/// en vez de forzar una relación de aspecto fija con `GridView.count` +
/// `childAspectRatio`. Esto último es lo que causaba los errores de
/// "BOTTOM OVERFLOWED" que aparecían en algunos dispositivos/tamaños de
/// fuente: el número fijo de relación de aspecto se calculaba para un
/// ancho de pantalla puntual y no se adaptaba a otros. Acá cada fila
/// mide lo que necesite su contenido más alto (vía `IntrinsicHeight` +
/// `CrossAxisAlignment.stretch`), así que nunca se desborda sin importar
/// el tamaño de pantalla o la escala de fuente del sistema.
class TwoColumnLayout extends StatelessWidget {
  const TwoColumnLayout({super.key, required this.children, this.spacing = 12, this.runSpacing = 12});

  final List<Widget> children;
  final double spacing;
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += 2) {
      final second = i + 1 < children.length ? children[i + 1] : null;
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: children[i]),
              SizedBox(width: spacing),
              Expanded(child: second ?? const SizedBox.shrink()),
            ],
          ),
        ),
      );
      if (i + 2 < children.length) rows.add(SizedBox(height: runSpacing));
    }
    return Column(mainAxisSize: MainAxisSize.min, children: rows);
  }
}
