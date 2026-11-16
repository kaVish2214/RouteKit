//
//  RouteHandleProtocol.swift
//  RouteKit
//
//  Created by kavi gevariya on 19/05/26.
//  Copyright © 2026 Kavi Gevariya (@kaVish2214).
//  Licensed under the Business Source License 1.1. See LICENSE.
//

import Foundation
import AuthSessionInterface
import UIKit
import DependencyResolver

/// The handle a host app uses to drive routing on a single `UIWindowScene`.
///
/// `RouteHandleProtocol` is the public surface of the run-time engine that
/// owns the primary navigation stack, the splash + content-obscuration
/// overlay, and the auth-session subscription that drives transitions.
/// `RouteHandle` (in the `Route` module) is the default concrete conformer.
///
/// Conforming types also conform to `DependencyResolver` so a handle can be
/// resolved through the shared container from anywhere in the app —
/// typically by routed view controllers reaching back through
/// ``RoutingViewControlling/routeHandle``.
///
/// `@MainActor` because every method touches UIKit on the main thread;
/// `AnyObject` so the handle's identity is stable across the scene's
/// lifetime.
@MainActor
public protocol RouteHandleProtocol: AnyObject, DependencyResolver, StateRestorable {

    /// The scene this handle drives. Weak / optional because the scene owns the
    /// handle indirectly and may disconnect before the handle is released.
    var windowScene: UIWindowScene? { get }

    /// The app-level launch-state owner (the ``SceneHandleProtocol``), kept as a
    /// back-reference so the handle can flip the app out of its launch phase
    /// (``UIApplicationStateProtocol/applicationLaunched()``) once *this* scene
    /// finishes its launch sequence. Optional / weak because the scene handle
    /// owns the route handle, not the other way round.
    var applicationState: (any UIApplicationStateProtocol)? { get }

    /// The auth session whose status changes drive routing transitions for
    /// this scene. Read by routers (for example, to decide the initial view
    /// controller) and by RouteKit's internal obscuration gating logic.
    var authSessionHandle: any AuthSessionHandleProtocol { get }
    
    /// `true` once the launch sequence has finished installing the initial
    /// navigation stack on the primary window; `false` while the splash is
    /// still on screen. Lets observers distinguish launch-time state from
    /// steady-state routing.
    ///
    /// Conformers are expected to flip this at the *end* of their launch
    /// path (the default conformer does so via `defer`), so a reader who
    /// sees `true` is guaranteed that all launch-time UI work has already
    /// landed.
    var isRouteInitialized: Bool { get }

    /// The view controller currently sitting on top of the navigation stack,
    /// or `nil` before the launch sequence completes. Typed as the broader
    /// `UIViewController` rather than ``RoutingViewControlling`` so the
    /// property can surface non-routed system controllers (for example, an
    /// `SFSafariViewController` pushed by a deep-link handler) — callers
    /// that only care about routed screens can cast.
    ///
    /// Default conformers derive this on demand from the navigation stack's
    /// top, so reading it always reflects the live UIKit state with no
    /// bookkeeping required from feature code.
    var currentViewController: UIViewController? { get }
    
    /// The per-scene store of pending scene intents (deep links / activities /
    /// quick actions) awaiting execution, plus the unregistered ones held aside.
    /// The handle drains it as routing becomes able to honour each intent.
    var sceneIntentController: any SceneIntentControllerProtocol { get }

    /// Designated initializer.
    ///
    /// - Parameters:
    ///   - configuration: The bundle of inputs the scene handle assembled for
    ///     this scene — the ``RouteHandleConfigurable/windowScene`` the handle
    ///     takes ownership of (creating and managing both its primary and
    ///     overlay windows), the pending
    ///     ``RouteHandleConfigurable/sceneIntentController`` to replay once
    ///     routing is live, and the ``RouteHandleConfigurable/stateRestoration``
    ///     façade.
    ///   - authenticationSessionHandle: The auth session driving routing.
    ///     The parameter is optional for source compatibility, but the
    ///     default conformer treats `nil` as a programmer error and traps
    ///     with `preconditionFailure` — every routing decision branches on
    ///     the session.
    ///   - router: The router supplying the splash, initial, and obscuration
    ///     view controllers.
    init(_ configuration: any RouteHandleConfigurable, authenticationSessionHandle: (any AuthSessionHandleProtocol)?, router: any RouterProtocol)

    /// Pushes `viewController` onto the navigation stack, honouring its
    /// ``RoutingViewControlling/preferredNavigationActionWhenPushed()``
    /// decision (plain push, replace-current, replace-all, with or without
    /// the incoming view controller's preceding chain).
    ///
    /// No-op when the navigation controller has not yet been installed
    /// (i.e. before the launch sequence completes).
    ///
    /// - Parameters:
    ///   - viewController: The view controller to push.
    ///   - animated: Whether the push uses an animated transition.
    @discardableResult
    func push(to viewController: any RoutingViewControlling, animated: Bool) -> Bool

    /// Pushes a plain `UIViewController` that doesn't adopt
    /// ``RoutingViewControlling`` — e.g. a system controller like
    /// `SFSafariViewController` surfaced by a deep-link handler. Without a
    /// declared navigation action it's treated as a plain
    /// ``NavigationAction/push``.
    ///
    /// - Returns: `true` when the push was performed, `false` when the
    ///   navigation controller isn't installed yet or the router vetoed it.
    @discardableResult
    func push(to viewController: UIViewController, animated: Bool) -> Bool

