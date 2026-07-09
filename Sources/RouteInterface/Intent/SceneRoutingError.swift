//
//  SceneRoutingError.swift
//  RouteKit
//
//  Created by kavi gevariya on 30/06/26.
//

import Foundation


/// Errors thrown by the scene handle when it cannot honour an intent or scene
/// activation request.
public enum SceneRoutingError: Error, Sendable {

    /// An inbound URL / activity / shortcut did not match any intent the
    /// configurator registered via
    /// ``SceneConfiguratorProtocol/registerIntents()``. Carries the offending
    /// ``SceneIntent`` (which is itself `Sendable`).
    case unregisteredIntent(SceneIntent)

    /// A new-window operation was requested but the app does not support
    /// multiple scenes (`UIApplication.supportsMultipleScenes` is `false`).
    case multipleScenesNotSupported

    /// A scene activation targeted a scene that isn't in the handle's
    /// ``SceneHandleProtocol/registeredScenes``.
    case sceneNotRegistered(any SceneRepresentable)

    /// The router denied execution of a pending intent for now (see
    /// ``SceneIntentExecutionPermission/executionDenied``). Raised per-intent —
    /// the intent is re-queued and retried later, e.g. once the user signs in.
    case sceneIntentExecutionDenied(SceneIntent)

    /// A scene activation targeted an identity whose window is already the
    /// active foreground scene, so there was nothing new to activate.
    case sceneAlreadyActive(any SceneRepresentable)
}

extension SceneRoutingError: LocalizedError {

    /// A user-/log-facing message for each case, embedding the offending intent
    /// or scene where relevant.
    public var errorDescription: String? {
        switch self {
        case .unregisteredIntent(let sceneIntent):
            return "\(sceneIntent) is not registered."
        case .multipleScenesNotSupported:
            return "Multiple scenes are not supported."
        case .sceneNotRegistered(let scene):
            return "\(String(describing: scene)) is not registered."
        case .sceneIntentExecutionDenied(let intent):
            return "\(String(describing: intent)) is not allowed to be executed, Will be executed once user signs in."
        case .sceneAlreadyActive(let scene):
            return "\(scene) is already active."
        }
    }
}
