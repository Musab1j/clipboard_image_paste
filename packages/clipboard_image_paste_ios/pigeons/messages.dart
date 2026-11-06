import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/messages.g.dart',
    swiftOut:
        'ios/clipboard_image_paste_ios/Sources/clipboard_image_paste_ios/Messages.g.swift',
  ),
)
/// An image read from the clipboard, as encoded bytes plus their MIME type.
class PlatformClipboardImage {
  PlatformClipboardImage({required this.bytes, required this.mimeType});

  Uint8List bytes;
  String mimeType;
}

@HostApi()
abstract class ClipboardImageApi {
  /// Whether the pasteboard holds an image. Never triggers the paste prompt.
  bool hasImage();

  /// The best image representation on the pasteboard, or nil if there is none.
  ///
  /// Runs on a background queue: the read blocks while iOS shows the paste
  /// permission prompt, and PNG-encoding a large image takes a while.
  @TaskQueue(type: TaskQueueType.serialBackgroundThread)
  PlatformClipboardImage? readImage();
}
