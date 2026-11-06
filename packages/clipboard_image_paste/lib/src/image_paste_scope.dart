import 'dart:async';

import 'package:clipboard_image_paste_platform_interface/clipboard_image_paste_platform_interface.dart';
import 'package:flutter/cupertino.dart' show CupertinoTextField;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'clipboard_image_paste.dart';

/// Lets users paste clipboard images into the text fields below it.
///
/// On its own a [TextField] only offers Paste when the clipboard holds text,
/// and only ever pastes text. Under an [ImagePasteScope], pasting while the
/// clipboard holds an image calls [onImagePaste] with that image instead, and
/// leaves the field's text alone. When there is no image, the field pastes
/// text as usual.
///
/// ```dart
/// ImagePasteScope(
///   onImagePaste: (image) => setState(() => attachments.add(image)),
///   child: TextField(
///     contextMenuBuilder: ImagePasteScope.contextMenuBuilder,
///   ),
/// )
/// ```
///
/// Users can paste an image with:
///
///  * the Paste button of the text selection toolbar, for fields that use
///    [ImagePasteScope.contextMenuBuilder]. The button also appears when the
///    clipboard holds only an image.
///  * Ctrl+V or Cmd+V on a hardware keyboard, in every field under the scope.
///    One scope can wrap a whole form or chat composer.
///  * on Android, keyboards that insert images directly, such as Gboard's
///    clipboard suggestions, for fields that use
///    [ImagePasteScope.contentInsertionConfiguration].
///
/// If the clipboard holds both an image and text, the image is pasted.
///
/// Works with [CupertinoTextField] and anything else built on [EditableText].
/// On platforms other than Android and iOS the fields simply paste text.
class ImagePasteScope extends StatefulWidget {
  /// Creates a scope that calls [onImagePaste] when an image is pasted into a
  /// text field in [child].
  const ImagePasteScope({
    super.key,
    required this.onImagePaste,
    this.onError,
    required this.child,
  });

  /// Called with the image the user pasted.
  final ValueChanged<ClipboardImage> onImagePaste;

  /// Called when checking for or reading the clipboard image fails, for
  /// example with a `read_failed` [PlatformException] on Android.
  ///
  /// The paste then goes ahead as a text paste. If this is null, the error is
  /// reported to [FlutterError.reportError].
  final void Function(Object error, StackTrace stackTrace)? onError;

  /// The subtree whose text fields can paste images.
  final Widget child;

  /// A [TextField.contextMenuBuilder] whose Paste button pastes images too.
  ///
  /// Builds the platform's usual text selection toolbar. It adds a Paste
  /// button when the clipboard holds only an image, which the default
  /// toolbar leaves out.
  ///
  /// The field must be inside an [ImagePasteScope]. Without one, this builds
  /// the default toolbar.
  static Widget contextMenuBuilder(
    BuildContext context,
    EditableTextState editableTextState,
  ) {
    // `context` belongs to the overlay the menu is shown in, not to the field,
    // so look for the scope from the field instead.
    final scope = editableTextState.context
        .findAncestorStateOfType<_ImagePasteScopeState>();
    if (scope == null) {
      return AdaptiveTextSelectionToolbar.editableText(
        editableTextState: editableTextState,
      );
    }
    return _ImagePasteContextMenu(
      scope: scope,
      editableTextState: editableTextState,
    );
  }

  /// A [TextField.contentInsertionConfiguration] that passes images inserted
  /// by the keyboard to [onImagePaste].
  ///
  /// Android keyboards can insert images straight into a field, for example
  /// from Gboard's clipboard suggestions or its sticker and GIF pickers. iOS
  /// keyboards can't, so this only has an effect on Android.
  ///
  /// [allowedMimeTypes] are the image types the field tells the keyboard it
  /// accepts.
  static ContentInsertionConfiguration contentInsertionConfiguration({
    required ValueChanged<ClipboardImage> onImagePaste,
    List<String> allowedMimeTypes = kDefaultContentInsertionMimeTypes,
  }) {
    return ContentInsertionConfiguration(
      allowedMimeTypes: allowedMimeTypes,
      onContentInserted: (content) {
        final data = content.data;
        if (data == null || data.isEmpty) {
          return;
        }
        onImagePaste(ClipboardImage(bytes: data, mimeType: content.mimeType));
      },
    );
  }

  @override
  State<ImagePasteScope> createState() => _ImagePasteScopeState();
}

class _ImagePasteScopeState extends State<ImagePasteScope> {
  late final AppLifecycleListener _lifecycleListener;
  late final Map<Type, Action<Intent>> _actions = <Type, Action<Intent>>{
    PasteTextIntent: _PasteImageAction(this),
  };

