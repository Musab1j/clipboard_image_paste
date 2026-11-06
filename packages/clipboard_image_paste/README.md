# clipboard_image_paste

[![pub package](https://img.shields.io/pub/v/clipboard_image_paste.svg)](https://pub.dev/packages/clipboard_image_paste)

Paste images from the system clipboard in Flutter apps on Android and iOS.

A Flutter `TextField` can only paste text. If the clipboard holds just an
image, it doesn't even show a Paste button. This plugin lets users paste
screenshots, photos and GIFs into your text fields, as they can in native
apps. It also gives you a small API to check for and read the clipboard image
yourself.

- **Check** whether the clipboard holds an image, without triggering iOS's
  paste prompt or Android's clipboard toast.
- **Read** the image as encoded bytes plus a MIME type, or get `null` when
  there is none, so you can fall back to a text paste.
- **Paste into text fields**: the toolbar's Paste button and Ctrl+V / Cmd+V
  paste images, and Android keyboards such as Gboard can insert images
  directly.

| Platform | Support | Minimum version |
| -------- | :-----: | --------------- |
| Android  |   ✅    | API 24 (7.0)    |
| iOS      |   ✅    | 15.0            |
| Web, macOS, Windows, Linux | – | Text fields paste text as usual. |

## Installation

```sh
flutter pub add clipboard_image_paste
```

Requires Flutter 3.44 or later. No permissions or platform setup are needed.

## Paste images into a text field

Wrap the field in an `ImagePasteScope`, and give the field the scope's
context menu builder:

```dart
import 'package:clipboard_image_paste/clipboard_image_paste.dart';

ImagePasteScope(
  onImagePaste: (ClipboardImage image) {
    setState(() => attachments.add(image));
  },
  child: TextField(
    controller: controller,
    contextMenuBuilder: ImagePasteScope.contextMenuBuilder,
    // Optional: accept images that Android keyboards insert directly.
    contentInsertionConfiguration:
        ImagePasteScope.contentInsertionConfiguration(
          onImagePaste: (image) => setState(() => attachments.add(image)),
        ),
  ),
)
```

Show a pasted image with `Image.memory(image.bytes)`.

Pasting works like this:

- **Clipboard holds an image:** `onImagePaste` is called, and the field's
  text is left alone. The image wins even if the clipboard holds text too.
- **Clipboard holds only text:** the field pastes the text as usual.
- **Paste button:** shown whenever the clipboard holds text *or* an image.
- **Ctrl+V / Cmd+V on a hardware keyboard:** works in every field under the
  scope. One scope can wrap a whole form or chat composer.
- **Read-only fields:** never paste.

`ImagePasteScope.contextMenuBuilder` builds the platform's usual toolbar
(`AdaptiveTextSelectionToolbar`), so Cut, Copy, Select All and the rest stay
as they were. It works with `TextField`, `CupertinoTextField` and anything
else built on `EditableText`.

If reading the image fails, `onError` is called and the paste goes ahead as a
text paste. Without `onError`, the error goes to `FlutterError.reportError`.

## Read the clipboard yourself

```dart
if (await ClipboardImagePaste.hasImage()) {
  final ClipboardImage? image = await ClipboardImagePaste.readImage();
  if (image != null) {
    print('${image.mimeType}, ${image.bytes.length} bytes');
  }
}

// Or just the bytes, null when there is no image:
final Uint8List? bytes = await ClipboardImagePaste.readImageBytes();
```

| Method | Returns |
| ------ | ------- |
| `hasImage()` | Whether the clipboard holds an image. Never prompts. |
| `readImage()` | A `ClipboardImage` (`bytes`, `mimeType`), or `null`. |
| `readImageBytes()` | The encoded bytes, or `null`. |

You get the clipboard's own encoding of the image, with no re-encoding. When
several formats are offered, GIF wins so animations survive, then PNG, JPEG,
HEIC, HEIF, WebP, TIFF and BMP.

## Platform behavior

### iOS

- **Paste prompt.** On iOS 16 and later, reading content that another app
  copied shows the system's "Allow Paste" prompt. The user can turn it off
  for your app under *Settings → (your app) → Paste from Other Apps*.
  `hasImage()` doesn't trigger it. `ImagePasteScope` checks `hasImage()`
  before reading, so a text-only clipboard never prompts twice.
- **Image-only pasteboards.** Some apps only put a `UIImage` on the
  pasteboard. Those images come back PNG-encoded.

### Android

- **Clipboard toast.** On Android 12 and later, the system shows a toast
  when an app reads the clipboard. `hasImage()` only reads the clipboard's
  description, so it doesn't trigger the toast.
- **Focus.** On Android 10 and later, only the app with input focus can read
  the clipboard. At other times `hasImage()` returns `false` and
  `readImage()` returns `null`.
- **Read errors.** Copied images are `content://` URIs that belong to the
  app that copied them. If that app has revoked access or deleted the file,
  `readImage()` throws a `PlatformException` with code `read_failed`.
- **Keyboard insertion.** Gboard and other keyboards can insert images from
  their clipboard strip, sticker or GIF pickers. To receive those, set
  `ImagePasteScope.contentInsertionConfiguration` on the field.

## Limitations

- **iOS system edit menu.** The native Paste item of `SystemContextMenu`
  pastes text only. Use `ImagePasteScope.contextMenuBuilder` for fields that
  should accept images.
- **Reading only.** The plugin doesn't put images on the clipboard.
- **Android and iOS only.** On other platforms the `ClipboardImagePaste`
  methods throw `UnimplementedError`, and text fields under an
  `ImagePasteScope` just paste text.

## Example

The [example app](example/lib/main.dart) is a chat composer. Paste images
into the message field and they show up as attachments.

## Federated plugin

This is the app-facing package of a
[federated plugin](https://docs.flutter.dev/packages-and-plugins/developing-packages#federated-plugins):

| Package | Role |
| ------- | ---- |
| [`clipboard_image_paste`](https://pub.dev/packages/clipboard_image_paste) | API used by apps |
| [`clipboard_image_paste_platform_interface`](https://pub.dev/packages/clipboard_image_paste_platform_interface) | Interface that implementations extend |
| [`clipboard_image_paste_android`](https://pub.dev/packages/clipboard_image_paste_android) | Android implementation (endorsed) |
| [`clipboard_image_paste_ios`](https://pub.dev/packages/clipboard_image_paste_ios) | iOS implementation (endorsed) |

To add another platform, publish a package that extends
`ClipboardImagePastePlatform` and declares
`implements: clipboard_image_paste` in its pubspec.
