// auth_gate_test.dart
//
// Pruebas de AuthGate: la rama del StreamBuilder segun haya o no usuario, y el
// boton de cerrar sesion. Se simula el repositorio y se usan los mocks oficiales
// de Firebase Core para poder construir la pantalla autenticada.

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:videofeed/repositories/auth_repository.dart';
import 'package:videofeed/screens/auth/auth_gate.dart';
import 'package:videofeed/screens/auth/login_screen.dart';
import 'package:videofeed/screens/home/firebase_check_screen.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockUser extends Mock implements User {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthRepository repositorio;
  late StreamController<User?> controlador;
  late MockUser usuario;

  setUpAll(() async {
    setupFirebaseCoreMocks();
    // initializeCore del mock ya crea la app por defecto con opciones ficticias;
    // sin argumentos inicializamos sin chocar con esas opciones.
    await Firebase.initializeApp();
  });

  setUp(() {
    repositorio = MockAuthRepository();
    controlador = StreamController<User?>.broadcast();
    usuario = MockUser();
    when(() => repositorio.cambiosDeUsuario)
        .thenAnswer((_) => controlador.stream);
    when(() => repositorio.cerrarSesion()).thenAnswer((_) async {});
  });

  tearDown(() => controlador.close());

  Widget montar() =>
      MaterialApp(home: AuthGate(repositorio: repositorio));

  testWidgets('sin usuario muestra el login', (tester) async {
    await tester.pumpWidget(montar());
    controlador.add(null);
    await tester.pump();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(FirebaseCheckScreen), findsNothing);
  });

  testWidgets('con usuario muestra la app y el boton de cerrar sesion',
      (tester) async {
    await tester.pumpWidget(montar());
    controlador.add(usuario);
    await tester.pumpAndSettle();

    expect(find.byType(FirebaseCheckScreen), findsOneWidget);
    expect(find.byIcon(Icons.logout), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
  });

  testWidgets('el boton de cerrar sesion llama a cerrarSesion',
      (tester) async {
    await tester.pumpWidget(montar());
    controlador.add(usuario);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.logout));
    await tester.pump();

    verify(() => repositorio.cerrarSesion()).called(1);
  });
}
