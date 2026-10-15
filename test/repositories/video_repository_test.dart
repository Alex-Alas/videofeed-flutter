import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:videofeed/repositories/video_repository.dart';

/// Implementación simple en memoria para verificar que el contrato
/// de [VideoRepository] es implementable y usable sin fricción.
class MockMemoryVideoRepository implements VideoRepository {
  final List<Video> _videos = [];
  final Set<String> _likes = {}; // "videoId_uid"
  final StreamController<List<Video>> _feedController =
      StreamController<List<Video>>.broadcast();

  @override
  Stream<List<Video>> observarFeed({int limite = 20}) {
    // Retorna una lista ordenada cronológicamente de forma descendente y truncada al límite
    Future.microtask(() {
      final sorted = List<Video>.from(_videos)
        ..sort((a, b) {
          final dateA = a.creadoEn ?? DateTime.fromMillisecondsSinceEpoch(0);
          final dateB = b.creadoEn ?? DateTime.fromMillisecondsSinceEpoch(0);
          return dateB.compareTo(dateA);
        });
      _feedController.add(sorted.take(limite).toList());
    });
    return _feedController.stream;
  }

  @override
  Future<void> crearVideo(Video video) async {
    final nuevo = video.copyWith(
      id: video.id.isEmpty ? 'id_${_videos.length + 1}' : video.id,
      creadoEn: video.creadoEn ?? DateTime.now(),
    );
    _videos.add(nuevo);
    _feedController.add(List.unmodifiable(_videos));
  }

  @override
  Future<void> darLike(String videoId, String uid) async {
    _likes.add('${videoId}_$uid');
    final index = _videos.indexWhere((v) => v.id == videoId);
    if (index != -1) {
      _videos[index] = _videos[index].copyWith(likes: _videos[index].likes + 1);
      _feedController.add(List.unmodifiable(_videos));
    }
  }

  @override
  Future<void> quitarLike(String videoId, String uid) async {
    _likes.remove('${videoId}_$uid');
    final index = _videos.indexWhere((v) => v.id == videoId);
    if (index != -1 && _videos[index].likes > 0) {
      _videos[index] = _videos[index].copyWith(likes: _videos[index].likes - 1);
      _feedController.add(List.unmodifiable(_videos));
    }
  }

  @override
  Stream<bool> yaDiLike(String videoId, String uid) {
    return Stream.value(_likes.contains('${videoId}_$uid'));
  }
}

void main() {
  group('VideoRepository contract tests', () {
    late VideoRepository repository;

    setUp(() {
      repository = MockMemoryVideoRepository();
    });

    test('cumple con el contrato básico de crear y observar el feed', () async {
      final video = Video(
        autorUid: 'u1',
        autorNombre: 'Test User',
        titulo: 'Video de prueba',
        videoUrl: 'https://url/video.mp4',
        storagePath: 'videos/u1/1.mp4',
      );

      await repository.crearVideo(video);

      final feed = await repository.observarFeed(limite: 10).first;
      expect(feed.length, 1);
      expect(feed.first.titulo, 'Video de prueba');
      expect(feed.first.id, isNotEmpty);
    });

    test('darLike y quitarLike modifican el contador y el estado de like', () async {
      final video = Video(
        id: 'v100',
        autorUid: 'u1',
        autorNombre: 'User',
        titulo: 'Likeable video',
        videoUrl: 'https://video.mp4',
        storagePath: 'path',
      );

      await repository.crearVideo(video);

      expect(await repository.yaDiLike('v100', 'u2').first, isFalse);

      await repository.darLike('v100', 'u2');
      expect(await repository.yaDiLike('v100', 'u2').first, isTrue);

      await repository.quitarLike('v100', 'u2');
      expect(await repository.yaDiLike('v100', 'u2').first, isFalse);
    });
  });
}
