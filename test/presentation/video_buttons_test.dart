// video_buttons_test.dart
//
// Pruebas del botón de like (L-02) contra FakeVideoRepository.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:videofeed/infrastructure/repositories/fake_video_repository.dart';
import 'package:videofeed/presentation/widgets/shared/video_buttons.dart';

void main() {
  const video = Video(
    id: 'v1',
    autorUid: 'autor',
    autorNombre: 'Autor',
    titulo: 'Un video',
    videoUrl: 'https://ejemplo.com/v1.mp4',
    storagePath: 'videos/autor/v1.mp4',
    likes: 3,
  );

  late FakeVideoRepository repositorio;

  setUp(() {
    repositorio = FakeVideoRepository(videosIniciales: [video]);
  });

  tearDown(() => repositorio.dispose());

  Widget montar() => MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.black,
          body: VideoButtons(
            video: video,
            repositorio: repositorio,
            uid: 'yo',
          ),
        ),
      );

  testWidgets('muestra el contador y el corazón vacío sin like',
      (tester) async {
    await tester.pumpWidget(montar());
    await tester.pump();

    expect(find.text('3'), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border), findsOneWidget);
  });

  testWidgets('tocar el corazón da like y otro toque lo quita',
      (tester) async {
    await tester.pumpWidget(montar());
    await tester.pump();

    await tester.tap(find.byKey(const Key('boton-like')));
    await tester.pump();
    await tester.pump();

    expect(repositorio.tieneLike('v1', 'yo'), isTrue);
    expect(find.byIcon(Icons.favorite), findsOneWidget);

    await tester.tap(find.byKey(const Key('boton-like')));
    await tester.pump();
    await tester.pump();

    expect(repositorio.tieneLike('v1', 'yo'), isFalse);
    expect(find.byIcon(Icons.favorite_border), findsOneWidget);
  });
}
