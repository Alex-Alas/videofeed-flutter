# Plan: Rediseño UX/UI y refactor de la cámara en vivo con filtros (VideoFeed)

Alcance: **solo** la pantalla de cámara en vivo con filtros (`FiltrosEnVivoScreen`).
Quedan **fuera de alcance** `fullscreen_player.dart`, `upload_screen.dart` (salvo el
cambio de `import`), y cualquier otra screen.

Restricciones: **sin cambiar tecnología ni librerías**. Se sigue usando `camera`,
`google_mlkit_face_detection`, `path_provider` y `flutter/material`. El refactor es de
organización y limpieza, no de stack.

## 1. Objetivo

1. Rediseñar la interfaz de captura en vivo con un estilo tipo Instagram / TikTok:
   - **Un solo botón** principal, abajo al centro.
   - El resto de controles en una **capa flotante arriba a la derecha**.
   - El **título** va junto al botón inferior (es un dato de la captura, no un control).
   - Vista **inmersiva edge-to-edge**, sin `AppBar`.
2. Limpiar y refactorizar todo el código relacionado al live camera, dividiendo el
   archivo monolítico en unidades con una sola responsabilidad.

## 2. Decisiones acordadas

1. **Toggles de filtros**: se presentan como iconos en la capa superior derecha, con
   estado activo/inactivo (`Sombrero`, `Máscara`) junto a cambiar cámara y cerrar.
2. **Título**: campo expandible tipo IG. Estado compacto con texto placeholder
   ("Agrega un título…"); al tocarlo se expande para escribir. Siempre junto al botón
   inferior.
3. **Pantalla completa**: preview inmersivo edge-to-edge (cover), fondo negro, overlay
   flotante, sin `AppBar`.
4. **Contador de rostros**: se elimina de la UI. Se conserva solo como `debugPrint`
   para depuración.
5. **Refactor**: se elimina el archivo muerto `facial_filters.dart` (100 % comentado) y
   se divide `live_camera.dart` en varios widgets/archivos.
6. **Pruebas**: se respetan los tests existentes; el refactor no debe romper la API
   pública de `FiltrosEnVivoScreen` ni el flujo de `upload_screen.dart`.

## 3. Estado actual (problema)

`lib/presentation/widgets/uploaders/live_camera.dart` (496 líneas) concentra:

- La screen `FiltrosEnVivoScreen` (UI).
- Toda la lógica de cámara (`_initCameras`, `_startCamera`, `_stopCamera`,
  `_switchCamera`, `_processFrame`, `_toInputImage`).
- ML Kit (`FaceDetector`) y la conversión de frames.
- Captura de pantalla, guardado temporal y subida (`_publicarFoto`).
- `FiltrosEnVivoPainter` (CustomPainter).
- UI actual: `AppBar` + preview en caja con `AspectRatio` + columna de controles
  (2 `SwitchListTile`, `TextField`, contador de rostros) + `FloatingActionButton`.

Archivos relacionados:

| Archivo | Estado |
| --- | --- |
| `lib/presentation/widgets/uploaders/live_camera.dart` | Monolítico, a refactorizar. |
| `lib/presentation/widgets/uploaders/facial_filters.dart` | **100 % comentado, código muerto.** Se elimina. |
| `lib/utils/facial_filters_utils.dart` | Dibujo de overlays; **se conserva** (reusable). |
| `lib/presentation/screens/upload/upload_screen.dart` | Solo cambia el `import`. |

## 4. Arquitectura propuesta

Se mantiene el mismo patrón del proyecto (StatefulWidget + métodos), pero separando
responsabilidades. La lógica de cámara/ML Kit/subida se mueve a un `ChangeNotifier`
(API de Flutter, sin librerías nuevas); la UI queda como widgets de presentación puros.

```
FiltrosEnVivoScreen (Screen)          live_camera_screen.dart
        | crea y escucha
        v
LiveCameraController extends ChangeNotifier   live_camera_controller.dart
  - availableCameras / CameraController
  - FaceDetector + conversion de frames
  - toggles (sombrero, mascara), titulo, estado de publicacion
  - capturarYPublicar() usando VideoRepository + StorageService
        |
        v
Widgets de UI (sin logica de negocio)
  - LiveCameraControllerPanel  (capa flotante arriba derecha)
  - LiveCameraCaptureBar       (boton central + titulo expandible)
  - LiveCameraPreview          (preview + painter)
        |
        v
FiltrosEnVivoPainter    live_camera_overlay_painter.dart
facial_filters_utils.dart (se conserva)
```

