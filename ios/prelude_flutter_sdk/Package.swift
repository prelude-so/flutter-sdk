// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "prelude_flutter_sdk",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(name: "prelude-flutter-sdk", targets: ["prelude_flutter_sdk"])
    ],
    dependencies: [
        .package(url: "https://github.com/prelude-so/apple-sdk", from: "0.2.5")
    ],
    targets: [
        .target(
            name: "prelude_flutter_sdk",
            dependencies: [
                .product(name: "Prelude", package: "apple-sdk")
            ],
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ]
        )
    ]
)
