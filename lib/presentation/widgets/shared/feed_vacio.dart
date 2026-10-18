// feed_vacio.dart
//
// Lo que ve el usuario cuando todavía no hay videos en el feed.

import 'package:flutter/material.dart';

class FeedVacio extends StatelessWidget {
  final VoidCallback? onSubirVideo;

  const FeedVacio({super.key, this.onSubirVideo});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.video_library_outlined,
              size: 80,
              color: Colors.white,
            ),
            const SizedBox(height: 16),
            const Text(
              'Aún no hay videos',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sé el primero en subir uno',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white),
            ),
            if (onSubirVideo != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onSubirVideo,
                icon: const Icon(Icons.add),
                label: const Text('Subir video'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}