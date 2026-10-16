// app_theme.dart
//
// Tema global de VideoFeed (claro y oscuro) con la semilla teal acordada.
// El feed siempre se pinta sobre fondo negro, como TikTok, sin importar el tema.

import 'package:flutter/material.dart';

class AppTheme {
  static const Color _semilla = Colors.teal;

  static ThemeData claro() => ThemeData(
        colorSchemeSeed: _semilla,
        useMaterial3: true,
      );

  static ThemeData oscuro() => ThemeData(
        colorSchemeSeed: _semilla,
        brightness: Brightness.dark,
        useMaterial3: true,
      );
}
