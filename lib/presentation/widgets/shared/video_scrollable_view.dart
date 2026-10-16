// video_scrollable_view.dart
//
// Tarea F-01: feed vertical estilo TikTok. Un video por página; al deslizar,
// el PageView descarta la página anterior y su reproductor se libera.

import 'package:flutter/material.dart';

import '../../../domain/repositories/video_repository.dart';
import '../video/fullscreen_player.dart';
import 'video_buttons.dart';

class VideoScrollableView extends StatelessWidget {
  final List<Video> videos;
  final VideoRepository repositorio;
  final String uid;

  const VideoScrollableView({
    super.key,
    required this.videos,
    required this.repositorio,
    required this.uid,
  });

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      scrollDirection: Axis.vertical,
      physics: const BouncingScrollPhysics(),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final video = videos[index];

        debugPrint(
          'Feed item => url=${video.videoUrl} storage=${video.storagePath}',
        );
        return Stack(
          key: ValueKey(video.id),
          children: [
            // Reproductor + degradado + texto.
            SizedBox.expand(
              child: FullScreenPlayer(
                videoUrl: video.videoUrl,
                titulo: video.titulo,
                autor: video.autorNombre,
              ),
            ),

            // Botones laterales.
            Positioned(
              bottom: 40,
              right: 12,
              child: VideoButtons(
                video: video,
                repositorio: repositorio,
                uid: uid,
              ),
            ),
          ],
        );
      },
    );
  }
}
