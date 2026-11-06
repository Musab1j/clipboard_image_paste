import 'dart:typed_data';

import 'package:clipboard_image_paste_platform_interface/clipboard_image_paste_platform_interface.dart';
import 'package:clipboard_image_paste_android/clipboard_image_paste_android.dart';
import 'package:clipboard_image_paste_android/src/messages.g.dart';
import 'package:flutter_test/flutter_test.dart';

/// Answers the host API calls without a platform channel.
class FakeClipboardImageApi implements ClipboardImageApi {
  bool hasImageReply = false;
  PlatformClipboardImage? readImageReply;

  @override
  Future<bool> hasImage() async => hasImageReply;

  @override
  Future<PlatformClipboardImage?> readImage() async => readImageReply;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeClipboardImageApi api;
  late ClipboardImagePasteAndroid platform;

  setUp(() {
    api = FakeClipboardImageApi();
    platform = ClipboardImagePasteAndroid(api: api);
  });

  test('registerWith sets the default instance', () {
    ClipboardImagePasteAndroid.registerWith();
    expect(
      ClipboardImagePastePlatform.instance,
      isA<ClipboardImagePasteAndroid>(),
    );
  });

  test('hasImage forwards the host answer', () async {
    expect(await platform.hasImage(), isFalse);
    api.hasImageReply = true;
    expect(await platform.hasImage(), isTrue);
  });

  test('readImage returns null when the host has no image', () async {
    expect(await platform.readImage(), isNull);
  });

  test('readImage maps the host image to a ClipboardImage', () async {
    final bytes = Uint8List.fromList([137, 80, 78, 71]);
    api.readImageReply = PlatformClipboardImage(
      bytes: bytes,
      mimeType: 'image/png',
    );

    final image = await platform.readImage();

    expect(image, isNotNull);
    expect(image!.bytes, bytes);
    expect(image.mimeType, 'image/png');
  });
}
