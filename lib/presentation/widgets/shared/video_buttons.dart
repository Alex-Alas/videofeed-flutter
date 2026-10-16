// video_buttons.dart
//
// Tarea L-02: botones laterales del video (like con contador).
// El estado del like viene de VideoRepository.yaDiLike (tiempo real) y el
// contador del propio Video, que se actualiza cuando el feed vuelve a emitir.

import 'package:flutter/material.dart';

import '../../../config/helpers/human_formats.dart';
import '../../../domain/repositories/video_repository.dart';

class VideoButtons extends StatefulWidget {
  final Video video;
  final VideoRepository repositorio;
  final String uid;

  const VideoButtons({
    super.key,
    required this.video,
    required this.repositorio,
    required this.uid,
  });

  @override
  State<VideoButtons> createState() => _VideoButtonsState();
}

class _VideoButtonsState extends State<VideoButtons> {
  late Stream<bool> _yaDiLike;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    _yaDiLike = widget.repositorio.yaDiLike(widget.video.id, widget.uid);
  }

  @override
  void didUpdateWidget(covariant VideoButtons oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.video.id != widget.video.id ||
        oldWidget.uid != widget.uid ||
        oldWidget.repositorio != widget.repositorio) {
      _yaDiLike = widget.repositorio.yaDiLike(widget.video.id, widget.uid);
    }
  }

  Future<void> _alternarLike(bool diLike) async {
    if (_enviando) return;
    setState(() => _enviando = true);
    try {
      if (diLike) {
        await widget.repositorio.quitarLike(widget.video.id, widget.uid);
      } else {
        await widget.repositorio.darLike(widget.video.id, widget.uid);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('No se pudo registrar el like.')),
          );
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: _yaDiLike,
      builder: (context, snapshot) {
        final diLike = snapshot.data ?? false;
        return _BotonConContador(
          key: const Key('boton-like'),
          icono: diLike ? Icons.favorite : Icons.favorite_border,
          color: diLike ? Colors.red : Colors.white,
          valor: widget.video.likes,
          tooltip: diLike ? 'Quitar like' : 'Dar like',
          onPressed: () => _alternarLike(diLike),
        );
      },
    );
  }
}

class _BotonConContador extends StatelessWidget {
  final IconData icono;
  final Color color;
  final int valor;
  final String tooltip;
  final VoidCallback onPressed;

  const _BotonConContador({
    super.key,
    required this.icono,
    required this.color,
    required this.valor,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onPressed,
          tooltip: tooltip,
          icon: Icon(icono, color: color, size: 34),
        ),
        Text(
          HumanFormats.numeroLegible(valor),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
