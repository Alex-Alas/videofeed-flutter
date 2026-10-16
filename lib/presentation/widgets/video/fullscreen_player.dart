// fullscreen_player.dart
//
// Tarea F-02: reproductor a pantalla completa de un video del feed.
// Reproduce en bucle desde la URL de Storage; un toque pausa o reanuda.

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'video_background.dart';

class FullScreenPlayer extends StatefulWidget {
  final String videoUrl;
  final String titulo;
  final String autor;

  const FullScreenPlayer({
    super.key,
    required this.videoUrl,
    required this.titulo,
    required this.autor,
  });

  @override
  State<FullScreenPlayer> createState() => _FullScreenPlayerState();
}

class _FullScreenPlayerState extends State<FullScreenPlayer> {
  bool get _esImagen {
    final url = widget.videoUrl.toLowerCase();

    return url.contains('.jpg') ||
        url.contains('.png') ||
        url.contains('.webp') ||
        url.contains('.jpeg');
  }
  late final VideoPlayerController _controller;
  late final Future<void> _inicializacion;

  @override
  void initState() {
    super.initState();

    if(_esImagen) {
      return;
    }
    // Los videos de ejemplo vienen de assets/; los reales, de Storage (https).
    _controller = widget.videoUrl.startsWith('assets/')
        ? VideoPlayerController.asset(widget.videoUrl)
        : VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    // Se guarda el Future para no reinicializar el video en cada build.
    _inicializacion = _controller.initialize().then((_) {
      // Si el usuario ya deslizó a otro video, el controller está liberado.
      if (!mounted) return;
      _controller
        ..setLooping(true)
        ..play();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _alternarReproduccion() {
    setState(() {
      _controller.value.isPlaying ? _controller.pause() : _controller.play();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_esImagen) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            widget.videoUrl,
            fit: BoxFit.cover,
          ),

          VideoBackground(stops: const [0.7, 1.0]),

          Positioned(
            bottom: 50,
            left: 20,
            child: _VideoCaption(autor: widget.autor, titulo: widget.titulo,),
          ),
        ],
        );
    }
    return FutureBuilder<void>(
      future: _inicializacion,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _ErrorDeVideo();
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }

        return GestureDetector(
          onTap: _alternarReproduccion,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _VideoAjustado(controller: _controller),

              // Degradado inferior para leer el texto.
              VideoBackground(stops: const [0.7, 1.0]),

              // Autor y título.
              Positioned(
                bottom: 50,
                left: 20,
                child: _VideoCaption(
                  autor: widget.autor,
                  titulo: widget.titulo,
                ),
              ),

              // TODO(Integrante 6): indicador de pausa y barra de progreso.
              //  1. Si el video está pausado (!_controller.value.isPlaying),
              //     mostrar en el centro un Icon(Icons.play_arrow_rounded)
              //     grande, blanco y semitransparente.
              //  2. Abajo de todo, un VideoProgressIndicator(_controller,
              //     allowScrubbing: true) con colores visibles sobre negro.
              //  _alternarReproduccion ya llama a setState, así que el ícono
              //  aparece y desaparece solo al tocar el video.
            ],
          ),
        );
      },
    );
  }
}

/// Los videos verticales llenan la pantalla (recortando bordes, como TikTok);
/// los horizontales se muestran completos con franjas negras.
class _VideoAjustado extends StatelessWidget {
  final VideoPlayerController controller;

  const _VideoAjustado({required this.controller});

  @override
  Widget build(BuildContext context) {
    final valor = controller.value;
    final esVertical = valor.aspectRatio < 1;

    if (!esVertical || valor.size.isEmpty) {
      return Center(
        child: AspectRatio(
          aspectRatio: valor.aspectRatio,
          child: VideoPlayer(controller),
        ),
      );
    }

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: valor.size.width,
          height: valor.size.height,
          child: VideoPlayer(controller),
        ),
      ),
    );
  }
}

class _VideoCaption extends StatelessWidget {
  final String autor;
  final String titulo;

  const _VideoCaption({required this.autor, required this.titulo});

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.sizeOf(context).width * 0.7;
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      width: ancho,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '@$autor',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            titulo,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodyLarge?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _ErrorDeVideo extends StatelessWidget {
  const _ErrorDeVideo();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: Colors.white70, size: 48),
          SizedBox(height: 8),
          Text(
            'No se pudo reproducir este video',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
