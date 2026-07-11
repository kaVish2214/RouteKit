//
//  StateRestorationTests.swift
//  RouteKit
//
//  Copyright © 2026 Kavi Gevariya (@kaVish2214).
//  Licensed under the Business Source License 1.1. See LICENSE.
//

import Testing
import Foundation
@testable import RouteInterface

extension RouteInterfaceModuleTests {

    /// Covers the UIKit-free half of the state-restoration contract: the
    /// `StateRepresentable` snapshot encoding and the `StateRestoring`
    /// snapshot → rebuild round-trip. (The engine that keys these by scene
    /// session — `StateRestorationHandle` — is integration-only.)
    @Suite("State restoration contract")
    struct StateRestorationContractTests {

        /// A small `Codable` snapshot.
        private struct DemoState: StateRepresentable, Equatable {
            var id: Int
            var title: String
        }

        /// A non-UIKit ``StateRestoring`` so the round-trip can run without a
        /// view-controller host.
        @MainActor
        private final class DemoScreen: StateRestoring {
            let id: Int
            let title: String
            init(id: Int, title: String) { self.id = id; self.title = title }

            func restoringState() -> DemoState { DemoState(id: id, title: title) }

            static func restore(with state: DemoState) -> any StateRestoring {
                DemoScreen(id: state.id, title: state.title)
            }
        }

        // MARK: - StateRepresentable

        @Test("encoded() produces JSON that decodes back to an equal value")
        func encodedRoundTrips() throws {
            let state = DemoState(id: 7, title: "hello")
            let data = try state.encoded()
            let decoded = try JSONDecoder().decode(DemoState.self, from: data)
            #expect(decoded == state)
        }

        // MARK: - StateRestoring

        @Test("restoringState → encode → decode → restore rebuilds the screen")
        @MainActor
        func restoreRoundTrips() throws {
            let original = DemoScreen(id: 42, title: "profile")
            let data = try original.restoringState().encoded()

            let decoded = try JSONDecoder().decode(DemoState.self, from: data)
            let rebuilt = DemoScreen.restore(with: decoded)

            let rebuiltScreen = try #require(rebuilt as? DemoScreen)
            #expect(rebuiltScreen.id == 42)
            #expect(rebuiltScreen.title == "profile")
        }

        @Test("default restoringTargetIdentifier is the class name")
        @MainActor
        func defaultTargetIdentifier() {
            #expect(DemoScreen.restoringTargetIdentifier == NSStringFromClass(DemoScreen.self))
            // Stable across reads.
            #expect(DemoScreen.restoringTargetIdentifier == DemoScreen.restoringTargetIdentifier)
        }
    }

    /// `StateRestorationError` message surface.
    @Suite("StateRestorationError")
    struct StateRestorationErrorTests {

        @Test("payloadTooLarge embeds the identifier, size, and limit")
        func payloadTooLarge() {
            let error = StateRestorationError.payloadTooLarge(identifier: "Screen.A", bytes: 999, limit: 100)
            let message = error.errorDescription ?? ""
            #expect(message.contains("Screen.A"))
            #expect(message.contains("999"))
            #expect(message.contains("100"))
        }

        @Test("targetNotFound embeds the identifier")
        func targetNotFound() {
            let error = StateRestorationError.targetNotFound(identifier: "Missing.Type")
            #expect(error.errorDescription?.contains("Missing.Type") == true)
        }

        @Test("storageNotInitialized has a stable message")
        func storageNotInitialized() {
            #expect(StateRestorationError.storageNotInitialized.errorDescription == "Storage not initialized")
        }
    }
}
