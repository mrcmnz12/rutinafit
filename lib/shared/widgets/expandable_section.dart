import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Contenedor con encabezado tocable que expande/colapsa el contenido de
/// abajo — el "spoiler" pedido para los gráficos de evolución. Quien lo usa
/// arma el encabezado (nombre del ejercicio, resumen, píldora de dolor,
/// etc.); esta clase solo le agrega la flecha y el toque para expandir.
class ExpandableSection extends StatefulWidget {
  const ExpandableSection({
    super.key,
    required this.header,
    required this.builder,
    this.initiallyExpanded = false,
    this.onExpand,
    this.padding = const EdgeInsets.all(12),
    this.expanded,
    this.onToggle,
  });

  /// Contenido del encabezado (sin la flecha, que se agrega sola).
  final Widget header;

  /// Contenido a mostrar cuando está expandido. Se construye recién ahí, así
  /// que sirve para retrasar trabajo (por ejemplo cargar datos) hasta que el
  /// usuario realmente lo pide.
  final WidgetBuilder builder;
  final bool initiallyExpanded;

  /// Se llama una sola vez, la primera vez que se expande (no en colapsos ni
  /// re-expansiones posteriores) — útil para disparar una carga perezosa.
  final VoidCallback? onExpand;
  final EdgeInsets padding;

  /// Modo controlado: si no es nulo, el estado expandido/colapsado lo maneja
  /// quien usa este widget (por ejemplo, para que solo una sección de una
  /// lista quede abierta a la vez — patrón acordeón). Requiere [onToggle].
  /// Si es nulo, el widget maneja su propio estado internamente.
  final bool? expanded;
  final VoidCallback? onToggle;

  @override
  State<ExpandableSection> createState() => _ExpandableSectionState();
}

class _ExpandableSectionState extends State<ExpandableSection> {
  // Solo se usa en modo NO controlado (widget.expanded == null). En modo
  // controlado, `_expanded` se lee directamente de widget.expanded en cada
  // build — nunca se guarda una copia propia ni se llama setState() por un
  // cambio que viene de afuera. Mezclar ambas cosas (como se hacía antes,
  // sincronizando con setState() dentro de didUpdateWidget y además
  // disparando onExpand desde ahí) terminó marcando el elemento como sucio
  // dos veces en el mismo frame dentro de la lista con scroll, lo que
  // rompía una aserción interna de Flutter (SelectionKeepAlive/`!_dirty`).
  bool _internalExpanded = false;
  bool _everExpanded = false;

  @override
  void initState() {
    super.initState();
    _internalExpanded = widget.initiallyExpanded;
  }

  bool get _isControlled => widget.expanded != null;
  bool get _expanded => _isControlled ? widget.expanded! : _internalExpanded;

  void _toggle() {
    if (_isControlled) {
      // El padre decide; a él le toca, en su propio setState, actualizar lo
      // que sea necesario (incluida una eventual carga perezosa).
      widget.onToggle?.call();
      return;
    }
    setState(() => _internalExpanded = !_internalExpanded);
    if (_expanded && !_everExpanded) {
      _everExpanded = true;
      widget.onExpand?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final hPad = widget.padding.horizontal / 2;
    final vPad = widget.padding.vertical / 2;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface1,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: _toggle,
            child: Padding(
              padding: widget.padding,
              child: Row(
                children: [
                  Expanded(child: widget.header),
                  const SizedBox(width: 6),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: Icon(Icons.keyboard_arrow_down, color: colors.textMuted, size: 20),
                  ),
                ],
              ),
            ),
          ),
          ClipRect(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 180),
              alignment: Alignment.topCenter,
              child: _expanded
                  ? Padding(
                      padding: EdgeInsets.fromLTRB(hPad, 0, hPad, vPad + 2),
                      child: widget.builder(context),
                    )
                  : const SizedBox(width: double.infinity, height: 0),
            ),
          ),
        ],
      ),
    );
  }
}
