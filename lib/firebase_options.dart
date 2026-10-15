// firebase_options.dart
//
// PLANTILLA. Este archivo lo sobrescribe `flutterfire configure` (tarea
// S-02) con los valores reales del proyecto de Firebase del equipo. No lo
// edites a mano: si ves este mensaje al correr la app, falta correr ese
// comando o hacer `git pull` de main.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    throw UnsupportedError(
      'Firebase todavía no está configurado. Corre `flutterfire configure` '
      '(tarea S-02) o actualiza tu rama con `git pull origin main`.',
    );
  }
}
