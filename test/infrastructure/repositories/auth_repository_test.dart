// auth_repository_test.dart
//
// Pruebas de AuthRepository usando MockAuthService: comprueban que el
// repositorio solo delega en la interfaz AuthDataSource y propaga AuthFailure.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:videofeed/infrastructure/repositories/auth_repository.dart';
import 'package:videofeed/domain/datasources/auth_data_source.dart';

import '../../mocks/mock_auth_service.dart';

class MockUser extends Mock implements User {}

void main() {
  late MockAuthService dataSource;
  late AuthRepository repositorio;

  setUp(() {
    dataSource = MockAuthService();
    repositorio = AuthRepository(dataSource);
  });

  test('registrarse delega en el datasource con todos los datos', () async {
    when(() => dataSource.registrarse(
          correo: any(named: 'correo'),
          contrasena: any(named: 'contrasena'),
          nombre: any(named: 'nombre'),
        )).thenAnswer((_) async {});

    await repositorio.registrarse(
      correo: 'ana@correo.com',
      contrasena: 'secreto123',
      nombre: 'Ana',
    );

    verify(() => dataSource.registrarse(
          correo: 'ana@correo.com',
          contrasena: 'secreto123',
          nombre: 'Ana',
        )).called(1);
  });

  test('iniciarSesion delega en el datasource', () async {
    when(() => dataSource.iniciarSesion(
          correo: any(named: 'correo'),
          contrasena: any(named: 'contrasena'),
        )).thenAnswer((_) async {});

    await repositorio.iniciarSesion(
      correo: 'ana@correo.com',
      contrasena: 'secreto123',
    );

    verify(() => dataSource.iniciarSesion(
          correo: 'ana@correo.com',
          contrasena: 'secreto123',
        )).called(1);
  });

  test('cerrarSesion delega en el datasource', () async {
    when(() => dataSource.cerrarSesion()).thenAnswer((_) async {});

    await repositorio.cerrarSesion();

    verify(() => dataSource.cerrarSesion()).called(1);
  });

  test('propaga el AuthFailure del datasource', () async {
    when(() => dataSource.iniciarSesion(
          correo: any(named: 'correo'),
          contrasena: any(named: 'contrasena'),
        )).thenThrow(AuthFailure('Correo o contrasena incorrectos.'));

    expect(
      () => repositorio.iniciarSesion(correo: 'ana@correo.com', contrasena: 'x'),
      throwsA(isA<AuthFailure>()),
    );
  });

  test('cambiosDeUsuario expone el stream del datasource', () {
    final usuario = MockUser();
    final controlador = Stream<User?>.value(usuario);
    when(() => dataSource.cambiosDeUsuario).thenAnswer((_) => controlador);

    expect(repositorio.cambiosDeUsuario, emits(usuario));
  });
}
