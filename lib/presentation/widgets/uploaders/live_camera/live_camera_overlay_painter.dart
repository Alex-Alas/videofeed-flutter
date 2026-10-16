// live_camera_overlay_painter.dart
//
// Dibuja los filtros (sombrero / máscara) sobre cada rostro detectado en el
// preview en vivo. El canvas debe estar en coordenadas del frame procesado
// por ML Kit: la geometría la resuelve `facial_filters_utils.dart`.

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../../../../utils/facial_filters_utils.dart';

class FiltrosEnVivoPainter extends CustomPainter {
  final List<Face> faces;
  final Size frameSize;
  final bool mirror;
  final ui.Image? hat;
  final ui.Image? mask;

  FiltrosEnVivoPainter({
    required this.faces,
    required this.frameSize,
    required this.mirror,
    required this.hat,
    required this.mask,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    if (mirror) {
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
    }
    canvas.scale(size.width / frameSize.width, size.height / frameSize.height);

    for (final face in faces) {
      pintarFiltrosEnRostro(
        canvas: canvas,
        face: face,
        hat: hat,
        mask: mask,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant FiltrosEnVivoPainter oldDelegate) {
    return oldDelegate.faces != faces ||
        oldDelegate.frameSize != frameSize ||
        oldDelegate.mirror != mirror ||
        oldDelegate.hat != hat ||
        oldDelegate.mask != mask;
  }
}
