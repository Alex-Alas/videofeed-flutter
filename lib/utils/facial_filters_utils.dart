import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'dart:math' as math;


Future<ui.Image> cargarImagenDeAsset(String assetPath) async {
  final data = await rootBundle.load(assetPath);
  final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
  final frame = await codec.getNextFrame();
  return frame.image;
}

void pintarFiltrosEnRostro({
  required ui.Canvas canvas,
  required Face face,
  required ui.Image? hat,
  required ui.Image? mask,
}) {
  final leftEye = face.landmarks[FaceLandmarkType.leftEye]?.position;
  final rightEye = face.landmarks[FaceLandmarkType.rightEye]?.position;
  final noseBase = face.landmarks[FaceLandmarkType.noseBase]?.position;
  final leftMouth = face.landmarks[FaceLandmarkType.leftMouth]?.position;
  final rightMouth = face.landmarks[FaceLandmarkType.rightMouth]?.position;
  final bottomMouth = face.landmarks[FaceLandmarkType.bottomMouth]?.position;

  if (hat != null && leftEye != null && rightEye != null) {
    _drawBetweenAnchors(
      canvas: canvas,
      overlay: hat,
      anchorA: Offset(leftEye.x.toDouble(), leftEye.y.toDouble()),
      anchorB: Offset(rightEye.x.toDouble(), rightEye.y.toDouble()),
      widthFactor: 2.5,
    );
  }

  if (mask != null && leftMouth != null && rightMouth != null) {
    final centerX = (leftMouth.x + rightMouth.x) / 2.0;
    final mouthTopY = bottomMouth != null
        ? bottomMouth.y.toDouble()
        : (leftMouth.y + rightMouth.y) / 2.0;
    final centerY = noseBase != null
        ? (noseBase.y.toDouble() -20)
        : mouthTopY - 14;
    final angle = math.atan2(
      (rightMouth.y - leftMouth.y).toDouble(),
      (rightMouth.x - leftMouth.x).toDouble(),
    );
    final mouthWidth = (rightMouth.x - leftMouth.x).abs().toDouble();
    _drawAt(
      canvas: canvas,
      overlay: mask,
      center: Offset(centerX, centerY),
      angle: angle,
      targetWidth: mouthWidth * 3.6,
    );
  }
}

void _drawBetweenAnchors({
  required ui.Canvas canvas,
  required ui.Image overlay,
  required Offset anchorA,
  required Offset anchorB,
  required double widthFactor,
}) {
  final center = Offset(
    (anchorA.dx + anchorB.dx) / 2,
    (anchorA.dy + anchorB.dy) / 2 - 210,
  );
  final dx = anchorB.dx - anchorA.dx;
  final dy = anchorB.dy - anchorA.dy;
  final distance = math.sqrt(dx * dx + dy * dy);
  final angle = math.atan2(dy, dx);
  _drawAt(
    canvas: canvas,
    overlay: overlay,
    center: center,
    angle: angle,
    targetWidth: distance * widthFactor,
  );
}

void _drawAt({
  required ui.Canvas canvas,
  required ui.Image overlay,
  required Offset center,
  required double angle,
  required double targetWidth,
}) {
  final scaleFactor = targetWidth / overlay.width;
  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.rotate(angle);
  canvas.scale(scaleFactor);
  canvas.drawImage(
    overlay,
    Offset(-overlay.width / 2, -overlay.height / 2),
    ui.Paint(),
  );
  canvas.restore();
}