  // The last known answer to ClipboardImagePaste.hasImage, so a context menu
  // can show its Paste button in its first frame instead of popping it in.
  final ValueNotifier<bool> _clipboardHasImage = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    // The user may have copied an image in another app.
    _lifecycleListener = AppLifecycleListener(onResume: _refreshHasImage);
    _refreshHasImage();
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    _clipboardHasImage.dispose();
    super.dispose();
  }

  /// Updates [_clipboardHasImage].
  ///
  /// This is only a hint for the context menu, so errors are ignored here
  /// rather than reported; a real paste reports them.
  Future<void> _refreshHasImage() async {
    var hasImage = false;
    try {
      hasImage = await ClipboardImagePaste.hasImage();
    } catch (_) {
      // Treated as no image.
    }
    if (mounted) {
      _clipboardHasImage.value = hasImage;
    }
  }

  /// Pastes the clipboard image if there is one, and text otherwise.
  Future<void> _paste(
    EditableTextState editableTextState,
    SelectionChangedCause cause,
  ) async {
    // The same checks EditableText makes before its own paste.
    final field = editableTextState.widget;
    if (field.readOnly || !field.selectionEnabled) {
      return;
    }

    final image = await _readImage();
    if (!mounted || !editableTextState.mounted) {
      return;
    }
    if (image == null) {
      await editableTextState.pasteText(cause);
      return;
    }
    editableTextState.hideToolbar();
    widget.onImagePaste(image);
  }

  Future<ClipboardImage?> _readImage() async {
    try {
      // Check first: hasImage never prompts, so a text-only clipboard doesn't
      // cost iOS users an extra "Allow Paste" prompt.
      final hasImage = await ClipboardImagePaste.hasImage();
      if (mounted) {
        _clipboardHasImage.value = hasImage;
      }
      return hasImage ? await ClipboardImagePaste.readImage() : null;
    } on UnimplementedError {
      // Not Android or iOS: behave like a plain text field.
      return null;
    } catch (error, stackTrace) {
      _reportError(error, stackTrace);
      return null;
    }
  }

  void _reportError(Object error, StackTrace stackTrace) {
    final onError = widget.onError;
    if (onError != null) {
      onError(error, stackTrace);
      return;
    }
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'clipboard_image_paste',
        context: ErrorDescription('while pasting an image from the clipboard'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Actions(actions: _actions, child: widget.child);
  }
}

/// Stands in for the paste action of each text field under the scope, which
/// is what the Ctrl+V and Cmd+V shortcuts invoke.
class _PasteImageAction extends ContextAction<PasteTextIntent> {
  _PasteImageAction(this.scope);

  final _ImagePasteScopeState scope;

  // `callingAction` is set only while this runs as an override of a text
  // field's own paste action. Invoked any other way, stay disabled so the
  // shortcut still reaches whatever would handle it without the scope.
  @override
  bool isEnabled(PasteTextIntent intent, [BuildContext? context]) {
    return callingAction != null;
  }

  @override
  Object? invoke(PasteTextIntent intent, [BuildContext? context]) {
    // `context` is the focused field's, which sits inside its EditableText.
    final editableTextState = context
        ?.findAncestorStateOfType<EditableTextState>();
    if (editableTextState == null) {
      final fallback = callingAction;
      return fallback is ContextAction<PasteTextIntent>
          ? fallback.invoke(intent, context)
          : fallback?.invoke(intent);
    }
    unawaited(scope._paste(editableTextState, intent.cause));
    return null;
  }
}

/// The platform's text selection toolbar, with a Paste button that pastes
/// images too.
class _ImagePasteContextMenu extends StatefulWidget {
  const _ImagePasteContextMenu({
    required this.scope,
    required this.editableTextState,
  });

  final _ImagePasteScopeState scope;
  final EditableTextState editableTextState;

  @override
  State<_ImagePasteContextMenu> createState() => _ImagePasteContextMenuState();
}

class _ImagePasteContextMenuState extends State<_ImagePasteContextMenu> {
  @override
  void initState() {
    super.initState();
    // Show the cached answer straight away, and correct it if it's stale.
    widget.scope._refreshHasImage();
  }

  List<ContextMenuButtonItem> _buttonItems(bool clipboardHasImage) {
    final editableTextState = widget.editableTextState;
    void paste() {
      widget.scope._paste(editableTextState, SelectionChangedCause.toolbar);
    }

    final items = <ContextMenuButtonItem>[
      for (final item in editableTextState.contextMenuButtonItems)
        item.type == ContextMenuButtonType.paste
            ? item.copyWith(onPressed: paste)
            : item,
    ];
    final hasPaste = items.any(
      (item) => item.type == ContextMenuButtonType.paste,
    );
    if (!hasPaste &&
        clipboardHasImage &&
        !editableTextState.widget.readOnly &&
        editableTextState.widget.selectionEnabled) {
      // EditableText only offers Paste for text. Put the button where it
      // would have been: after Cut and Copy.
      final index =
          items.lastIndexWhere(
            (item) =>
                item.type == ContextMenuButtonType.cut ||
                item.type == ContextMenuButtonType.copy,
          ) +
          1;
      items.insert(
        index,
        ContextMenuButtonItem(
          type: ContextMenuButtonType.paste,
          onPressed: paste,
        ),
      );
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: widget.scope._clipboardHasImage,
      builder: (context, clipboardHasImage, _) {
        return AdaptiveTextSelectionToolbar.buttonItems(
          anchors: widget.editableTextState.contextMenuAnchors,
          buttonItems: _buttonItems(clipboardHasImage),
        );
      },
    );
  }
}
