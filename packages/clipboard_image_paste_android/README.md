# clipboard_image_paste_android

The Android implementation of
[`clipboard_image_paste`](https://pub.dev/packages/clipboard_image_paste).

## Usage

This package is
[endorsed](https://docs.flutter.dev/packages-and-plugins/developing-packages#endorsed-federated-plugin):
add `clipboard_image_paste` to your app and this package is included
automatically. You don't need to depend on it yourself.

## How it works

- **Checking for an image.** `hasImage` looks for an `image/*` MIME type in
  the clipboard's `ClipDescription`. Reading only the description doesn't
  show Android 12+'s "pasted from your clipboard" toast.
- **Reading the image.** `readImage` streams the bytes of the first image
  `content://` URI in the clip through `ContentResolver`, on a background
  thread. The MIME type comes from the provider, or from the clip
  description if the provider gives none.
- **Read errors.** If the URI can't be opened (access revoked, file deleted),
  `readImage` throws a `PlatformException` with code `read_failed`.

Requires Android API 24 or later.
