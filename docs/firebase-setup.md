# Configuración de Firebase (tareas S-02 a S-06)

Esta guía la sigue una sola persona (Alex) con su cuenta de Google. El resto del equipo solo hace `git pull` cuando termine.

## 1. Crear el proyecto (S-02)

1. Entra a <https://console.firebase.google.com> y elige **Agregar proyecto**.
2. Nombre sugerido: `videofeed-grupo`. Firebase le agrega un sufijo al ID si ya existe; anota el **ID del proyecto**.
3. Google Analytics: desactívalo, no lo necesitamos.

## 2. Plan Blaze con costo $0 (solo para Storage)

Storage en proyectos nuevos requiere el plan **Blaze**. El uso del proyecto cabe en la cuota gratuita mensual de Cloud Storage (5 GB guardados, 100 GB de descarga, 5,000 subidas y 50,000 lecturas al mes), así que el costo esperado es $0.

1. Abajo a la izquierda, **Spark → Actualizar → Blaze** y vincula la tarjeta.
2. Crea una **alerta de presupuesto** de USD 1. Ojo: la alerta solo avisa por correo, no corta el servicio.
3. La cuota gratuita solo aplica a buckets en `us-central1`, `us-east1` o `us-west1`. Por eso Storage se crea en **US-CENTRAL1** (paso 4).

## 3. Authentication (S-03)

**Compilación → Authentication → Comenzar → Método de acceso → Correo electrónico/contraseña → Habilitar → Guardar.**
Deja desactivado "Vínculo de correo electrónico".

## 4. Firestore y Storage (S-04)

1. **Compilación → Firestore Database → Crear base de datos**. Elige una ubicación (por ejemplo `nam5 (us-central)`) y **modo de producción**.
2. En la pestaña **Reglas**, pega el contenido de `firestore.rules` del repo y **Publicar**.
3. **Compilación → Storage → Comenzar**, ubicación **US-CENTRAL1** (no otra: fuera de esas regiones no hay cuota gratis).
4. En **Reglas**, pega `storage.rules` y **Publicar**.

No uses el modo de prueba: deja la base abierta a cualquiera con la configuración del proyecto durante 30 días (es justo lo que pide analizar la actividad 4).

## 5. Conectar Flutter con FlutterFire (S-02 y S-06)

En tu computadora, dentro del repo clonado:

```bash
npm install -g firebase-tools          # si no lo tienes
firebase login
dart pub global activate flutterfire_cli
flutterfire configure --project=<ID-del-proyecto> --platforms=android
```

Si alguien del equipo usa Mac, agrega `ios` a `--platforms` (`android,ios`).

El comando genera o modifica:

- `lib/firebase_options.dart` (reemplaza la plantilla)
- `android/app/google-services.json`
- los archivos Gradle de Android (plugin de google-services)

Luego:

```bash
flutter pub get
flutter run
```

Debes ver la pantalla **"Firebase conectado"** con el ID del proyecto. Eso confirma el orden de inicialización de `main.dart`.

Sube todo a `main`:

```bash
git checkout -b feature/S-02-firebase
git add -A
git commit -m "S-02: conectar el proyecto de Firebase con FlutterFire"
git push -u origin feature/S-02-firebase
```

y fusiona el PR. Estos archivos sí van en el repo: las claves de `firebase_options.dart` identifican al proyecto, no dan acceso; la protección real son las reglas.

## 6. Dar acceso al equipo (S-05)

- **Firebase:** ⚙ Configuración del proyecto → **Usuarios y permisos → Agregar miembro** → correo de cada compañero → rol **Editor**.
- **GitHub:** repo → **Settings → Collaborators → Add people** (los 5).
- **Tablero:** botón Compartir → invitar por correo con permiso **Editor**.
- Escribe el link del repo y el ID del proyecto en "Editar nombres del equipo y enlaces" del tablero.
