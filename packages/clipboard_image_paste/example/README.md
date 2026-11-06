# clipboard_image_paste example

A chat composer that accepts pasted images as attachments.

- **Paste into the field:** copy an image in another app (Photos, Safari,
  Chrome's "Copy image", a screenshot), then long-press the message field
  and tap **Paste**. The image appears above the field, and **Send** posts
  it as a message.
- **Hardware keyboard:** press Ctrl+V (Android) or Cmd+V (iPad, or the iOS
  simulator with a connected keyboard).
- **Gboard:** on Android, tap an image in Gboard's clipboard strip.
- **Check clipboard** (app bar): calls `ClipboardImagePaste.hasImage()`.
- **Image button** (left of the field): calls
  `ClipboardImagePaste.readImage()` directly.

```sh
flutter run
```

Tests:

```sh
flutter test                    # widget tests with a fake clipboard
flutter test integration_test   # on a device or simulator
```
