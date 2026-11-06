package io.github.musab1j.clipboard_image_paste

import android.content.ClipDescription
import android.content.ClipboardManager
import android.content.ContentResolver
import java.io.IOException

/**
 * Answers [ClipboardImageApi] from the system clipboard.
 *
 * Apps that copy an image put a `content://` URI on the clipboard, so reading the image means
 * streaming that URI through [contentResolver]. The clipboard service grants the reading app
 * access to it.
 *
 * On Android 10+ only the app with input focus can read the clipboard. Any other app sees an
 * empty clipboard, so both methods then answer as if there were no image.
 */
class ClipboardImageReader(
    private val clipboard: ClipboardManager,
    private val contentResolver: ContentResolver,
) : ClipboardImageApi {
    // Only the description is read here. Unlike getPrimaryClip, it doesn't show Android 12+'s
    // "pasted from your clipboard" toast, so it's safe to call whenever a menu opens.
    override fun hasImage(): Boolean = imageMimeType(clipboard.primaryClipDescription) != null

    override fun readImage(): PlatformClipboardImage? {
        val clip = clipboard.primaryClip ?: return null
        val describedMimeType = imageMimeType(clip.description)

        for (i in 0 until clip.itemCount) {
            val uri = clip.getItemAt(i).uri ?: continue
            try {
                // Trust the provider's type when it gives one. Otherwise fall back to what the
                // copying app declared in the clip description.
                val mimeType = contentResolver.getType(uri) ?: describedMimeType ?: continue
                if (!isImageMimeType(mimeType)) continue

                val bytes = contentResolver.openInputStream(uri)?.use { it.readBytes() } ?: continue
                return PlatformClipboardImage(bytes, mimeType)
            } catch (e: SecurityException) {
                throw FlutterError("read_failed", "No permission to read the clipboard image at $uri.", e.message)
            } catch (e: IOException) {
                throw FlutterError("read_failed", "Could not read the clipboard image at $uri.", e.message)
            }
        }
        return null
    }

    private fun imageMimeType(description: ClipDescription?): String? {
        if (description == null) return null
        return (0 until description.mimeTypeCount)
            .map { description.getMimeType(it) }
            .firstOrNull { isImageMimeType(it) }
    }

    // ClipDescription.compareMimeTypes would do, but it is static and so can't be exercised by JVM
    // unit tests, where android.jar is only stubs.
    private fun isImageMimeType(mimeType: String?): Boolean =
        mimeType != null && mimeType.lowercase().startsWith("image/")
}
