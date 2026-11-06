import 'package:clipboard_image_paste_platform_interface/clipboard_image_paste_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// A clipboard that holds [image], or throws [readError] when it is read.
class FakeClipboardImagePastePlatform
    with MockPlatformInterfaceMixin
    implements ClipboardImagePastePlatform {
  ClipboardImage? image;
  Object? readError;

  int hasImageCalls = 0;
  int readImageCalls = 0;

  @override
  Future<bool> hasImage() async {
    hasImageCalls++;
    return image != null;
  }

  @override
  Future<ClipboardImage?> readImage() async {
    readImageCalls++;
    if (readError case final error?) {
      throw error;
    }
    return image;
  }
}

/// Puts [text] on the mocked system clipboard that text fields paste from,
/// or empties it when null.
void setClipboardText(WidgetTester tester, String? text) {
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      switch (call.method) {
        case 'Clipboard.getData':
          return text == null ? null : <String, Object?>{'text': text};
        case 'Clipboard.hasStrings':
          return <String, Object?>{'value': text != null};
      }
      return null;
    },
  );
}

final testImage = ClipboardImage(
  bytes: Uint8List.fromList(<int>[137, 80, 78, 71]),
  mimeType: 'image/png',
);
