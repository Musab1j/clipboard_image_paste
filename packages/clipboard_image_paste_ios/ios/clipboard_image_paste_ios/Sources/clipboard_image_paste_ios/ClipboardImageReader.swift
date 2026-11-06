import Flutter
import UIKit
import UniformTypeIdentifiers

/// The parts of `UIPasteboard` the reader uses, so tests can substitute a fake.
protocol Pasteboard {
  var hasImages: Bool { get }
  var types: [String] { get }
  var image: UIImage? { get }
  func data(forPasteboardType pasteboardType: String) -> Data?
}

extension UIPasteboard: Pasteboard {}

/// Answers `ClipboardImageApi` from a pasteboard.
///
/// Apps that copy an image often put several representations of it on the pasteboard. The reader
/// hands back the original encoded data of the most useful one instead of re-encoding, so GIFs keep
/// their animation and photos keep their compression.
final class ClipboardImageReader: ClipboardImageApi {
  /// Formats in the order they're preferred when the pasteboard offers more than one.
  static let preferredTypes: [UTType] = [.gif, .png, .jpeg, .heic, .heif, .webP, .tiff, .bmp]

  private let pasteboard: Pasteboard

  init(pasteboard: Pasteboard) {
    self.pasteboard = pasteboard
  }

  // `hasImages` is one of the pasteboard properties iOS 16+ answers without showing the
  // "Allow Paste" prompt, so this is safe to call whenever a menu opens.
  func hasImage() throws -> Bool {
    pasteboard.hasImages
  }

  func readImage() throws -> PlatformClipboardImage? {
    if let best = Self.bestImageType(in: pasteboard.types),
      let data = pasteboard.data(forPasteboardType: best.type.identifier)
    {
      return PlatformClipboardImage(bytes: FlutterStandardTypedData(bytes: data), mimeType: best.mimeType)
    }
    // Some apps put only a UIImage object on the pasteboard, with no encoded data to hand back.
    if let png = pasteboard.image?.pngData() {
      return PlatformClipboardImage(bytes: FlutterStandardTypedData(bytes: png), mimeType: "image/png")
    }
    return nil
  }

  /// The most preferred image type among `identifiers` that has a MIME type, falling back to any
  /// other image type that has one.
  static func bestImageType(in identifiers: [String]) -> (type: UTType, mimeType: String)? {
    let images = identifiers.compactMap { UTType($0) }.filter { $0.conforms(to: .image) }
    let ordered = preferredTypes.filter { images.contains($0) } + images
    for type in ordered {
      if let mimeType = type.preferredMIMEType {
        return (type, mimeType)
      }
    }
    return nil
  }
}
