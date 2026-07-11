//
//  SceneHandleProtocol.swift
//  RouteKit
//
//  Created by kavi gevariya on 29/06/26.
//  Copyright © 2026 Kavi Gevariya (@kaVish2214).
//  Licensed under the Business Source License 1.1. See LICENSE.
//

import Foundation
import UIKit

/// The app-level owner of every scene's routing — one instance per app,
/// retained by the composition root (typically the `UIWindowSceneDelegate`).
///
/// Where ``RouteHandleProtocol`` drives a *single* scene, `SceneHandleProtocol`
/// sits above them all: it caches the ``SceneConfiguratorProtocol``'s scene and
/// intent registrations, builds a route handle per connecting `UIWindowScene`,
/// and is the entry point the scene delegate forwards its callbacks to
/// (`willConnectTo`, `openURLContexts`, `continue`, `performActionFor`). It also
/// owns scene *activation* — opening or bringing forward windows — gated by
/// ``allowsMultipleScenes``.
///
/// ``SceneManager`` is the default concrete conformer. `@MainActor` because
/// every method is on the UIKit scene-lifecycle path.
@MainActor
public protocol SceneHandleProtocol: AnyObject, UIApplicationStateProtocol {

    /// Every scene the configurator registered, cached at init. Activating a
    /// scene outside this set fails with ``SceneRoutingError/sceneNotRegistered(_:)``.
    var registeredScenes: Set<SceneConfigurator.SceneObject> { get }

    /// The inbound intents this handle accepts, cached from the configurator's
    /// ``SceneConfiguratorProtocol/registerIntents()`` at init. Inbound
    /// values not matching one of these are rejected.
    var registeredIntents: Set<SceneIntent> { get }

    /// Whether the app supports more than one scene simultaneously. New-window
    /// operations fail with ``SceneRoutingError/multipleScenesNotSupported``
    /// when this is `false`, and inbound intents degrade to the current window.
    /// Defaults to `UIApplication.shared.supportsMultipleScenes`.
    var allowsMultipleScenes: Bool { get }

    /// The app's window-multiplicity policy, cached from the configurator's
    /// ``SceneConfiguratorProtocol/registerWindowBehavior()`` at init. See
    /// ``WindowBehavior``.
    var preferredWindowBehavior: WindowBehavior { get }

    /// The scenes currently connected and tracked by the handle (a subset of
    /// ``registeredScenes`` — those with a live `UIWindowScene`).
    var connectedScenes: Set<SceneConfigurator.SceneObject> { get }

    /// The app's ``SceneConfiguratorProtocol`` type.
    associatedtype SceneConfigurator: SceneConfiguratorProtocol

    /// The configurator the handle consults for all app-specific scene
    /// decisions. Retained for the handle's lifetime.
    var sceneConfigurator: SceneConfigurator { get }

    /// Designated initializer. Caches the configurator's scene and intent
    /// registrations up front.
    init(sceneConfigurator: SceneConfigurator)

    /// Handles a `UIWindowScene` connection: resolves the scene's identity,
    /// persists it on the session, collects and routes the intents that
    /// accompanied the connection, builds the ``RouteHandleProtocol`` for the
    /// scene, and returns it.
    ///
    /// Forward the scene delegate's `scene(_:willConnectTo:options:)` here.
    ///
    /// - Throws: ``SceneRoutingError/sceneNotRegistered(_:)`` when the resolved
    ///   identity isn't registered (the session is destroyed). Per-intent
    ///   routing failures surface asynchronously on `errorHandler`.
    @discardableResult
    func scene(_ scene: UIWindowScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions, errorHandler: @escaping (any Error) -> Void) throws -> (any RouteHandleProtocol)?

    /// The ``SceneObject`` identity for a live `UIScene`, or `nil` if the handle
    /// isn't tracking it.
    func scene(for uiScene: UIScene?) -> SceneConfigurator.SceneObject?

    /// The connected `UIScene` backing a given ``SceneObject`` identity, or
    /// `nil` if that scene isn't currently connected. When several windows share
    /// the identity, returns the first match — use ``uiScenes(for:)`` for all.
    func uiScene(for scene: SceneConfigurator.SceneObject?) -> UIScene?

    /// Every connected `UIScene` backing a given ``SceneObject`` identity —
    /// possibly more than one on multi-window iPad/Mac, empty when none is
    /// connected.
    func uiScenes(for scene: SceneConfigurator.SceneObject?) -> [UIScene]

