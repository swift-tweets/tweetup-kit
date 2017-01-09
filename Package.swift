import PackageDescription

let package = Package(
    name: "TweetupKit",
    dependencies: [
        .Package(url: "https://github.com/swift-tweets/OAuthSwift.git", "1.2.0-beta")
    ]
)
