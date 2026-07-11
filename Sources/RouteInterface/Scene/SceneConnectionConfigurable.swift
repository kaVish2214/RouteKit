//
//  SceneConnectionConfigurable.swift
//  RouteKit
//
//  Created by kavi gevariya on 29/06/26.
//  Copyright © 2026 Kavi Gevariya (@kaVish2214).
//  Licensed under the Business Source License 1.1. See LICENSE.
//

import UIKit


/// The UIKit inputs that accompany a scene connection, bundled into one value
/// the scene handle threads through its `scene(_:willConnectTo:options:...)`
/// pipeline.
///
/// It carries the connecting window, its session, and the shared
/// state-restoration façade. The pipeline uses the ``scene`` as the built route
/// handle's window (and its lookup key in the scene store) and hands
/// ``stateRestoration`` to the new handle so it can seed a restored screen and
/// persist snapshots. The ``session`` is where a previously-connected scene's
/// identity is recovered from on relaunch (its persisted `userInfo`).
///
/// Deliberately carries only these — the inbound `connectionOptions` (URLs,
/// activities, shortcut) are handled separately by the intent pipeline, not by
/// connection configuration. `SceneConnectionConfiguration` in the `Route`
/// module is the default value box.
@MainActor
public protocol SceneConnectionConfigurable: Hashable, Equatable {

    /// The window scene UIKit is connecting.
    var scene: UIWindowScene { get }

    /// The session backing ``scene`` — its persisted `userInfo` is how a
    /// previously-connected scene's identity is recovered on relaunch.
    var session: UISceneSession { get }

    /// The shared state-restoration façade handed to the route handle built for
    /// this connection (see ``RouteStateRestoration``).
    var stateRestoration: any RouteStateRestoration { get }
}
