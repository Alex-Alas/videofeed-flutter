import 'package:flutter_test/flutter_test.dart';
import 'package:videofeed/firebase_options.dart';

void main() {
  test('firebase_options apunta al proyecto videofeed-grupo', () {
    expect(DefaultFirebaseOptions.android.projectId, 'videofeed-grupo');
  });
}
