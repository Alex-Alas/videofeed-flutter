// firebase_check_screen.dart
//
// Pantalla temporal: confirma que Firebase se inicializó y que el proyecto
// conectado es el del equipo. Se elimina cuando AuthGate (A-03) y la
// navegación principal (F-03) estén en main.

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class FirebaseCheckScreen extends StatelessWidget {
  /// Cierra la sesion; si es null no se muestra el boton en la barra superior.
  final Future<void> Function()? onCerrarSesion;

  const FirebaseCheckScreen({super.key, this.onCerrarSesion});

  @override
  Widget build(BuildContext context) {
    final app = Firebase.app();
    return Scaffold(
      appBar: AppBar(
        title: const Text('VideoFeed'),
        actions: [
          if (onCerrarSesion != null)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Cerrar sesion',
              onPressed: onCerrarSesion,
            ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, size: 64, color: Colors.green),
              const SizedBox(height: 16),
              Text(
                'Firebase conectado',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text('Proyecto: ${app.options.projectId}'),
            ],
          ),
        ),
      ),
    );
  }
}
