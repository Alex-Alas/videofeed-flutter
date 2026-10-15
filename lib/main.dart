// main.dart
//
// Punto de entrada de VideoFeed. El orden de inicialización es obligatorio
// (punto 1 de la actividad de la Clase 23):
//   1) WidgetsFlutterBinding.ensureInitialized()
//   2) await Firebase.initializeApp(...)
//   3) runApp(...)

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/home/firebase_check_screen.dart';

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
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.teal,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      // TODO(A-03): reemplazar por AuthGate (StreamBuilder sobre
      // authStateChanges) cuando AuthService (A-01) esté listo.
      home: const FirebaseCheckScreen(),
    );
  }
}
