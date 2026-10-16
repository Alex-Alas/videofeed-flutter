// feed_screen.dart
//
// Tareas F-01..F-04: pantalla principal con el feed en tiempo real
// (StreamBuilder sobre VideoRepository.observarFeed, más recientes primero),
// accesos a subir video y cerrar sesión.

import 'package:flutter/material.dart';

import '../../../domain/repositories/video_repository.dart';
import '../../../infrastructure/datasources/storage_service.dart';
import '../../widgets/shared/feed_vacio.dart';
import '../../widgets/shared/video_scrollable_view.dart';
import '../upload/upload_screen.dart';

class FeedScreen extends StatefulWidget {
  final VideoRepository repositorio;
  final String uid;
  final String nombreUsuario;

  /// Si es null no se muestra el botón de subir (por ejemplo en modo demo).
  final StorageService? storage;

  /// Si es null no se muestra el botón de cerrar sesión.
  final Future<void> Function()? onCerrarSesion;

  const FeedScreen({
    super.key,
    required this.repositorio,
    required this.uid,
    required this.nombreUsuario,
    this.storage,
    this.onCerrarSesion,
  });

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  late Stream<List<Video>> _feed;

  @override
  void initState() {
    super.initState();
    // Se crea una vez: si se creara en build, cada rebuild re-suscribiría.
    _feed = widget.repositorio.observarFeed();
  }

  @override
  void didUpdateWidget(covariant FeedScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repositorio != widget.repositorio) {
      _feed = widget.repositorio.observarFeed();
    }
  }

  Future<void> _abrirSubida() async {
    final storage = widget.storage;
    if (storage == null) return;

    final publicado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => UploadScreen(
          repositorio: widget.repositorio,
          storage: storage,
          uid: widget.uid,
          nombreUsuario: widget.nombreUsuario,
        ),
      ),
    );

    if (publicado == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Video publicado!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final puedeSubir = widget.storage != null;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        // Sin tinte de Material 3 al deslizar: la barra flota sobre el video.
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'VideoFeed',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (puedeSubir)
            IconButton(
              key: const Key('boton-subir'),
              icon: const Icon(Icons.add_box_outlined),
              tooltip: 'Subir video',
              onPressed: _abrirSubida,
            ),
          if (widget.onCerrarSesion != null)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Cerrar sesion',
              onPressed: widget.onCerrarSesion,
            ),
        ],
      ),
      body: StreamBuilder<List<Video>>(
        stream: _feed,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _MensajeFeed(
              icono: Icons.cloud_off,
              texto: 'No se pudo cargar el feed.\n${snapshot.error}',
            );
          }
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            );
          }

          final videos = snapshot.data!;
          if (videos.isEmpty) {
            return FeedVacio(onSubirVideo: puedeSubir ? _abrirSubida : null);
          }

          return VideoScrollableView(
            videos: videos,
            repositorio: widget.repositorio,
            uid: widget.uid,
          );
        },
      ),
    );
  }
}

class _MensajeFeed extends StatelessWidget {
  final IconData icono;
  final String texto;

  const _MensajeFeed({required this.icono, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, color: Colors.white70, size: 48),
            const SizedBox(height: 12),
            Text(
              texto,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
