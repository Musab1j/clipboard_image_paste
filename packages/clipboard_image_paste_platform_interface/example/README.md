# clipboard_image_paste_platform_interface example

This package holds the interface that platform implementations of
[`clipboard_image_paste`](https://pub.dev/packages/clipboard_image_paste) extend.
To add a new platform, extend `ClipboardImagePastePlatform` and register your
instance in `registerWith`:

```dart
class ClipboardImagePasteMyPlatform extends ClipboardImagePastePlatform {
  static void registerWith() {
    ClipboardImagePastePlatform.instance = ClipboardImagePasteMyPlatform();
  }

  @override
  Future<bool> hasImage() async => /* ... */ false;

  @override
  Future<ClipboardImage?> readImage() async => /* ... */ null;
}
```

Apps should use the [`clipboard_image_paste` example app](https://github.com/Musab1j/clipboard_image_paste/tree/main/packages/clipboard_image_paste/example)
instead.
