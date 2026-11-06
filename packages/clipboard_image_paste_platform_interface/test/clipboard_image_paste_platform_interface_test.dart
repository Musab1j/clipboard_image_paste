import 'dart:typed_data';

import 'package:clipboard_image_paste_platform_interface/clipboard_image_paste_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class ExtendsPlatform extends ClipboardImagePastePlatform {}

class ImplementsPlatform implements ClipboardImagePastePlatform {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockPlatform
    with MockPlatformInterfaceMixin
    implements ClipboardImagePastePlatform {
  @override
  Future<bool> hasImage() async => true;

  @override
  Future<ClipboardImage?> readImage() async => null;
}

void main() {
  final initial = ClipboardImagePastePlatform.instance;

  tearDown(() => ClipboardImagePastePlatform.instance = initial);

  test('the default instance throws UnimplementedError', () {
    expect(initial.hasImage, throwsUnimplementedError);
    expect(initial.readImage, throwsUnimplementedError);
  });

  test('accepts implementations that extend the interface', () {
    final platform = ExtendsPlatform();
    ClipboardImagePastePlatform.instance = platform;
    expect(ClipboardImagePastePlatform.instance, same(platform));
  });

  test('rejects implementations that only implement the interface', () {
    expect(
      () => ClipboardImagePastePlatform.instance = ImplementsPlatform(),
      throwsA(isA<AssertionError>()),
    );
  });

  test('accepts mocks that use MockPlatformInterfaceMixin', () {
    final platform = MockPlatform();
    ClipboardImagePastePlatform.instance = platform;
    expect(ClipboardImagePastePlatform.instance, same(platform));
  });

  test('ClipboardImage.toString reports type and size, not the bytes', () {
    final image = ClipboardImage(
      bytes: Uint8List.fromList([1, 2, 3]),
      mimeType: 'image/png',
    );
    expect(image.toString(), 'ClipboardImage(mimeType: image/png, bytes: 3)');
  });
}
