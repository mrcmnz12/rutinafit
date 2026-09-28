/// Mapa de ejercicios que traen una imagen de referencia empaquetada con
/// la app (en vez de depender de que el usuario suba una foto propia).
///
/// La clave es el id del ejercicio en el catálogo (`Exercise.id`, ver
/// `lib/data/seed/seed_data.dart`); el valor es el nombre del archivo
/// dentro de `assets/exercise_images/`. Varios ids pueden apuntar al
/// mismo archivo cuando comparten la misma imagen (ej. `prensa` y
/// `prensa-pies-altos`, que usan la misma foto de la prensa).
///
/// Cómo agregar una imagen nueva:
/// 1. Dejar el archivo en `assets/exercise_images/<nombre_que_sea>`.
/// 2. Agregar una entrada acá: `'id-del-ejercicio': 'nombre_del_archivo'`.
/// 3. Nada más — al reconstruir la app (`flutter build` / `flutter run`)
///    la imagen queda incluida automáticamente, porque
///    `assets/exercise_images/` ya está declarada en `pubspec.yaml`.
///
/// Mientras un ejercicio no esté en este mapa, `ExerciseThumb` y
/// `HeroExerciseImage` siguen mostrando el ícono de respaldo de siempre.
const Map<String, String> kBundledExerciseImages = {
  'press-pecho': 'press-pecho.jpg',
  'remo-pecho-apoyado': 'remo-pecho-apoyado.jpg',
  'press-inclinado': 'press-inclinado.jpg',
  'jalon-pecho': 'jalon-pecho.jpg',
  'elevaciones-laterales': 'elevaciones-laterales.jpg',
  'triceps-cuerda': 'triceps-cuerda.jpg',
  'prensa': 'prensa.jpg',
  'prensa-pies-altos': 'prensa.jpg', // misma foto que 'prensa'
  'curl-femoral-sentado': 'curl-femoral-sentado.jpg',
  'extension-cuadriceps': 'extension-cuadriceps.jpg',
  'curl-femoral-acostado': 'curl-femoral-acostado.jpg',
  'pantorrilla': 'pantorrilla.jpg',
  'dead-bug': 'dead-bug.jpg',
  'plancha-lateral': 'plancha-lateral.jpg',
  'sentadilla-goblet': 'sentadilla-goblet.jpg',
  'abduccion-cadera': 'abduccion-cadera.jpg',
  'pallof-press': 'pallof-press.png',
  'reverse-pec-deck': 'reverse-pec-deck.png',
  'curl-martillo': 'curl-martillo.png',
  'plancha': 'plancha.png',
  'curl-biceps-polea': 'curl-biceps-polea.png',
};

/// Ruta del asset empaquetado para un ejercicio, o `null` si ese ejercicio
/// no tiene imagen incluida con la app.
String? bundledExerciseImagePath(String exerciseId) {
  final file = kBundledExerciseImages[exerciseId];
  if (file == null) return null;
  return 'assets/exercise_images/$file';
}
