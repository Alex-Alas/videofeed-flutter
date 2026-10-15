// auth_repository.dart
//
// Capa de repositorio de autenticacion. Es una clase concreta que depende de la
// interfaz AuthDataSource, no de Firebase: asi puede recibir el datasource real
// o uno falso en las pruebas. Delega cada operacion en el datasource.

import 'package:firebase_auth/firebase_auth.dart';

import '../services/auth_data_source.dart';

class AuthRepository {
  final AuthDataSource _dataSource;

  AuthRepository(this._dataSource);

  /// Cambios de sesion emitidos por el datasource.
  Stream<User?> get cambiosDeUsuario => _dataSource.cambiosDeUsuario;

  /// Usuario con sesion iniciada, o null.
  User? get usuarioActual => _dataSource.usuarioActual;

  /// Registra la cuenta y su perfil en Firestore.
  Future<void> registrarse({
    required String correo,
    required String contrasena,
    required String nombre,
  }) {
    return _dataSource.registrarse(
      correo: correo,
      contrasena: contrasena,
      nombre: nombre,
    );
  }

  /// Inicia sesion con correo y contrasena.
  Future<void> iniciarSesion({
    required String correo,
    required String contrasena,
  }) {
    return _dataSource.iniciarSesion(correo: correo, contrasena: contrasena);
  }

  /// Cierra la sesion actual.
  Future<void> cerrarSesion() => _dataSource.cerrarSesion();
}
