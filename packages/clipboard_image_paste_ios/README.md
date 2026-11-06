# clipboard_image_paste_ios

The iOS implementation of
[`clipboard_image_paste`](https://pub.dev/packages/clipboard_image_paste).

## Usage

This package is
[endorsed](https://docs.flutter.dev/packages-and-plugins/developing-packages#endorsed-federated-plugin):
add `clipboard_image_paste` to your app and this package is included
automatically. You don't need to depend on it yourself.

## How it works

- **Checking for an image.** `hasImage` uses `UIPasteboard.hasImages`, which
  iOS 16+ answers without showing the "Allow Paste" prompt.
- **Reading the image.** `readImage` returns the pasteboard's own data for
  the best image type it offers, in this order: GIF, PNG, JPEG, HEIC, HEIF,
  WebP, TIFF, BMP, then any other image type. If the pasteboard only holds a
  `UIImage`, that image is encoded as PNG.
- **Threading.** Reads run on a background queue. While iOS shows its paste
  prompt the read blocks, and the Flutter UI must keep running meanwhile.

Supports Swift Package Manager and CocoaPods. Requires iOS 15 or later.
