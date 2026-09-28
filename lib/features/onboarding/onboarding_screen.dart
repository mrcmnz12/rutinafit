import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/onboarding_provider.dart';

/// Tutorial de bienvenida: 5 pasos explicando las funciones principales
/// de la app. Se muestra automáticamente la primera vez que se abre
/// RutinaFit (`RutinaFitApp` decide eso mirando `OnboardingProvider`) y
/// también queda disponible bajo demanda desde Ajustes > Ver tutorial.
///
/// `fromSettings` distingue ambos casos: al terminar/saltar, si vino de
/// Ajustes simplemente se hace `pop()` de vuelta; si es la primera vez
/// (es la pantalla `home` de la app, sin ruta anterior que hacer pop),
/// alcanza con marcar `markSeen()` — `RutinaFitApp` está escuchando ese
/// provider y cambia sola a `RootShell` en cuanto se pone en true.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, this.fromSettings = false});
  final bool fromSettings;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingStep {
  const _OnboardingStep({required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;
}

const _steps = [
  _OnboardingStep(
    icon: Icons.fitness_center,
    title: 'Bienvenido a RutinaFit',
    body: 'Lleva tus rutinas de gimnasio y tus actividades físicas en un solo lugar, 100% local en tu teléfono — nada se sube a internet.',
  ),
  _OnboardingStep(
    icon: Icons.today,
    title: 'Tu día, de un vistazo',
    body: 'Inicio te muestra la rutina de gym que toca según tu rotación y la actividad física del día, si tienes una configurada. Un toque y queda registrada.',
  ),
  _OnboardingStep(
    icon: Icons.event_repeat,
    title: 'Configura tu semana',
    body: 'En Ajustes > Configurar semana defines qué rutina o actividad prefieres cada día. Es solo una sugerencia, nunca una obligación: puedes entrenar lo que quieras, cuando quieras.',
  ),
  _OnboardingStep(
    icon: Icons.checklist_rtl,
    title: 'Tu catálogo, a tu manera',
    body: 'Agrega y edita tus propios ejercicios y actividades adicionales (fútbol, zumba, lo que sea) desde Ajustes, con tus fotos y parámetros.',
  ),
  _OnboardingStep(
    icon: Icons.insights,
    title: 'Sigue tu progreso',
    body: 'El calendario del mes queda siempre a la vista en Inicio, y los gráficos de evolución de tu peso y tus ejercicios te muestran tu avance real.',
  ),
];

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isLast => _page == _steps.length - 1;

  Future<void> _finish() async {
    await context.read<OnboardingProvider>().markSeen();
    if (widget.fromSettings && mounted) Navigator.of(context).pop();
  }

  void _next() {
    if (_isLast) {
      _finish();
    } else {
      _controller.nextPage(duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      backgroundColor: colors.screenBg,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 8, top: 4),
                child: _isLast
                    ? const SizedBox(height: 40)
                    : TextButton(
                        onPressed: _finish,
                        child: Text('Saltar', style: TextStyle(color: colors.textMuted, fontWeight: FontWeight.w600)),
                      ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _steps.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) => _StepView(step: _steps[i], colors: colors),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < _steps.length; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: i == _page ? 20 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: i == _page ? colors.accent : colors.border,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _next,
                      child: Text(_isLast ? 'Comenzar' : 'Siguiente'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepView extends StatelessWidget {
  const _StepView({required this.step, required this.colors});
  final _OnboardingStep step;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(color: colors.accentSoft, shape: BoxShape.circle),
            child: Icon(step.icon, color: colors.accent, size: 42),
          ),
          const SizedBox(height: 28),
          Text(
            step.title,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: colors.textPrimary),
          ),
          const SizedBox(height: 12),
          Text(
            step.body,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, height: 1.4, color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}
