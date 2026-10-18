# VideoFeed

App de la actividad en grupo de la Clase 23 (Desarrollo de Aplicaciones Móviles): Flutter + Firebase con registro e inicio de sesión, un feed con los videos más recientes, subida de videos y likes.

El reparto de tareas, responsables y bloqueos está en el tablero del equipo (enlace en el grupo). Cada rama y cada PR lleva el ID de su tarea.

## Requisitos

- Flutter estable (3.x) y un emulador o teléfono Android
- Acceso al proyecto de Firebase del equipo (te lo da Alex en la tarea S-05)

## Correr la app

```bash
git clone <url-del-repo>
cd videofeed-flutter
flutter pub get
flutter run
```

`lib/firebase_options.dart` ya viene con la configuración del proyecto del equipo una vez que S-02 está en `main`. No hace falta que cada quien corra `flutterfire configure`.

Si la app falla al iniciar con "Firebase todavía no está configurado", actualiza tu rama: `git pull origin development`.

## Estructura

Misma organización por capas que la referencia (`dam-353n/copiaTikTokCompleta`):

```
lib/
  main.dart                     orden de inicialización de Firebase
  main_demo.dart                feed con datos falsos, sin login ni Firebase
  firebase_options.dart         generado por flutterfire configure
  config/
    helpers/                    HumanFormats (contadores legibles)
    theme/                      AppTheme (claro y oscuro)
  domain/                       qué hace la app, sin Firebase
    entities/                   Video (D-01)
    datasources/                AuthDataSource + AuthFailure (A-01)
    repositories/               VideoRepository (contrato D-01)
  infrastructure/               cómo lo hace (Firebase)
    datasources/                AuthService (A-01), StorageService (U-02)
    repositories/               AuthRepository, Fake/FirestoreVideoRepository (D-02, D-03, L-01)
  presentation/
    screens/auth/               AuthGate y login/registro (A-02, A-03)
    screens/feed/               FeedScreen (F-01..F-04)
    screens/upload/             UploadScreen (U-01..U-04)
    widgets/shared/             VideoScrollableView, VideoButtons, FeedVacio
    widgets/video/              FullScreenPlayer, VideoBackground
  shared/data/                  videos de ejemplo para el Fake y el demo
assets/videos/                  videos verticales de Pexels (licencia libre)
firestore.rules                 reglas de Firestore (S-04, D-04)
storage.rules                   reglas de Storage (S-04, D-04)
docs/                           guía de Firebase y planes
```

Para trabajar la UI del feed sin tocar el proyecto de Firebase:

```bash
flutter run -t lib/main_demo.dart
```

## Cómo trabajamos

1. Antes de empezar, marca tu tarea como **En progreso** en el tablero.
2. Crea una rama desde `development` con el ID de la tarea:
   `git checkout development && git pull origin development`
   `git checkout -b feature/A-01-auth-service`
3. Haz commits pequeños y sube tu rama: `git push -u origin feature/A-01-auth-service`
4. Abre un Pull Request hacia `development` (no hacia `main`) usando la plantilla. Alex (o quien tenga la tarea relacionada) lo revisa.
5. Cuando se fusione, marca la tarea como **Hecho** en el tablero.

Reglas del equipo:

- Nadie fuera de `lib/infrastructure` usa `FirebaseFirestore.instance` ni `FirebaseStorage.instance` directamente.
- `development` es la rama de integración; `main` solo recibe versiones estables desde `development` (lo hace Alex).
- No se sube a `development` ni a `main` sin PR.
- Corre `flutter analyze` antes de abrir el PR.

## Modelo de datos

```
users/{uid}                 email, nombre, creadoEn
videos/{videoId}            autorUid, autorNombre, titulo, videoUrl,
                            storagePath, likes, creadoEn
videos/{videoId}/likes/{uid}  creadoEn   (un like por usuario)
Storage: videos/{uid}/{timestamp}.mp4
```

## Costo

