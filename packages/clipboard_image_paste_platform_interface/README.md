# clipboard_image_paste_platform_interface

A common platform interface for the
[`clipboard_image_paste`](https://pub.dev/packages/clipboard_image_paste)
plugin.

This interface lets platform-specific implementations of
`clipboard_image_paste`, and the plugin itself, ensure they support the same
interface.

## Usage

To implement a new platform-specific implementation of
`clipboard_image_paste`:

1. Extend `ClipboardImagePastePlatform` with an implementation of
   `hasImage` and `readImage` for your platform.
2. Set `ClipboardImagePastePlatform.instance` to an instance of your class
   in its `registerWith` method.
3. Declare `implements: clipboard_image_paste` in your pubspec.

`hasImage` must not read the clipboard's contents. Apps call it whenever a
paste menu opens, so it must never trigger a paste-permission prompt.

## Note on breaking changes

Strongly prefer non-breaking changes (such as adding a method to the
interface) over breaking changes for this package.

See https://flutter.dev/go/platform-interface-breaking-changes for a
discussion on why a less-clean interface is preferable to a breaking change.
