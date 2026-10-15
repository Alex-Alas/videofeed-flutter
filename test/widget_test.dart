import 'package:flutter_test/flutter_test.dart';
import 'package:videofeed/firebase_options.dart';

void main() {
  test('la plantilla de firebase_options pide correr flutterfire configure', () {
    expect(() => DefaultFirebaseOptions.currentPlatform, throwsUnsupportedError);
  });
}
