# Primer arranque en Android Studio

## Por qué hay un paso obligatorio antes de correr la app

Todo el código Dart de RutinaFit (`lib/**`) está escrito a mano en este
repositorio. Lo que **no existe todavía** son las carpetas `android/` e
`ios/` — la integración nativa de cada plataforma (Gradle, manifiestos,
`build.gradle`, wrappers, etc.) que Flutter genera automáticamente.

Esas carpetas se generan con herramientas del SDK de Flutter que no
estaban disponibles en el entorno donde se escribió este código (sin
Flutter instalado y sin acceso a internet). Generarlas a mano no es
seguro — en particular el `gradle-wrapper.jar` es un binario, y un
`android/` mal armado puede fallar de formas difíciles de diagnosticar.
Por eso el primer paso queda para vos, en tu máquina, con Flutter real.

## Pasos

1. **Instalar Flutter** (si no lo tenés ya) siguiendo la guía oficial
   para Windows: https://docs.flutter.dev/get-started/install/windows
   Verificá con `flutter doctor` que Android toolchain y Android Studio
   queden en verde.

2. **Abrir una terminal en la carpeta del proyecto** (`AppEjercicios/`,
   donde está `pubspec.yaml`) y correr:

   ```
   flutter create . --platforms=android
   ```

   Esto genera `android/` respetando el `pubspec.yaml` y el `lib/`
   existentes — no toca el código Dart ya escrito. Se pasó
   `--platforms=android` porque el pedido inicial es "por ahora solo
   Android"; si más adelante se decide sumar iOS, correr de nuevo
   `flutter create . --platforms=ios` agrega esa carpeta sin romper nada.

3. **Instalar las dependencias declaradas en `pubspec.yaml`:**

   ```
   flutter pub get
   ```

4. **Abrir la carpeta del proyecto en Android Studio** (File → Open →
   elegir `AppEjercicios/`). Android Studio debería reconocerlo como
   proyecto Flutter automáticamente (ícono de Flutter en la barra de
   herramientas, opción de elegir dispositivo/emulador).

5. **Elegir un emulador o conectar un teléfono Android** (con
   depuración USB activada) y correr con el botón ▶ de Android Studio,
   o desde la terminal:

   ```
   flutter run
   ```

## Qué esperar en el primer build

- La primera vez que corre, la app crea la base de datos SQLite local
  (`rutinafit.db`, en el almacenamiento privado de la app) y la llena
  con la rutina real ya cargada (4 días de entrenamiento + 3 de
  descanso, 21 ejercicios, ~13 sesiones históricas de ejemplo) — así se
  puede probar la app con datos con sentido desde el primer momento, sin
  tener que cargar todo a mano. Esa siembra **solo ocurre si la base
  está vacía**: no vuelve a correr ni pisa datos reales una vez que la
  app se usó.
- Es esperable que el analizador de Dart marque **advertencias menores**
  la primera vez que se resuelven las dependencias reales (en particular
  `fl_chart`, que ha tenido pequeños cambios de nombres de parámetros
  entre versiones 0.6x — hay una nota en
  `lib/shared/widgets/line_chart.dart` señalando exactamente eso). Son
  ajustes puntuales, no errores de diseño: el analizador te va a señalar
  la línea exacta a corregir si la versión resuelta difiere.
- Si aparece algún error de compilación específico de Android (versión
  de Gradle, `minSdkVersion`, permisos en el `AndroidManifest.xml` para
  `image_picker`, etc.), son justamente "los detalles que corregimos
  después en Android Studio" — se resuelven ahí, con el proyecto ya
  abierto y el emulador a mano.

## Permisos que probablemente haya que revisar

`image_picker` necesita permiso de cámara/galería en
`android/app/src/main/AndroidManifest.xml`. Flutter/el plugin suelen
dejarlo listo al generar el proyecto, pero si al elegir una imagen la
app pide un permiso que no aparece o falla, ese es el archivo a revisar.

## Ejecutar en modo release (para instalar en un teléfono sin cable)

```
flutter build apk --release
```

El `.apk` queda en `build/app/outputs/flutter-apk/app-release.apk`.
