// auth_gate.dart
//
// Puerta de autenticacion global. Escucha authStateChanges mediante un
// StreamBuilder: sin usuario muestra el login; con usuario muestra el feed. Al
// iniciar o cerrar sesion el stream emite y la pantalla cambia sola, sin
// navegacion manual.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../infrastructure/datasources/storage_service.dart';
import '../../../infrastructure/repositories/auth_repository.dart';
import '../../../infrastructure/repositories/auth_repository_factory.dart';
import '../../../infrastructure/repositories/firestore_video_repository.dart';
import '../feed/feed_screen.dart';
import 'login_screen.dart';

class AuthGate extends StatefulWidget {
  /// Repositorio inyectable; si es null se crea con el factory (Firebase).
  final AuthRepository? repositorio;

  /// Repositorio de videos inyectable; si es null se usa Firestore.
  final VideoRepository? videoRepositorio;

  /// Servicio de Storage inyectable; si es null se usa Firebase Storage.
  final StorageService? storage;

  const AuthGate({
    super.key,
    this.repositorio,
    this.videoRepositorio,
    this.storage,
  });

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final AuthRepository _repositorio;

  // Perezosos: solo se crean cuando hay sesion y se muestra el feed.
  late final VideoRepository _videos =
      widget.videoRepositorio ?? FirestoreVideoRepository();
  late final StorageService _storage = widget.storage ?? StorageService();

  @override
  void initState() {
    super.initState();
    _repositorio =
        widget.repositorio ?? AuthRepositoryFactory.crear(AuthBackend.firebase);
  }

  /// displayName puede llegar vacio justo despues del registro (se asigna
  /// despues de crear la cuenta), asi que se usa el correo como respaldo.
  String _nombreVisible(User usuario) {
    final nombre = usuario.displayName?.trim() ?? '';
    if (nombre.isNotEmpty) return nombre;
    final correo = usuario.email ?? '';
    if (correo.contains('@')) return correo.split('@').first;
    return 'Anónimo';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _repositorio.cambiosDeUsuario,
      builder: (context, snapshot) {
        // Mientras Firebase restaura la sesion no se muestra el login (evita
        // que aparezca un instante a quien ya tenia sesion iniciada).
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // snapshot.hasData define la rama: usuario presente o no.
        final usuario = snapshot.data;
        if (usuario != null) {
          return FeedScreen(
            repositorio: _videos,
            storage: _storage,
            uid: usuario.uid,
            nombreUsuario: _nombreVisible(usuario),
            onCerrarSesion: _repositorio.cerrarSesion,
          );
        }
        return LoginScreen(repositorio: _repositorio);
      },
    );
  }
}
