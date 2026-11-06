import 'package:clipboard_image_paste_platform_interface/clipboard_image_paste_platform_interface.dart';
import 'package:flutter/foundation.dart';

import 'src/messages.g.dart';

/// The Android implementation of [ClipboardImagePastePlatform].
///
/// Registered automatically by the Flutter tool when an app depends on
/// `clipboard_image_paste`; apps don't use this class directly.
class ClipboardImagePasteAndroid extends ClipboardImagePastePlatform {
  /// Creates the Android implementation, talking to the host through [api].
  ClipboardImagePasteAndroid({@visibleForTesting ClipboardImageApi? api})
    : _api = api ?? ClipboardImageApi();

  final ClipboardImageApi _api;

  /// Registers this class as the default instance of
  /// [ClipboardImagePastePlatform].
  static void registerWith() {
    ClipboardImagePastePlatform.instance = ClipboardImagePasteAndroid();
  }

  @override
  Future<bool> hasImage() => _api.hasImage();

  @override
  Future<ClipboardImage?> readImage() async {
    final image = await _api.readImage();
    return image == null
        ? null
        : ClipboardImage(bytes: image.bytes, mimeType: image.mimeType);
  }
}
