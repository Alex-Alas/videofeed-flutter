// auth_service_test.dart
//
// Pruebas del datasource real (AuthService). Verifican el registro con creacion
// del perfil en Firestore, la traduccion de errores y el manejo de sesion. Se
// usan mocks de Firebase Auth y Firestore: no requieren Firebase inicializado.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:videofeed/services/auth_data_source.dart';
import 'package:videofeed/services/auth_service.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockUserCredential extends Mock implements UserCredential {}

class MockUser extends Mock implements User {}

// ignore: subtype_of_sealed_class
class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

// ignore: subtype_of_sealed_class
class MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

// FirebaseAuthException tiene constructor protegido: un subclass en la prueba
// puede invocarlo para simular errores de Firebase.
class _ErrorAutenticacion extends FirebaseAuthException {
  _ErrorAutenticacion(String code) : super(code: code);
}

void main() {
  late MockFirebaseAuth auth;
  late MockFirebaseFirestore firestore;
  late MockUserCredential credencial;
  late MockUser user;
  late MockCollectionReference usuarios;
  late MockDocumentReference documento;
  late AuthService servicio;

  setUp(() {
    auth = MockFirebaseAuth();
    firestore = MockFirebaseFirestore();
    credencial = MockUserCredential();
    user = MockUser();
    usuarios = MockCollectionReference();
    documento = MockDocumentReference();
    servicio = AuthService(firebaseAuth: auth, firestore: firestore);
  });

  group('registrarse', () {
    test('crea la cuenta, fija el displayName y escribe users/{uid}', () async {
      when(() => user.uid).thenReturn('uid-123');
      when(() => auth.createUserWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => credencial);
      when(() => credencial.user).thenReturn(user);
      when(() => user.updateDisplayName(any())).thenAnswer((_) async {});
      when(() => firestore.collection('users')).thenReturn(usuarios);
      when(() => usuarios.doc('uid-123')).thenReturn(documento);
      when(() => documento.set(any())).thenAnswer((_) async {});

      await servicio.registrarse(
        correo: 'ana@correo.com',
        contrasena: 'secreto123',
        nombre: 'Ana Maria',
      );

      verify(() => auth.createUserWithEmailAndPassword(
            email: 'ana@correo.com',
            password: 'secreto123',
          )).called(1);
      verify(() => user.updateDisplayName('Ana Maria')).called(1);

      final datos = verify(() => documento.set(captureAny())).captured.single
          as Map<String, dynamic>;
      expect(datos['email'], 'ana@correo.com');
      expect(datos['nombre'], 'Ana Maria');
      expect(datos['creadoEn'], isA<FieldValue>());
    });

    test('traduce email-already-in-use a AuthFailure en espanol', () async {
      when(() => auth.createUserWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(_ErrorAutenticacion('email-already-in-use'));

      expect(
        () => servicio.registrarse(
          correo: 'ana@correo.com',
          contrasena: 'secreto123',
          nombre: 'Ana',
        ),
        throwsA(
          isA<AuthFailure>().having(
            (e) => e.mensaje,
            'mensaje',
            'Ya existe una cuenta registrada con ese correo.',
          ),
        ),
      );
    });
  });

  group('iniciarSesion', () {
    test('delega en Firebase con el correo y la contrasena', () async {
      when(() => auth.signInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => credencial);

      await servicio.iniciarSesion(
        correo: 'ana@correo.com',
        contrasena: 'secreto123',
      );

      verify(() => auth.signInWithEmailAndPassword(
            email: 'ana@correo.com',
            password: 'secreto123',
          )).called(1);
    });

    test('traduce wrong-password a AuthFailure en espanol', () async {
      when(() => auth.signInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(_ErrorAutenticacion('wrong-password'));

      expect(
        () => servicio.iniciarSesion(
          correo: 'ana@correo.com',
          contrasena: 'mala',
        ),
        throwsA(isA<AuthFailure>()),
      );
    });
  });

  test('cerrarSesion llama a signOut', () async {
    when(() => auth.signOut()).thenAnswer((_) async {});

    await servicio.cerrarSesion();

    verify(() => auth.signOut()).called(1);
  });
}
