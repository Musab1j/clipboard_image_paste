package io.github.musab1j.clipboard_image_paste

import android.content.ClipData
import android.content.ClipDescription
import android.content.ClipboardManager
import android.content.ContentResolver
import android.net.Uri
import org.mockito.Mockito
import org.mockito.Mockito.`when`
import java.io.ByteArrayInputStream
import java.io.FileNotFoundException
import kotlin.test.Test
import kotlin.test.assertContentEquals
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

/*
 * Unit tests for ClipboardImageReader, with the clipboard and content resolver mocked.
 *
 * Once you have built the plugin's example app, you can run these tests from the command
 * line by running `./gradlew :clipboard_image_paste_android:testDebugUnitTest` in the
 * `packages/clipboard_image_paste/example/android/` directory, or you can run them directly
 * from IDEs that support JUnit such as Android Studio.
 */

internal class ClipboardImageReaderTest {
    private val clipboard: ClipboardManager = Mockito.mock(ClipboardManager::class.java)
    private val resolver: ContentResolver = Mockito.mock(ContentResolver::class.java)
    private val reader = ClipboardImageReader(clipboard, resolver)

    private fun description(vararg mimeTypes: String): ClipDescription {
        val description = Mockito.mock(ClipDescription::class.java)
        `when`(description.mimeTypeCount).thenReturn(mimeTypes.size)
        mimeTypes.forEachIndexed { i, type -> `when`(description.getMimeType(i)).thenReturn(type) }
        return description
    }

    /** Puts a clip on the mocked clipboard with one item per entry in [uris] (null for text items). */
    private fun setClip(description: ClipDescription, vararg uris: Uri?) {
        val clip = Mockito.mock(ClipData::class.java)
        `when`(clip.description).thenReturn(description)
        `when`(clip.itemCount).thenReturn(uris.size)
        uris.forEachIndexed { i, uri ->
            val item = Mockito.mock(ClipData.Item::class.java)
            `when`(item.uri).thenReturn(uri)
            `when`(clip.getItemAt(i)).thenReturn(item)
        }
        `when`(clipboard.primaryClip).thenReturn(clip)
        `when`(clipboard.primaryClipDescription).thenReturn(description)
    }

    private fun uriWithContent(mimeType: String?, bytes: ByteArray): Uri {
        val uri = Mockito.mock(Uri::class.java)
        `when`(resolver.getType(uri)).thenReturn(mimeType)
        `when`(resolver.openInputStream(uri)).thenReturn(ByteArrayInputStream(bytes))
        return uri
    }

    @Test
    fun emptyClipboard_hasNoImage() {
        assertFalse(reader.hasImage())
        assertNull(reader.readImage())
    }

    @Test
    fun textOnly_hasNoImage() {
        setClip(description(ClipDescription.MIMETYPE_TEXT_PLAIN), null)

        assertFalse(reader.hasImage())
        assertNull(reader.readImage())
    }

    @Test
    fun imageUri_isReadWithProviderMimeType() {
        val bytes = byteArrayOf(1, 2, 3)
        setClip(description("image/*"), uriWithContent("image/png", bytes))

        assertTrue(reader.hasImage())
        val image = reader.readImage()!!
        assertEquals("image/png", image.mimeType)
        assertContentEquals(bytes, image.bytes)
    }

    @Test
    fun mimeTypeFallsBackToClipDescription() {
        setClip(description("image/jpeg"), uriWithContent(null, byteArrayOf(9)))

        assertEquals("image/jpeg", reader.readImage()!!.mimeType)
    }

    @Test
    fun mimeTypeCheckIgnoresCase() {
        setClip(description("IMAGE/PNG"), uriWithContent("IMAGE/PNG", byteArrayOf(9)))

        assertTrue(reader.hasImage())
        assertEquals("IMAGE/PNG", reader.readImage()!!.mimeType)
    }

    @Test
    fun nonImageUrisAreSkipped() {
        val pdf = uriWithContent("application/pdf", byteArrayOf(0))
        val gif = uriWithContent("image/gif", byteArrayOf(7, 7))
        setClip(description("application/pdf", "image/gif"), null, pdf, gif)

        val image = reader.readImage()!!
        assertEquals("image/gif", image.mimeType)
        assertContentEquals(byteArrayOf(7, 7), image.bytes)
    }

    @Test
    fun securityException_becomesReadFailed() {
        val uri = Mockito.mock(Uri::class.java)
        `when`(resolver.getType(uri)).thenReturn("image/png")
        `when`(resolver.openInputStream(uri)).thenThrow(SecurityException("denied"))
        setClip(description("image/png"), uri)

        val error = assertFailsWith<FlutterError> { reader.readImage() }
        assertEquals("read_failed", error.code)
    }

    @Test
    fun missingFile_becomesReadFailed() {
        val uri = Mockito.mock(Uri::class.java)
        `when`(resolver.getType(uri)).thenReturn("image/png")
        `when`(resolver.openInputStream(uri)).thenThrow(FileNotFoundException("gone"))
        setClip(description("image/png"), uri)

        val error = assertFailsWith<FlutterError> { reader.readImage() }
        assertEquals("read_failed", error.code)
    }
}
