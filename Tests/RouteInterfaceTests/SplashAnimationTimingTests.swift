//
//  SplashAnimationTimingTests.swift
//  RouteKit
//
//  Copyright © 2026 Kavi Gevariya (@kaVish2214).
//  Licensed under the Business Source License 1.1. See LICENSE.
//

import Testing
@testable import RouteInterface

extension RouteInterfaceModuleTests {

    @Suite("SplashAnimationTiming")
    struct SplashAnimationTimingTests {

        @Test(".default and .waitUntilAnimationComplete are distinct cases")
        func casesAreDistinct() {
            let a: SplashAnimationTiming = .default
            let b: SplashAnimationTiming = .waitUntilAnimationComplete
            switch (a, b) {
            case (.default, .waitUntilAnimationComplete):
                break
            default:
                Issue.record("Expected distinct .default and .waitUntilAnimationComplete cases")
            }
        }

        @Test(".default pattern-matches as .default")
        func defaultMatches() {
            let timing: SplashAnimationTiming = .default
            if case .default = timing {
                // expected
            } else {
                Issue.record(".default did not pattern-match as .default")
            }
        }

        @Test(".waitUntilAnimationComplete pattern-matches as .waitUntilAnimationComplete")
        func waitUntilMatches() {
            let timing: SplashAnimationTiming = .waitUntilAnimationComplete
            if case .waitUntilAnimationComplete = timing {
                // expected
            } else {
                Issue.record(".waitUntilAnimationComplete did not pattern-match correctly")
            }
        }
    }
}
