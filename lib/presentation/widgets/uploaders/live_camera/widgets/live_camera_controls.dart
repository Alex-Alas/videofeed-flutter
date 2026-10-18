// live_camera_controls.dart
//
// Capa flotante superior derecha: cerrar, cambiar cámara y los toggles de
// filtros (sombrero / máscara). Todo con el mismo botón circular.

import 'package:flutter/material.dart';

import '../live_camera_controller.dart';

class LiveCameraControls extends StatelessWidget {
  final LiveCameraController controller;
  final VoidCallback onCerrar;

  const LiveCameraControls({
    super.key,
    required this.controller,
    required this.onCerrar,
  });

  @override
  Widget build(BuildContext context) {
    final bloqueado = controller.publicando;
    final listo = controller.lista && !bloqueado;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _BotonCircular(
              icon: Icons.close,
              tooltip: 'Cerrar',
              onPressed: bloqueado ? null : onCerrar,
            ),
            const SizedBox(height: 12),
            if (controller.hayVariasCamaras)
              _BotonCircular(
                icon: Icons.cameraswitch_outlined,
                tooltip: 'Cambiar cámara',
                onPressed: listo ? controller.cambiarCamara : null,
              ),
            const SizedBox(height: 12),
            _BotonCircular(
              icon: Icons.emoji_people,
              tooltip: controller.mostrarSombrero
                  ? 'Quitar sombrero'
                  : 'Poner sombrero',
              activo: controller.mostrarSombrero,
              onPressed: bloqueado ? null : controller.alternarSombrero,
            ),
            const SizedBox(height: 12),
            _BotonCircular(
              icon: Icons.masks,
              tooltip: controller.mostrarMascara
                  ? 'Quitar máscara'
                  : 'Poner máscara',
              activo: controller.mostrarMascara,
              onPressed: bloqueado ? null : controller.alternarMascara,
            ),
          ],
        ),
      ),
    );
  }
}

class _BotonCircular extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool activo;

  const _BotonCircular({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.activo = false,
  });

  @override
  Widget build(BuildContext context) {
    final habilitado = onPressed != null;
    final primario = Theme.of(context).colorScheme.primary;

    final Color fondo = activo ? primario : Colors.black38;
    final Color colorIcono = habilitado ? Colors.white : Colors.white38;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: fondo,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 46,
            height: 46,
            child: Icon(icon, color: colorIcono, size: 22),
          ),
        ),
      ),
    );
  }
}