- `FiltrosEnVivoScreen` conserva **exactamente** su constructor público
  (`repositorio`, `storage`, `uid`, `nombreUsuario`) y devuelve `pop(true)` al publicar,
  para no romper `upload_screen.dart`.
- La UI nunca llama a ML Kit ni a `CameraController` directamente: habla con el
  controller.

## 5. Diseño UX/UI (wireframe)

```
+--------------------------------------------------+
|  (estado/reloj)                                  |
|                                        ( X )      |  <- cerrar
|                                       ( 🔄 )      |  <- cambiar camara
|                                       ( 🎩 )      |  <- toggle sombrero
|                                       ( 😷 )      |  <- toggle mascara
|                                                  |
|                                                  |
|              [ preview camara ]                  |
|             (cover, pantalla completa)           |
|              + overlays de filtros               |
|                                                  |
|                                                  |
|                                                  |
|                                                  |
|        +------------------------------+          |
|        |  Agrega un titulo...         |          |  <- pill expandible
|        +------------------------------+          |
|                    (  O  )                        |  <- boton captura (centro)
|                                                  |
+--------------------------------------------------+
```

Detalles:

- **Capa superior derecha**: columna de botones circulares con fondo
  `Colors.black38`/blur y borde sutil. Orden sugerido: `Cerrar` (X),
  `Cambiar cámara` (solo si hay >1), `Sombrero`, `Máscara`. El toggle activo se resalta
  (relleno/acento teal); el inactivo queda translúcido. Cada botón con `tooltip` y
  `Semantics`/`IconButton` con etiqueta.
- **Botón de captura** (centro inferior): anillo exterior blanco (estilo IG) con círculo
  interior blanco; al presionar se encoge levemente; durante la publicación se convierte
  en un anillo de progreso con el `%` al centro.
- **Título expandible**:
  - Estado compacto: pill translúcido con `Icon(Icons.edit)` + placeholder
    "Agrega un título…".
  - Al tocar: se expande a un `TextField` multilínea (máx. 2 líneas) con botón de
    "listo" (check) para colapsar y quitar el foco.
  - Validación: si está vacío y se intenta publicar, se muestra el `SnackBar`
    "Escribe un título" (comportamiento actual preservado).
  - Ubicación: siempre inmediatamente encima del botón central, dentro de la barra
    inferior.
- **Capa de publicación**: overlay negro semitransparente con `CircularProgressIndicator`
  + porcentaje (comportamiento actual, con estética nueva).
- **Inmersivo**: `Scaffold` con `backgroundColor: Colors.black`,
  `extendBodyBehindAppBar: true`, sin `AppBar`. Status bar transparente con iconos
  claros (`SystemUiOverlayStyle`). La orientación sigue forzada a `portraitUp` mientras
  la screen está viva y se restaura en `dispose` (como hoy).
- El preview pasa de caja con `AspectRatio` a **cover** a pantalla completa
  (se conserva el pintado de overlays con el mismo mapeo `frameSize -> size` y el espejo
  en cámara frontal).
- Fondo negro también para los estados de `_error` y "cargando".

## 6. Plan de archivos

### Nuevos

| Archivo | Contenido |
| --- | --- |
| `lib/presentation/widgets/uploaders/live_camera/live_camera_screen.dart` | `FiltrosEnVivoScreen`: crea el controller, arma el `Stack` (preview + overlays + barras) y escucha cambios con `AnimatedBuilder`/`ListenableBuilder`. API pública idéntica. |
| `lib/presentation/widgets/uploaders/live_camera/live_camera_controller.dart` | `LiveCameraController extends ChangeNotifier`: cámaras, `CameraController`, `FaceDetector`, `_processFrame`/`_toInputImage`, toggles, título, `capturarYPublicar`, disposición. Toda la lógica no-visual. |
| `lib/presentation/widgets/uploaders/live_camera/live_camera_overlay_painter.dart` | `FiltrosEnVivoPainter` movido tal cual (misma lógica de dibujo). |
| `lib/presentation/widgets/uploaders/live_camera/widgets/live_camera_controls.dart` | `LiveCameraControls`: capa superior derecha con los botones (cerrar, cambiar cámara, sombrero, máscara) + botón circular reutilizable. |
| `lib/presentation/widgets/uploaders/live_camera/widgets/live_camera_capture_bar.dart` | `LiveCameraCaptureBar`: botón central de captura + título expandible + progreso local de la barra. |
| `lib/presentation/widgets/uploaders/live_camera/widgets/live_camera_preview.dart` | `LiveCameraPreview`: `CameraPreview` + `RepaintBoundary` (clave de captura) + painter + overlay de publicación. |

