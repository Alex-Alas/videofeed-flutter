// main_demo.dart
//
// Modo demo: abre el feed con FakeVideoRepository, sin login ni Firebase.
// Sirve para trabajar la UI del feed sin crear datos en el proyecto real.
//
//   flutter run -t lib/main_demo.dart
//
// Los likes viven en memoria y el botón de subir no aparece.

import 'package:flutter/material.dart';

import 'config/theme/app_theme.dart';
import 'infrastructure/repositories/fake_video_repository.dart';
import 'presentation/screens/feed/feed_screen.dart';

void main() {
  runApp(
    MaterialApp(
      title: 'VideoFeed (demo)',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.claro(),
      darkTheme: AppTheme.oscuro(),
      home: FeedScreen(
        repositorio: FakeVideoRepository(),
        uid: 'demo',
        nombreUsuario: 'Demo',
      ),
    ),
  );
}
