//
//  StateRestorationHandleProtocol.swift
//  RouteKit
//
//  Created by kavi gevariya on 06/07/26.
//  Copyright © 2026 Kavi Gevariya (@kaVish2214).
//  Licensed under the Business Source License 1.1. See LICENSE.
//

import Foundation
import UIKit


/// The app-level owner of state restoration — one instance per app, sitting
/// above the per-scene ``RouteStateRestoration`` operations it inherits.
///
/// It refines ``RouteStateRestoration`` with two things the individual route
/// handles can't own themselves: construction from the host's
/// ``StateRestorationConfigurable`` (which also selects and initializes the
/// storage backend), and bulk cleanup keyed by ``UISceneSession`` — the shape
/// UIKit hands back when the system discards sessions (`didDiscardSceneSessions`),
/// which may name scenes that aren't currently connected to any handle.
///
/// `StateRestorationHandle` in the `Route` module is the default conformer.
@MainActor
public protocol StateRestorationHandleProtocol: RouteStateRestoration {

    /// Designated initializer. Reads the host's storage registration from
    /// `configuration` (falling back to the default file-backed storage) and
    /// initializes it up front, reporting any failure through the
    /// configuration's error hook.
    init(_ configuration: any StateRestorationConfigurable)

    /// Discards persisted records for a set of scene sessions at once — used to
    /// service UIKit's `application(_:didDiscardSceneSessions:)`, where the
    /// sessions may no longer be connected. Keyed by
    /// `UISceneSession.persistentIdentifier`.
    func discardStates(for sessions: Set<UISceneSession>)
}

