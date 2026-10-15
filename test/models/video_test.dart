import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:videofeed/models/video.dart';

void main() {
  group('Video model tests', () {
    test('instanciación básica con valores por defecto', () {
      const video = Video(
        autorUid: 'user123',
        autorNombre: 'Alex',
        titulo: 'Flutter demo',
        videoUrl: 'https://storage.googleapis.com/video.mp4',
        storagePath: 'videos/user123/12345.mp4',
      );

      expect(video.id, '');
      expect(video.autorUid, 'user123');
      expect(video.autorNombre, 'Alex');
      expect(video.titulo, 'Flutter demo');
      expect(video.videoUrl, 'https://storage.googleapis.com/video.mp4');
      expect(video.storagePath, 'videos/user123/12345.mp4');
      expect(video.likes, 0);
      expect(video.creadoEn, isNull);
    });

    test('Video.vacio crea un modelo seguro sin valores nulos', () {
      final vacio = Video.vacio();
      expect(vacio.id, '');
      expect(vacio.autorUid, '');
      expect(vacio.autorNombre, 'Anónimo');
      expect(vacio.titulo, '');
      expect(vacio.videoUrl, '');
      expect(vacio.storagePath, '');
      expect(vacio.likes, 0);
      expect(vacio.creadoEn, isNull);
    });

    test('fromMap parsea correctamente mapa completo con Timestamp', () {
      final now = DateTime.now();
      final map = {
        'autorUid': 'uid_1',
        'autorNombre': 'María Gómez',
        'titulo': 'Mi primer video',
        'videoUrl': 'https://video.mp4',
        'storagePath': 'videos/uid_1/1.mp4',
        'likes': 15,
        'creadoEn': Timestamp.fromDate(now),
      };

      final video = Video.fromMap(map, id: 'doc_123');

      expect(video.id, 'doc_123');
      expect(video.autorUid, 'uid_1');
      expect(video.autorNombre, 'María Gómez');
      expect(video.titulo, 'Mi primer video');
      expect(video.videoUrl, 'https://video.mp4');
      expect(video.storagePath, 'videos/uid_1/1.mp4');
      expect(video.likes, 15);
      expect(video.creadoEn?.millisecondsSinceEpoch,
          closeTo(now.millisecondsSinceEpoch, 1000));
    });

    test('fromMap es tolerante ante tipos numéricos y valores nulos (evita desbordamientos/crashes)', () {
      final map = {
        'autorUid': null,
        'autorNombre': '   ',
        'titulo': null,
        'videoUrl': null,
        'storagePath': null,
        'likes': -5, // Valor negativo anómalo
        'creadoEn': null,
      };

      final video = Video.fromMap(map, id: 'id_safe');

      expect(video.id, 'id_safe');
      expect(video.autorUid, '');
      expect(video.autorNombre, 'Anónimo');
      expect(video.titulo, '');
      expect(video.videoUrl, '');
      expect(video.storagePath, '');
      expect(video.likes, 0); // Normalizado a >= 0
      expect(video.creadoEn, isNull);
    });

    test('fromMap parsea múltiples formatos de fecha (Timestamp, DateTime, int epoch, ISO-8601)', () {
      final date = DateTime.utc(2026, 5, 20, 10, 30);

      final videoFromDateTime = Video.fromMap({'creadoEn': date});
      expect(videoFromDateTime.creadoEn, date);

      final videoFromEpoch = Video.fromMap({'creadoEn': date.millisecondsSinceEpoch});
      expect(videoFromEpoch.creadoEn?.millisecondsSinceEpoch, date.millisecondsSinceEpoch);

      final videoFromIso = Video.fromMap({'creadoEn': date.toIso8601String()});
      expect(videoFromIso.creadoEn, date);
    });

    test('toMap serializa correctamente con Timestamp o FieldValue.serverTimestamp', () {
      final now = DateTime.utc(2026, 1, 1, 12, 0);
      final videoConFecha = Video(
        id: 'v1',
        autorUid: 'u1',
        autorNombre: 'Pepe',
        titulo: 'Test',
        videoUrl: 'http://video',
        storagePath: 'storage/path',
        likes: 3,
        creadoEn: now,
      );

      final map1 = videoConFecha.toMap();
      expect(map1['autorUid'], 'u1');
      expect(map1['likes'], 3);
      expect(map1['creadoEn'], isA<Timestamp>());
      expect((map1['creadoEn'] as Timestamp).toDate().toUtc(), now);

      final videoSinFecha = videoConFecha.copyWith(clearCreadoEn: true);
      final map2 = videoSinFecha.toMap(incluirServerTimestamp: true);
      expect(map2['creadoEn'], isA<FieldValue>());

      final map3 = videoSinFecha.toMap(incluirServerTimestamp: false);
      expect(map3.containsKey('creadoEn'), isFalse);
    });

    test('copyWith crea nuevas instancias modificando solo lo solicitado', () {
      const original = Video(
        id: '1',
        autorUid: 'u1',
        autorNombre: 'Nombre',
        titulo: 'Titulo',
        videoUrl: 'url',
        storagePath: 'path',
        likes: 0,
      );

      final modificado = original.copyWith(likes: 10, titulo: 'Nuevo titulo');

      expect(modificado.id, '1');
      expect(modificado.likes, 10);
      expect(modificado.titulo, 'Nuevo titulo');
      expect(modificado.autorUid, 'u1');
    });

    test('igualdad por valor y hashCode', () {
      const video1 = Video(
        id: '1',
        autorUid: 'u1',
        autorNombre: 'N',
        titulo: 'T',
        videoUrl: 'url',
        storagePath: 'p',
        likes: 5,
      );

      const video2 = Video(
        id: '1',
        autorUid: 'u1',
        autorNombre: 'N',
        titulo: 'T',
        videoUrl: 'url',
        storagePath: 'p',
        likes: 5,
      );

      expect(video1, equals(video2));
      expect(video1.hashCode, equals(video2.hashCode));
    });

    test('tituloTruncado trunca correctamente para evitar desbordamientos en la UI', () {
      const videoLargo = Video(
        autorUid: 'u',
        autorNombre: 'N',
        titulo: 'Este es un título excesivamente largo que podría causar problemas de overflow si no se controla adecuadamente',
        videoUrl: 'url',
        storagePath: 'path',
      );

      expect(videoLargo.tituloTruncado(20), 'Este es un título ex...');
      expect(videoLargo.tituloTruncado(200), videoLargo.titulo);
    });
  });
}
