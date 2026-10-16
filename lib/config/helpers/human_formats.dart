// human_formats.dart
//
// Formatos legibles para la UI (contadores de likes, etc.).

class HumanFormats {
  /// Convierte un contador en texto corto para los botones del feed.
  ///
  /// TODO(Integrante 4): devolver el número en formato compacto con el paquete
  /// `intl` (NumberFormat.compact). Ejemplos esperados:
  ///   0 -> '0', 999 -> '999', 1200 -> '1.2K', 15000 -> '15K', 2500000 -> '2.5M'
  /// Hoy devuelve el número tal cual para que la app compile y funcione.
  static String numeroLegible(int numero) => '$numero';
}
