// auth_data_source.dart
//
// Contrato del datasource de autenticacion. La capa de UI y el repositorio
// dependen de esta interfaz, nunca de Firebase. AuthService la implementa con
// Firebase Auth y Firestore; las pruebas la implementan con un mock.

import 'package:firebase_auth/firebase_auth.dart';

/// Error de autenticacion con un mensaje en espanol listo para la UI.
class AuthFailure implements Exception {
  final String mensaje;
  AuthFailure(this.mensaje);

  @override
  String toString() => mensaje;
}

/// Operaciones de autenticacion y perfil que debe cumplir cualquier backend.
abstract class AuthDataSource {
  /// Emite el usuario actual cada vez que cambia la sesion (null si no hay).
  Stream<User?> get cambiosDeUsuario;

  /// Usuario con sesion iniciada, o null.
  User? get usuarioActual;

  /// Crea la cuenta con correo y contrasena, y el documento users/{uid}.
  Future<void> registrarse({
    required String correo,
    required String contrasena,
    required String nombre,
  });

  /// Inicia sesion con correo y contrasena.
  Future<void> iniciarSesion({
    required String correo,
    required String contrasena,
  });

  /// Cierra la sesion actual.
  Future<void> cerrarSesion();
}