    /// The route handle owning a given `UIScene`, or `nil` if none.
    func routeHandle(for scene: UIScene?) -> (any RouteHandleProtocol)?

    /// Activates `scene` in its own window. Requires multi-scene support —
    /// reports ``SceneRoutingError/multipleScenesNotSupported`` (or
    /// ``SceneRoutingError/sceneNotRegistered(_:)``) through `errorHandler`.
    func requestSceneActivation(_ scene: SceneConfigurator.SceneObject, errorHandler: @escaping (any Error) -> Void)

    /// Tears down the window(s) backing a `scene` identity. When more than one
    /// window shares the identity, `executionHandler` is consulted with the live
    /// windows to pick which to destroy (first / all / a specific one — see
    /// ``UISceneExecutionPolicy``). Failures — including a scene the configurator's
    /// ``SceneConfiguratorProtocol/sceneTerminationPolicy(for:with:within:)`` won't
    /// allow to close — surface on `errorHandler`.
    func requestSceneDestruction(_ scene: SceneConfigurator.SceneObject, executionHandler: @escaping ([UIScene]) -> UISceneExecutionPolicy, errorHandler: @escaping (any Error) -> Void)

    /// Tears down one specific window. Failures (e.g. a termination policy that
    /// vetoes the close) surface on `errorHandler`.
    func requestSceneDestruction(_ uiScene: UIScene, errorHandler: @escaping (any Error) -> Void)

    /// Dispatches a `sceneIntent` programmatically, applying the configurator's
    /// ``SceneConfiguratorProtocol/routingBehavior(for:within:)`` (current /
    /// new / existing window). `currentScene` is the originating window the
    /// behavior is resolved relative to.
    ///
    /// - Throws: ``SceneRoutingError/unregisteredIntent(_:)`` synchronously when
    ///   the intent isn't registered. Deferred failures surface via `errorHandler`.
    func requestSceneIntentActivation(_ sceneIntent: SceneIntent, currentScene: UIScene, errorHandler: @escaping (any Error) -> Void) throws

    /// Forwards inbound deep-link URLs delivered while running. Each URL is
    /// validated and routed per its behavior; failures/denials arrive on
    /// `errorHandler` (one call per failing intent). Forward the scene delegate's
    /// `scene(_:openURLContexts:)` here.
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>, errorHandler: @escaping (any Error) -> Void)

    /// Forwards an inbound `NSUserActivity` (Handoff / Spotlight / Siri)
    /// delivered while running. Mirrors ``scene(_:openURLContexts:errorHandler:)``.
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity, errorHandler: @escaping (any Error) -> Void)

    /// Forwards a Home Screen quick action delivered while running. Calls
    /// `completionHandler` exactly once with `true` when the action was
    /// recognized and dispatched, `false` when its intent isn't registered; the
    /// unregistered-intent error is delivered separately on `errorHandler`.
    /// Forward the scene delegate's `windowScene(_:performActionFor:completionHandler:)` here.
    func scene(_ scene: UIScene, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void, errorHandler: @escaping (any Error) -> Void)

    /// Drops the handle's tracking (and any restoration records) for sessions
    /// the system has discarded. Forward the app delegate's
    /// `application(_:didDiscardSceneSessions:)` here.
    func discardSceneSessions(for sessions: Set<UISceneSession>)
}

extension SceneHandleProtocol {

    /// Convenience: the route handle for a ``SceneObject`` identity, resolved by
    /// first finding its live `UIScene` (the first match when several share the
    /// identity). `nil` if the scene isn't connected.
    public func routeHandle(using anyScene: SceneConfigurator.SceneObject?) -> (any RouteHandleProtocol)? {
        let uiScene = self.uiScene(for: anyScene)
        return self.routeHandle(for: uiScene)
    }

    /// Default: reflects `UIApplication.shared.supportsMultipleScenes`, which
    /// is driven by the `UIApplicationSupportsMultipleScenes` Info.plist key.
    public var allowsMultipleScenes: Bool {
        return UIApplication.shared.supportsMultipleScenes
    }

    /// Whether `intent` was registered by the configurator and may be handled.
    public func canHandle(_ intent: SceneIntent) -> Bool {
        return registeredIntents.contains(intent)
    }
}
