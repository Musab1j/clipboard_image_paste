# clipboard_image_paste workspace

Source for the federated
[`clipboard_image_paste`](packages/clipboard_image_paste) Flutter plugin.
It pastes images from the system clipboard on Android and iOS. See
[its README](packages/clipboard_image_paste/README.md) for usage.

| Package | Role |
| ------- | ---- |
| [`clipboard_image_paste`](packages/clipboard_image_paste) | App-facing API and `ImagePasteScope`, plus the example app |
| [`clipboard_image_paste_platform_interface`](packages/clipboard_image_paste_platform_interface) | `ClipboardImagePastePlatform` and `ClipboardImage` |
| [`clipboard_image_paste_android`](packages/clipboard_image_paste_android) | Kotlin implementation |
| [`clipboard_image_paste_ios`](packages/clipboard_image_paste_ios) | Swift implementation (SPM and CocoaPods) |

The packages form a [pub workspace](https://dart.dev/tools/pub/workspaces):
one `flutter pub get` at the root resolves them all against each other.

## Development

```sh
flutter pub get
dart format .
flutter analyze

# Dart tests, per package
(cd packages/clipboard_image_paste && flutter test)
(cd packages/clipboard_image_paste_platform_interface && flutter test)
(cd packages/clipboard_image_paste_android && flutter test)
(cd packages/clipboard_image_paste_ios && flutter test)
(cd packages/clipboard_image_paste/example && flutter test)

# Integration test on a device or simulator
(cd packages/clipboard_image_paste/example && flutter test integration_test)
```

### Native tests

Android (JUnit + Mockito):

```sh
cd packages/clipboard_image_paste/example
flutter build apk --config-only
cd android && ./gradlew :clipboard_image_paste_android:testDebugUnitTest
```

iOS (XCTest, in `example/ios/RunnerTests`):

```sh
cd packages/clipboard_image_paste/example
flutter build ios --config-only --simulator
xcodebuild test -workspace ios/Runner.xcworkspace -scheme Runner \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

### Platform channels

The channels are generated with [Pigeon](https://pub.dev/packages/pigeon)
from each platform package's `pigeons/messages.dart`. After changing one,
regenerate from that package's directory:

```sh
dart run pigeon --input pigeons/messages.dart
```

## Publishing

Publish in dependency order:

1. `clipboard_image_paste_platform_interface`
2. `clipboard_image_paste_android` and `clipboard_image_paste_ios`
3. `clipboard_image_paste`

```sh
cd packages/<package> && flutter pub publish
```
