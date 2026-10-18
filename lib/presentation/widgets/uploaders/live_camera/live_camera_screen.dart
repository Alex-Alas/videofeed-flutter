// live_camera_screen.dart
//
// Pantalla de cámara en vivo con filtros faciales (estilo IG/TikTok):
// preview inmersivo a pantalla completa, controles flotantes arriba a la
// derecha y un único botón de captura abajo al centro con el título pegado.
//
// La lógica de cámara, ML Kit y publicación vive en `LiveCameraController`.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../domain/repositories/video_repository.dart';
import '../../../../infrastructure/datasources/storage_service.dart';
import 'live_camera_controller.dart';
import 'widgets/live_camera_capture_bar.dart';
import 'widgets/live_camera_controls.dart';
import 'widgets/live_camera_preview.dart';

class FiltrosEnVivoScreen extends StatefulWidget {
  final VideoRepository repositorio;
  final StorageService storage;
  final String uid;
  final String nombreUsuario;

  const FiltrosEnVivoScreen({
    super.key,
    required this.repositorio,
    required this.storage,
    required this.uid,
    required this.nombreUsuario,
  });

  @override
  State<FiltrosEnVivoScreen> createState() => _FiltrosEnVivoScreenState();
}

class _FiltrosEnVivoScreenState extends State<FiltrosEnVivoScreen> {
  late final LiveCameraController _controller;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _controller = LiveCameraController(
      repositorio: widget.repositorio,
      storage: widget.storage,
      uid: widget.uid,
      nombreUsuario: widget.nombreUsuario,
    );
    _controller.inicializar();
  }

  @override
  void dispose() {
    _controller.dispose();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  void _mostrarMensaje(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(mensaje), behavior: SnackBarBehavior.floating),
      );
  }

  void _cerrar() {
    if (_controller.publicando) return;
    Navigator.of(context).pop(false);
  }

  Future<void> _capturar() async {
    final error = await _controller.capturarYPublicar();
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop(true);
    } else {
      _mostrarMensaje(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return PopScope(
          canPop: !_controller.publicando,
          child: AnnotatedRegion<SystemUiOverlayStyle>(
            value: const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.light,
              statusBarBrightness: Brightness.dark,
              systemNavigationBarColor: Colors.black,
              systemNavigationBarIconBrightness: Brightness.light,
            ),
            child: Scaffold(
              backgroundColor: Colors.black,
              body: _contenido(),
            ),
          ),
        );
      },
    );
  }

  Widget _contenido() {
    final error = _controller.error;
    if (error != null) {
      return _MensajeCentral(texto: error);
    }
    if (!_controller.lista) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        LiveCameraPreview(controller: _controller),
        if (_controller.publicando)
          _OverlayPublicando(progreso: _controller.progreso),
        Positioned(
          top: 0,
          right: 0,
          child: LiveCameraControls(
            controller: _controller,
            onCerrar: _cerrar,
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: LiveCameraCaptureBar(
            controller: _controller,
            onCapturar: _capturar,
          ),
        ),
      ],
    );
  }
}

class _MensajeCentral extends StatelessWidget {
  final String texto;

  const _MensajeCentral({required this.texto});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          texto,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70),
        ),
      ),
    );
  }
}

class _OverlayPublicando extends StatelessWidget {
  final double? progreso;

  const _OverlayPublicando({required this.progreso});

  @override
  Widget build(BuildContext context) {
    final porcentaje = progreso == null
        ? null
        : '${(progreso! * 100).toStringAsFixed(0)}%';

    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black54,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text(
                porcentaje == null ? 'Subiendo…' : 'Subiendo… $porcentaje',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
