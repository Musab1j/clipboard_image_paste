import 'package:clipboard_image_paste/clipboard_image_paste.dart';
import 'package:clipboard_image_paste_platform_interface/clipboard_image_paste_platform_interface.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_platform.dart';

void main() {
  late FakeClipboardImagePastePlatform platform;
  late TextEditingController controller;
  late List<ClipboardImage> pasted;
  late List<Object> errors;

  setUp(() {
    platform = FakeClipboardImagePastePlatform();
    ClipboardImagePastePlatform.instance = platform;
    controller = TextEditingController();
    pasted = <ClipboardImage>[];
    errors = <Object>[];
  });

  tearDown(() => controller.dispose());

  Widget buildField({
    bool readOnly = false,
    bool withScope = true,
    bool cupertino = false,
  }) {
    final Widget field = cupertino
        ? CupertinoTextField(
            controller: controller,
            readOnly: readOnly,
            contextMenuBuilder: ImagePasteScope.contextMenuBuilder,
          )
        : TextField(
            controller: controller,
            readOnly: readOnly,
            contextMenuBuilder: ImagePasteScope.contextMenuBuilder,
          );
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: withScope
              ? ImagePasteScope(
                  onImagePaste: pasted.add,
                  onError: (error, _) => errors.add(error),
                  child: field,
                )
              : field,
        ),
      ),
    );
  }

  /// Focuses the field and opens its text selection toolbar.
  Future<void> showToolbar(WidgetTester tester) async {
    await tester.tap(find.byType(EditableText));
    await tester.pumpAndSettle();
    tester.state<EditableTextState>(find.byType(EditableText)).showToolbar();
    await tester.pumpAndSettle();
  }

  Future<void> pressPasteShortcut(WidgetTester tester) async {
    final modifier = defaultTargetPlatform == TargetPlatform.iOS
        ? LogicalKeyboardKey.metaLeft
        : LogicalKeyboardKey.controlLeft;
    await tester.sendKeyDownEvent(modifier);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyV);
    await tester.sendKeyUpEvent(modifier);
    await tester.pumpAndSettle();
  }

  group('toolbar', () {
    testWidgets('offers Paste when the clipboard holds only an image', (
      tester,
    ) async {
      setClipboardText(tester, null);
      platform.image = testImage;
      await tester.pumpWidget(buildField());

      await showToolbar(tester);

      expect(find.text('Paste'), findsOneWidget);
    }, variant: TargetPlatformVariant.mobile());

    testWidgets('has no Paste when the clipboard is empty', (tester) async {
      setClipboardText(tester, null);
      await tester.pumpWidget(buildField());

      await showToolbar(tester);

      expect(find.text('Paste'), findsNothing);
    }, variant: TargetPlatformVariant.mobile());

    testWidgets('Paste hands the image over and leaves the text alone', (
      tester,
    ) async {
      setClipboardText(tester, 'copied text');
      platform.image = testImage;
      controller.text = 'draft';
      await tester.pumpWidget(buildField());
      await showToolbar(tester);

      await tester.tap(find.text('Paste'));
      await tester.pumpAndSettle();

      expect(pasted, <ClipboardImage>[testImage]);
      expect(controller.text, 'draft');
      expect(find.text('Paste'), findsNothing, reason: 'toolbar hidden');
    }, variant: TargetPlatformVariant.mobile());

    testWidgets('Paste falls back to text when there is no image', (
      tester,
    ) async {
      setClipboardText(tester, 'copied text');
      await tester.pumpWidget(buildField());
      await showToolbar(tester);

      await tester.tap(find.text('Paste'));
      await tester.pumpAndSettle();

      expect(pasted, isEmpty);
      expect(controller.text, 'copied text');
      expect(platform.readImageCalls, 0, reason: 'no needless read');
    }, variant: TargetPlatformVariant.mobile());

    testWidgets('has no Paste in a read-only field', (tester) async {
      setClipboardText(tester, null);
      platform.image = testImage;
      controller.text = 'read only';
      await tester.pumpWidget(buildField(readOnly: true));

      await showToolbar(tester);

      expect(find.text('Paste'), findsNothing);
    }, variant: TargetPlatformVariant.mobile());

    testWidgets('picks up an image copied after the scope was built', (
      tester,
    ) async {
      setClipboardText(tester, null);
      await tester.pumpWidget(buildField());
      platform.image = testImage;

      await showToolbar(tester);

      expect(find.text('Paste'), findsOneWidget);
    }, variant: TargetPlatformVariant.mobile());

    testWidgets('builds the default toolbar without a scope', (tester) async {
      setClipboardText(tester, 'copied text');
      platform.image = testImage;
      await tester.pumpWidget(buildField(withScope: false));
      await showToolbar(tester);

      await tester.tap(find.text('Paste'));
      await tester.pumpAndSettle();

      expect(controller.text, 'copied text');
      expect(platform.readImageCalls, 0);
    }, variant: TargetPlatformVariant.mobile());

    testWidgets('works with CupertinoTextField', (tester) async {
      setClipboardText(tester, null);
      platform.image = testImage;
      await tester.pumpWidget(buildField(cupertino: true));
      await showToolbar(tester);

      await tester.tap(find.text('Paste'));
      await tester.pumpAndSettle();

      expect(pasted, <ClipboardImage>[testImage]);
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
  });

  group('keyboard shortcut', () {
    testWidgets('pastes the image', (tester) async {
      setClipboardText(tester, 'copied text');
      platform.image = testImage;
      await tester.pumpWidget(buildField());
      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();

      await pressPasteShortcut(tester);

      expect(pasted, <ClipboardImage>[testImage]);
      expect(controller.text, isEmpty);
    }, variant: TargetPlatformVariant.mobile());

    testWidgets('pastes text when there is no image', (tester) async {
      setClipboardText(tester, 'copied text');
      await tester.pumpWidget(buildField());
      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();

      await pressPasteShortcut(tester);

      expect(pasted, isEmpty);
      expect(controller.text, 'copied text');
    }, variant: TargetPlatformVariant.mobile());

    testWidgets('does nothing in a read-only field', (tester) async {
      setClipboardText(tester, 'copied text');
      platform.image = testImage;
      controller.text = 'read only';
      await tester.pumpWidget(buildField(readOnly: true));
      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();

      await pressPasteShortcut(tester);

      expect(pasted, isEmpty);
      expect(controller.text, 'read only');
      expect(platform.readImageCalls, 0);
    }, variant: TargetPlatformVariant.mobile());
  });

  testWidgets('a read error is reported and the paste falls back to text', (
    tester,
  ) async {
    setClipboardText(tester, 'copied text');
    platform
      ..image = testImage
      ..readError = PlatformException(code: 'read_failed');
    await tester.pumpWidget(buildField());
    await tester.tap(find.byType(EditableText));
    await tester.pumpAndSettle();

    await pressPasteShortcut(tester);

    expect(errors, <Matcher>[
      isA<PlatformException>().having((e) => e.code, 'code', 'read_failed'),
    ]);
    expect(pasted, isEmpty);
    expect(controller.text, 'copied text');
  }, variant: TargetPlatformVariant.mobile());

  testWidgets('unsupported platforms paste text without reporting errors', (
    tester,
  ) async {
    ClipboardImagePastePlatform.instance = _UnsupportedPlatform();
    setClipboardText(tester, 'copied text');
    await tester.pumpWidget(buildField());
    await tester.tap(find.byType(EditableText));
    await tester.pumpAndSettle();

    await pressPasteShortcut(tester);

    expect(errors, isEmpty);
    expect(controller.text, 'copied text');
  }, variant: TargetPlatformVariant.mobile());

  group('contentInsertionConfiguration', () {
    test('passes inserted images on', () {
      final configuration = ImagePasteScope.contentInsertionConfiguration(
        onImagePaste: pasted.add,
      );

      configuration.onContentInserted(
        KeyboardInsertedContent(
          mimeType: 'image/gif',
          uri: 'content://keyboard/sticker.gif',
          data: testImage.bytes,
        ),
      );

      expect(pasted, hasLength(1));
      expect(pasted.single.mimeType, 'image/gif');
      expect(pasted.single.bytes, testImage.bytes);
    });

    test('ignores content without data', () {
      final configuration = ImagePasteScope.contentInsertionConfiguration(
        onImagePaste: pasted.add,
      );

      configuration.onContentInserted(
        const KeyboardInsertedContent(
          mimeType: 'image/png',
          uri: 'content://keyboard/missing.png',
        ),
      );

      expect(pasted, isEmpty);
    });

    test('accepts the default image types unless told otherwise', () {
      expect(
        ImagePasteScope.contentInsertionConfiguration(
          onImagePaste: pasted.add,
        ).allowedMimeTypes,
        kDefaultContentInsertionMimeTypes,
      );
      expect(
        ImagePasteScope.contentInsertionConfiguration(
          onImagePaste: pasted.add,
          allowedMimeTypes: const <String>['image/png'],
        ).allowedMimeTypes,
        <String>['image/png'],
      );
    });
  });
}

/// The platform interface's own behavior on platforms without an
/// implementation.
class _UnsupportedPlatform extends ClipboardImagePastePlatform {}
