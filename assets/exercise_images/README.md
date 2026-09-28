# Imágenes empaquetadas de ejercicios

Estas imágenes se muestran en la app cuando un ejercicio no tiene foto
propia subida por el usuario (ver `lib/core/data/bundled_exercise_images.dart`).

Catálogo completo cubierto (21 de 21 ejercicios, 20 archivos —
`prensa.jpg` se reutiliza para `prensa` y `prensa-pies-altos`):
press-pecho, remo-pecho-apoyado, press-inclinado, jalon-pecho,
elevaciones-laterales, triceps-cuerda, prensa, prensa-pies-altos,
curl-femoral-sentado, extension-cuadriceps, curl-femoral-acostado,
pantorrilla, dead-bug, plancha-lateral, sentadilla-goblet,
abduccion-cadera, pallof-press, reverse-pec-deck, curl-martillo,
plancha, curl-biceps-polea.

Si el catálogo suma un ejercicio nuevo más adelante: dejá el archivo acá
(cualquier nombre) y sumá `'id-del-ejercicio': 'nombre_del_archivo'` en
`lib/core/data/bundled_exercise_images.dart`.
