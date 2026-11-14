//
//  EngineLinkageTests.swift
//  RouteKit
//
//  Copyright © 2026 Kavi Gevariya (@kaVish2214).
//  Licensed under the Business Source License 1.1. See LICENSE.
//

import Testing
import Route

extension RouteInterfaceModuleTests {

    /// Smoke tests that reach into the `Route` engine itself.
    ///
    /// The other suites here exercise `RouteInterface` only, so they would still pass
    /// if the precompiled engine failed to link. These reference public engine types
    /// (class metadata and a resilient enum), which forces the engine's code to be
    /// linked and executed — in the distribution package, from the binary xcframework.
    @Suite("Engine linkage")
    struct EngineLinkageTests {

        @Test("RouteHandle metadata resolves from the engine")
        func routeHandleMetadataResolves() {
            #expect(String(describing: RouteHandle.self) == "RouteHandle")
        }

        @Test("SceneTerminationRequestType cases round-trip through the engine")
        func terminationRequestTypeCasesMatch() {
            let system: SceneTerminationRequestType = .system
            let auth: SceneTerminationRequestType = .authenticationSession
            if case .system = system {} else { Issue.record(".system did not match .system") }
            if case .authenticationSession = auth {} else { Issue.record(".authenticationSession did not match") }
        }
    }
}
