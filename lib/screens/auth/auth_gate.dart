// auth_gate.dart
//
// Puerta de autenticacion global. Escucha authStateChanges mediante un
// StreamBuilder: sin usuario muestra el login; con usuario muestra la app. Al
// iniciar o cerrar sesion el stream emite y la pantalla cambia sola, sin
// navegacion manual.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../repositories/auth_repository.dart';
import '../../repositories/auth_repository_factory.dart';
import '../home/firebase_check_screen.dart';
import 'login_screen.dart';

class AuthGate extends StatefulWidget {
  /// Repositorio inyectable; si es null se crea con el factory (Firebase).
  final AuthRepository? repositorio;

  const AuthGate({super.key, this.repositorio});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final AuthRepository _repositorio;

  @override
  void initState() {
    super.initState();
    _repositorio =
        widget.repositorio ?? AuthRepositoryFactory.crear(AuthBackend.firebase);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _repositorio.cambiosDeUsuario,
      builder: (context, snapshot) {
        // snapshot.hasData define la rama: usuario presente o no.
        if (snapshot.hasData) {
          return FirebaseCheckScreen(
            onCerrarSesion: _repositorio.cerrarSesion,
          );
        }
        return LoginScreen(repositorio: _repositorio);
      },
    );
  }
}
