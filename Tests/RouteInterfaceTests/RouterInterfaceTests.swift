//
//  RouterInterfaceTests.swift
//  RouteKit
//
//  Copyright © 2026 Kavi Gevariya (@kaVish2214).
//  Licensed under the Business Source License 1.1. See LICENSE.
//

import Testing
import UIKit
@testable import RouteInterface

extension RouteInterfaceModuleTests {

    @Suite("RouterProtocol surface")
    @MainActor
    struct RouterProtocolTests {

        @Test("a stub conformer satisfies the RouterProtocol surface")
        func stubConforms() {
            let sut = StubRouter()
            _ = sut // constructing a conformer proves the protocol surface is satisfiable.
        }

        @Test("allowsPrecedingStackOnInitialRoute round-trips through a stub conformer")
        func precedingStackFlagRoundTrips() {
            let sut = StubRouter()
            #expect(sut.allowsPrecedingStackOnInitialRoute == false)
            sut.allowsPrecedingStackOnInitialRoute = true
            #expect(sut.allowsPrecedingStackOnInitialRoute == true)
        }

        // MARK: - Integration-only coverage
        //
        // `RouterProtocol`'s remaining methods all take a parameter that's
        // prohibitively heavy to stub at the unit-test level:
        //
        //  - `shouldObscureContentWhenInactive(for:)`              ← RouteHandleProtocol
        //  - `preferredContentObscurationViewController(for:)`     ← RouteHandleProtocol
        //  - `preferredInitialViewController(for:)`                ← AuthSessionHandleProtocol
        //
        // ``RouteHandleProtocol`` depends transitively on
        // ``AuthSessionHandleProtocol``, which has two associated types,
        // conforms to ``DelegateMultiCasting`` + `Sendable`, and pulls in
        // ``AuthSessionProviderProtocol`` + ``AuthSessionProtocol`` +
        // ``BiometricAuthenticationRequestor`` implementations. The default
        // implementations of the obscuration hooks additionally branch on
        // ``AuthSessionHandleProtocol/isManualAuthenticationRequired`` and
        // ``AuthSessionStatusProtocol/isSignedIn``.
        //
        // The behaviours of these three methods — including the obscuration
        // defaults — are covered by host-app integration tests where a real
        // `RouteHandle` and `AuthSessionHandle` can be brought up together.
    }
}
