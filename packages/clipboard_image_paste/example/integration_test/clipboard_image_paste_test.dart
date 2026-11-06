// Runs on a device against the real Android or iOS implementation:
//
//   flutter test integration_test
//
// Dart can only put text on the clipboard, so this checks the channel wiring
// and the no-image answers. Pasting a real image is covered by the native
// unit tests and by trying the example app.

import 'package:clipboard_image_paste/clipboard_image_paste.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a text-only clipboard has no image', (tester) async {
    await Clipboard.setData(const ClipboardData(text: 'clipboard_image_paste'));

    expect(await ClipboardImagePaste.hasImage(), isFalse);
    expect(await ClipboardImagePaste.readImage(), isNull);
    expect(await ClipboardImagePaste.readImageBytes(), isNull);
  });
}
