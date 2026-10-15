// video.dart
//
// Tarea D-01: Modelo Video con fromDoc / fromMap / toMap.
//
// Campos acordados (documento en la colección `videos`):
//   id           String    id del documento
//   autorUid     String    uid de quien lo subió
//   autorNombre  String    nombre visible del autor
//   titulo       String    título o descripción del video
//   videoUrl     String    URL de descarga del archivo
//   storagePath  String    ruta del archivo en Storage (videos/{uid}/...)
//   likes        int       contador (FieldValue.increment)
//   creadoEn     DateTime? FieldValue.serverTimestamp()

import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de datos inmutable que representa un video en VideoFeed.
///
/// Corresponde a un documento dentro de la colección `videos/{videoId}`.
///
/// ### Prevención de desbordamientos y errores:
/// - **Robustez ante nulos y tipos dinámicos:** Tolera campos ausentes, nulos o con
///   tipos numéricos dispares (`int`, `double`, `num`), evitando fallos en tiempo de ejecución.
/// - **Fechas flexibles:** Acepta tanto `Timestamp` de Firestore como `DateTime`, `int` (milisegundos)
///   o strings ISO-8601 (ideal para `FakeVideoRepository` y tests sin emulador).
/// - **Recomendación para UI (RenderFlex overflow):** Al mostrar [titulo] o [autorNombre]
///   en pantallas como `FeedScreen` dentro de un `Row` o `Column`, recuerde envolverlos en
///   `Expanded` o `Flexible` y definir `overflow: TextOverflow.ellipsis` junto a `maxLines`.
class Video {
  /// Identificador único del documento en Firestore (`videoId`).
  /// Puede ser vacío al instanciar un video nuevo antes de subirlo.
  final String id;

  /// UID de Firebase Authentication del usuario creador.
  final String autorUid;

  /// Nombre para mostrar del autor (por ejemplo, del perfil de usuario).
  final String autorNombre;

  /// Título o pie de video.
  final String titulo;

  /// URL pública o de descarga de Firebase Storage para reproducir el video.
  final String videoUrl;

  /// Ruta relativa del archivo dentro de Firebase Storage (ej: `videos/{uid}/{timestamp}.mp4`).
  final String storagePath;

  /// Número de likes acumulados por el video.
  final int likes;

  /// Fecha y hora en la que fue creado o publicado el video.
  final DateTime? creadoEn;

  const Video({
    this.id = '',
    required this.autorUid,
    required this.autorNombre,
    required this.titulo,
    required this.videoUrl,
    required this.storagePath,
    this.likes = 0,
    this.creadoEn,
  });

  /// Crea un [Video] vacío o por defecto (útil para estados iniciales o mocks).
  factory Video.vacio() {
    return const Video(
      id: '',
      autorUid: '',
      autorNombre: 'Anónimo',
      titulo: '',
      videoUrl: '',
      storagePath: '',
      likes: 0,
      creadoEn: null,
    );
  }

  /// Construye un [Video] a partir de un mapa de clave-valor y un id opcional.
  ///
  /// Es tolerante a valores nulos o tipos incompatibles:
  /// - `likes`: si es nulo o negativo se normaliza a un entero `>= 0`.
  /// - `creadoEn`: parsea de forma segura [Timestamp], [DateTime], [int] y [String].
  /// - Cadenas: se asegura de que no sean nulas y aplica `.trim()`.
  factory Video.fromMap(Map<String, dynamic> map, {String id = ''}) {
    // Manejo seguro del contador de likes (evita TypeError y desbordamientos negativos)
    final rawLikes = map['likes'];
    int parsedLikes = 0;
    if (rawLikes is num) {
      parsedLikes = rawLikes.toInt();
      if (parsedLikes < 0) parsedLikes = 0;
    }

    // Manejo flexible de la fecha de creación
    DateTime? parsedCreadoEn;
    final rawFecha = map['creadoEn'];
    if (rawFecha is Timestamp) {
      parsedCreadoEn = rawFecha.toDate();
    } else if (rawFecha is DateTime) {
      parsedCreadoEn = rawFecha;
    } else if (rawFecha is int) {
      parsedCreadoEn = DateTime.fromMillisecondsSinceEpoch(rawFecha);
    } else if (rawFecha is String) {
      parsedCreadoEn = DateTime.tryParse(rawFecha);
    }

    final String finalId = (map['id'] as String?)?.trim() ?? id.trim();

    return Video(
      id: finalId,
      autorUid: (map['autorUid'] as String?)?.trim() ?? '',
      autorNombre: (map['autorNombre'] as String?)?.trim().isNotEmpty == true
          ? (map['autorNombre'] as String).trim()
          : 'Anónimo',
      titulo: (map['titulo'] as String?)?.trim() ?? '',
      videoUrl: (map['videoUrl'] as String?)?.trim() ?? '',
      storagePath: (map['storagePath'] as String?)?.trim() ?? '',
      likes: parsedLikes,
      creadoEn: parsedCreadoEn,
    );
  }

