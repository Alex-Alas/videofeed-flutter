# Tareas de los integrantes 4, 5 y 6

Tres aportes cortos (5-10 min cada uno) que quedan pendientes después del
refactor `feat/big-refactor`. Cada uno toca **un solo archivo** de `lib/` y está
marcado en el código con `TODO(Integrante N)`, así que no hay conflictos entre
ustedes.

## Antes de empezar (los tres)

```bash
git checkout development
git pull origin development
git checkout -b feature/<tu-id>          # ver el nombre en tu tarea
flutter pub get
flutter run -t lib/main_demo.dart        # feed con videos de ejemplo, sin login
```

`lib/main_demo.dart` abre el feed con `FakeVideoRepository` y 4 videos de
`assets/videos/`: no necesitan cuenta ni tocan Firebase. Con la app corriendo,
guarda el archivo y presiona `r` en la terminal para ver el cambio (hot reload).

Al terminar:

```bash
flutter analyze        # debe decir "No issues found!"
flutter test           # deben pasar todas
git add <tus archivos>
git commit -m "<id>: <qué hiciste>"
git push -u origin feature/<tu-id>
```

Y abre el Pull Request hacia `development` (no hacia `main`).

Si Gradle falla con `this and base files have different roots` (proyecto en un
disco y caché de pub en otro), agrega `kotlin.incremental=false` a
`%USERPROFILE%\.gradle\gradle.properties` y vuelve a correr.

---

## Integrante 4 — Contadores legibles (`1.2K`, `2.4M`)

- **Rama:** `feature/I4-human-formats`
- **Archivo:** `lib/config/helpers/human_formats.dart`
- **Prueba nueva:** `test/config/human_formats_test.dart`
- **Dónde se ve:** el número debajo del corazón en cada video
  (`lib/presentation/widgets/shared/video_buttons.dart` ya llama a
  `HumanFormats.numeroLegible`). Hoy el 4.º video del demo muestra `2400000`.

Pasos:

1. `flutter pub add intl`
2. En `numeroLegible`, devuelve `NumberFormat.compact(locale: 'en').format(numero)`
   (importa `package:intl/intl.dart`).
3. Crea la prueba con estos casos: `0 -> '0'`, `999 -> '999'`,
   `1200 -> '1.2K'`, `15000 -> '15K'`, `2400000 -> '2.4M'`.
4. Corre el demo: el 1.º video debe decir `1.25K`, el 3.º `15.3K` y el 4.º `2.4M`.

---

## Integrante 5 — Estado vacío del feed

- **Rama:** `feature/I5-feed-vacio`
- **Archivo:** `lib/presentation/widgets/shared/feed_vacio.dart`
- **Prueba nueva:** `test/presentation/feed_vacio_test.dart`
- **Dónde se ve:** cuando no hay videos en Firestore, `FeedScreen` muestra
  `FeedVacio` en vez del feed. Hoy es solo un texto.

Pasos (dentro de `build`, todo centrado y con texto blanco porque el fondo es negro):

1. Ícono grande `Icons.video_library_outlined` (tamaño ~80, blanco).
2. Título `Aún no hay videos` y subtítulo `Sé el primero en subir uno`.
3. Si `onSubirVideo != null`, un `FilledButton.icon` con `Icons.add` y el texto
   `Subir video` que llame a `onSubirVideo`. Si es null, no se muestra.
4. No cambies el nombre de la clase ni el constructor:
   `test/presentation/feed_screen_test.dart` ya la busca.
5. Prueba (widget test): muestra el título; sin callback no hay botón; con
   callback, tocar el botón lo llama una vez.

Para verlo en el emulador, cambia **temporalmente** en `lib/main_demo.dart`
`FakeVideoRepository()` por `FakeVideoRepository(videosIniciales: [])` y
**no subas ese cambio**.

---

## Integrante 6 — Ícono de pausa y barra de progreso

- **Rama:** `feature/I6-progreso-video`
- **Archivo:** `lib/presentation/widgets/video/fullscreen_player.dart`
  (busca `TODO(Integrante 6)`, está dentro del `Stack`)
- **Dónde se ve:** al tocar un video se pausa, pero hoy no hay ninguna señal.

Pasos (agrega estos hijos al `Stack`, en el lugar del TODO):

1. Si el video está pausado, un ícono de play en el centro:

   ```dart
   if (!_controller.value.isPlaying)
     const IgnorePointer(
       child: Center(
         child: Icon(Icons.play_arrow_rounded, size: 96, color: Colors.white70),
       ),
     ),
   ```

2. La barra de progreso pegada abajo:

   ```dart
   Positioned(
     left: 0,
     right: 0,
     bottom: 0,
     child: VideoProgressIndicator(
       _controller,
       allowScrubbing: true,
       colors: const VideoProgressColors(
         playedColor: Colors.white,
         bufferedColor: Colors.white38,
         backgroundColor: Colors.white12,
       ),
     ),
   ),
   ```

3. Borra el comentario TODO. `_alternarReproduccion` ya llama a `setState`, así
   que el ícono aparece y desaparece solo; `VideoProgressIndicator` se actualiza
   por su cuenta.
4. Pruébalo en el demo: toca el video (aparece el ícono), toca otra vez (se va),
   y arrastra la barra para adelantar.

Este widget usa `video_player`, que necesita la plataforma, así que aquí no se
pide widget test: basta con `flutter analyze`, `flutter test` en verde y la
prueba manual en el emulador.
