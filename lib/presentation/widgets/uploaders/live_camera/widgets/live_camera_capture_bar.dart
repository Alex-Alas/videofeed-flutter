// live_camera_capture_bar.dart
//
// Barra inferior de la cámara en vivo: el título (pill que se expande) pegado
// al único botón principal, centrado en la parte de abajo.

import 'package:flutter/material.dart';

import '../live_camera_controller.dart';

class LiveCameraCaptureBar extends StatefulWidget {
  final LiveCameraController controller;
  final VoidCallback onCapturar;

  const LiveCameraCaptureBar({
    super.key,
    required this.controller,
    required this.onCapturar,
  });

  @override
  State<LiveCameraCaptureBar> createState() => _LiveCameraCaptureBarState();
}

class _LiveCameraCaptureBarState extends State<LiveCameraCaptureBar> {
  final FocusNode _focusTitulo = FocusNode();
  bool _editandoTitulo = false;

  @override
  void dispose() {
    _focusTitulo.dispose();
    super.dispose();
  }

  void _expandirTitulo() {
    if (widget.controller.publicando) return;
    setState(() => _editandoTitulo = true);
    _focusTitulo.requestFocus();
  }

  void _colapsarTitulo() {
    _focusTitulo.unfocus();
    setState(() => _editandoTitulo = false);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: _editandoTitulo ? _campoTitulo() : _pillTitulo(),
            ),
            const SizedBox(height: 14),
            _BotonCaptura(
              publicando: widget.controller.publicando,
              onPressed: widget.controller.publicando
                  ? null
                  : widget.onCapturar,
            ),
          ],
        ),
      ),
    );
  }

  Widget _pillTitulo() {
    final texto = widget.controller.tituloController.text.trim();
    final tieneTexto = texto.isNotEmpty;

    return Align(
      key: const ValueKey('pill'),
      alignment: Alignment.center,
      child: Material(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _expandirTitulo,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.edit, color: Colors.white70, size: 18),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    tieneTexto ? texto : 'Agrega un título…',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: tieneTexto ? Colors.white : Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _campoTitulo() {
    return Row(
      key: const ValueKey('campo'),
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: TextField(
            controller: widget.controller.tituloController,
            focusNode: _focusTitulo,
            enabled: !widget.controller.publicando,
            minLines: 1,
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _colapsarTitulo(),
            style: const TextStyle(color: Colors.white),
            cursorColor: Colors.white,
            decoration: InputDecoration(
              hintText: 'Escribe un título…',
              hintStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: Colors.black45,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Material(
          color: Colors.black45,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _colapsarTitulo,
            customBorder: const CircleBorder(),
            child: const SizedBox(
              width: 46,
              height: 46,
              child: Icon(Icons.check, color: Colors.white, size: 22),
            ),
          ),
        ),
      ],
    );
  }
}

class _BotonCaptura extends StatelessWidget {
  final bool publicando;
  final VoidCallback? onPressed;

  const _BotonCaptura({required this.publicando, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final primario = Theme.of(context).colorScheme.primary;

    return Semantics(
      button: true,
      label: 'Tomar fotografía',
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
          ),
          padding: const EdgeInsets.all(6),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: publicando
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: primario,
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}
