// firestore_video_repository.dart
//
// Tareas D-03 y L-01: Implementación de VideoRepository con Cloud Firestore.
//
// Regla fundamental del equipo:
// "Nadie fuera de lib/infrastructure/repositories usa FirebaseFirestore.instance directamente."
//
// Esquema de datos (README.md):
//   videos/{videoId}                 autorUid, autorNombre, titulo, videoUrl,
//                                    storagePath, likes, creadoEn
//   videos/{videoId}/likes/{uid}     creadoEn   (un like por usuario)

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/video_repository.dart';

export '../../domain/repositories/video_repository.dart';

/// Implementación de producción de [VideoRepository] conectada a Cloud Firestore.
///
/// Encapsula todas las operaciones de consulta, creación y gestión de likes
/// para evitar accesos directos a Firestore desde pantallas o widgets de UI.
class FirestoreVideoRepository implements VideoRepository {
  final FirebaseFirestore _firestore;

  /// Permite inyectar una instancia personalizada de [FirebaseFirestore]
  /// (útil para pruebas unitarias con mocks o emuladores).
  FirestoreVideoRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Referencia a la colección principal de videos (`videos`).
  CollectionReference<Map<String, dynamic>> get _videosRef =>
      _firestore.collection('videos');

  @override
  Stream<List<Video>> observarFeed({int limite = 20}) {
    final queryLimit = limite > 0 ? limite : 20;

    return _videosRef
        .orderBy('creadoEn', descending: true)
        .limit(queryLimit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Video.fromDoc(doc)).toList();
    });
  }

  @override
  Future<void> crearVideo(Video video) async {
    // Si el video ya tiene un ID asignado se utiliza ese documento,
    // de lo contrario Firestore genera un ID único automáticamente.
    final docRef = video.id.trim().isNotEmpty
        ? _videosRef.doc(video.id.trim())
        : _videosRef.doc();

    final data = video.toMap(incluirServerTimestamp: true);

    await docRef.set(data);
  }

  @override
  Future<void> darLike(String videoId, String uid) async {
    if (videoId.isEmpty || uid.isEmpty) return;

    final videoRef = _videosRef.doc(videoId);
    final likeRef = videoRef.collection('likes').doc(uid);

    // Se utiliza una transacción para garantizar atomicidad e idempotencia:
    // solo se incrementa el contador si el usuario no había dado like previamente.
    await _firestore.runTransaction((transaction) async {
      final likeDoc = await transaction.get(likeRef);
      if (likeDoc.exists) return; // Ya tiene like registrado

      transaction.set(likeRef, {
        'creadoEn': FieldValue.serverTimestamp(),
      });

      transaction.update(videoRef, {
        'likes': FieldValue.increment(1),
      });
    });
  }

  @override
  Future<void> quitarLike(String videoId, String uid) async {
    if (videoId.isEmpty || uid.isEmpty) return;

    final videoRef = _videosRef.doc(videoId);
    final likeRef = videoRef.collection('likes').doc(uid);

    // Transacción atómica: remueve el like y decrementa el contador sin bajar de cero.
    await _firestore.runTransaction((transaction) async {
      final likeDoc = await transaction.get(likeRef);
      if (!likeDoc.exists) return; // No tenía like previo

      final videoDoc = await transaction.get(videoRef);
      final int likesActuales =
          (videoDoc.data()?['likes'] as num?)?.toInt() ?? 0;

      transaction.delete(likeRef);

      // Las reglas solo aceptan likes ± 1: si ya está en 0 no se toca el
      // contador (escribir un 0 literal haría fallar toda la transacción).
      if (likesActuales > 0) {
        transaction.update(videoRef, {
          'likes': FieldValue.increment(-1),
        });
      }
    });
  }

  @override
  Stream<bool> yaDiLike(String videoId, String uid) {
    if (videoId.isEmpty || uid.isEmpty) {
      return Stream.value(false);
    }

    return _videosRef
        .doc(videoId)
        .collection('likes')
        .doc(uid)
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }
}
