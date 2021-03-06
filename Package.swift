// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "TweetupKit",
    products: [
        .library(name: "TweetupKit", targets: ["TweetupKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/koher/PromiseK.git", from: "3.0.0-alpha"),
        .package(url: "https://github.com/OAuthSwift/OAuthSwift.git", .branch("master")),
    ],
    targets: [
        .target(name: "TweetupKit", dependencies: ["PromiseK", "OAuthSwift"]),
        .testTarget(name: "TweetupKitTests", dependencies: ["TweetupKit", "PromiseK", "OAuthSwift"]),
    ]
)
