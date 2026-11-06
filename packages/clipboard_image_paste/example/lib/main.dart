import 'package:clipboard_image_paste/clipboard_image_paste.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const ExampleApp());
}

/// Demonstrates clipboard_image_paste with a chat composer.
class ExampleApp extends StatelessWidget {
  /// Creates the example app.
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clipboard image paste',
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
      ),
      home: const ComposerPage(),
    );
  }
}

/// A chat screen whose message field accepts pasted images as attachments.
class ComposerPage extends StatefulWidget {
  /// Creates the composer page.
  const ComposerPage({super.key});

  @override
  State<ComposerPage> createState() => _ComposerPageState();
}

class _ComposerPageState extends State<ComposerPage> {
  final _controller = TextEditingController();
  final _attachments = <ClipboardImage>[];
  final _messages = <_Message>[];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _attach(ClipboardImage image) {
    setState(() => _attachments.add(image));
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  // The low-level API: no text field involved.
  Future<void> _checkClipboard() async {
    final hasImage = await ClipboardImagePaste.hasImage();
    if (!mounted) return;
    _showMessage(
      hasImage ? 'The clipboard holds an image.' : 'No image on the clipboard.',
    );
  }

  Future<void> _pasteImage() async {
    final image = await ClipboardImagePaste.readImage();
    if (!mounted) return;
    if (image == null) {
      _showMessage('No image on the clipboard.');
    } else {
      _attach(image);
    }
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty && _attachments.isEmpty) return;
    setState(() {
      _messages.add(_Message(text, List.of(_attachments)));
      _attachments.clear();
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clipboard image paste'),
        actions: [
          IconButton(
            icon: const Icon(Icons.content_paste_search),
            tooltip: 'Check clipboard',
            onPressed: _checkClipboard,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? const _EmptyHint()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, i) => _MessageBubble(_messages[i]),
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_attachments.isNotEmpty)
                    SizedBox(
                      height: 96,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _attachments.length,
                        separatorBuilder: (context, i) =>
                            const SizedBox(width: 8),
                        itemBuilder: (context, i) => _AttachmentThumbnail(
                          image: _attachments[i],
                          onRemove: () =>
                              setState(() => _attachments.removeAt(i)),
                        ),
                      ),
                    ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.add_photo_alternate_outlined),
                        tooltip: 'Paste image',
                        onPressed: _pasteImage,
                      ),
                      Expanded(
                        // Long-press the field and tap Paste, or press
                        // Ctrl+V / Cmd+V on a hardware keyboard.
                        child: ImagePasteScope(
                          onImagePaste: _attach,
                          onError: (error, _) =>
                              _showMessage('Could not paste the image: $error'),
                          child: TextField(
                            controller: _controller,
                            minLines: 1,
                            maxLines: 5,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              hintText: 'Message',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            contextMenuBuilder:
                                ImagePasteScope.contextMenuBuilder,
                            // Android keyboards such as Gboard can insert
                            // copied images straight from their clipboard
                            // strip.
                            contentInsertionConfiguration:
                                ImagePasteScope.contentInsertionConfiguration(
                                  onImagePaste: _attach,
                                ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send),
                        tooltip: 'Send',
                        onPressed: _send,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Message {
  _Message(this.text, this.images);

  final String text;
  final List<ClipboardImage> images;
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.content_paste,
              size: 48,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Copy an image in another app, then long-press the message '
              'field and tap Paste.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble(this.message);

  final _Message message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, left: 48),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colors.primaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final image in message.images)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 240),
                    child: _ImageView(image),
                  ),
                ),
              ),
            if (message.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  message.text,
                  style: TextStyle(color: colors.onPrimaryContainer),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AttachmentThumbnail extends StatelessWidget {
  const _AttachmentThumbnail({required this.image, required this.onRemove});

  final ClipboardImage image;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox.square(
            dimension: 80,
            child: _ImageView(image, fit: BoxFit.cover),
          ),
        ),
        Positioned(
          left: 4,
          bottom: 4,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surface.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              child: Text(
                _describe(image),
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: IconButton.filledTonal(
            iconSize: 16,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.close),
            tooltip: 'Remove',
            onPressed: onRemove,
          ),
        ),
      ],
    );
  }

  static String _describe(ClipboardImage image) {
    final format = image.mimeType.split('/').last.toUpperCase();
    final kb = image.bytes.lengthInBytes / 1024;
    final size = kb < 1024
        ? '${kb.toStringAsFixed(0)} KB'
        : '${(kb / 1024).toStringAsFixed(1)} MB';
    return '$format · $size';
  }
}

/// Shows the pasted bytes, or a placeholder for formats the device can't
/// decode (such as HEIC on older Android versions).
class _ImageView extends StatelessWidget {
  const _ImageView(this.image, {this.fit = BoxFit.contain});

  final ClipboardImage image;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Image.memory(
      image.bytes,
      fit: fit,
      gaplessPlayback: true,
      errorBuilder: (context, error, stackTrace) => const ColoredBox(
        color: Colors.black12,
        child: Center(child: Icon(Icons.broken_image_outlined)),
      ),
    );
  }
}
