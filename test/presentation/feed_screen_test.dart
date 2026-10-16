// feed_screen_test.dart
//
// Pruebas de FeedScreen con FakeVideoRepository: estados de carga, vacío y
// error, y botones de la barra superior. No se monta el reproductor (necesita
// la plataforma), por eso los casos con videos se prueban en video_buttons_test.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:videofeed/infrastructure/datasources/storage_service.dart';
import 'package:videofeed/infrastructure/repositories/fake_video_repository.dart';
import 'package:videofeed/presentation/screens/feed/feed_screen.dart';
import 'package:videofeed/presentation/widgets/shared/feed_vacio.dart';

class _RepositorioConError extends FakeVideoRepository {
  _RepositorioConError() : super(videosIniciales: []);

  @override
  Stream<List<Video>> observarFeed({int limite = 20}) =>
      Stream.error(Exception('sin red'));
}

class _RepositorioQueNoEmite extends FakeVideoRepository {
  _RepositorioQueNoEmite() : super(videosIniciales: []);

  @override
  Stream<List<Video>> observarFeed({int limite = 20}) =>
      StreamController<List<Video>>().stream;
}

void main() {
  Widget montar(
    VideoRepository repositorio, {
    StorageService? storage,
    Future<void> Function()? onCerrarSesion,
  }) {
    return MaterialApp(
      home: FeedScreen(
        repositorio: repositorio,
        uid: 'uid-prueba',
        nombreUsuario: 'Prueba',
        storage: storage,
        onCerrarSesion: onCerrarSesion,
      ),
    );
  }

  testWidgets('mientras no hay datos muestra un indicador de carga',
      (tester) async {
    await tester.pumpWidget(montar(_RepositorioQueNoEmite()));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('sin videos muestra el estado vacío', (tester) async {
    await tester.pumpWidget(montar(FakeVideoRepository(videosIniciales: [])));
    await tester.pump();

    expect(find.byType(FeedVacio), findsOneWidget);
  });

  testWidgets('si el stream falla muestra un mensaje de error', (tester) async {
    await tester.pumpWidget(montar(_RepositorioConError()));
    await tester.pump();

    expect(find.textContaining('No se pudo cargar el feed'), findsOneWidget);
  });

  testWidgets('el botón de subir solo aparece con StorageService',
      (tester) async {
    await tester.pumpWidget(montar(FakeVideoRepository(videosIniciales: [])));
    expect(find.byKey(const Key('boton-subir')), findsNothing);

    await tester.pumpWidget(
      montar(
        FakeVideoRepository(videosIniciales: []),
        storage: StorageService(),
      ),
    );
    expect(find.byKey(const Key('boton-subir')), findsOneWidget);
  });

  testWidgets('el botón de cerrar sesión llama al callback', (tester) async {
    var llamadas = 0;
    await tester.pumpWidget(
      montar(
        FakeVideoRepository(videosIniciales: []),
        onCerrarSesion: () async => llamadas++,
      ),
    );

    await tester.tap(find.byIcon(Icons.logout));
    await tester.pump();

    expect(llamadas, 1);
  });
}
