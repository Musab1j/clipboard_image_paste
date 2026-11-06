import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/messages.g.dart',
    kotlinOut:
        'android/src/main/kotlin/io/github/musab1j/clipboard_image_paste/Messages.g.kt',
    kotlinOptions: KotlinOptions(
      package: 'io.github.musab1j.clipboard_image_paste',
    ),
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
  /// Whether the clipboard holds an image, judged from its description only.
  bool hasImage();

  /// The first image on the clipboard, or null if there is none.
  ///
  /// Runs on a background thread because the image is streamed from a content
  /// provider that may be slow or remote.
  @TaskQueue(type: TaskQueueType.serialBackgroundThread)
  PlatformClipboardImage? readImage();
}
