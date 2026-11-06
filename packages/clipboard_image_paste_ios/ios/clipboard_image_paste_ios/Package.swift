// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "clipboard_image_paste_ios",
    platforms: [
        .iOS("15.0")
    ],
    products: [
        .library(name: "clipboard-image-paste-ios", targets: ["clipboard_image_paste_ios"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "clipboard_image_paste_ios",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            resources: [
                // The plugin collects no data and uses no required-reason APIs; the manifest says so.
                .process("PrivacyInfo.xcprivacy")
            ]
        )
    ]
)
