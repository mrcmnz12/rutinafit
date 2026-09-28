import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../features/bodyweight/bodyweight_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/routines/routines_list_screen.dart';
import '../../features/settings/settings_screen.dart';

/// Shell de navegación con 4 pestañas, cada una con su propio Navigator
/// anidado: así la barra inferior queda siempre visible aunque el
/// usuario entre varios niveles (ej. Rutinas → una rutina → ejercicio).
/// La pestaña Rutinas muestra la rotación de gym (ya rediseñada para no
/// amarrarse a un día de la semana) y sirve para EMPEZAR cualquier
/// rutina, no solo la sugerida del día; editarlas vive aparte, en
/// Ajustes > Editar rutinas. El catálogo de ejercicios no tiene pestaña
/// propia: se accede desde Ajustes > Editar ejercicios. El botón atrás
/// del sistema primero intenta retroceder dentro de la pestaña actual;
/// si no puede, vuelve a Inicio; si ya está en Inicio, cierra la app.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _currentIndex = 0;

  final List<GlobalKey<NavigatorState>> _navKeys = List.generate(_tabs.length, (_) => GlobalKey<NavigatorState>());

  static const List<_TabDef> _tabs = [
    _TabDef(icon: Icons.home_outlined, selectedIcon: Icons.home, label: 'Inicio'),
    _TabDef(icon: Icons.calendar_month_outlined, selectedIcon: Icons.calendar_month, label: 'Rutinas'),
    _TabDef(icon: Icons.monitor_weight_outlined, selectedIcon: Icons.monitor_weight, label: 'Peso'),
    _TabDef(icon: Icons.settings_outlined, selectedIcon: Icons.settings, label: 'Ajustes'),
  ];

  Widget _rootScreenFor(int index) {
    switch (index) {
      case 0:
        return const HomeScreen();
      case 1:
        return const RoutinesListScreen();
      case 2:
        return const BodyWeightScreen();
      case 3:
        return const SettingsScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  void _onTabTapped(int index) {
    // Tocar cualquier pestaña (esté activa o no) siempre vuelve a su
    // raíz. El IndexedStack mantiene los Navigator de cada pestaña
    // montados (aunque no visibles) para no perder su estado al
    // cambiar de pestaña, así que sin este reset se podía volver a una
    // pestaña y encontrarla en la última pantalla en la que había
    // quedado en vez de en su raíz.
    _navKeys[index].currentState?.popUntil((route) => route.isFirst);
    if (index != _currentIndex) {
      setState(() => _currentIndex = index);
    }
  }

  Future<void> _handleBack() async {
    final nav = _navKeys[_currentIndex].currentState;
    if (nav != null && nav.canPop()) {
      nav.pop();
      return;
    }
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
      return;
    }
    await SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleBack();
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: List.generate(_tabs.length, (i) {
            return Navigator(
              key: _navKeys[i],
              onGenerateRoute: (settings) => MaterialPageRoute(builder: (_) => _rootScreenFor(i)),
            );
          }),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          items: [
            for (final t in _tabs)
              BottomNavigationBarItem(icon: Icon(t.icon), activeIcon: Icon(t.selectedIcon), label: t.label),
          ],
        ),
      ),
    );
  }
}

class _TabDef {
  const _TabDef({required this.icon, required this.selectedIcon, required this.label});
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}
