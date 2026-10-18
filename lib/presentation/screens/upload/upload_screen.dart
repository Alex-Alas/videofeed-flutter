// upload_screen.dart
//
// Tareas U-01..U-04: elegir un video de la galería, vista previa, título,
// progreso de subida y publicar. Límites: 50 MB y 60 s (storage.rules / U-04).

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import '../../../domain/repositories/video_repository.dart';
import '../../../infrastructure/datasources/storage_service.dart';
import '../../widgets/uploaders/live_camera/live_camera_screen.dart';

class UploadScreen extends StatefulWidget {
  static const Duration duracionMaxima = Duration(seconds: 60);
  static const int maxCaracteresTitulo = 200;

  final VideoRepository repositorio;
  final StorageService storage;
  final String uid;
  final String nombreUsuario;

  const UploadScreen({
    super.key,
    required this.repositorio,
    required this.storage,
    required this.uid,
    required this.nombreUsuario,
  });

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _picker = ImagePicker();

  File? _archivo;
  VideoPlayerController? _preview;
  double? _progreso;
  bool _publicando = false;

  @override
  void dispose() {
    _tituloController.dispose();
    _preview?.dispose();
    super.dispose();
  }

  Future<void> _elegirVideo() async {
    final elegido = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: UploadScreen.duracionMaxima,
    );
    if (elegido == null) return;

    if (!mounted) return;

    final archivo = File(elegido.path);
    final bytes = await archivo.length();
    if (bytes > StorageService.maxBytes) {
      _mostrarMensaje('El video pesa más de 50 MB. Elige uno más corto.');
      return;
    }

    final preview = VideoPlayerController.file(archivo);
    try {
      await preview.initialize();
    } catch (_) {
      await preview.dispose();
      _mostrarMensaje('No se pudo abrir ese video.');
      return;
    }

    // Un segundo de tolerancia por redondeos del contenedor.
    if (preview.value.duration >
        UploadScreen.duracionMaxima + const Duration(seconds: 1)) {
      await preview.dispose();
      _mostrarMensaje('El video dura más de 60 segundos.');
      return;
    }

    await preview.setLooping(true);
    await preview.play();

    // El usuario pudo salir de la pantalla mientras se abría el video.
    if (!mounted) {
      await preview.dispose();
      return;
    }

    final anterior = _preview;
    setState(() {
      _archivo = archivo;
      _preview = preview;
    });
    await anterior?.dispose();
  }

  Future<void> _publicar() async {
    FocusScope.of(context).unfocus();
    final archivo = _archivo;
    if (archivo == null) {
      _mostrarMensaje('Primero elige un video.');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    _preview?.pause();
    setState(() {
      _publicando = true;
      _progreso = 0;
    });

    try {
      final subida = await widget.storage.subirVideo(
        archivo: archivo,
        uid: widget.uid,
        onProgreso: (p) {
          if (mounted) setState(() => _progreso = p);
        },
      );

      try {
        await widget.repositorio.crearVideo(
          Video(
            autorUid: widget.uid,
            autorNombre: widget.nombreUsuario,
            titulo: _tituloController.text.trim(),
            videoUrl: subida.url,
            storagePath: subida.storagePath,
          ),
        );
      } catch (_) {
        // Sin documento nadie verá el archivo: se borra para no gastar cuota
        // y para que reintentar no deje copias duplicadas en Storage.
        await widget.storage.eliminarVideo(subida.storagePath);
        rethrow;
      }

      if (mounted) Navigator.of(context).pop(true);
    } on StorageFailure catch (e) {
      _mostrarMensaje(e.mensaje);
    } catch (_) {
      _mostrarMensaje('No se pudo publicar el video. Intenta de nuevo.');
    } finally {
      if (mounted) {
        setState(() {
          _publicando = false;
          _progreso = null;
        });
      }
    }
  }

  void _mostrarMensaje(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(mensaje), behavior: SnackBarBehavior.floating),
      );
  }

  String? _validarTitulo(String? valor) {
    final titulo = valor?.trim() ?? '';
    if (titulo.isEmpty) return 'Escribe un título.';
    if (titulo.length > UploadScreen.maxCaracteresTitulo) {
      return 'Máximo ${UploadScreen.maxCaracteresTitulo} caracteres.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final preview = _preview;

    return PopScope(
      // No se puede salir a mitad de la subida.
      canPop: !_publicando,
      child: Scaffold(
        appBar: AppBar(title: const Text('Subir video')),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _VistaPrevia(
                  controller: preview,
                  onElegir: _publicando ? null : _elegirVideo,
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _publicando ? null : ()  async {
                    final publicado = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => FiltrosEnVivoScreen(
                          repositorio: widget.repositorio,
                          storage: widget.storage,
                          uid: widget.uid,
                          nombreUsuario: widget.nombreUsuario) 
                        ),
                    );
                    if (!context.mounted) return;

                    if (publicado == true) {
                      Navigator.of(context).pop(true);
                    }
                  },
                  icon: const Icon(Icons.photo_camera),
                  label: const Text('Tomar fotografía'),
                ),
                const SizedBox(height: 12),
                if (preview != null)
                  TextButton.icon(
                    onPressed: _publicando ? null : _elegirVideo,
                    icon: const Icon(Icons.swap_horiz),
                    label: const Text('Elegir otro video'),
                  ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('campo-titulo'),
                  controller: _tituloController,
                  enabled: !_publicando,
                  maxLength: UploadScreen.maxCaracteresTitulo,
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Título',
                    prefixIcon: Icon(Icons.title),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(14)),
                    ),
                  ),
                  validator: _validarTitulo,
                ),
                const SizedBox(height: 16),
                if (_progreso != null) ...[
                  LinearProgressIndicator(value: _progreso),
                  const SizedBox(height: 8),
                  Text(
                    'Subiendo... ${((_progreso ?? 0) * 100).toStringAsFixed(0)} %',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                ],
                FilledButton.icon(
                  key: const Key('boton-publicar'),
                  onPressed: _publicando ? null : _publicar,
                  icon: const Icon(Icons.cloud_upload_outlined),
                  label: Text(_publicando ? 'Publicando...' : 'Publicar'),
                ),
                const SizedBox(height: 8),
                Text(
                  'Máximo 60 segundos y 50 MB.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VistaPrevia extends StatelessWidget {
  final VideoPlayerController? controller;
  final VoidCallback? onElegir;

  const _VistaPrevia({required this.controller, required this.onElegir});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final controller = this.controller;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 9 / 12,
        child: ColoredBox(
          color: Colors.black,
          child: controller == null
              ? InkWell(
                  key: const Key('boton-elegir-video'),
                  onTap: onElegir,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.video_library_outlined,
                        size: 56,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Toca para elegir un video',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                )
              : Center(
                  child: AspectRatio(
                    aspectRatio: controller.value.aspectRatio,
                    child: VideoPlayer(controller),
                  ),
                ),
        ),
      ),
    );
  }
}
