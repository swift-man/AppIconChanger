// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "AppIconChanger",
  platforms: [
    .iOS(.v13),
  ],
  products: [
    .library(
      name: "AppIconChanger",
      targets: ["AppIconChanger"]
    ),
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