  /// Construye un [Video] a partir de un [DocumentSnapshot] de Firestore.
  ///
  /// Toma automáticamente el `doc.id` como [id] del modelo y extrae los datos
  /// sin importar si el snapshot tiene genéricos especificados.
  factory Video.fromDoc(DocumentSnapshot doc) {
    final data = doc.data();
    final map = (data is Map<String, dynamic>) ? data : <String, dynamic>{};
    return Video.fromMap(map, id: doc.id);
  }

  /// Convierte el modelo en un mapa serializable para Firestore.
  ///
  /// - Si [creadoEn] tiene valor, se serializa como [Timestamp].
  /// - Si [creadoEn] es nulo y [incluirServerTimestamp] es true, se genera
  ///   [FieldValue.serverTimestamp()] para que Firestore asigne la hora del servidor al guardar.
  /// - Por convención de Firestore, el `id` no se incluye en el mapa porque ya
  ///   es la clave del documento.
  Map<String, dynamic> toMap({bool incluirServerTimestamp = true}) {
    final map = <String, dynamic>{
      'autorUid': autorUid,
      'autorNombre': autorNombre,
      'titulo': titulo,
      'videoUrl': videoUrl,
      'storagePath': storagePath,
      'likes': likes,
    };

    if (creadoEn != null) {
      map['creadoEn'] = Timestamp.fromDate(creadoEn!);
    } else if (incluirServerTimestamp) {
      map['creadoEn'] = FieldValue.serverTimestamp();
    }

    return map;
  }

  /// Devuelve una copia de la instancia actual con los campos actualizados.
  Video copyWith({
    String? id,
    String? autorUid,
    String? autorNombre,
    String? titulo,
    String? videoUrl,
    String? storagePath,
    int? likes,
    DateTime? creadoEn,
    bool clearCreadoEn = false,
  }) {
    return Video(
      id: id ?? this.id,
      autorUid: autorUid ?? this.autorUid,
      autorNombre: autorNombre ?? this.autorNombre,
      titulo: titulo ?? this.titulo,
      videoUrl: videoUrl ?? this.videoUrl,
      storagePath: storagePath ?? this.storagePath,
      likes: likes ?? this.likes,
      creadoEn: clearCreadoEn ? null : (creadoEn ?? this.creadoEn),
    );
  }

  /// Helper de utilidad para vistas resumidas: obtiene el título truncado si excede
  /// el límite indicado, evitando posibles desbordamientos de layout en la interfaz.
  String tituloTruncado([int maxLength = 60]) {
    if (titulo.length <= maxLength) return titulo;
    return '${titulo.substring(0, maxLength)}...';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Video &&
        other.id == id &&
        other.autorUid == autorUid &&
        other.autorNombre == autorNombre &&
        other.titulo == titulo &&
        other.videoUrl == videoUrl &&
        other.storagePath == storagePath &&
        other.likes == likes &&
        other.creadoEn == creadoEn;
  }

  @override
  int get hashCode => Object.hash(
        id,
        autorUid,
        autorNombre,
        titulo,
        videoUrl,
        storagePath,
        likes,
        creadoEn,
      );

  @override
  String toString() {
    return 'Video(id: "$id", titulo: "$titulo", autorNombre: "$autorNombre", likes: $likes, creadoEn: $creadoEn)';
  }
}
