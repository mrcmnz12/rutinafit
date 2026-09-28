import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/navigation/root_shell.dart';
import 'core/theme/app_theme.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'providers/onboarding_provider.dart';
import 'providers/theme_provider.dart';

/// Raíz visual de la app: arma el ThemeData a partir del modo/paleta
/// elegidos (persistidos en ThemeProvider) y decide la pantalla
/// inicial — el tutorial de bienvenida si todavía no se vio, o el
/// shell de navegación normal. `OnboardingProvider` se observa acá
/// para que, apenas el tutorial se marca como visto (al terminarlo o
/// saltarlo), la app cambie sola a `RootShell` sin necesitar una
/// navegación explícita.
class RutinaFitApp extends StatelessWidget {
  const RutinaFitApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final onboarding = context.watch<OnboardingProvider>();

    Widget home;
    if (onboarding.loading) {
      home = const Scaffold(body: Center(child: CircularProgressIndicator()));
    } else if (!onboarding.seen) {
      home = const OnboardingScreen();
    } else {
      home = const RootShell();
    }

    return MaterialApp(
      title: 'RutinaFit',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(theme.themeMode, theme.paletteKey),
      home: home,
    );
  }
}
