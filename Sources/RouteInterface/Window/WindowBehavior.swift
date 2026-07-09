//
//  WindowBehavior.swift
//  RouteKit
//
//  Created by kavi gevariya on 03/07/26.
//

import Foundation


/// The app's window-multiplicity policy, declared once via
/// ``SceneConfiguratorProtocol/registerWindowBehavior()`` and cached by the
/// scene handle.
///
/// Governs what a ``SceneRoutingBehavior/newScene(_:)`` intent does when a
/// window of the target scene identity is already open: with
/// ``windowPerScene`` the intent routes into the existing window (each identity
/// gets at most one window); with ``undefined`` no constraint applies and a
/// duplicate window is opened.
public enum WindowBehavior: Sendable, Hashable {

    /// No multiplicity constraint — `.newScene` always opens another window,
    /// so several windows may share one scene identity.
    case undefined

    /// At most one window per scene identity — `.newScene` reuses an existing
    /// window of the target identity instead of duplicating it. The default.
    case windowPerScene
}

