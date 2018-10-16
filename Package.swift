// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "Steam",
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "3.1.0"),

        // 🔵 Swift ORM (queries, models, relations, etc) built on SQLite 3.
        .package(url: "https://github.com/vapor/fluent-sqlite.git", from: "3.0.0"),

        .package(url: "https://github.com/vapor/leaf.git", from: "3.0.1"),

        .package(url: "https://github.com/vapor/validation.git", from: "2.1.0"),
        
        // 👤 Authentication and Authorization framework for Fluent.
        .package(url: "https://github.com/vapor/auth.git", from: "2.0.1")
    ],
    targets: [
            .target(name: "App", dependencies: ["Authentication", "Validation", "Leaf", "FluentSQLite", "Vapor"]),
            .target(name: "Run", dependencies: ["App"]),
            .testTarget(name: "AppTests", dependencies: ["App"])
    ]
)
