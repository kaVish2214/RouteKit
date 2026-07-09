// The Route implementation ships as a precompiled binary (RouteBinary.xcframework).
//
// This umbrella re-exports it so consumers keep writing `import Route` and never
// need to know the binary module exists. This is the ONLY source file in the
// distributed `Route` target — the actual engine lives in the sealed binary.
@_exported import RouteBinary
