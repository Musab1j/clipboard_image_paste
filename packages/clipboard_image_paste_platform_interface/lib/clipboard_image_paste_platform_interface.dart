import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'src/clipboard_image.dart';

export 'src/clipboard_image.dart';

/// The interface that implementations of clipboard_image_paste must extend.
///
/// Platform implementations should extend this class rather than implement it,
/// because `implements` does not consider newly added methods to be breaking
/// changes. Extending this class (using `extends`) ensures that the subclass
/// gets the default implementation, while platform implementations that
/// `implements` this interface will be broken by newly added methods.
abstract class ClipboardImagePastePlatform extends PlatformInterface {
  /// Constructs a ClipboardImagePastePlatform.
  ClipboardImagePastePlatform() : super(token: _token);

  static final Object _token = Object();

  static ClipboardImagePastePlatform _instance = _PlaceholderImplementation();

  /// The default instance of [ClipboardImagePastePlatform] to use.
  ///
  /// Platform packages register themselves here at startup. Until one does
  /// (for example on a platform this plugin doesn't support), every method
  /// throws [UnimplementedError].
  static ClipboardImagePastePlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [ClipboardImagePastePlatform] when
  /// they register themselves.
  static set instance(ClipboardImagePastePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Whether the clipboard currently holds an image.
  ///
  /// Implementations must answer without reading the clipboard contents, so
  /// that calling this never shows a paste-permission prompt or toast.
  Future<bool> hasImage() {
    throw UnimplementedError('hasImage() has not been implemented.');
  }

  /// Reads the image on the clipboard, or returns `null` if there is none.
  Future<ClipboardImage?> readImage() {
    throw UnimplementedError('readImage() has not been implemented.');
  }
}

/// Used until a platform package registers, so that unsupported platforms get
/// a clear [UnimplementedError] instead of a missing-plugin exception.
class _PlaceholderImplementation extends ClipboardImagePastePlatform {}
