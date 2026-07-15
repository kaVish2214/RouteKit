//
//  SceneConfiguratorProtocol.swift
//  RouteKit
//
//  Created by kavi gevariya on 29/06/26.
//  Copyright © 2026 Kavi Gevariya (@kaVish2214).
//  Licensed under the Business Source License 1.1. See LICENSE.
//

import Foundation
import UIKit


/// The host app's plug-in that teaches a ``SceneHandleProtocol`` about its
/// scenes: which scene types exist, which inbound intents they accept, how each
/// intent should be routed, and how to build the ``RouteHandleProtocol`` for a
/// connected scene.
///
/// A single configurator instance is owned by the scene handle
/// (``SceneManager``) for the app's lifetime. Everything the handle needs to
/// know that is *app-specific* is asked here, so the engine stays generic over
/// the app's own scene vocabulary (`SceneObject`).
///
/// `@MainActor` because every method runs on the UIKit scene-lifecycle path.
@MainActor
public protocol SceneConfiguratorProtocol: AnyObject, StateRestorationConfigurable {

    /// The app's scene-identity type — typically a `String`-backed enum. All
    /// scene-typed API on the handle and configurator is generic over this.
    associatedtype SceneObject: SceneRepresentable

    /// Every scene type the app supports. Cached by the handle as
    /// ``SceneHandleProtocol/registeredScenes``; activating a scene not in this
    /// set fails with ``SceneRoutingError/sceneNotRegistered(_:)``.
    func registerScenes() -> Set<SceneObject>

    /// Every inbound intent (deep link / activity / quick action) the app is
    /// willing to handle. Cached as ``SceneHandleProtocol/registeredIntents``;
    /// an inbound value matching none of these is rejected with
    /// ``SceneRoutingError/unregisteredIntent(_:)``.
    func registerIntents() -> Set<SceneIntent>

    /// The app's window-multiplicity policy, cached at init. With
    /// ``WindowBehavior/windowPerScene``, a `.newScene` routing behaviour reuses
    /// an already-open window of the target identity instead of opening a
    /// duplicate. Defaults to ``WindowBehavior/windowPerScene``.
    func registerWindowBehavior() -> WindowBehavior
    
    /// The scene to fall back to when no specific identity is known — the
    /// single scene on a device without multi-window support, or a connecting
    /// window whose identity couldn't be recovered from any carrier.
    func primaryScene(for sceneHandle: any SceneHandleProtocol) -> SceneObject
    
    /// Builds (or resolves) the ``RouteHandleProtocol`` that will drive routing
    /// for `scene`, seeded with the `configuration` (window scene, owning
    /// handle, and the pending scene intents to replay once routing is live).
    /// Return `nil` to decline building a handle for this scene.
    func routeHandle(for scene: SceneObject, with configuration: any RouteHandleConfigurable, within sceneHandle: any SceneHandleProtocol) -> (any RouteHandleProtocol)?
    
    /// Where a *registered* `intent` should be routed when it arrives while the
    /// app is running — the current window, a new one, or an existing matching
    /// one. Defaults to ``SceneRoutingBehavior/currentScene``.
    func routingBehavior(for intent: SceneIntent, within sceneHandle: any SceneHandleProtocol) -> SceneRoutingBehavior<SceneObject>

    /// When an intent lands on a scene identity backed by *several* open
    /// windows, decides which of them execute it — the first match, all of
    /// them, or one specific `UIScene`. Defaults to
    /// ``UISceneExecutionPolicy/default``.
    func sceneIntentExecutionPolicy(for intent: SceneIntent, within sceneHandle: any SceneHandleProtocol) -> UISceneExecutionPolicy

    /// The teardown policy for the window `uiScene` given a
    /// `terminationRequest`. The handle uses
    /// ``SceneTerminationPolicy/isSystemTerminationAllowed`` to drive the
    /// scene's `windowingBehaviors.isClosable`.
    func sceneTerminationPolicy(for uiScene: UIScene, with terminationRequest: any SceneTerminationRequest, within sceneHandle: any SceneHandleProtocol) -> any SceneTerminationPolicy

    /// Notifies that a requested scene destruction failed (`uiScene` is the
    /// window that refused to die, when known). Default: no-op — override to
    /// log or retry.
    func sceneTermination(for uiScene: UIScene?, didFailedWith error: Error, within sceneHandle: any SceneHandleProtocol)
}

extension SceneConfiguratorProtocol {

    /// Default: one window per scene identity (reuse over duplicate).
    public func registerWindowBehavior() -> WindowBehavior {
        return .windowPerScene
    }

    /// Default: route every registered intent into the window that received it.
    public func routingBehavior(for intent: SceneIntent, within sceneHandle: any SceneHandleProtocol) -> SceneRoutingBehavior<SceneObject> {
        return .currentScene
    }

    /// Default: ignore destruction failures.
    public func sceneTermination(for uiScene: UIScene?, didFailedWith error: Error, within sceneHandle: any SceneHandleProtocol) {}

    /// Default: execute on the first matching window only.
    public func sceneIntentExecutionPolicy(for intent: SceneIntent, within sceneHandle: any SceneHandleProtocol) -> UISceneExecutionPolicy {
        .default
    }
}
