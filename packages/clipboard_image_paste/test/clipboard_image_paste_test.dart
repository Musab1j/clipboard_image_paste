import 'package:clipboard_image_paste/clipboard_image_paste.dart';
import 'package:clipboard_image_paste_platform_interface/clipboard_image_paste_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_platform.dart';

void main() {
  late FakeClipboardImagePastePlatform platform;

  setUp(() {
    platform = FakeClipboardImagePastePlatform();
    ClipboardImagePastePlatform.instance = platform;
  });

  test('hasImage reports whether the clipboard holds an image', () async {
    expect(await ClipboardImagePaste.hasImage(), isFalse);
    platform.image = testImage;
    expect(await ClipboardImagePaste.hasImage(), isTrue);
  });

  test('readImage returns null when there is no image', () async {
    expect(await ClipboardImagePaste.readImage(), isNull);
    expect(await ClipboardImagePaste.readImageBytes(), isNull);
  });

  test('readImage returns the image, readImageBytes its bytes', () async {
    platform.image = testImage;

    expect(await ClipboardImagePaste.readImage(), same(testImage));
    expect(await ClipboardImagePaste.readImageBytes(), same(testImage.bytes));
  });

  test('platform errors reach the caller', () async {
    platform
      ..image = testImage
      ..readError = StateError('denied');

    expect(ClipboardImagePaste.readImage(), throwsStateError);
  });
}
