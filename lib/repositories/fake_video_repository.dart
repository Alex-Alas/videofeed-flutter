// fake_video_repository.dart
//
// Tarea D-02: Implementación en memoria de VideoRepository con datos de ejemplo.
//
// Permite desarrollar y probar las pantallas FeedScreen (F-01..F-04),
// UploadScreen (U-01..U-04) y el sistema de Likes (L-01) de forma desacoplada
// de Firebase, sin requerir emuladores ni consumir cuotas de Firestore.

import 'dart:async';
import 'video_repository.dart';

export 'video_repository.dart';

/// Evento interno para notificar cambios reactivos de likes por usuario y video.
class _LikeEvent {
  final String videoId;
  final String uid;
  final bool dioLike;

  const _LikeEvent({
    required this.videoId,
    required this.uid,
    required this.dioLike,
  });
}

/// Implementación en memoria de [VideoRepository] para pruebas y desarrollo.
///
/// Características principales:
/// - **Emisión reactiva inmediata:** Al suscribirse a [observarFeed] o [yaDiLike],
///   emite inmediatamente el estado actual (evitando que `StreamBuilder` se quede en espera).
/// - **Orden cronológico garantizado:** Devuelve siempre los videos ordenados por
///   `creadoEn` descendente (los más recientes primero).
/// - **Respeto de límites:** Cumple con el parámetro `limite` para evitar desbordamientos.
/// - **Persistencia volátil en memoria:** Modifica la lista local y notifica a todos
///   los suscriptores cuando se crea un video o se da/quita like.
class FakeVideoRepository implements VideoRepository {
  /// Lista interna mutable de videos en memoria.
  final List<Video> _videos = [];

  /// Conjunto de identificadores compuestos `"${videoId}_$uid"` para registrar likes únicos.
  final Set<String> _likes = {};

  /// Controlador de difusión para cambios en el feed general.
  final StreamController<void> _feedController =
      StreamController<void>.broadcast();

  /// Controlador de difusión para cambios específicos de likes.
  final StreamController<_LikeEvent> _likesController =
      StreamController<_LikeEvent>.broadcast();

  /// Crea una instancia de [FakeVideoRepository].
  ///
  /// Si no se especifican [videosIniciales], carga por defecto un conjunto
  /// de videos de ejemplo con URLs públicas válidas para `video_player`.
  FakeVideoRepository({
    List<Video>? videosIniciales,
    Set<String>? likesIniciales,
  }) {
    if (videosIniciales != null) {
      _videos.addAll(videosIniciales);
    } else {
      _cargarDatosDeEjemplo();
    }

    if (likesIniciales != null) {
      _likes.addAll(likesIniciales);
    }
  }

  /// Videos predeterminados con URLs seguras (HTTPS) para pruebas de reproducción y feed.
  static List<Video> generarDatosDeEjemplo() {
    final ahora = DateTime.now();
    return [
      Video(
        id: 'fake-video-1',
        autorUid: 'user_alex',
        autorNombre: 'Alex Alas',
        titulo: '¡Bienvenidos a VideoFeed! Feed de videos con Flutter y Firebase 🔥',
        videoUrl:
            'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
        storagePath: 'videos/user_alex/sample1.mp4',
        likes: 12,
        creadoEn: ahora.subtract(const Duration(minutes: 5)),
      ),
      Video(
        id: 'fake-video-2',
        autorUid: 'user_maria',
        autorNombre: 'María Gómez',
        titulo: 'Animaciones fluidas y reproductor optimizado en Flutter 🚀',
        videoUrl:
            'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
        storagePath: 'videos/user_maria/sample2.mp4',
        likes: 27,
        creadoEn: ahora.subtract(const Duration(hours: 2)),
      ),
      Video(
        id: 'fake-video-3',
        autorUid: 'user_carlos',
        autorNombre: 'Carlos Ruiz',
        titulo: 'Reglas de seguridad en Firestore y arquitectura limpia 🔒',
        videoUrl:
            'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
        storagePath: 'videos/user_carlos/sample3.mp4',
        likes: 8,
        creadoEn: ahora.subtract(const Duration(hours: 6)),
      ),
      Video(
        id: 'fake-video-4',
        autorUid: 'user_lucia',
        autorNombre: 'Lucía Fernández',
        titulo: 'Tips para controlar el tamaño de videos y ahorrar cuota de Storage 📱',
        videoUrl:
            'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4',
        storagePath: 'videos/user_lucia/sample4.mp4',
        likes: 45,
        creadoEn: ahora.subtract(const Duration(days: 1)),
      ),
    ];
  }

