//
//  SceneTerminationRequest.swift
//  RouteKit
//
//  Created by kavi gevariya on 30/06/26.
//  Copyright © 2026 Kavi Gevariya (@kaVish2214).
//  Licensed under the Business Source License 1.1. See LICENSE.
//

import Foundation


/// The trigger asking whether a scene should be torn down — passed to
/// ``SceneConfiguratorProtocol/sceneTerminationPolicy(for:with:within:)`` so the
/// configurator can answer differently for a user/system close versus an
/// auth-driven teardown.
///
/// A request reports its origin through mutually-exclusive flags rather than an
/// enum so the contract stays open for host apps to model additional triggers;
/// the shipped concrete type is the `Route` module's `SceneTerminationRequestType`.
public protocol SceneTerminationRequest: Sendable {

    /// `true` when the teardown originates from the user or the system (e.g.
    /// closing the window).
    var isSystemRequest: Bool { get }

    /// `true` when the teardown originates from an auth-session transition.
    var isAuthSessionTermination: Bool { get }
}

