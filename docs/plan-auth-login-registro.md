# Plan: Login, registro y estado global de autenticación (VideoFeed)

Tareas cubiertas: A-01 (AuthService), A-02 (Login y registro), A-03 (AuthGate).
Rama de trabajo: `feature/auth-service` (ya activa).

## 1. Decisiones acordadas

1. El registro pide **nombre** ademas de correo y contrasena. El nombre se guarda
   como `displayName` de Firebase Auth y como campo `nombre` en `users/{uid}`.
2. Con usuario autenticado **no se crea una pantalla nueva** (el Home/Feed le toca
   a otro miembro). Se reutiliza la pantalla temporal existente y solo se agrega
   el boton de cerrar sesion en la barra superior.
3. Pruebas con **mocktail** (sin generacion de codigo).
4. Se mantiene el tema actual (`colorSchemeSeed: Colors.teal`, Material 3).
5. Patron repository: pantalla usa el **factory**; el repositorio es una **clase
   concreta** que depende de la **interfaz `AuthDataSource`**; `AuthService` se
   actualiza para implementar esa interfaz; el factory inyecta la dependencia
   segun la clave del backend (`firebase`).
6. Estado de autenticacion global solo con **StreamBuilder**, sin librerias.

## 2. Arquitectura (flujo de dependencias)

```
LoginScreen / AuthGate            (UI)
        | usa
        v
AuthRepositoryFactory.crear(AuthBackend.firebase)
        | construye
        v
AuthRepository( AuthDataSource )  (capa repositorio, clase concreta)
        ^ implementa
        |
AuthService implements AuthDataSource   (datasource real: Firebase Auth + Firestore)
```

- La UI nunca conoce `FirebaseAuth` ni `FirebaseFirestore`; solo habla con
  `AuthRepository`.
- `AuthRepository` no sabe si el datasource es Firebase o un fake: depende de la
  interfaz `AuthDataSource`. Esto es lo que permite un futuro backend alterno y
  las pruebas.

## 3. Archivos

### Nuevos

| Archivo | Contenido |
| --- | --- |
| `lib/services/auth_data_source.dart` | Interfaz abstracta `AuthDataSource` y excepcion `AuthFailure`. |
| `lib/repositories/auth_repository.dart` | Clase concreta `AuthRepository` que envuelve un `AuthDataSource`. |
| `lib/repositories/auth_repository_factory.dart` | `enum AuthBackend { firebase }` y `AuthRepositoryFactory.crear(...)`. |
| `lib/screens/auth/auth_gate.dart` | `AuthGate` con `StreamBuilder<User?>` sobre `cambiosDeUsuario`. |
| `test/auth_service_test.dart` | Pruebas del datasource (registro + perfil, errores, sesion). |
| `test/auth_repository_test.dart` | Pruebas del repositorio con `test/mocks/mock_auth_service.dart`. |
| `test/mocks/mock_auth_service.dart` | Doble de `AuthDataSource` con mocktail para las pruebas del repositorio. |
| `test/auth_gate_test.dart` | Widget test: sin usuario -> login, con usuario -> app + boton cerrar sesion. |
| `test/login_screen_test.dart` | Widget test del formulario (validaciones y llamadas al repo). |

### Modificados

| Archivo | Cambio |
| --- | --- |
| `lib/services/auth_service.dart` | `implements AuthDataSource`; `registrarse` recibe `nombre`, setea `displayName` y crea `users/{uid}`; recibe `FirebaseFirestore` inyectable. Se conserva la traduccion de codigos a espanol. |
| `lib/screens/auth/login_screen.dart` | Formulario real de login/registro con validaciones y manejo de error/carga. |
| `lib/screens/home/firebase_check_screen.dart` | Parametro opcional `onCerrarSesion` para mostrar el boton de cerrar sesion en la `AppBar`. |
| `lib/main.dart` | `home: AuthGate()` en lugar de `FirebaseCheckScreen`. |
| `pubspec.yaml` | `mocktail` en `dev_dependencies`. |

## 4. Contratos

### `AuthDataSource` (interfaz)

```dart
abstract class AuthDataSource {
  Stream<User?> get cambiosDeUsuario;
  User? get usuarioActual;
  Future<void> registrarse({
    required String correo,
    required String contrasena,
    required String nombre,
  });
  Future<void> iniciarSesion({
    required String correo,
    required String contrasena,
  });
  Future<void> cerrarSesion();
}
```

`AuthFailure` (mensaje en espanol) se define junto a la interfaz para que la capa
repository y la UI puedan capturarla sin conocer Firebase.

### `AuthRepository` (clase concreta)

Delega cada metodo en el `AuthDataSource` inyectado y expone la misma superficie.
No traduce errores: recibe el `AuthFailure` del datasource y lo propaga.

### `AuthRepositoryFactory`

```dart
enum AuthBackend { firebase }

class AuthRepositoryFactory {
  static AuthRepository crear(AuthBackend backend) {
    switch (backend) {
      case AuthBackend.firebase:
        return AuthRepository(AuthService());
    }
  }
}
```

## 5. `AuthService.registrarse` (paso a paso)

