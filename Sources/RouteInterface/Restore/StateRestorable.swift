//
//  StateRestorable.swift
//  RouteKit
//
//  Created by kavi gevariya on 06/07/26.
//  Copyright © 2026 Kavi Gevariya (@kaVish2214).
//  Licensed under the Business Source License 1.1. See LICENSE.
//

import Foundation


/// The upward "please save / please forget my state" trigger surface.
///
/// Where ``StateRestoring`` describes *how* a screen snapshots itself,
/// `StateRestorable` is the imperative other half: the handful of calls a
/// screen (or the route handle) makes to *ask* RouteKit to persist or drop the
/// current scene's state on demand — for example, storing right after a
/// meaningful navigation, or discarding on sign-out.
///
/// Both ``RouteHandleProtocol`` and ``ViewControlling`` conform. A view
/// controller's default implementation simply forwards to its
/// ``ViewControlling/routeHandle``, so feature code can call
/// ``requestStoreState()`` from inside a screen without reaching for the handle
/// directly; the handle in turn routes the request through its
/// ``RouteStateRestoration``.
///
/// `@MainActor` because these calls originate from UIKit lifecycle work.
@MainActor
public protocol StateRestorable {

    /// Requests that the current scene's restoration snapshot be captured and
    /// persisted now. Resolves to a no-op when there's nothing restorable on
    /// top of the stack.
    func requestStoreState()

    /// Requests that any persisted snapshot for the current scene be discarded
    /// — e.g. on sign-out or when the screen becomes non-restorable.
    func requestDiscardState()
}


