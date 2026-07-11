//
//  AuthSessionDelegateEventTests.swift
//  RouteKit
//
//  Copyright © 2026 Kavi Gevariya (@kaVish2214).
//  Licensed under the Business Source License 1.1. See LICENSE.
//

import Testing
import AuthSessionInterface
@testable import RouteInterface

extension RouteInterfaceModuleTests {

    /// Shape-only tests for ``AuthSessionDelegateEvent``.
    ///
    /// The proxy-translation tests in `AuthSessionDelegateProxyTests` cover
    /// each case in the context of an upstream callback. These tests stand
    /// alone — they verify the enum's pattern-matching and payload
    /// destructuring independently, so a refactor that changes case shapes
    /// gets caught here even before any proxy code runs.
    @Suite("AuthSessionDelegateEvent shape")
    struct AuthSessionDelegateEventTests {

        @Test(".sessionFetch(isInitial: true) destructures to true")
        func sessionFetchInitialPayload() {
            let event: AuthSessionDelegateEvent = .sessionFetch(isInitial: true)
            guard case .sessionFetch(let isInitial) = event else {
                Issue.record("Expected .sessionFetch, got \(event)")
                return
            }
            #expect(isInitial == true)
        }

        @Test(".sessionFetch(isInitial: false) destructures to false")
        func sessionFetchRefreshPayload() {
            let event: AuthSessionDelegateEvent = .sessionFetch(isInitial: false)
            guard case .sessionFetch(let isInitial) = event else {
                Issue.record("Expected .sessionFetch, got \(event)")
                return
            }
            #expect(isInitial == false)
        }

        @Test(".sessionFetch does not pattern-match as another case")
        func sessionFetchDoesNotMatchOthers() {
            let event: AuthSessionDelegateEvent = .sessionFetch(isInitial: true)
            switch event {
            case .login, .logout, .sessionStatusChanged, .failure, .userUpdate:
                Issue.record(".sessionFetch matched a non-fetch case")
            case .sessionFetch:
                break
            }
        }

        @Test(".logout(error: nil) destructures to nil")
        func logoutNilErrorDestructures() {
            let event: AuthSessionDelegateEvent = .logout(error: nil)
            guard case .logout(let error) = event else {
                Issue.record("Expected .logout, got \(event)")
                return
            }
            #expect(error == nil)
        }

        @Test(".logout(error:) preserves a non-nil error payload")
        func logoutErrorPayloadPreserved() {
            struct StubError: Error { }
            let event: AuthSessionDelegateEvent = .logout(error: StubError())
            guard case .logout(let error) = event else {
                Issue.record("Expected .logout, got \(event)")
                return
            }
            #expect(error is StubError)
        }
    }
}
