# Seguridad y privacidad

RutinaFit no tiene login todavía (a propósito, por pedido explícito), lo
que significa que por ahora **todos los datos viven exclusivamente en el
dispositivo de quien usa la app**, sin salir nunca a ningún servidor.
Esto en sí mismo es la primera capa de privacidad: no hay backend que
pueda filtrarse. Las decisiones de abajo son las que se tomaron para que
esto siga siendo así, y para que agregar login en el futuro sea un
agregado y no una reescritura.

## Dónde y cómo se guardan los datos

- **Base de datos**: `sqflite` guarda `rutinafit.db` en el almacenamiento
  **privado y en sandbox** de la app (en Android, el directorio interno
  de la app — no es accesible a otras apps sin acceso root al
  dispositivo).
- **Imágenes de referencia de ejercicios**: se copian con
  `path_provider` al directorio de documentos de la app
  (`app_images/`), también privado. Nunca se guardan como base64 en la
  base de datos (evita filas enormes y una base más difícil de
  inspeccionar/exportar por error) ni se suben a ningún servicio.
- **`.gitignore`** excluye explícitamente `*.db`, `*.sqlite`,
  `/app_images/` y `.env` — así ni la base con datos reales de una
  persona ni sus fotos pueden terminar commiteadas por accidente a un
  repositorio (por ejemplo, si en el futuro este proyecto se sube a
  GitHub).

## SQL: 100% parametrizado

Cada método de cada repositorio en `data/repositories/` arma sus queries
con placeholders (`?` + `whereArgs`), nunca concatenando un valor
(nombre de ejercicio, objetivo de un día, etc.) directamente dentro del
string SQL. Esto elimina la inyección SQL como clase de bug — no
depende de sanitizar caso por caso, el mecanismo mismo no permite que un
valor se interprete como código SQL. Se puede verificar leyendo
`data/repositories/*.dart`: no hay un solo `db.rawQuery` o `db.rawUpdate`
que use interpolación de string para un valor de usuario.

## Claves foráneas e integridad

`PRAGMA foreign_keys = ON` se activa en `onConfigure` de
`DatabaseHelper`, y las tablas relacionadas usan `ON DELETE CASCADE`
(por ejemplo, borrar un ejercicio del catálogo automáticamente lo saca
de `routine_day_exercises` y de `exercise_logs`). Esto evita filas
huérfanas que podrían quedar inconsistentes o exponer referencias a
datos que ya no deberían existir.

## Qué pasa cuando se agregue login (a futuro)

La app está armada en capas (`repositories` → `providers` → `features`)
específicamente para que esto sea agregable sin romper lo existente:

1. Un login agregaría una tabla de usuario/sesión y, probablemente, una
   columna `user_id` en las tablas que hoy son "de una sola persona"
   (`routine_days`, `exercise_logs`, `bodyweight_entries`, etc.) — esto
   se resuelve con una migración en `DatabaseHelper.onUpgrade` (el
   comentario en `_initDb()` ya deja el lugar marcado), sin tocar el
   esquema de `onCreate` existente.
2. Cada repositorio filtraría sus queries por el usuario activo — un
   cambio contenido a esa capa, sin tocar providers ni pantallas.
3. Si el login se conecta a un backend propio, la app pasaría de "solo
   local" a "local + sync": eso es un cambio de arquitectura mayor
   (fuera del alcance de esta nota), pero el hecho de que hoy no exista
   ningún acceso a red en la app (más allá de abrir un link de video en
   el navegador del sistema) significa que ese cambio se puede auditar
   fácilmente: cualquier código nuevo que hable con una red va a ser
   visiblemente nuevo, no mezclado con lógica ya existente.

## Qué NO hace esta app (a propósito)

- No pide permisos que no necesita. Los únicos permisos de plataforma
  que va a pedir son los de cámara/galería (`image_picker`), y solo en
  el momento en que la persona elige agregar una foto a un ejercicio.
- No manda ningún dato a servidores propios ni de terceros. La única
  conexión de red que puede iniciar el sistema operativo (no la app
  misma) es al abrir el link de video de un ejercicio, con la app/
  navegador que la persona ya tiene instalada.
