package io.github.musab1j.clipboard_image_paste

import android.content.ClipboardManager
import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin

/** Connects [ClipboardImageReader] to the Dart side through the Pigeon-generated [ClipboardImageApi]. */
class ClipboardImagePastePlugin : FlutterPlugin {
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        val context = binding.applicationContext
        val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        ClipboardImageApi.setUp(
            binding.binaryMessenger,
            ClipboardImageReader(clipboard, context.contentResolver),
        )
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        ClipboardImageApi.setUp(binding.binaryMessenger, null)
    }
}
