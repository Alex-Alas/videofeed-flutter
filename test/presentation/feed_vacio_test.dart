// feed_vacio_test.dart
//
// Pruebas de FeedVacio: título, botón opcional y callback.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:videofeed/presentation/widgets/shared/feed_vacio.dart';

void main() {
  Widget montar({VoidCallback? onSubirVideo}) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: FeedVacio(onSubirVideo: onSubirVideo),
      ),
    );
  }

  testWidgets('muestra el título, el subtítulo y el ícono', (tester) async {
    await tester.pumpWidget(montar());

    expect(find.text('Aún no hay videos'), findsOneWidget);
    expect(find.text('Sé el primero en subir uno'), findsOneWidget);
    expect(find.byIcon(Icons.video_library_outlined), findsOneWidget);
  });

  testWidgets('sin callback no muestra el botón', (tester) async {
    await tester.pumpWidget(montar());

    expect(find.text('Subir video'), findsNothing);
    expect(find.byIcon(Icons.add), findsNothing);
  });

  testWidgets('con callback, tocar el botón lo llama una vez', (tester) async {
    var llamadas = 0;
    await tester.pumpWidget(montar(onSubirVideo: () => llamadas++));

    expect(find.text('Subir video'), findsOneWidget);

    await tester.tap(find.text('Subir video'));
    await tester.pump();

    expect(llamadas, 1);
  });
}