El proyecto de Firebase está en el plan Blaze solo porque Storage lo exige, pero el uso cabe en la cuota gratuita mensual y tiene una alerta de presupuesto de USD 1. El bucket está en `us-central1` (región con cuota gratis). Respeten el límite de 50 MB y 60 s por video (U-04).

## Actividad 4: consulta a la IA sobre las reglas en modo de prueba

**Herramienta:** Claude (Claude Code), octubre de 2026.

**Consulta:** "¿Qué riesgo hay en dejar las reglas de seguridad de Firestore y Storage en modo de prueba? Explícalo para nuestro proyecto, VideoFeed."

**Respuesta de la IA:**

Al crear Firestore o Storage en modo de prueba, Firebase publica una regla de este tipo:

```
match /{document=**} {
  allow read, write: if request.time < timestamp.date(2026, 11, 17);
}
```

La regla solo revisa la fecha (30 días después de crear la base). No pregunta quién hace la petición: hasta ese día, cualquiera puede leer, crear, modificar y borrar cualquier documento o archivo, sin haber iniciado sesión.

Ese "cualquiera" es literal. `firebase_options.dart` y `google-services.json` van dentro del APK (y en el repo, si es público). La API key solo identifica al proyecto, no da permisos. Con ella cualquiera puede llamar directamente a la API REST de Firestore o de Storage sin pasar por la app. Lo único que decide qué se permite son las reglas. Además, existen herramientas que buscan proyectos de Firebase abiertos a partir de apps publicadas.

Qué podría pasar en VideoFeed:

1. **Fuga de datos.** `users/{uid}` guarda el correo y el nombre de cada usuario. Con la base abierta se puede descargar la colección completa.
2. **Vandalismo y trampas.** Se puede poner `likes` en cualquier número, cambiar el título o el `autorUid` de videos ajenos, o borrar la colección `videos` y los archivos de Storage. Los límites de la app (60 s, 50 MB, título obligatorio) no sirven, porque quien ataca no usa la app.
3. **Costos.** El proyecto está en el plan Blaze. Alguien puede subir gigas a Storage o descargarlos en bucle hasta salir de la cuota gratuita. La alerta de presupuesto de USD 1 solo avisa por correo, no detiene el servicio.
4. **Alojamiento de contenido ajeno.** El bucket puede usarse para guardar y repartir archivos ilegales o malware con las URLs del proyecto, y eso puede terminar en la suspensión del proyecto por parte de Google.
5. **La fecha no protege.** Durante esos 30 días la base está abierta, y los daños anteriores toman minutos. Cuando vence, se deniega todo y la app deja de funcionar de golpe. La salida rápida suele ser extender la fecha o poner `if true`, y así la base queda abierta para siempre.

Qué hacer en su lugar (lo que ya plantea este repo):

- Crear la base en modo de producción, que deniega todo, y publicar desde el inicio `firestore.rules` y `storage.rules`. Esas reglas exigen sesión iniciada, que cada quien escriba solo lo suyo (`autorUid == request.auth.uid`, carpeta `videos/{uid}/`), que los likes cambien de uno en uno y que los archivos sean video de hasta 50 MB.
- Publicarlas con `firebase deploy --only firestore:rules,storage` en vez de copiarlas a mano en la consola. `firebase.json` ya apunta a los dos archivos, así que lo que corre en Firebase sería lo mismo que está en el repo.
- Probarlas en el Emulator Suite de Firebase antes de publicarlas.
- Agregar App Check (Play Integrity en Android) para que solo la app real pueda usar la API. App Check complementa a las reglas, no las reemplaza.

Lo que las reglas actuales todavía no cubren:

- Cualquier usuario con sesión puede leer `users` completo, y como el registro es abierto, basta con crear una cuenta para ver los correos de todos.
- La regla de likes acepta +1 sin comprobar que exista `videos/{videoId}/likes/{uid}`, así que una misma persona puede inflar el contador repitiendo la operación. Se puede amarrar el cambio del contador al documento del like con `exists()` y `existsAfter()`.
- Storage valida el `contentType` que declara el cliente, no el contenido real del archivo.
