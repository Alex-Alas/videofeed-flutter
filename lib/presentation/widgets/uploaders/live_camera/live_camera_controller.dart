// live_camera_controller.dart
//
// Lógica de la cámara en vivo con filtros: inicialización de cámaras,
// detección de rostros con ML Kit y publicación de la captura.
//
// No conoce nada de la UI más allá del `GlobalKey` del boundary que se
// captura; la presentación vive en `live_camera_screen.dart` y sus widgets.

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../domain/repositories/video_repository.dart';
import '../../../../infrastructure/datasources/storage_service.dart';
import '../../../../utils/facial_filters_utils.dart';

class LiveCameraController extends ChangeNotifier {
  final VideoRepository repositorio;
  final StorageService storage;
  final String uid;
  final String nombreUsuario;

  LiveCameraController({
    required this.repositorio,
    required this.storage,
    required this.uid,
    required this.nombreUsuario,
  });

  /// Boundary que se rasteriza al publicar (preview + filtros).
  final GlobalKey captureKey = GlobalKey();

  /// Título de la publicación. La barra inferior lo edita; aquí se conserva
  /// para que el estado sobreviva a los rebuilds.
  final TextEditingController tituloController = TextEditingController();

  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.fast,
      enableLandmarks: true,
    ),
  );

  List<CameraDescription> _cameras = const [];
  int _cameraIndex = 0;
  CameraController? _camera;

  List<Face> _faces = const [];
  Size? _frameSize;
  bool _isProcessing = false;

  ui.Image? _hatImage;
  ui.Image? _maskImage;

  String? _error;
  bool _publicando = false;
  double? _progreso;
  bool _mostrarSombrero = true;
  bool _mostrarMascara = true;
  bool _disposed = false;

  // --- Estado expuesto a la UI -------------------------------------------

  CameraController? get camera => _camera;
  String? get error => _error;
  bool get publicando => _publicando;
  double? get progreso => _progreso;
  List<Face> get faces => _faces;
  Size? get frameSize => _frameSize;
  ui.Image? get hatImage => _hatImage;
  ui.Image? get maskImage => _maskImage;
  bool get mostrarSombrero => _mostrarSombrero;
  bool get mostrarMascara => _mostrarMascara;
  bool get hayVariasCamaras => _cameras.length > 1;
  bool get camaraEsFrontal =>
      _camera?.description.lensDirection == CameraLensDirection.front;
  bool get lista =>
      _camera != null && _camera!.value.isInitialized;

  // --- Ciclo de vida ------------------------------------------------------

  Future<void> inicializar() async {
    await Future.wait([_cargarOverlays(), _iniciarCamaras()]);
  }

  @override
  void dispose() {
    _disposed = true;
    tituloController.dispose();
    _detenerCamara();
    _faceDetector.close();
    super.dispose();
  }

  void _notificar() {
    if (!_disposed) notifyListeners();
  }

  // --- Filtros ------------------------------------------------------------

  void alternarSombrero() {
    _mostrarSombrero = !_mostrarSombrero;
    _notificar();
  }

  void alternarMascara() {
    _mostrarMascara = !_mostrarMascara;
    _notificar();
  }

  // --- Cámara -------------------------------------------------------------

  Future<void> _iniciarCamaras() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        _error = 'Este dispositivo no tiene cámara.';
        _notificar();
        return;
      }

      final frontal = _cameras.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
      );
      _cameraIndex = frontal >= 0 ? frontal : 0;
      await _abrirCamara();
    } catch (e) {
      _error = 'No se pudo abrir la cámara: $e';
      _notificar();
    }
  }

  Future<void> _abrirCamara() async {
    final controller = CameraController(
      _cameras[_cameraIndex],
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );
    _camera = controller;
    await controller.initialize();
    if (_disposed) return;
    await controller.startImageStream(_procesarFrame);
    _notificar();
  }

  Future<void> _detenerCamara() async {
    final controller = _camera;
    _camera = null;
    if (controller == null) return;
    if (controller.value.isStreamingImages) {
      await controller.stopImageStream();
    }
    await controller.dispose();
  }

  Future<void> cambiarCamara() async {
    if (_cameras.length < 2) return;
    await _detenerCamara();
    _faces = const [];
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    await _abrirCamara();
  }

  // --- Detección de rostros ----------------------------------------------

  Future<void> _procesarFrame(CameraImage image) async {
    if (_isProcessing) return;
    final inputImage = _aInputImage(image);
    if (inputImage == null) return;

    _isProcessing = true;
    try {
      final faces = await _faceDetector.processImage(inputImage);
      if (_disposed) return;
      final rotation = inputImage.metadata!.rotation;
      final rotado = rotation == InputImageRotation.rotation90deg ||
          rotation == InputImageRotation.rotation270deg;
      _faces = faces;
      _frameSize = rotado
          ? Size(image.height.toDouble(), image.width.toDouble())
          : Size(image.width.toDouble(), image.height.toDouble());
      debugPrint('live camera: ${_faces.length} rostro(s)');
      _notificar();
    } catch (e) {
      debugPrint('Error al detectar rostros: $e');
    } finally {
      _isProcessing = false;
    }
  }

  InputImage? _aInputImage(CameraImage image) {
    final camera = _cameras[_cameraIndex];
    final rotation =
        InputImageRotationValue.fromRawValue(camera.sensorOrientation);
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (rotation == null || format == null) return null;
    if (Platform.isAndroid && format != InputImageFormat.nv21) return null;
    if (Platform.isIOS && format != InputImageFormat.bgra8888) return null;
    if (image.planes.length != 1) return null;

    final plane = image.planes.first;
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  // --- Assets de los overlays --------------------------------------------

  Future<void> _cargarOverlays() async {
    final hat = await cargarImagenDeAsset('assets/images/hat.png');
    final mask = await cargarImagenDeAsset('assets/images/mask.png');
    if (_disposed) return;
    _hatImage = hat;
    _maskImage = mask;
    _notificar();
  }

  // --- Captura y publicación ---------------------------------------------

  /// Rasteriza la vista actual y la sube como publicación.
  ///
  /// Devuelve `null` si se publicó correctamente, o un mensaje listo para
  /// mostrar al usuario si algo falló.
  Future<String?> capturarYPublicar() async {
    if (_publicando) return null;

    final camera = _camera;
    if (camera == null || !camera.value.isInitialized) {
      return 'La cámara no está lista.';
    }
    if (tituloController.text.trim().isEmpty) {
      return 'Escribe un título';
    }

    _publicando = true;
    _progreso = 0;
    _notificar();

    try {
      final bytes = await _capturarPreview();
      if (bytes == null) {
        throw Exception('No se pudo capturar la vista');
      }

      final archivo = await _guardarCaptura(bytes);

      final subida = await storage.subirVideo(
        archivo: archivo,
        uid: uid,
        onProgreso: (p) {
          _progreso = p;
          _notificar();
        },
      );

      await repositorio.crearVideo(
        Video(
          autorUid: uid,
          autorNombre: nombreUsuario,
          titulo: tituloController.text.trim(),
          videoUrl: subida.url,
          storagePath: subida.storagePath,
        ),
      );

      await archivo.delete();
      return null;
    } catch (e, stackTrace) {
      if (camera.value.isInitialized && !camera.value.isStreamingImages) {
        await camera.startImageStream(_procesarFrame);
      }
      debugPrint('ERROR PUBLICANDO FOTO: $e');
      debugPrint(stackTrace.toString());
      return 'No se pudo publicar la foto';
    } finally {
      _publicando = false;
      _progreso = null;
      _notificar();
    }
  }

  Future<Uint8List?> _capturarPreview() async {
    final boundary =
        captureKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;

    final image = await boundary.toImage(pixelRatio: 3);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  Future<File> _guardarCaptura(Uint8List bytes) async {
    final dir = await getTemporaryDirectory();
    final archivo =
        File('${dir.path}/${DateTime.now().millisecondsSinceEpoch}.png');
    await archivo.writeAsBytes(bytes);
    return archivo;
  }
}