    /// Pops the top view controller off the navigation stack. No-op when
    /// the navigation controller has not yet been installed.
    ///
    /// `@discardableResult` mirrors `UINavigationController.popViewController(animated:)`
    /// so call sites that only care about the pop side-effect don't have to
    /// silence a warning.
    ///
    /// - Parameter animated: Whether the pop uses an animated transition.
    /// - Returns: The popped view controller, or `nil` when nothing was on
    ///   the stack to pop (or the navigation controller wasn't yet
    ///   installed).
    @discardableResult
    func pop(animated: Bool) -> UIViewController?
    
    /// Presents `viewController` modally over the scene. `presentationSource`
    /// chooses the presenter: the top-most controller
    /// (``PresentationSource/currentController``) or the navigation controller
    /// itself (``PresentationSource/rootController``, which covers the whole
    /// stack). `completion` fires once the presentation finishes.
    func present(_ viewController: UIViewController, with presentationSource: any PresentationSourceProtocol, animated flag: Bool, completion: (() -> Void)?)

    /// Routes a single inbound `sceneIntent` into this scene.
    ///
    /// If routing isn't live yet (``isRouteInitialized`` is `false`), the intent
    /// is **queued** on the ``sceneIntentController`` and replayed once the
    /// launch sequence completes — so intents survive arriving mid-launch.
    /// Otherwise the handle asks the router (``RouterProtocol/shouldExecute(pending:current:for:)``)
    /// and pushes, denies, or discards accordingly.
    ///
    /// - Parameter completion: A **per-intent error/denial channel** — invoked
    ///   only when this intent can't be honoured (e.g. the router denied it). It
    ///   is *not* a once-only completion and is never called on success; a
    ///   fan-out across several intents may invoke it once per failing intent.
    func route(to sceneIntent: SceneIntent, completion: @escaping (any Error) -> Void)

    /// Replays every intent still queued on the ``sceneIntentController`` —
    /// typically after an event that may now permit previously-denied intents
    /// to run (for example, a successful sign-in). Each still-blocked intent
    /// stays queued and reports through `completion` as in ``route(to:completion:)``.
    func executePendingSceneIntents(completion: @escaping (any Error) -> Void)
}

extension RouteHandleProtocol {

    /// Convenience that resolves `type` through the dependency container
    /// and pushes the resolved instance. Silently no-ops when the
    /// container has no registration for `type`, or when the resolved value
    /// is not a ``RoutingViewControlling``.
    ///
    /// - Parameters:
    ///   - type: The view-controller type to resolve and push.
    ///   - animated: Whether the push uses an animated transition.
    public func push<ViewController>(_ type: ViewController.Type, animated: Bool = true) {
        guard let viewController = self.resolved(type) as? RoutingViewControlling else {
            return
        }
        self.push(to: viewController, animated: animated)
    }
    
    // The conveniences below deliberately use signatures that DIFFER from the
    // requirements they forward to. An extension method whose signature matches
    // a requirement becomes that requirement's default witness, so a conformer
    // that forgot to implement it would compile and then recurse forever.
    // With distinct signatures, a missing implementation is a compile error.

    /// Convenience over the `RoutingViewControlling` push requirement for call
    /// sites that omit `animated:` (pushes animated).
    @discardableResult
    public func push(to viewController: any RoutingViewControlling) -> Bool {
        return self.push(to: viewController, animated: true)
    }

    /// Convenience over the plain-`UIViewController` push requirement for call
    /// sites that omit `animated:` (pushes animated).
    @discardableResult
    func push(to viewController: UIViewController) -> Bool {
        return self.push(to: viewController, animated: true)
    }

    /// Default-argument convenience over
    /// ``present(_:with:animated:completion:)`` without a completion: presents
    /// from the top-most controller (``PresentationSource/currentController``),
    /// animated, unless specified otherwise.
    public func present(_ viewController: UIViewController, with presentationSource: any PresentationSourceProtocol = PresentationSource.currentController, animated flag: Bool = true) {
        self.present(viewController, with: presentationSource, animated: flag, completion: nil)
    }

    /// Default-argument convenience over
    /// ``present(_:with:animated:completion:)`` with a completion (e.g. a
    /// trailing closure). The completion is non-optional here so this overload
    /// is not a witness for the requirement; it is forwarded as an optional,
    /// which can only resolve to the requirement.
    public func present(_ viewController: UIViewController, with presentationSource: any PresentationSourceProtocol = PresentationSource.currentController, animated flag: Bool = true, completion: @escaping () -> Void) {
        let completion: (() -> Void)? = completion
        self.present(viewController, with: presentationSource, animated: flag, completion: completion)
    }
    
    /// Asks UIKit to refresh this scene's session — re-querying its
    /// configuration (e.g. its title/activity) via
    /// `UIApplication.requestSceneSessionRefresh`. No-op if the scene has
    /// already disconnected.
    public func requestSceneSessionRefresh() {
        guard let windowScene else {
            return
        }
        UIApplication.shared.requestSceneSessionRefresh(windowScene.session)
    }
}
