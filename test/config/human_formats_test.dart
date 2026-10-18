import 'package:flutter_test/flutter_test.dart';
import 'package:videofeed/config/helpers/human_formats.dart';

void main() {
  group('HumanFormats.numeroLegible', () {
    test('formatea contadores compactos', () {
      expect(HumanFormats.numeroLegible(0), '0');
      expect(HumanFormats.numeroLegible(999), '999');
      expect(HumanFormats.numeroLegible(1200), '1.2K');
      expect(HumanFormats.numeroLegible(15000), '15K');
      expect(HumanFormats.numeroLegible(2400000), '2.4M');
    });

    test('conserva precisión útil para contadores del demo', () {
      expect(HumanFormats.numeroLegible(1250), '1.25K');
      expect(HumanFormats.numeroLegible(15300), '15.3K');
    });
  });
}