1. `createUserWithEmailAndPassword(correo, contrasena)`.
2. `user.updateDisplayName(nombre)`.
3. `Firestore.collection('users').doc(uid).set({ 'email': ..., 'nombre': ...,
   'creadoEn': FieldValue.serverTimestamp() })`, justo despues del registro.
4. Cualquier `FirebaseAuthException` o fallo de Firestore se traduce a
   `AuthFailure` con mensaje en espanol.

> Nota de equipo: la regla "nadie fuera de `lib/repositories` usa
> `FirebaseFirestore.instance`" se respeta en lo esencial: la instancia se inyecta
> por constructor y solo el factory/servicio la crea, no la UI. El requisito pide
> expresamente que el documento `users/{uid}` se cree desde `auth_service.dart`,
> por lo que el acceso a Firestore queda encapsulado en ese servicio.

## 6. `AuthGate` y cierre de sesion

```dart
StreamBuilder<User?>(
  stream: _repositorio.cambiosDeUsuario,
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      return FirebaseCheckScreen(onCerrarSesion: _repositorio.cerrarSesion);
    }
    return LoginScreen(repositorio: _repositorio);
  },
)
```

- Sin usuario -> `LoginScreen`. Con usuario -> app (pantalla temporal actual).
- `snapshot.hasData` decide la rama; el estado se actualiza solo al iniciar o
  cerrar sesion, asi que "la pantalla se cierra sola" (no hay `Navigator.push`
  manual que limpiar).
- El boton de cerrar sesion vive en la `AppBar` de la pantalla autenticada y llama
  a `AuthRepository.cerrarSesion()`; el stream emite y el `StreamBuilder` redibuja
  el login.
- Tanto `AuthGate` como `LoginScreen` aceptan un `AuthRepository?` opcional: si es
  `null` usan `AuthRepositoryFactory.crear(AuthBackend.firebase)`; en pruebas se
  inyecta el repositorio con el mock.

## 7. UI de `LoginScreen` (sin overflow)

- `Scaffold` + `SafeArea` + `LayoutBuilder` + `SingleChildScrollView` con
  `ConstrainedBox(minHeight)` y `IntrinsicHeight` para que en pantallas bajas o
  con teclado abierto el contenido haga scroll en vez de desbordar.
- `Form` con `GlobalKey<FormState>`; campos `TextFormField` para correo,
  contrasena y (solo en modo registro) nombre.
- `AutovalidateMode.onUserInteraction`, validacion de correo con
  `RegExp`, contrasena minimo 6.
- Encabezado llamativo con el nombre de la app, campos con bordes redondeados y
  boton principal a ancho completo; `CircularProgressIndicator` en el boton
  mientras carga y `SnackBar` con el `AuthFailure.mensaje` si falla.
- Enlace para alternar entre "Iniciar sesion" y "Crear cuenta" con `setState`.

## 8. TDD (orden de implementacion)

1. Escribir `test/auth_service_test.dart` con mocks de `FirebaseAuth`,
   `FirebaseFirestore` y `User` (mocktail) -> falla.
2. Implementar `auth_data_source.dart` y actualizar `auth_service.dart` -> pasa.
3. Escribir `test/mocks/mock_auth_service.dart` y `test/auth_repository_test.dart`
   -> falla.
4. Implementar `auth_repository.dart` y `auth_repository_factory.dart` -> pasa.
5. Escribir `test/login_screen_test.dart` y `test/auth_gate_test.dart` -> falla.
6. Implementar `login_screen.dart`, `auth_gate.dart` y el boton de cierre en
   `firebase_check_screen.dart` -> pasan.
7. `flutter analyze` y `flutter test` en verde.

Casos de prueba minimos:

- `registrarse` crea el usuario, setea `displayName` y escribe `users/{uid}` con
  `email`, `nombre` y `creadoEn`.
- `registrarse`/`iniciarSesion` traducen `FirebaseAuthException` a `AuthFailure`
  (p. ej. `email-already-in-use`, `wrong-password`).
- El repositorio delega en el datasource y propaga `AuthFailure`.
- El factory `crear(AuthBackend.firebase)` devuelve un `AuthRepository`.
- `AuthGate` con stream vacio muestra el login; con usuario muestra la app y el
  boton de cerrar sesion; al pulsarlo se llama `cerrarSesion`.
- `LoginScreen` valida campos vacios/correo invalido antes de llamar al repo.

## 9. Criterios de aceptacion

- [ ] La UI de auth usa `AuthRepository` creado por el factory; nadie en UI toca
      Firebase directamente.
- [ ] Existen `AuthDataSource` (interfaz), `AuthRepository` (concreto) y
      `AuthRepositoryFactory`.
- [ ] `AuthService implements AuthDataSource` y crea `users/{uid}` en el registro.
- [ ] `AuthGate` usa `StreamBuilder` + `snapshot.hasData`, muestra login o la app,
      y la barra superior tiene el boton de cerrar sesion.
- [ ] Cambiar de estado entra o sale de la app sin navegacion manual.
- [ ] Sin overflow en pantallas pequenas / con teclado.
- [ ] `flutter analyze` sin issues y `flutter test` en verde.
- [ ] Comentarios breves, precisos, sin emojis (espanol, como el resto del repo).
