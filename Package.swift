// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "AppIconChanger",
  platforms: [
    .iOS(.v13),
    .macOS(.v10_15),
  ],
  products: [
    .library(
      name: "AppIconChanger",
      targets: ["AppIconChanger"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
  ],
  targets: [
    .target(
      name: "AppIconChanger"
    ),
    .testTarget(
      name: "AppIconChangerTests",
      dependencies: ["AppIconChanger"]
    ),
  ],
  swiftLanguageModes: [.v6]
)
