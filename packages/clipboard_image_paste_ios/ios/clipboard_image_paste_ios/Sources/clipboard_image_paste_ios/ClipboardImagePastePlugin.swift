import Flutter
import UIKit

/// Connects `ClipboardImageReader` to the Dart side through the Pigeon-generated `ClipboardImageApi`.
public class ClipboardImagePastePlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    ClipboardImageApiSetup.setUp(
      binaryMessenger: registrar.messenger(),
      api: ClipboardImageReader(pasteboard: UIPasteboard.general))
    registrar.publish(ClipboardImagePastePlugin())
  }

  public func detachFromEngine(for registrar: FlutterPluginRegistrar) {
    ClipboardImageApiSetup.setUp(binaryMessenger: registrar.messenger(), api: nil)
  }
}
