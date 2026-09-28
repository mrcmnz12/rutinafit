# RutinaFit

App de seguimiento de rutinas de gimnasio: rutina semanal, registro diario
de series/reps/peso o tiempo, calendario de entrenos, evolución de peso
corporal y del rendimiento por ejercicio, imágenes y video de referencia
por ejercicio, y personalización visual (7 paletas × modo claro/oscuro).

Este proyecto arrancó como una maqueta HTML interactiva (ver el historial
de la conversación / el doc "RutinaFit — Definición de producto" en
Claude) y ahora se está construyendo como app real con Flutter, para
depurarse y correr en Android Studio.

## Estado del proyecto

Todo el código Dart de la app (modelos, base de datos, repositorios,
providers, tema visual, widgets y las 8 pantallas) está escrito y vive en
`lib/`. **Lo que falta es un paso que solo se puede hacer con el SDK de
Flutter instalado**, que no está disponible en el entorno donde se
escribió este código — por eso el primer paso en Android Studio es
obligatorio. Ver `docs/SETUP_ANDROID_STUDIO.md`.

## Stack elegido

- **Flutter (Dart)** como framework de UI. Se eligió sobre Kotlin nativo
  Android-only porque el objetivo explícito es escalar a multiplataforma
  (potencialmente iOS a futuro) compartiendo la mayor parte del código de
  UI y lógica, y sobre .NET MAUI porque el entorno de depuración elegido
  es Android Studio, no Visual Studio.
- **sqflite** (SQLite local) para persistencia — sin backend, sin
  cuentas, todos los datos quedan en el dispositivo. Se prefirió sobre
  `drift` porque `drift` requiere generación de código (`build_runner`),
  que no se pudo ejecutar en el entorno donde se escribió este código; el
  esquema de `sqflite` es SQL plano y no necesita ese paso.
- **provider** para manejo de estado (un `ChangeNotifier` por dominio:
  rutinas, ejercicios, registros, peso corporal, sesiones, tema).
- **fl_chart** para los gráficos de evolución (peso corporal, evolución
  por ejercicio).
- **image_picker** + **path_provider** para las fotos de referencia de
  cada ejercicio (se copian al almacenamiento privado de la app; nunca se
  guarda una URL ni se sube nada a ningún servidor).
- **url_launcher** para abrir el link de video de un ejercicio.

Más detalle y justificación en `docs/ARQUITECTURA.md`.

## Estructura del proyecto

```
lib/
  main.dart                  # arranque: DB, seed, repos, providers
  app.dart                   # MaterialApp + tema
  core/
    db/                      # DatabaseHelper (sqflite) + nombres de tablas
    domain/                  # formatters.dart (texto reutilizado en UI)
    navigation/               # RootShell: shell de 5 pestañas
    theme/                    # paletas, tokens por modo, ThemeExtension
    utils/                    # fechas (formato ISO, fechas en español)
  data/
    models/                  # Exercise, RoutineDay, TrainingSession, ...
    repositories/            # una clase por tabla, SQL parametrizado
    seed/                    # datos de ejemplo (rutina real ya cargada)
  providers/                 # un ChangeNotifier por dominio
  shared/widgets/            # widgets reutilizados entre pantallas
  features/
    home/                    # Inicio: rutina sugerida, stats, calendario
    routines/                # Rutinas: lista, día, log de día pasado
    exercises/                # Ejercicios: catálogo + detalle dual-modo
    bodyweight/               # Peso corporal: registrar + evolución
    settings/                 # Ajustes: apariencia + editar rutinas
docs/
  ARQUITECTURA.md
  SETUP_ANDROID_STUDIO.md
  SEGURIDAD.md
```

## Edición de ejercicios: un solo lugar

Antes había dos formularios para tocar un ejercicio (uno en "Ejercicios"
para registrar lo hecho hoy, y otro en "Ajustes" para editar sus
parámetros). Se unificó: `ExerciseDetailScreen`
(`lib/features/exercises/exercise_detail_screen.dart`) es la única
pantalla de ejercicio, con dos modos según cómo se abre:

- **Con `dayKey`** (desde la rutina de hoy, `RoutineDayScreen`): modo
  registro — "Registrar serie de hoy" + imágenes/video de solo lectura.
- **Sin `dayKey`** (desde el catálogo "Ejercicios", o desde el botón
  "editar" de un ejercicio dentro de "Ajustes → Editar rutinas"): modo
  edición — parámetros (series/reps/descanso) e imágenes/video editables.

Así hay una sola fuente de verdad para los datos de cada ejercicio.

## Próximos pasos

Ver `docs/SETUP_ANDROID_STUDIO.md` para el primer arranque, y la sección
de decisiones abiertas en el doc "RutinaFit — Definición de producto"
para lo que falta decidir a nivel de producto (login futuro, generación
de imágenes con IA, etc).
