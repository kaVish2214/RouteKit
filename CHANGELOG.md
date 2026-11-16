# Changelog

All notable changes to RouteKit are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project aims to follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.7] - 2026-11-14

### Fixed
- RouteKit 0.1.6 failed to build with Xcode 27 ("compiling for iOS 14.0, but module
  'AuthSessionInterface' has a minimum deployment target of iOS 15.0"). The engine
  interface now targets iOS 15, so every Xcode from Swift 6.3 onwards can rebuild it.

### Changed
- **Minimum deployment target raised to iOS 15.0 and Mac Catalyst 15.0** (was 14.0).
  Xcode 27's SDKs no longer support iOS 14, and the engine binary now targets
  iOS 15, so the package declares the floor it actually requires.
- `UtilityKit` and `AuthSessionKit` are now pinned with `.upToNextMinor(from:)` to
  the exact versions the precompiled engine is built against (previously
  `.upToNextMajor(from: "0.1.0")`, which for 0.x packages admitted any 0.x minor).
  Projects that resolve a different 0.x minor of either package must align with
  RouteKit's pinned line.
- `RouteHandleProtocol` conveniences no longer share signatures with the
  requirements they forward to. Previously, a custom conformer that omitted
  `push(to:animated:)` or `present(_:with:animated:completion:)` compiled and then
  recursed forever at run time; it is now a compile-time conformance error.
  Call sites are unaffected: `push(to:)` (without `animated:`) is now its own
  overload, and `present` is split into a no-completion and a with-completion
  overload with the same defaults as before.

### Security
- `RouteBinary.xcframework` is now code-signed with RouteKit's self-signed
  certificate, so its producer can be verified (the binary target is path-based and has
  no SwiftPM checksum). Compare the fingerprint Xcode shows with the one published in
  the README's "Security" section.

### Documentation
- README: fixed the quick-start `sceneTerminationPolicy(for:with:within:)`
  example, which used `for scene: AppScene` instead of the protocol's
  `for uiScene: UIScene`.
- README: the "Support & commercial use" section now matches the LICENSE
  (production use without limitation, for everyone).
- README / `SceneIntent` docs: URL intents match the full URL exactly (path and
  query included). The Notes example no longer registers `notes://note` while
  expecting `notes://note/<id>` to match; parameterised links are documented to go
  through `.userActivity` with the value in its `context`. No behavior change.
- README code examples now compile as written under Swift 6: the quick start adds the
  missing `import UIKit` and `restorationStorageExecution(for:didFailedWith:)`, the scene
  delegate calls `try` on `scene(_:willConnectTo:options:errorHandler:)` (it throws, e.g.
  for a refused duplicate window), the app delegate uses the shared manager, and the
  walkthrough uses the protocols' own parameter names. `route(to:)` references now read
  `route(to:completion:)`.
- README walkthrough: the Notes example registers a fixed deep link to one note
  (`notes://notes/groceries`) and routes it to that note's detail screen.
  `canPushViewController` now suppresses pushing only the *same* note twice in a row (it
  previously blocked any note detail over another, contradicting its comment).
  Its `sceneTerminationPolicy` now decides per window via `handle.scene(for:)`: sign-out
  closes the compose window only, and the main window stays and swaps to Sign in
  (previously every window allowed auth-session termination).
- New README overview animation: the Notes walkthrough on iPhone Duo and iPad — cold-launch
  Handoff queueing, sign-in replay, a deep link into the open window, a SwiftUI compose
  window, content obscuring, per-scene restoration, and sign-out by termination policy.
- README header: the RouteKit icon, centred above the title and badges.

## [0.1.6] - 2026-07-18

### Changed
- Documentation clean-up across the public API surface.

### Added
- Animated overview graphic in the README.

### Correction (added after release)
The original entry above was incomplete. 0.1.6 also contained API and behavior
changes, and the engine binary was rebuilt:
- **Added** `StateRestorationError.storageInitializationFailed`. This is
  **source-breaking** for code that switches exhaustively over
  `StateRestorationError` without a `default` / `@unknown default` case.
- **Changed:** when the restoration storage fails to initialize,
  `restorationStorageExecution(for:didFailedWith:)` now receives
  `.storageInitializationFailed` instead of the underlying error.
- **Changed:** the `reason` strings in `.writeFailed`, `.readFailed` and
  `.removalFailed` are now short, sanitized summaries; they no longer include the
  underlying error's description (which could contain file-system paths).
- **Changed:** `StateRestorationError.errorDescription` wording
  (`"… (underlying: <reason>)"` instead of `"…: Reason -> <reason>"`).

## [0.1.5] - 2026-07-15

### Changed
- Trimmed the dependency graph: `DependencyResolver` is no longer a direct
  dependency of the `Route` engine — it is reached transitively through
  `RouteInterface`, whose public API exposes it. No source or API change for
  consumers.

### Added
- `CHANGELOG.md`.
- Package metadata badges and a Support / Sponsorship section in the README.

## [0.1.4] - 2026-07-11

### Changed
- Documentation cleanup: public API doc comments no longer reference internal
  engine types. Documentation-only; no API or behavior change.

## [0.1.3] - 2026-07-11

### Added
- Initial public release of RouteKit.
- `RouteInterface` (source) — the protocols and value types you program against.
- `Route` (precompiled `xcframework`) — the routing engine: scene lifecycle,
  routing, deep-link / intent handling, content obscuration, auth-driven
  navigation, and state restoration.
- Business Source License 1.1 (`LICENSE`).

[0.1.7]: https://github.com/kaVish2214/RouteKit/compare/0.1.6...0.1.7
[0.1.6]: https://github.com/kaVish2214/RouteKit/compare/0.1.5...0.1.6
[0.1.5]: https://github.com/kaVish2214/RouteKit/compare/0.1.4...0.1.5
[0.1.4]: https://github.com/kaVish2214/RouteKit/compare/0.1.3...0.1.4
[0.1.3]: https://github.com/kaVish2214/RouteKit/releases/tag/0.1.3
