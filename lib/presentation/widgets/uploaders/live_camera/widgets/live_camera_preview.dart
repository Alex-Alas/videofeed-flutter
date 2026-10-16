// live_camera_preview.dart
//
// Preview de la cámara a pantalla completa (cover) con los filtros dibujados
// encima. El `RepaintBoundary` es el que se rasteriza al publicar.

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../live_camera_controller.dart';
import '../live_camera_overlay_painter.dart';

class LiveCameraPreview extends StatelessWidget {
  final LiveCameraController controller;

  const LiveCameraPreview({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final camera = controller.camera;
    if (camera == null) return const SizedBox.shrink();

    return RepaintBoundary(
      key: controller.captureKey,
      child: ClipRect(
        child: FittedBox(
          // Cover: llena la pantalla recortando el sobrante. Preview y filtros
          // viven en el mismo box, así que el recorte los afecta por igual.
          fit: BoxFit.cover,
          child: SizedBox(
            width: _anchoVertical(camera),
            height: _altoVertical(camera),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CameraPreview(camera),
                if (controller.frameSize != null)
                  CustomPaint(
                    painter: FiltrosEnVivoPainter(
                      faces: controller.faces,
                      frameSize: controller.frameSize!,
                      mirror: controller.camaraEsFrontal,
                      hat: controller.mostrarSombrero ? controller.hatImage : null,
                      mask: controller.mostrarMascara ? controller.maskImage : null,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// `previewSize` viene en horizontal; en vertical se invierten sus lados.
  double _anchoVertical(CameraController camera) {
    final size = camera.value.previewSize;
    return size != null ? size.height : 9;
  }

  double _altoVertical(CameraController camera) {
    final size = camera.value.previewSize;
    return size != null ? size.width : 16;
  }
}
