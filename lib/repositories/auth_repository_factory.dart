// auth_repository_factory.dart
//
// Punto unico de construccion del repositorio. La UI pide el repositorio segun
// el backend deseado y la fabrica inyecta el datasource correcto; asi la UI no
// conoce ninguna implementacion concreta.

import '../services/auth_service.dart';
import 'auth_repository.dart';

/// Backends disponibles para la autenticacion.
enum AuthBackend { firebase }

class AuthRepositoryFactory {
  /// Crea un AuthRepository con el datasource del backend indicado.
  static AuthRepository crear(AuthBackend backend) {
    switch (backend) {
      case AuthBackend.firebase:
        return AuthRepository(AuthService());
    }
  }
}