- No usa analítica ni tracking.

## Auditoría — 28 de septiembre de 2026

Revisión completa del código contra lo que dice este documento, más hallazgos nuevos. Metodología: lectura de los 68 archivos de `lib/`, grep dirigido sobre `data/repositories/`, `android/app/` y `AndroidManifest.xml` — no reemplaza un análisis estático real (`flutter analyze`, un linter de seguridad), que no se puede correr desde este entorno.

### Confirmado, sigue vigente

- **SQL 100% parametrizado.** Se revisaron los 42 `insert`/`update`/`delete`/`query` de `data/repositories/`: todos usan `where: '... = ?'` + `whereArgs`, nunca interpolación de un valor dentro del string. Las únicas interpolaciones `${...}` en SQL son nombres de tabla/columna (constantes de `DbTables`/`SessionKind`), nunca datos de usuario.
- **Imágenes de ejercicios.** Se copian a `app_images/` en el directorio privado de documentos de la app (`path_provider`), con nombre de archivo generado (`id_slotN_timestamp.ext`), y el archivo viejo se borra al reemplazar o quitar una foto — no quedan huérfanos acumulándose.
- **Integridad referencial.** `PRAGMA foreign_keys = ON` + `ON DELETE CASCADE` siguen activos en `DatabaseHelper`.
- **Sin red propia.** No hay ninguna llamada de red saliente propia de la app (no hay `http`, `dio` ni paquete similar en `pubspec.yaml`); la única "salida" es `url_launcher` abriendo el link de video de un ejercicio en el navegador externo del sistema (no un WebView embebido), con `Uri.tryParse` + manejo de error si el link es inválido.
- **Sin secretos hardcodeados.** No se encontraron claves, tokens ni contraseñas en `lib/`.
- **Todavía no es un repositorio git** (no hay carpeta `.git`). El `.gitignore` ya está listo para cuando se inicialice, pero hoy no protege nada porque no hay nada versionado todavía.

### Hallazgos nuevos (revisar antes de un release real, no urgentes para uso personal)

1. **`applicationId = "com.example.rutinafit"`** en `android/app/build.gradle.kts` — es el ID de plantilla de `flutter create` (con su propio `// TODO` al lado). Google Play rechaza `com.example.*` directamente, y una vez publicado con un ID no se puede cambiar sin perder el historial de la app en la tienda.
2. **El build `release` firma con la key de debug** (`signingConfig = signingConfigs.getByName("debug")`, también con TODO propio). Sirve para probar `flutter run --release` en el teléfono, pero ese APK/AAB no lo acepta ninguna tienda — hace falta un keystore propio antes de publicar.
3. **`android:allowBackup` no está declarado** → Android usa el valor por defecto (`true`). Esto significa que, con una cuenta de Google conectada en el teléfono, Android puede respaldar automáticamente los datos de la app (la base SQLite y las fotos de `app_images/`) a Google Drive vía "Copia de seguridad de apps" — sin que la app escriba una sola línea de código para eso. No es una fuga a un tercero (es la cuenta del propio usuario), pero sí contradice literalmente la frase "nada sale del dispositivo" de la sección de arriba, y es justo el tipo de mecanismo que se preguntó hoy sobre "guardar el progreso en la cuenta de Google": ya existe, gratis, pasivo — solo no es todavía una decisión consciente. Para que la garantía "100% local" sea literal hay que declarar `android:allowBackup="false"` explícitamente.
4. **La base SQLite no está cifrada en disco** (`sqflite` estándar, no `sqlcipher`). Vive en el sandbox privado de la app — inaccesible en uso normal — pero en un teléfono rooteado, o si se extrae un backup completo del dispositivo, el archivo `.db` se puede abrir con cualquier lector de SQLite y leer todo en texto plano (rutinas, peso corporal, fechas de entrenamiento). Para el tipo de dato que maneja esta app (nada médico ni financiero) probablemente no amerita la complejidad de cifrar la base, pero es la verdad incómoda sin maquillar.

Ninguno de estos 4 puntos es urgente mientras la app viva solo en un teléfono de prueba — importan el día que se genere un build para instalar en otro teléfono o subirlo a una tienda.
