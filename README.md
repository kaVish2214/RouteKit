# RouteKit — Binary Distribution

This is the **distribution** form of RouteKit. Add *this* package via SPM to
consume RouteKit without access to the `Route` implementation source.

- **`RouteInterface`** ships as readable **source** — the public contract
  (protocols, enums, errors) you program against.
- **`Route`** ships as a precompiled **binary** (`RouteBinary.xcframework`) —
  the routing engine, sealed. You still `import Route`; a thin umbrella target
  re-exports the binary.

This is a **private** repository. The xcframework is committed in-repo and
resolved via `.binaryTarget(path:)`, so SwiftPM fetches it with your normal git
credentials when it clones the package — no separate authenticated download.

## For consumers

Make sure you have access to this private repo (SSH key or a token with `repo`
scope), then:

```swift
.package(url: "https://github.com/kaVish2214/RouteKit-Distribution.git", from: "1.0.0")
```

```swift
.target(
    name: "App",
    dependencies: [
        .product(name: "Route", package: "RouteKit-Distribution"),
        .product(name: "RouteInterface", package: "RouteKit-Distribution"),
    ]
)
```

Usage is identical to the source package — `import Route` / `import RouteInterface`.

## For maintainers

The `Route` **source lives only in the private development package** at
`../../RouteKit`. This distribution package holds:

- `Sources/RouteInterface/` — synced from the dev package (generated).
- `Sources/Route/Exports.swift` — the umbrella (`@_exported import RouteBinary`).
- `Artifacts/RouteBinary.xcframework` — the compiled engine (generated, committed).

### Release steps

```bash
# From this package, after the dev package has the changes you want to ship:
Scripts/build-xcframework.sh
git add -A && git commit -m "Release x.y.z"
git tag x.y.z && git push --tags        # SPM resolves the tag as the version
```

The script:

1. Syncs `RouteInterface` source from `../../RouteKit`.
2. Compiles `Route` as module `RouteBinary` with library evolution scoped to that
   target, for iOS device, iOS simulator, and Mac Catalyst, and embeds the Swift
   module + `.swiftinterface` into each framework slice.
3. Assembles `Artifacts/RouteBinary.xcframework`.
4. Also writes a `.zip` + checksum (only needed if you ever switch to remote
   Release-asset hosting; the zip is git-ignored).

> **Why library evolution is scoped per-target, not a global
> `BUILD_LIBRARY_FOR_DISTRIBUTION`:** globally, every source dependency is forced
> to emit a textual `.swiftinterface`, and UtilityKit's `MultiCastDelegate` module
> (which contains a protocol of the same name) emits one the compiler then fails to
> verify. Scoping evolution to `RouteBinary` keeps the dependency graph out of it.

### Requirements & caveats

- Build on a machine with Xcode; the script uses `xcodebuild -create-xcframework`.
- Public API signatures remain visible in the binary's `.swiftinterface`;
  only implementation bodies are hidden. Avoid `@inlinable` /
  `@_alwaysEmitIntoClient` in `Route` or those bodies leak.
- Keep the archived **dSYMs** (under `.xcbuild/archives/*.xcarchive/dSYMs`) to
  symbolicate crash reports from consumers.
- The xcframework is compiled against specific majors of UtilityKit /
  AuthSessionKit. Keep consumers on the same major to avoid module-compat issues.
