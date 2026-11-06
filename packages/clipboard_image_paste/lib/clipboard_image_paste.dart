/// Paste images from the system clipboard on Android and iOS.
///
/// Use [ClipboardImagePaste] to check for and read the clipboard image, and
/// [ImagePasteScope] to let users paste images into text fields.
library;

import 'src/clipboard_image_paste.dart';
import 'src/image_paste_scope.dart';

export 'package:clipboard_image_paste_platform_interface/clipboard_image_paste_platform_interface.dart'
    show ClipboardImage;

export 'src/clipboard_image_paste.dart';
export 'src/image_paste_scope.dart';
