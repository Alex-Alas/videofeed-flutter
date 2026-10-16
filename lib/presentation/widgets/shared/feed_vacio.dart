// feed_vacio.dart
//
// Lo que ve el usuario cuando todavía no hay videos en el feed.

import 'package:flutter/material.dart';

class FeedVacio extends StatelessWidget {
  /// Abre la pantalla de subir video; si es null no se muestra el botón.
  final VoidCallback? onSubirVideo;

  const FeedVacio({super.key, this.onSubirVideo});

  // TODO(Integrante 5): convertir este texto en un estado vacío completo:
  //  1. Un ícono grande (por ejemplo Icons.video_library_outlined) en blanco.
  //  2. Título "Aún no hay videos" y un subtítulo "Sé el primero en subir uno".
  //  3. Si onSubirVideo no es null, un FilledButton.icon con Icons.add y el
  //     texto "Subir video" que llame a onSubirVideo.
  //  Todo centrado y con texto blanco (el feed tiene fondo negro).
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Aún no hay videos',
        style: TextStyle(color: Colors.white),
      ),
    );
  }
}
