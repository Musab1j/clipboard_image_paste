import UIKit
import UniformTypeIdentifiers
import XCTest

@testable import clipboard_image_paste_ios

/// A pasteboard holding `items` in order, plus an optional UIImage-only representation.
final class FakePasteboard: Pasteboard {
  var items: [(type: String, data: Data)] = []
  var image: UIImage?

  var hasImages: Bool { image != nil || ClipboardImageReader.bestImageType(in: types) != nil }
  var types: [String] { items.map(\.type) }

  func data(forPasteboardType pasteboardType: String) -> Data? {
    items.first { $0.type == pasteboardType }?.data
  }
}

// Unit tests for the Swift side of clipboard_image_paste_ios.
//
// See https://developer.apple.com/documentation/xctest for more information about using XCTest.
class RunnerTests: XCTestCase {
  private let pasteboard = FakePasteboard()
  private lazy var reader = ClipboardImageReader(pasteboard: pasteboard)

  func testEmptyPasteboardHasNoImage() throws {
    XCTAssertFalse(try reader.hasImage())
    XCTAssertNil(try reader.readImage())
  }

  func testTextOnlyPasteboardHasNoImage() throws {
    pasteboard.items = [(UTType.utf8PlainText.identifier, Data("hello".utf8))]

    XCTAssertFalse(try reader.hasImage())
    XCTAssertNil(try reader.readImage())
  }

  func testPrefersPngOverTiff() throws {
    pasteboard.items = [
      (UTType.tiff.identifier, Data([1])),
      (UTType.png.identifier, Data([2])),
    ]

    let image = try XCTUnwrap(try reader.readImage())
    XCTAssertEqual(image.mimeType, "image/png")
    XCTAssertEqual(image.bytes.data, Data([2]))
  }

  func testKeepsGifSoAnimationSurvives() throws {
    pasteboard.items = [
      (UTType.png.identifier, Data([1])),
      (UTType.gif.identifier, Data([2])),
    ]

    let image = try XCTUnwrap(try reader.readImage())
    XCTAssertEqual(image.mimeType, "image/gif")
    XCTAssertEqual(image.bytes.data, Data([2]))
  }

  func testFallsBackToOtherImageTypes() throws {
    let jpeg2000 = try XCTUnwrap(UTType("public.jpeg-2000"))
    pasteboard.items = [(jpeg2000.identifier, Data([3]))]

    let image = try XCTUnwrap(try reader.readImage())
    XCTAssertEqual(image.mimeType, jpeg2000.preferredMIMEType)
    XCTAssertEqual(image.bytes.data, Data([3]))
  }

  func testEncodesUIImageOnlyPasteboardAsPng() throws {
    pasteboard.image = UIGraphicsImageRenderer(size: CGSize(width: 2, height: 2)).image { context in
      UIColor.red.setFill()
      context.fill(CGRect(x: 0, y: 0, width: 2, height: 2))
    }

    XCTAssertTrue(try reader.hasImage())
    let image = try XCTUnwrap(try reader.readImage())
    XCTAssertEqual(image.mimeType, "image/png")
    XCTAssertNotNil(UIImage(data: image.bytes.data))
  }

  // Against the real pasteboard, so it overwrites whatever the device had copied. The app only reads
  // what it wrote itself, which iOS allows without a paste prompt.
  func testReadsImageFromGeneralPasteboard() throws {
    let general = UIPasteboard.general
    let png = UIGraphicsImageRenderer(size: CGSize(width: 3, height: 3)).pngData { context in
      UIColor.blue.setFill()
      context.fill(CGRect(x: 0, y: 0, width: 3, height: 3))
    }
    general.setData(png, forPasteboardType: UTType.png.identifier)
    let reader = ClipboardImageReader(pasteboard: general)

    XCTAssertTrue(try reader.hasImage())
    let image = try XCTUnwrap(try reader.readImage())
    XCTAssertEqual(image.mimeType, "image/png")
    XCTAssertEqual(image.bytes.data, png)

    general.string = "just text"
    XCTAssertFalse(try reader.hasImage())
    XCTAssertNil(try reader.readImage())
  }

  func testMimeTypesOfPreferredFormats() {
    let expected: [UTType: String] = [
      .gif: "image/gif", .png: "image/png", .jpeg: "image/jpeg", .heic: "image/heic",
      .webP: "image/webp", .tiff: "image/tiff", .bmp: "image/bmp",
    ]
    for (type, mimeType) in expected {
      XCTAssertEqual(ClipboardImageReader.bestImageType(in: [type.identifier])?.mimeType, mimeType)
    }
  }
}
