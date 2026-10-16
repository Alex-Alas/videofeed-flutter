// video_background.dart
//
// Degradado sobre el video para que el texto blanco se lea bien.

import 'package:flutter/material.dart';

class VideoBackground extends StatelessWidget {
  final List<Color> colors;
  final List<double> stops;

  const VideoBackground({
    super.key,
    this.colors = const [Colors.transparent, Colors.black87],
    this.stops = const [0.0, 1.0],
  }) : assert(colors.length == stops.length,
            'colors y stops deben tener la misma longitud');

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              stops: stops,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
    );
  }
}
