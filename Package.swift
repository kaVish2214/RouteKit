// swift-tools-version: 6.3
import PackageDescription

let package = Package(
    name: "RouteKit",
    platforms: [
        .iOS(.v14),
        .macCatalyst(.v14),
    ],
    products: [
        .library(name: "RouteInterface", targets: ["RouteInterface"]),
        .library(name: "Route", targets: ["Route"]),
    ],
    dependencies: [
        .package(url: "https://github.com/kaVish2214/UtilityKit", .upToNextMajor(from: "0.1.0")),
        .package(url: "https://github.com/kaVish2214/AuthSessionKit", .upToNextMajor(from: "0.1.0")),
    ],
    targets: [
        // The public contract: protocols, enums and value types you program against.
        .target(
            name: "RouteInterface",
            dependencies: [
                .product(name: "DependencyResolver", package: "UtilityKit"),
                .product(name: "AuthSessionInterface", package: "AuthSessionKit"),
            ],
            path: "Sources/RouteInterface"
        ),

        // The routing engine, shipped precompiled.
        .binaryTarget(
            name: "RouteBinary",
            path: "Artifacts/RouteBinary.xcframework"
        ),

        // `import Route` — re-exports the engine and links its dependencies.
        // DependencyResolver is intentionally not listed here: it reaches the
        // consumer transitively through RouteInterface, whose public API exposes
        // it, which satisfies Route's references to it.
        .target(
            name: "Route",
            dependencies: [
                "RouteBinary",
                "RouteInterface",
                .product(name: "SwiftConcurrency", package: "UtilityKit"),
                .product(name: "AuthSessionInterface", package: "AuthSessionKit"),
            ],
            path: "Sources/Route"
        ),

        .testTarget(
            name: "RouteInterfaceTests",
            dependencies: [
                "RouteInterface",
                "Route",
                .product(name: "AuthSessionInterface", package: "AuthSessionKit"),
                .product(name: "DependencyResolver", package: "UtilityKit"),
            ],
            path: "Tests/RouteInterfaceTests"
        ),
    ],
    swiftLanguageModes: [.v6]
)
