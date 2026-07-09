// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// MARK: - RouteKit (Binary Distribution)
//
// This is the *distribution* form of RouteKit. It is intended to be the package
// that customers add via SPM. It differs from the development package in one way:
//
//   • `RouteInterface` ships as readable SOURCE (the public contract).
//   • `Route` ships as a PRECOMPILED BINARY (RouteBinary.xcframework) — the
//     implementation is sealed. Consumers still `import Route`; a thin umbrella
//     target re-exports the binary.
//
// The Route source lives ONLY in the private development package
// (../RouteKit). Run `Scripts/build-xcframework.sh` from that package to
// (re)generate `Artifacts/RouteBinary.xcframework` and sync the interface
// sources into this package.
//
// SPM constraint that shapes this file: a `.binaryTarget` cannot declare
// dependencies. The xcframework internally references RouteInterface,
// DependencyResolver, SwiftConcurrency and AuthSessionInterface, so a thin
// source shim (`Route`) carries those dependency declarations and re-exports
// the binary via `@_exported import RouteBinary`.

let package = Package(
    name: "RouteKit",
    platforms: [
        .iOS(.v14),
        .macCatalyst(.v14),
    ],
    products: [
        .library(
            name: "RouteInterface",
            targets: ["RouteInterface"]
        ),
        .library(
            name: "Route",
            targets: ["Route"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/kaVish2214/UtilityKit", .upToNextMajor(from: "0.1.0")),
        .package(url: "https://github.com/kaVish2214/AuthSessionKit", .upToNextMajor(from: "0.1.0")),
    ],
    targets: [
        // The public contract, shipped as source so consumers can read/adopt the
        // protocols, enums and errors they program against.
        .target(
            name: "RouteInterface",
            dependencies: [
                .product(name: "DependencyResolver", package: "UtilityKit"),
                .product(name: "AuthSessionInterface", package: "AuthSessionKit"),
            ],
            path: "Sources/RouteInterface"
        ),

        // The sealed implementation. Module name is `RouteBinary` (distinct from
        // the `Route` shim below) so the two do not collide.
        //
        // LOCAL form (current): consumes the xcframework from disk.
        .binaryTarget(
            name: "RouteBinary",
            path: "Artifacts/RouteBinary.xcframework"
        ),
        // REMOTE form (when hosting a zipped xcframework on a CDN / GitHub
        // Release), replace the binaryTarget above with:
        //
        // .binaryTarget(
        //     name: "RouteBinary",
        //     url: "https://your-host/RouteBinary-1.0.0.xcframework.zip",
        //     checksum: "<output of: swift package compute-checksum RouteBinary-1.0.0.xcframework.zip>"
        // ),

        // Thin umbrella. One file (`Exports.swift`) does `@_exported import
        // RouteBinary`, and this target carries the dependency declarations the
        // binary needs at link time.
        .target(
            name: "Route",
            dependencies: [
                "RouteBinary",
                "RouteInterface",
                .product(name: "DependencyResolver", package: "UtilityKit"),
                .product(name: "SwiftConcurrency", package: "UtilityKit"),
                .product(name: "AuthSessionInterface", package: "AuthSessionKit"),
            ],
            path: "Sources/Route"
        ),
    ],
    swiftLanguageModes: [.v6]
)
