// video_repository.dart
//
// Tarea D-01: Contrato que usan Feed, Subir y Likes.
//
// Regla fundamental del equipo:
// "Nadie fuera de lib/infrastructure/repositories usa FirebaseFirestore.instance directamente."
//
// Implementaciones previstas en el proyecto:
//   - fake_video_repository.dart       (D-02): Datos mock en memoria para desarrollo ágil y tests.
//   - firestore_video_repository.dart  (D-03 y L-01): Conexión directa con Cloud Firestore.

import '../entities/video.dart';

export '../entities/video.dart';

/// Interfaz del repositorio de videos.
///
/// Define el contrato que deben cumplir todas las fuentes de datos (falsas o de Firebase)
/// para aislar la capa de presentación (UI) de los detalles de almacenamiento.
abstract class VideoRepository {
  /// Emite un flujo en tiempo real con la lista de videos más recientes para el feed.
  ///
  /// - [limite]: Cantidad máxima de videos a consultar simultáneamente (por defecto 20).
  ///   Esta restricción previene el consumo excesivo de memoria, tiempos de carga elevados
  ///   y costos innecesarios en la cuota de lecturas de Firestore.
  /// - Los elementos deben venir ordenados cronológicamente de forma descendente
  ///   (el video más reciente primero).
  Stream<List<Video>> observarFeed({int limite = 20});

  /// Persiste un nuevo video en la colección `videos`.
  ///
  /// - [video]: Objeto [Video] con los metadatos y la URL multimedia.
  /// - Si la implementación es Firestore, debe asignar o respetar el ID del documento
  ///   y registrar la marca de tiempo de creación en el servidor.
  Future<void> crearVideo(Video video);

  /// Registra el "like" del usuario con identificador [uid] para el video [videoId].
  ///
  /// En Firestore debe:
  /// 1. Incrementar el campo `likes` en el documento del video (`videos/{videoId}`).
  /// 2. Crear un documento en la subcolección `videos/{videoId}/likes/{uid}` con `creadoEn`.
  Future<void> darLike(String videoId, String uid);

  /// Remueve el "like" del usuario [uid] para el video [videoId].
  ///
  /// En Firestore debe:
  /// 1. Decrementar el campo `likes` en el documento del video (`videos/{videoId}`).
  /// 2. Eliminar el documento en la subcolección `videos/{videoId}/likes/{uid}`.
  Future<void> quitarLike(String videoId, String uid);

  /// Emite en tiempo real `true` si el usuario [uid] ya tiene registrado un like
  /// en el video [videoId], o `false` en caso contrario.
  ///
  /// Permite que el botón de like en la interfaz reaccione inmediatamente y mantenga
  /// el estado visual sincronizado sin desbordamientos de peticiones repetitivas.
  Stream<bool> yaDiLike(String videoId, String uid);
}
