import 'package:clipboard_image_paste_example/main.dart';
import 'package:clipboard_image_paste_platform_interface/clipboard_image_paste_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class FakeClipboard
    with MockPlatformInterfaceMixin
    implements ClipboardImagePastePlatform {
  ClipboardImage? image;

  @override
  Future<bool> hasImage() async => image != null;

  @override
  Future<ClipboardImage?> readImage() async => image;
}

void main() {
  late FakeClipboard clipboard;

  setUp(() {
    clipboard = FakeClipboard();
    ClipboardImagePastePlatform.instance = clipboard;
  });

  testWidgets('Check clipboard reports what the clipboard holds', (
    tester,
  ) async {
    await tester.pumpWidget(const ExampleApp());

    await tester.tap(find.byTooltip('Check clipboard'));
    await tester.pump();
    expect(find.text('No image on the clipboard.'), findsOneWidget);

    clipboard.image = ClipboardImage(
      bytes: Uint8List(2048),
      mimeType: 'image/png',
    );
    await tester.tap(find.byTooltip('Check clipboard'));
    await tester.pump();
    expect(find.text('The clipboard holds an image.'), findsOneWidget);
  });

  testWidgets('a pasted image becomes an attachment and is sent', (
    tester,
  ) async {
    clipboard.image = ClipboardImage(
      bytes: Uint8List(2048),
      mimeType: 'image/png',
    );
    await tester.pumpWidget(const ExampleApp());
    await tester.tap(find.byType(TextField));
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyV);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    expect(find.text('PNG · 2 KB'), findsOneWidget);

    await tester.tap(find.byTooltip('Send'));
    await tester.pump();

    expect(find.text('PNG · 2 KB'), findsNothing);
    expect(find.byType(Image), findsOneWidget, reason: 'image in the bubble');
  });
}
