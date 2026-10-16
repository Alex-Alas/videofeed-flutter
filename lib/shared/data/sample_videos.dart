// sample_videos.dart
//
// Videos de ejemplo para FakeVideoRepository (D-02), el modo demo
// (lib/main_demo.dart) y las pruebas. Son videos verticales de Pexels
// (licencia libre) guardados en assets/videos/, así el demo funciona sin
// internet. FullScreenPlayer reproduce desde assets cuando la URL empieza con
// "assets/" y por red en cualquier otro caso (los videos reales de Storage).

import '../../domain/entities/video.dart';

List<Video> videosDeEjemplo() {
  final ahora = DateTime.now();
  return [
    Video(
      id: 'fake-video-1',
      autorUid: 'user_alex',
      autorNombre: 'Alex Alas',
      titulo: '¡Bienvenidos a VideoFeed! Desliza hacia arriba para ver más 👆',
      videoUrl: 'assets/videos/pexels_5877823.mp4',
      storagePath: 'videos/user_alex/sample1.mp4',
      likes: 1250,
      creadoEn: ahora.subtract(const Duration(minutes: 5)),
    ),
    Video(
      id: 'fake-video-2',
      autorUid: 'user_maria',
      autorNombre: 'María Gómez',
      titulo: 'Toca el video para pausarlo y el corazón para dar like ❤️',
      videoUrl: 'assets/videos/pexels_13853926.mp4',
      storagePath: 'videos/user_maria/sample2.mp4',
      likes: 87,
      creadoEn: ahora.subtract(const Duration(hours: 2)),
    ),
    Video(
      id: 'fake-video-3',
      autorUid: 'user_carlos',
      autorNombre: 'Carlos Ruiz',
      titulo: 'Videos verticales de prueba, como en TikTok 📱',
      videoUrl: 'assets/videos/pexels_11515140.mp4',
      storagePath: 'videos/user_carlos/sample3.mp4',
      likes: 15300,
      creadoEn: ahora.subtract(const Duration(hours: 6)),
    ),
    Video(
      id: 'fake-video-4',
      autorUid: 'user_lucia',
      autorNombre: 'Lucía Fernández',
      titulo: 'Máximo 60 segundos y 50 MB por video 🎬',
      videoUrl: 'assets/videos/pexels_20000940.mp4',
      storagePath: 'videos/user_lucia/sample4.mp4',
      likes: 2400000,
      creadoEn: ahora.subtract(const Duration(days: 1)),
    ),
  ];
}
