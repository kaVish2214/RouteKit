# Maintaining the RouteKit distribution

> Internal notes for the package owner. Not part of the consumer docs.

The `Route` **source lives only in the development package** at `../../RouteKit`.
This distribution package holds:

- `Sources/RouteInterface/` — synced from the dev package (generated).
- `Sources/Route/Exports.swift` — the umbrella that re-exports the binary.
- `Artifacts/RouteBinary.xcframework` — the compiled engine (generated, committed).

## Cutting a release

```bash
# After the dev package has the changes you want to ship:
Scripts/build-xcframework.sh
git add -A && git commit -m "Release x.y.z"
git tag x.y.z && git push origin main --tags    # SPM resolves the tag as the version
```

`Scripts/build-xcframework.sh`:

1. Syncs `RouteInterface` source from `../../RouteKit`.
2. Compiles `Route` (as `RouteBinary`) with library evolution scoped to that
   target, for iOS device, iOS simulator, and Mac Catalyst, embedding the Swift
   module + `.swiftinterface` into each framework slice.
3. Assembles `Artifacts/RouteBinary.xcframework`.
4. Also writes a `.zip` + checksum (only needed if you ever switch to remote
   Release-asset hosting; the zip is git-ignored).

## Caveats

- Build on a machine with Xcode; the script uses `xcodebuild -create-xcframework`.
- Public API signatures remain visible in the binary's `.swiftinterface`; only
  implementation bodies are hidden. Avoid `@inlinable` / `@_alwaysEmitIntoClient`
  in `Route`, or those bodies leak.
- Keep the archived **dSYMs** (under `.xcbuild/archives/*.xcarchive/dSYMs`) to
  symbolicate crash reports from consumers.
- The xcframework is compiled against specific majors of UtilityKit /
  AuthSessionKit. Keep consumers on the same major to avoid module-compat issues.
- **Why the xcframework is a STATIC framework, not dynamic:** a dynamic framework
  statically embeds its Swift dependencies (Factory, RouteInterface, …) into its
  binary. A consumer that also compiles those modules from source then has two
  copies, and cross-boundary calls (e.g. `SceneManager` resolving via Factory's
  `Container.shared`) reach a different copy → `EXC_BAD_ACCESS`. The static build
  leaves dependency symbols undefined so the consumer's single copy satisfies them.
  The build wraps SwiftPM's merged `RouteBinary.o` into a static framework binary
  with `libtool`.
- **Why library evolution is scoped per-target, not a global
  `BUILD_LIBRARY_FOR_DISTRIBUTION`:** globally, every source dependency is forced
  to emit a textual `.swiftinterface`, and UtilityKit's `MultiCastDelegate` module
  (which contains a protocol of the same name) emits one the compiler then fails
  to verify. Scoping evolution to `RouteBinary` keeps the dependency graph out of
  it.
