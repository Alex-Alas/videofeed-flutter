// human_formats.dart
//
// Formatos legibles para la UI (contadores de likes, etc.).

import 'package:intl/intl.dart';

class HumanFormats {
  /// Convierte un contador en texto corto para los botones del feed.
  static String numeroLegible(int numero) =>
      NumberFormat.compact(locale: 'en').format(numero);
}
