//
//  RouteHandleConfigurable.swift
//  RouteKit
//
//  Created by kavi gevariya on 29/06/26.
//  Copyright © 2026 Kavi Gevariya (@kaVish2214).
//  Licensed under the Business Source License 1.1. See LICENSE.
//

import Foundation
import UIKit


/// The inputs a ``SceneHandleProtocol`` hands to
/// ``SceneConfiguratorProtocol/routeHandle(for:with:within:)`` so it can build a
/// ``RouteHandleProtocol`` for a connecting scene.
///
/// Bundles the scene's window, the owning scene handle (kept as a back-reference
/// so the route handle can drive scene-level activation), and the set of scene
/// intents that arrived with the connection and should be replayed once the
/// route's navigation stack is live.
@MainActor
public protocol RouteHandleConfigurable: Hashable, Equatable {

    /// The window scene the route handle will own.
    var windowScene: UIWindowScene { get }

    /// The app-level launch-state owner, passed through so the built handle can
    /// report when its scene finishes launching (see
    /// ``RouteHandleProtocol/applicationState``).
    var applicationState: any UIApplicationStateProtocol { get }

    /// The pending scene intents that accompanied the connection, pre-sorted
    /// into registered/unregistered, ready for the handle to replay once its
    /// navigation stack is live.
    var sceneIntentController: any SceneIntentControllerProtocol { get }

    /// The shared state-restoration façade the handle drives to seed its initial
    /// screen and persist snapshots (see ``RouteStateRestoration``).
    var stateRestoration: any RouteStateRestoration { get }
}

/// Default identity: two configurations are the same when they target the same
/// persisted scene session, belong to the same scene handle (by object
/// identity), and carry the same intent set. Keyed on the session's
/// `persistentIdentifier` rather than the `UIWindowScene` object so identity
/// is stable across a session's disconnect/reconnect cycle.
extension RouteHandleConfigurable {

    /// Hashes on the session's `persistentIdentifier` so identity survives a
    /// scene's disconnect/reconnect cycle (the `UIWindowScene` object changes;
    /// the persisted session id does not).
    public func hash(into hasher: inout Hasher) {
        hasher.combine(windowScene.session.persistentIdentifier)
    }

    /// Two configurations are equal when they target the same persisted scene
    /// session.
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.windowScene.session.persistentIdentifier == rhs.windowScene.session.persistentIdentifier
    }
}
