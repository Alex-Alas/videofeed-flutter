// login_screen_test.dart
//
// Pruebas del formulario de login/registro. Usa un AuthRepository simulado para
// verificar validaciones y que se llame al repositorio correcto sin tocar
// Firebase.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:videofeed/infrastructure/repositories/auth_repository.dart';
import 'package:videofeed/presentation/screens/auth/login_screen.dart';
import 'package:videofeed/domain/datasources/auth_data_source.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repositorio;

  setUp(() {
    repositorio = MockAuthRepository();
  });

  Widget montar() => MaterialApp(home: LoginScreen(repositorio: repositorio));

  testWidgets('valida campos vacios y no llama al repositorio',
      (tester) async {
    await tester.pumpWidget(montar());

    await tester.tap(find.byKey(const Key('boton-enviar')));
    await tester.pump();

    expect(find.text('Ingresa tu correo.'), findsOneWidget);
    expect(find.text('Ingresa tu contrasena.'), findsOneWidget);
    verifyNever(() => repositorio.iniciarSesion(
          correo: any(named: 'correo'),
          contrasena: any(named: 'contrasena'),
        ));
  });

  testWidgets('rechaza un correo con formato invalido', (tester) async {
    await tester.pumpWidget(montar());

    await tester.enterText(find.byKey(const Key('campo-correo')), 'sin-arroba');
    await tester.enterText(
        find.byKey(const Key('campo-contrasena')), 'secreto123');
    await tester.tap(find.byKey(const Key('boton-enviar')));
    await tester.pump();

    expect(find.text('Correo con formato invalido.'), findsOneWidget);
    verifyNever(() => repositorio.iniciarSesion(
          correo: any(named: 'correo'),
          contrasena: any(named: 'contrasena'),
        ));
  });

  testWidgets('inicia sesion con credenciales validas', (tester) async {
    when(() => repositorio.iniciarSesion(
          correo: any(named: 'correo'),
          contrasena: any(named: 'contrasena'),
        )).thenAnswer((_) async {});

    await tester.pumpWidget(montar());
    await tester.enterText(
        find.byKey(const Key('campo-correo')), 'ana@correo.com');
    await tester.enterText(
        find.byKey(const Key('campo-contrasena')), 'secreto123');
    await tester.ensureVisible(find.byKey(const Key('boton-enviar')));
    await tester.tap(find.byKey(const Key('boton-enviar')));
    await tester.pumpAndSettle();

    verify(() => repositorio.iniciarSesion(
          correo: 'ana@correo.com',
          contrasena: 'secreto123',
        )).called(1);
  });

  testWidgets('el modo registro pide el nombre y llama a registrarse',
      (tester) async {
    when(() => repositorio.registrarse(
          correo: any(named: 'correo'),
          contrasena: any(named: 'contrasena'),
          nombre: any(named: 'nombre'),
        )).thenAnswer((_) async {});

    await tester.pumpWidget(montar());
    await tester.tap(find.byKey(const Key('boton-alternar')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('campo-nombre')), findsOneWidget);

    await tester.enterText(
        find.byKey(const Key('campo-nombre')), 'Ana Maria');
    await tester.enterText(
        find.byKey(const Key('campo-correo')), 'ana@correo.com');
    await tester.enterText(
        find.byKey(const Key('campo-contrasena')), 'secreto123');
    await tester.ensureVisible(find.byKey(const Key('boton-enviar')));
    await tester.tap(find.byKey(const Key('boton-enviar')));
    await tester.pumpAndSettle();

    verify(() => repositorio.registrarse(
          correo: 'ana@correo.com',
          contrasena: 'secreto123',
          nombre: 'Ana Maria',
        )).called(1);
  });

  testWidgets('muestra el mensaje de AuthFailure en un SnackBar',
      (tester) async {
    when(() => repositorio.iniciarSesion(
          correo: any(named: 'correo'),
          contrasena: any(named: 'contrasena'),
        )).thenThrow(AuthFailure('Correo o contrasena incorrectos.'));

    await tester.pumpWidget(montar());
    await tester.enterText(
        find.byKey(const Key('campo-correo')), 'ana@correo.com');
    await tester.enterText(
        find.byKey(const Key('campo-contrasena')), 'secreto123');
    await tester.ensureVisible(find.byKey(const Key('boton-enviar')));
    await tester.tap(find.byKey(const Key('boton-enviar')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Correo o contrasena incorrectos.'), findsOneWidget);
  });
}
