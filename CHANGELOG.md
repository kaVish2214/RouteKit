# Changelog

All notable changes to RouteKit are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project aims to follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

[0.1.5]: https://github.com/kaVish2214/RouteKit/compare/0.1.4...0.1.5
[0.1.4]: https://github.com/kaVish2214/RouteKit/compare/0.1.3...0.1.4
[0.1.3]: https://github.com/kaVish2214/RouteKit/releases/tag/0.1.3
