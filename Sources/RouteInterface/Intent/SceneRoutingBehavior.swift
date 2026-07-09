//
//  SceneRoutingBehaviour.swift
//  RouteKit
//
//  Created by kavi gevariya on 30/06/26.
//

import Foundation


/// Where a registered inbound intent should be routed once it arrives while the
/// app is running.
///
/// Returned by ``SceneConfiguratorProtocol/routingBehavior(for:within:)`` and
/// modeled on `UISceneSessionActivationRequest`'s activate-existing-or-create
/// semantics. The behavior only governs intents that arrive *while running* —
/// at cold launch the connecting scene is the destination by definition, so the
/// intent always routes into it.
///
/// Generic over the configurator's `SceneObject` so the new-window cases can
/// carry a type-safe target scene.
public enum SceneRoutingBehavior<SceneObject: SceneRepresentable>: Sendable {

    /// Route the intent into the window that received it. The default behavior.
    case currentScene

    /// Always activate a *new* window for `SceneObject` to handle the intent.
    /// Requires multi-scene support (see
    /// ``SceneHandleProtocol/allowsMultipleScenes``).
    case newScene(SceneObject)

    /// Bring an existing window of `SceneObject` forward and route into it,
    /// activating a new window only when none is currently connected. Requires
    /// multi-scene support.
    case preferExisting(SceneObject)
}
