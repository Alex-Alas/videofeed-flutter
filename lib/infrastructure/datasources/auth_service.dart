// auth_service.dart
//
// Datasource real de autenticacion: envuelve Firebase Auth y Firestore.
// Traduce los codigos de FirebaseAuthException a mensajes en espanol y crea el
// documento users/{uid} justo despues del registro.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/datasources/auth_data_source.dart';

class AuthService implements AuthDataSource {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthService({FirebaseAuth? firebaseAuth, FirebaseFirestore? firestore})
      : _auth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  // userChanges (no authStateChanges) tambien emite cuando cambia el perfil:
  // asi el feed recibe el displayName que se asigna justo despues del registro.
  Stream<User?> get cambiosDeUsuario => _auth.userChanges();

  @override
  User? get usuarioActual => _auth.currentUser;

  @override
  Future<void> registrarse({
    required String correo,
    required String contrasena,
    required String nombre,
  }) async {
    try {
      final credencial = await _auth.createUserWithEmailAndPassword(
        email: correo.trim(),
        password: contrasena,
      );

      final user = credencial.user;
      if (user == null) {
        throw AuthFailure('No se pudo crear la cuenta.');
      }

      // Nombre visible de Firebase Auth.
      await user.updateDisplayName(nombre.trim());

      // Perfil en Firestore: un documento por usuario registrado.
      await _firestore.collection('users').doc(user.uid).set({
        'email': correo.trim(),
        'nombre': nombre.trim(),
        'creadoEn': FieldValue.serverTimestamp(),
      });
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mensajeParaCodigo(e.code));
    } on FirebaseException catch (e) {
      throw AuthFailure('No se pudo guardar el perfil (codigo: ${e.code}).');
    }
  }

  @override
  Future<void> iniciarSesion({
    required String correo,
    required String contrasena,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: correo.trim(),
        password: contrasena,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mensajeParaCodigo(e.code));
    }
  }

  @override
  Future<void> cerrarSesion() => _auth.signOut();

  String _mensajeParaCodigo(String codigo) {
    switch (codigo) {
      case 'email-already-in-use':
        return 'Ya existe una cuenta registrada con ese correo.';
      case 'invalid-email':
        return 'El correo electronico no tiene un formato valido.';
      case 'weak-password':
        return 'La contrasena es demasiado debil (minimo 6 caracteres).';
      case 'user-not-found':
        return 'No existe ninguna cuenta registrada con ese correo.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Correo o contrasena incorrectos.';
      case 'user-disabled':
        return 'Esta cuenta fue deshabilitada. Contacta al administrador.';
      case 'too-many-requests':
        return 'Demasiados intentos fallidos. Intenta de nuevo mas tarde.';
      default:
        return 'No se pudo completar la operacion (codigo: $codigo).';
    }
  }
}