### Modificados

| Archivo | Cambio |
| --- | --- |
| `lib/presentation/screens/upload/upload_screen.dart` | Ajustar el `import` al nuevo `live_camera_screen.dart`. Sin cambios de lógica. |

### Eliminados

| Archivo | Motivo |
| --- | --- |
| `lib/presentation/widgets/uploaders/live_camera.dart` | Reemplazado por la carpeta `live_camera/`. |
| `lib/presentation/widgets/uploaders/facial_filters.dart` | 100 % comentado, sin referencias. Código muerto. |

> Nota: `lib/utils/facial_filters_utils.dart` **se conserva** sin cambios. Es lógica de
> dibujo reusable por el painter.

## 7. Comportamientos y estados a preservar

- [ ] Al publicar con éxito: subir a Storage con `onProgreso`, crear `Video` en el
      repositorio, borrar el archivo temporal y `Navigator.pop(true)`.
- [ ] En error: reiniciar el image stream si estaba detenido y mostrar `SnackBar`
      "No se pudo publicar la foto".
- [ ] `PopScope(canPop: !publicando)` para no salir a mitad de la subida.
- [ ] `enableAudio: false`, `ResolutionPreset.medium`, formato `nv21` (Android) /
      `bgra8888` (iOS), igual que hoy.
- [ ] Cámara frontal por defecto y espejo solo en frontal.
- [ ] Restaurar orientaciones en `dispose`.

## 8. Checklist de implementación

1. Crear la carpeta `live_camera/` y mover la lógica al `LiveCameraController`.
2. Extraer `FiltrosEnVivoPainter` a `live_camera_overlay_painter.dart`.
3. Crear `LiveCameraPreview`, `LiveCameraControls` y `LiveCameraCaptureBar`.
4. Reescribir `live_camera_screen.dart` con el `Stack` inmersivo y la nueva composición.
5. Implementar el título expandible (pill -> `TextField` -> colapsar).
6. Aplicar estética: botón de captura estilo IG, iconos circulares con estado,
   overlay de progreso, fondo negro y status bar transparente.
7. Eliminar `live_camera.dart` y `facial_filters.dart`.
8. Actualizar el `import` en `upload_screen.dart`.
9. Quitar los `debugPrint` ruidosos, conservando solo los útiles y el conteo de rostros
   en modo debug.
10. Ejecutar `flutter analyze` y los tests existentes (`flutter test`).
11. Verificación manual en dispositivo/emulador: captura, cambio de cámara, toggles,
    título vacío/lleno, progreso y retorno a `UploadScreen`.

## 9. Fuera de alcance

- `fullscreen_player.dart`, `upload_screen.dart` (más allá del import), feed, auth y
  cualquier otra screen.
- Cambios de librerías, versiones o backend (Firebase/Storage/ML Kit).
- Nuevas funcionalidades de cámara (grabar video, nuevos filtros, animaciones).

## 10. Riesgos y mitigación

| Riesgo | Mitigación |
| --- | --- |
| Romper el `import` o la API de `FiltrosEnVivoScreen`. | Mantener constructor y `pop(true)` idénticos; solo cambia la ruta del archivo. |
| El mapeo de overlays cambia al pasar a cover full-screen. | Reusar la misma matemática `size.width / frameSize.width` del painter actual; verificar en dispositivo. |
| Ciclo de vida del `CameraController`/`FaceDetector` al mover la lógica al controller. | `dispose()` del controller cierra detector, detiene stream y libera cámara; la screen llama `dispose` en su `dispose`. |
| `setState` desde el controller tras salir. | Usar `ChangeNotifier` + `ListenableBuilder` y `mounted`/`hasListeners` como hoy con `mounted`. |
