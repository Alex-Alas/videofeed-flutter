// storage_service.dart
//
// Tarea U-02: sube el video a `videos/{uid}/{timestamp}.{ext}`, reporta el
// progreso y devuelve la URL de descarga y la ruta en Storage.
//
// Igual que con Firestore, nadie fuera de lib/infrastructure usa
// FirebaseStorage.instance directamente.

import 'dart:async';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

/// Resultado de una subida: lo que necesita el documento `videos/{videoId}`.
class SubidaVideo {
  final String url;
  final String storagePath;

  const SubidaVideo({required this.url, required this.storagePath});
}

/// Error de subida con un mensaje en español listo para la UI.
class StorageFailure implements Exception {
  final String mensaje;
  StorageFailure(this.mensaje);

  @override
  String toString() => mensaje;
}

class StorageService {
  /// Límite acordado en U-04 y en storage.rules.
  static const int maxBytes = 50 * 1024 * 1024;

  final FirebaseStorage? _storageInyectado;

  StorageService({FirebaseStorage? storage}) : _storageInyectado = storage;

  // Perezoso: crear el servicio no toca Firebase (útil en pruebas y modo demo).
  FirebaseStorage get _storage => _storageInyectado ?? FirebaseStorage.instance;

  /// Sube [archivo] a la carpeta del usuario [uid].
  ///
  /// [onProgreso] recibe valores de 0.0 a 1.0 mientras se transfiere.
  Future<SubidaVideo> subirVideo({
    required File archivo,
    required String uid,
    void Function(double progreso)? onProgreso,
  }) async {
    final extension = _extension(archivo.path);
    final ruta =
        'videos/$uid/${DateTime.now().millisecondsSinceEpoch}.$extension';
    final ref = _storage.ref(ruta);

    final tarea = ref.putFile(
      archivo,
      SettableMetadata(contentType: _contentType(extension)),
    );

    final suscripcion = tarea.snapshotEvents.listen((snapshot) {
      if (snapshot.totalBytes > 0) {
        onProgreso?.call(snapshot.bytesTransferred / snapshot.totalBytes);
      }
    });

    try {
      await tarea;
      final url = await ref.getDownloadURL();
      return SubidaVideo(url: url, storagePath: ruta);
    } on FirebaseException catch (e) {
      throw StorageFailure(_mensajeParaCodigo(e.code));
    } finally {
      await suscripcion.cancel();
    }
  }

  /// Borra un archivo subido (por ejemplo si después falló guardar su
  /// documento en Firestore). No lanza error: es una limpieza de mejor esfuerzo.
  Future<void> eliminarVideo(String storagePath) async {
    try {
      await _storage.ref(storagePath).delete();
    } on FirebaseException {
      // Si no se puede borrar, queda huérfano; no bloquea al usuario.
    }
  }

  String _extension(String ruta) {
    final punto = ruta.lastIndexOf('.');
    if (punto == -1 || punto == ruta.length - 1) return 'mp4';
    return ruta.substring(punto + 1).toLowerCase();
  }

  String _contentType(String extension) {
    switch (extension) {
      case 'mov':
        return 'video/quicktime';
      case '3gp':
        return 'video/3gpp';
      case 'webm':
        return 'video/webm';
      case 'mkv':
        return 'video/x-matroska';
      default:
        return 'video/mp4';
    }
  }

  String _mensajeParaCodigo(String codigo) {
    switch (codigo) {
      case 'unauthorized':
        return 'No tienes permiso para subir este archivo (máximo 50 MB, solo video).';
      case 'canceled':
        return 'La subida se canceló.';
      case 'quota-exceeded':
        return 'Se superó la cuota de Storage. Avísale a Alex.';
      default:
        return 'No se pudo subir el video (código: $codigo).';
    }
  }
}
