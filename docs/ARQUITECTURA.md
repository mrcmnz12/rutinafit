# Arquitectura

## Capas

```
UI (features/*)  →  providers (ChangeNotifier)  →  repositories  →  sqflite
                         ↑                              ↑
                    shared/widgets                 core/db (DatabaseHelper)
```

- **`core/db/`** — un único `DatabaseHelper` (singleton) abre la base
  SQLite (`rutinafit.db`), define el esquema completo en `onCreate` y
  deja `onUpgrade` listo para cuando haga falta una migración (por
  ejemplo, al agregar login). `db_constants.dart` centraliza nombres de
  tablas y claves de configuración para evitar strings mágicos repetidos.
- **`data/models/`** — clases inmutables por entidad (`Exercise`,
  `RoutineDay`, `TrainingSession`, `ExerciseLogEntry`,
  `BodyWeightEntry`), cada una con `fromMap`/`toMap` para ir y volver de
  SQLite sin exponer el formato de la fila fuera del repositorio.
- **`data/repositories/`** — una clase por tabla (o por agregado, en el
  caso de rutinas + `routine_day_exercises`). Es la única capa que
  conoce SQL. **Toda query usa placeholders (`?`)**; no hay un solo lugar
  donde se arme SQL concatenando un valor que venga de un campo de
  texto — así se elimina la inyección SQL como clase de bug, no solo en
  los casos que se nos ocurrieron.
- **`providers/`** — un `ChangeNotifier` por dominio (rutinas,
  ejercicios, registros, sesiones, peso corporal, tema). Cada uno envuelve
  su repositorio, mantiene el estado en memoria que la UI necesita, y
  expone métodos de mutación que escriben en la base y vuelven a cargar.
  La UI nunca llama a un repositorio directamente.
- **`features/`** — una carpeta por pantalla/flujo, con su propio widget
  de pantalla y, si corresponde, subwidgets privados. Solo leen
  providers (`context.watch`/`context.read`), nunca repositorios.
- **`shared/widgets/`** — piezas visuales reutilizadas entre pantallas
  (tarjetas, chips, miniatura de ejercicio, gráfico de evolución).

## Por qué un join table y no una lista de ids en JSON

`routine_day_exercises` (day_key, exercise_id, position) es una tabla
propia en vez de guardar los ids de ejercicios de un día como una
columna JSON. Esto da integridad referencial real (`ON DELETE CASCADE`:
borrar un ejercicio lo saca automáticamente de todas las rutinas que lo
usaban), orden explícito (`position`), y la posibilidad de hacer
queries directas ("¿en qué días aparece este ejercicio?") sin tener que
traer y parsear JSON en Dart. Es la pieza central de por qué el modelo
"escala" como pidió el dueño del proyecto.

## Edición unificada de ejercicios

Antes de esta versión había dos lugares que escribían sobre el mismo
ejercicio: la pantalla "Ejercicios" (que mezclaba "editar parámetros" con
"registrar lo hecho hoy") y un panel de edición dentro de "Ajustes". Se
unificó en una sola pantalla, `ExerciseDetailScreen`, con dos modos
según cómo se navega a ella:

- Se abre **con `dayKey`** desde `RoutineDayScreen` (la rutina de hoy):
  modo registro. Solo permite guardar `ExerciseLogEntry` para la fecha
  de hoy; imágenes y video se muestran de solo lectura.
- Se abre **sin `dayKey`** desde `ExercisesListScreen` (catálogo) o desde
  el botón "editar" de un ejercicio dentro de
  `RoutineDayEditScreen` (Ajustes → Editar rutinas): modo edición. Ahí
  se escriben `sets_label`/`rep_low`/`rep_high`/`rest_label` (los únicos
  campos que este modo toca) y las imágenes/video.

`ExerciseRepository.updateParams()` es el único método de la app que
escribe esos cuatro campos — no hay un segundo camino de escritura, así
que no hay forma de que la definición de un ejercicio quede
inconsistente entre pantallas.

## Navegación: shell de 5 pestañas con Navigator anidado

`core/navigation/root_shell.dart` arma un `IndexedStack` con un
`Navigator` propio por pestaña (Inicio, Rutinas, Ejercicios, Peso,
Ajustes). Cada pestaña mantiene su propia pila de navegación en memoria
al cambiar de pestaña (no se resetea), y la barra inferior queda siempre
visible aunque el usuario esté varios niveles adentro — por ejemplo,
Rutinas → día → detalle de ejercicio — igual que el comportamiento de la
maqueta HTML original. El botón atrás del sistema usa `PopScope` para:
primero intentar retroceder dentro de la pestaña activa; si no puede
(está en la raíz de esa pestaña), vuelve a la pestaña Inicio; si ya
estaba en Inicio, deja salir de la app.

## Tema visual: paletas × modo, como `ThemeExtension`

La maqueta define 7 paletas de acento × 2 modos (claro/oscuro), más un
conjunto de tokens neutros y de estado que varían solo por modo
(fondos, texto, colores de grupo muscular, colores de gráfico). Se portó
1:1 a `core/theme/palettes.dart` (los valores hex exactos) y se expone a
los widgets como un `ThemeExtension<AppColors>` (`app_colors.dart`) — el
mecanismo idiomático de Flutter para tokens de diseño propios que no
entran en el `ColorScheme` estándar de Material. `AppColors.forModeAndPalette()`
reconstruye el set completo de colores cada vez que cambia modo o
paleta (nunca hay una mezcla parcial de paleta vieja + modo nuevo).

## Datos de ejemplo (seed) vs. datos reales

`data/seed/seed_data.dart` tiene la rutina real ya cargada (4 días de
entrenamiento + 3 de descanso, 21 ejercicios, con sus series/reps/peso
base reales) más un historial de ejemplo generado de forma determinística
(`generateLogFor`), portado de la misma lógica que usaba la maqueta
HTML. `DatabaseSeeder.seedIfEmpty()` los inserta **solo si la tabla de
rutinas está vacía** — la primera vez que corre la app. Ni bien el
usuario empieza a registrar sus propios datos, ese chequeo (`COUNT(*) >
0`) hace que el seed nunca vuelva a correr ni pise nada.

## Multiplataforma: qué cambia si se suma iOS

El único código con acceso a plataforma es `sqflite` (base de datos),
`image_picker`/`path_provider` (fotos) y `url_launcher` (abrir video) —
los tres son paquetes multiplataforma de Flutter, sin código nativo
propio escrito a mano. Toda la UI (`features/`, `shared/widgets/`,
`core/theme/`) es Dart puro y no asume Android. Sumar iOS a futuro
debería ser, en el caso ideal, solo correr
`flutter create . --platforms=ios` y ajustar configuración nativa
puntual (permisos de cámara/galería en `Info.plist`, ícono, splash) —
no reescribir pantallas.

## Qué falta a propósito (decisiones abiertas)

- **Login/autenticación**: no existe todavía, a propósito (pedido
  explícito: "aunque ahora mismo no tenga login"). La capa de
  repositorios ya está separada de la UI, así que agregar una
  `AuthRepository` y filtrar los datos por usuario más adelante no
  debería requerir reescribir pantallas — ver `docs/SEGURIDAD.md`.
- **Generación de imágenes con IA** para ejercicios sin foto: quedó como
  decisión abierta en el doc de producto, no implementada.
- **Sincronización en la nube / multi-dispositivo**: fuera de alcance
  por ahora — la base es 100% local.