  void _cargarDatosDeEjemplo() {
    _videos.addAll(generarDatosDeEjemplo());
  }

  /// Retorna la copia ordenada y acotada de la lista actual de videos.
  List<Video> _obtenerFeedOrdenado(int limite) {
    final copia = List<Video>.from(_videos);
    copia.sort((a, b) {
      final fechaA = a.creadoEn ?? DateTime.fromMillisecondsSinceEpoch(0);
      final fechaB = b.creadoEn ?? DateTime.fromMillisecondsSinceEpoch(0);
      return fechaB.compareTo(fechaA); // Descendente: más reciente primero
    });

    if (limite > 0 && copia.length > limite) {
      return List.unmodifiable(copia.take(limite));
    }
    return List.unmodifiable(copia);
  }

  @override
  Stream<List<Video>> observarFeed({int limite = 20}) async* {
    // 1. Emisión inicial instantánea para evitar estados de espera prolongados en la UI
    yield _obtenerFeedOrdenado(limite);

    // 2. Emisión subsiguiente cada vez que se cree un video o cambien sus likes
    yield* _feedController.stream.map((_) => _obtenerFeedOrdenado(limite));
  }

  @override
  Future<void> crearVideo(Video video) async {
    final String idFinal = video.id.trim().isNotEmpty
        ? video.id.trim()
        : 'fake-video-${DateTime.now().millisecondsSinceEpoch}';

    final DateTime fechaFinal = video.creadoEn ?? DateTime.now();

    final nuevoVideo = video.copyWith(
      id: idFinal,
      creadoEn: fechaFinal,
    );

    _videos.add(nuevoVideo);
    _feedController.add(null);
  }

  @override
  Future<void> darLike(String videoId, String uid) async {
    final clave = '${videoId}_$uid';
    if (_likes.contains(clave)) return; // Idempotencia: un like por usuario

    _likes.add(clave);

    final index = _videos.indexWhere((v) => v.id == videoId);
    if (index != -1) {
      final actual = _videos[index];
      _videos[index] = actual.copyWith(likes: actual.likes + 1);
    }

    _likesController.add(_LikeEvent(videoId: videoId, uid: uid, dioLike: true));
    _feedController.add(null);
  }

  @override
  Future<void> quitarLike(String videoId, String uid) async {
    final clave = '${videoId}_$uid';
    if (!_likes.contains(clave)) return;

    _likes.remove(clave);

    final index = _videos.indexWhere((v) => v.id == videoId);
    if (index != -1) {
      final actual = _videos[index];
      final nuevosLikes = actual.likes > 0 ? actual.likes - 1 : 0;
      _videos[index] = actual.copyWith(likes: nuevosLikes);
    }

    _likesController.add(_LikeEvent(videoId: videoId, uid: uid, dioLike: false));
    _feedController.add(null);
  }

  @override
  Stream<bool> yaDiLike(String videoId, String uid) async* {
    final clave = '${videoId}_$uid';

    // 1. Emisión inmediata del estado actual
    yield _likes.contains(clave);

    // 2. Emisiones posteriores filtradas para esta combinación específica
    yield* _likesController.stream
        .where((e) => e.videoId == videoId && e.uid == uid)
        .map((e) => e.dioLike);
  }

  // --- Métodos de conveniencia para pruebas y depuración ---

  /// Obtiene una instantánea inmutable de los videos actualmente almacenados.
  List<Video> get videosEnMemoria => List.unmodifiable(_videos);

  /// Consulta sincrónica de si un usuario ya dio like a un video.
  bool tieneLike(String videoId, String uid) => _likes.contains('${videoId}_$uid');

  /// Restablece el repositorio con los datos de ejemplo iniciales.
  void reiniciar() {
    _videos.clear();
    _likes.clear();
    _cargarDatosDeEjemplo();
    _feedController.add(null);
  }

  /// Limpia todos los datos almacenados en memoria.
  void limpiar() {
    _videos.clear();
    _likes.clear();
    _feedController.add(null);
  }

  /// Cierra los controladores de streams si se destruye la instancia.
  void dispose() {
    _feedController.close();
    _likesController.close();
  }
}
