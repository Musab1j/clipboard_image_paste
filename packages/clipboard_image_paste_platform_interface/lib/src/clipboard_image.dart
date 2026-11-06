import 'package:flutter/foundation.dart';

/// An image read from the system clipboard.
///
/// [bytes] are the encoded image exactly as the clipboard holds it (PNG,
/// JPEG, GIF, HEIC, WebP, ...), so they can be shown with `Image.memory`,
/// uploaded, or written to a file without re-encoding. [mimeType] says which
/// format that is.
@immutable
class ClipboardImage {
  /// Creates a clipboard image from its encoded [bytes] and [mimeType].
  const ClipboardImage({required this.bytes, required this.mimeType});

  /// The encoded image data.
  final Uint8List bytes;

  /// The MIME type of [bytes], such as `image/png` or `image/gif`.
  final String mimeType;

  @override
  String toString() =>
      'ClipboardImage(mimeType: $mimeType, bytes: ${bytes.length})';
}
