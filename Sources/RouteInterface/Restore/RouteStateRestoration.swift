//
//  RouteStateRestoration.swift
//  RouteKit
//
//  Created by kavi gevariya on 06/07/26.
//

import UIKit


/// The per-handle façade the routing engine uses to save, restore, and drop a
/// scene's state.
///
/// Every operation is expressed *in terms of a route handle*, because the handle
/// is what knows the concrete scene session (the persistence key, via its
/// `windowScene.session.persistentIdentifier`), the current top view controller
/// (the thing worth snapshotting), and the auth status the snapshot should be
/// gated against.
///
/// A route handle receives one of these at construction (through its
/// ``RouteHandleConfigurable/stateRestoration``) and drives it at the right
/// lifecycle moments: reading a snapshot back at launch to seed the initial
/// screen, writing one when the scene backgrounds or navigates, and discarding
/// one when the session ends. ``StateRestorationHandleProtocol`` is the
/// app-level refinement (with an app-wide initializer and bulk cleanup);
/// `StateRestorationHandle` in the `Route` module is the default conformer.
///
/// `@MainActor` because it reads live UIKit state; `AnyObject` because a single
/// instance is shared across the scenes of an app.
@MainActor
public protocol RouteStateRestoration: AnyObject {

    /// Returns the screen to restore for `routeHandle`'s scene, or `nil` when
    /// there's no usable record — none stored, the saved type can't be
    /// resolved, decoding fails, or the record's captured auth state doesn't
    /// match the current session. A `nil` result means "launch normally".
    func restoreState(for routeHandle: any RouteHandleProtocol) -> (any StateRestoring)?

    /// Captures and persists a snapshot of `routeHandle`'s current top screen.
    /// When the top screen isn't a ``StateRestoring``, this instead discards any
    /// existing record so stale state can't linger.
    func storeState(for routeHandle: any RouteHandleProtocol)

    /// Drops any persisted record for `routeHandle`'s scene session.
    func discardState(for routeHandle: any RouteHandleProtocol)
}
