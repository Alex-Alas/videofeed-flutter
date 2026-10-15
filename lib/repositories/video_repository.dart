// video_repository.dart
//
// TODO(D-01): contrato que usan Feed, Subir y Likes. Nadie fuera de
// lib/repositories llama directamente a FirebaseFirestore.instance.
//
// abstract class VideoRepository {
//   Stream<List<Video>> observarFeed({int limite = 20});
//   Future<void> crearVideo(Video video);
//   Future<void> darLike(String videoId, String uid);
//   Future<void> quitarLike(String videoId, String uid);
//   Stream<bool> yaDiLike(String videoId, String uid);
// }
//
// Implementaciones:
//   fake_video_repository.dart       (D-02) datos de ejemplo en memoria
//   firestore_video_repository.dart  (D-03 y L-01)
