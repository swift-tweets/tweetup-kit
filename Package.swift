// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "TweetupKit",
    products: [
        .library(name: "TweetupKit", targets: ["TweetupKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-tweets/OAuthSwift.git", from: "2.0.0-beta"),
    ],
    targets: [
        .target(name: "TweetupKit", dependencies: ["OAuthSwift"]),
        .testTarget(name: "TweetupKitTests", dependencies: ["TweetupKit", "OAuthSwift"]),
    ]
)
