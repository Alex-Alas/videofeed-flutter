// main.dart
//
// Punto de entrada de VideoFeed. El orden de inicialización es obligatorio
// (punto 1 de la actividad de la Clase 23):
//   1) WidgetsFlutterBinding.ensureInitialized()
//   2) await Firebase.initializeApp(...)
//   3) runApp(...)

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'config/theme/app_theme.dart';
import 'firebase_options.dart';
import 'presentation/screens/auth/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const VideoFeedApp());
}

class VideoFeedApp extends StatelessWidget {
  const VideoFeedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VideoFeed',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.claro(),
      darkTheme: AppTheme.oscuro(),
      // AuthGate decide login o feed segun authStateChanges.
      home: const AuthGate(),
    );
  }
}
