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

Si la app falla al iniciar con "Firebase todavía no está configurado", actualiza tu rama: `git pull origin main`.

## Estructura

```
lib/
  main.dart              orden de inicialización de Firebase
  firebase_options.dart  generado por flutterfire configure
  models/                Video (D-01)
  repositories/          VideoRepository + Fake y Firestore (D-01..D-03, L-01)
  services/              AuthService (A-01), StorageService (U-02)
  screens/
    auth/                Login y registro (A-02)
    feed/                Feed y reproductor (F-01..F-04)
    upload/              Subir video (U-01..U-04)
firestore.rules          reglas de Firestore (S-04, D-04)
storage.rules            reglas de Storage (S-04, D-04)
docs/                    guía de Firebase y actividad 4
```

## Cómo trabajamos

1. Antes de empezar, marca tu tarea como **En progreso** en el tablero.
2. Crea una rama desde `main` con el ID de la tarea:
   `git checkout -b feature/A-01-auth-service`
3. Haz commits pequeños y sube tu rama: `git push -u origin feature/A-01-auth-service`
4. Abre un Pull Request hacia `main` usando la plantilla. Alex (o quien tenga la tarea relacionada) lo revisa.
5. Cuando se fusione, marca la tarea como **Hecho** en el tablero.

Reglas del equipo:

- Nadie fuera de `lib/repositories` usa `FirebaseFirestore.instance` directamente.
- No se sube a `main` sin PR.
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
