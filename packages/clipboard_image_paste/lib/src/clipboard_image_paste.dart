import 'package:clipboard_image_paste_platform_interface/clipboard_image_paste_platform_interface.dart';
import 'package:flutter/services.dart';

import 'image_paste_scope.dart';

/// Reads images from the system clipboard on Android and iOS.
///
/// ```dart
/// final bytes = await ClipboardImagePaste.readImageBytes();
/// if (bytes == null) {
///   // No image on the clipboard: fall back to a normal text paste.
/// }
/// ```
///
/// To let users paste images into a text field, wrap it in an
/// [ImagePasteScope] instead of calling these yourself.
///
/// On platforms other than Android and iOS every method throws
/// [UnimplementedError].
abstract final class ClipboardImagePaste {
  /// Whether the clipboard currently holds an image.
  ///
  /// This only looks at what kinds of data the clipboard holds, never at the
  /// data itself. So it doesn't show iOS's "Allow Paste" prompt or Android's
  /// "pasted from your clipboard" toast, and is cheap enough to call every
  /// time a paste menu opens.
  static Future<bool> hasImage() {
    return ClipboardImagePastePlatform.instance.hasImage();
  }

  /// Reads the image on the clipboard, or returns `null` if there is none.
  ///
  /// The bytes are the clipboard's own encoding of the image (see
  /// [ClipboardImage.mimeType]). When the clipboard offers several formats,
  /// GIF is preferred so animations survive, then PNG, JPEG, HEIC, HEIF,
  /// WebP, TIFF and BMP. On iOS, an image that is only available as a
  /// `UIImage` is encoded as PNG.
  ///
  /// Call this in response to a paste gesture, and check [hasImage] first:
  ///
  ///  * On iOS 16 and later, reading what another app copied shows the
  ///    system's "Allow Paste" prompt, unless the user has set "Paste from
  ///    Other Apps" to Allow in your app's settings.
  ///  * On Android 12 and later, the system shows a toast saying the app
  ///    pasted from the clipboard.
  ///  * On Android 10 and later, only the app with input focus can read the
  ///    clipboard. At other times this returns `null`.
  ///
  /// Throws a [PlatformException] with code `read_failed` on Android if the
  /// clipboard holds an image the app isn't allowed to open, or that has
  /// since been deleted.
  static Future<ClipboardImage?> readImage() {
    return ClipboardImagePastePlatform.instance.readImage();
  }

  /// Reads the encoded bytes of the image on the clipboard, or returns
  /// `null` if there is none.
  ///
  /// The same as [readImage] without the MIME type.
  static Future<Uint8List?> readImageBytes() async {
    final image = await readImage();
    return image?.bytes;
  }
}
