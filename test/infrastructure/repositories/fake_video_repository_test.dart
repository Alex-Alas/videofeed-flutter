import 'package:flutter_test/flutter_test.dart';
import 'package:videofeed/infrastructure/repositories/fake_video_repository.dart';

void main() {
  group('FakeVideoRepository tests', () {
    late FakeVideoRepository repository;

    setUp(() {
      repository = FakeVideoRepository();
    });

    tearDown(() {
      repository.dispose();
    });

    test('inicializa con datos de ejemplo por defecto', () {
      expect(repository.videosEnMemoria.isNotEmpty, isTrue);
      expect(repository.videosEnMemoria.length, 4);
    });

    test('observarFeed emite inmediatamente los videos ordenados por fecha descendente', () async {
      final feed = await repository.observarFeed().first;
      expect(feed.length, 4);

      for (int i = 0; i < feed.length - 1; i++) {
        final actual = feed[i].creadoEn ?? DateTime.fromMillisecondsSinceEpoch(0);
        final siguiente = feed[i + 1].creadoEn ?? DateTime.fromMillisecondsSinceEpoch(0);
        expect(actual.isAfter(siguiente) || actual.isAtSameMomentAs(siguiente), isTrue);
      }
    });

    test('observarFeed respeta el parámetro de límite', () async {
      final feed = await repository.observarFeed(limite: 2).first;
      expect(feed.length, 2);
    });

    test('crearVideo agrega un nuevo video y emite la actualización en el feed', () async {
      final nuevo = Video(
        autorUid: 'user_nuevo',
        autorNombre: 'Dev Tester',
        titulo: 'Nuevo video en el feed',
        videoUrl: 'https://video.mp4',
        storagePath: 'videos/user_nuevo/1.mp4',
      );

      final feedStream = repository.observarFeed();

      // Primer evento: estado inicial
      final feedInicial = await feedStream.first;
      final totalInicial = feedInicial.length;

      // Crear el video
      await repository.crearVideo(nuevo);

      // El video más reciente debe ser el nuevo
      final feedActualizado = await repository.observarFeed().first;
      expect(feedActualizado.length, totalInicial + 1);
      expect(feedActualizado.first.titulo, 'Nuevo video en el feed');
      expect(feedActualizado.first.id, isNotEmpty);
      expect(feedActualizado.first.creadoEn, isNotNull);
    });

    test('darLike incrementa el contador y emite en yaDiLike', () async {
      const videoId = 'fake-video-1';
      const uid = 'tester_uid';

      // Verificar que inicialmente no tiene like
      expect(await repository.yaDiLike(videoId, uid).first, isFalse);

      final videosIniciales = repository.videosEnMemoria;
      final videoOriginal = videosIniciales.firstWhere((v) => v.id == videoId);
      final likesOriginales = videoOriginal.likes;

      // Dar like
      await repository.darLike(videoId, uid);

      // Comprobar que yaDiLike emite true
      expect(await repository.yaDiLike(videoId, uid).first, isTrue);

      // Comprobar contador actualizado en el feed
      final feed = await repository.observarFeed().first;
      final videoActualizado = feed.firstWhere((v) => v.id == videoId);
      expect(videoActualizado.likes, likesOriginales + 1);

      // Idempotencia: dar like de nuevo con el mismo usuario no duplica el contador
      await repository.darLike(videoId, uid);
      final feedReintentado = await repository.observarFeed().first;
      final videoReintentado = feedReintentado.firstWhere((v) => v.id == videoId);
      expect(videoReintentado.likes, likesOriginales + 1);
    });

    test('quitarLike decrementa el contador y actualiza yaDiLike', () async {
      const videoId = 'fake-video-2';
      const uid = 'tester_uid_2';

      await repository.darLike(videoId, uid);
      expect(await repository.yaDiLike(videoId, uid).first, isTrue);

      final videoConLike = repository.videosEnMemoria.firstWhere((v) => v.id == videoId);
      final likesConLike = videoConLike.likes;

      await repository.quitarLike(videoId, uid);

      expect(await repository.yaDiLike(videoId, uid).first, isFalse);
      final videoSinLike = repository.videosEnMemoria.firstWhere((v) => v.id == videoId);
      expect(videoSinLike.likes, likesConLike - 1);
    });

    test('quitarLike no disminuye los likes por debajo de cero', () async {
      const videoId = 'fake-video-cero';
      const uid = 'tester_uid_3';

      final repoVacio = FakeVideoRepository(
        videosIniciales: [
          const Video(
            id: videoId,
            autorUid: 'u',
            autorNombre: 'N',
            titulo: 'T',
            videoUrl: 'v',
            storagePath: 's',
            likes: 0,
          )
        ],
        likesIniciales: {'${videoId}_$uid'},
      );

      await repoVacio.quitarLike(videoId, uid);
      expect(repoVacio.videosEnMemoria.first.likes, 0);

      repoVacio.dispose();
    });

    test('reiniciar y limpiar gestionan el estado en memoria adecuadamente', () {
      repository.limpiar();
      expect(repository.videosEnMemoria.isEmpty, isTrue);

      repository.reiniciar();
      expect(repository.videosEnMemoria.length, 4);
    });
  });
}
