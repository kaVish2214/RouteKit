//
//  RouterProtocol.swift
//  RouteKit
//
//  Created by kavi gevariya on 19/05/26.
//  Copyright © 2026 Kavi Gevariya (@kaVish2214).
//  Licensed under the Business Source License 1.1. See LICENSE.
//

import Foundation
import AuthSessionInterface
import UIKit

/// Supplies the view controllers the routing layer presents at each routing
/// decision point.
///
/// Implement `RouterProtocol` to plug the host app's screens into RouteKit's
/// launch + obscuration pipeline:
///
/// - **Splash** — ``preferredSplashViewController(for:)`` returns the screen
///   shown over the primary window while the auth session is loading or the
///   splash animation is in flight.
/// - **Initial content** — ``preferredInitialViewController(for:with:)``
///   returns the screen installed as the root of the navigation stack once the
///   splash dismisses. Implementations branch on the handle's
///   `authSessionHandle.sessionStatus` to choose between signed-in and
///   signed-out entry points, or resume the restored screen when one is
///   supplied.
/// - **Content obscuration** — ``preferredContentObscurationViewController(for:)``
///   returns the screen used to cover the app's content when the scene
///   becomes inactive, gated by ``shouldObscureContentWhenInactive(for:)``.
///
/// The routing layer treats each factory method as a fresh call: return new
/// instances unless the implementation explicitly wants shared state.
///
/// `@MainActor` because every method is invoked from UIKit work on the main
/// thread; `AnyObject` so the routing handle can retain a single conformer
/// for the scene's lifetime.
@MainActor
public protocol RouterProtocol: AnyObject {

    /// Whether the launch sequence should show a splash at all. Return `false`
    /// to skip straight to the initial view controller once the session is
    /// loaded. Defaults to `true`.
    func shouldShowSplashViewController(for routeHandling: any RouteHandleProtocol) -> Bool

    /// The splash view controller shown over the primary window while the
    /// auth session is loading or the configured splash animation is in
    /// flight.
    func preferredSplashViewController(for routeHandling: any RouteHandleProtocol) -> any RoutingSplashControlling

    /// Whether the routing layer should cover the primary window with the
    /// obscuration view controller while the scene is not foreground-active.
    ///
    /// The default implementation returns `true` only when the session is
    /// signed in **and** no manual reauthentication is pending — there's
    /// nothing worth hiding when the user is signed out, and the manual-
    /// reauth UI is already covering the content path on its own.
    ///
    /// - Parameter routeHandling: The handle whose primary window is being
    ///   considered for obscuration. The default implementation inspects its
    ///   ``RouteHandleProtocol/authSessionHandle`` to make the decision.
    func shouldObscureContentWhenInactive(for routeHandling: any RouteHandleProtocol) -> Bool

    /// The view controller used to obscure the app's content when the scene
    /// becomes inactive while signed in.
    ///
    /// The default implementation returns RouteKit's built-in system blur
    /// (`UIVisualEffectView` with `.systemUltraThinMaterialLight`). Override
    /// to supply a custom obscuration treatment (a brand graphic, a solid
    /// splash, a different blur style).
    ///
    /// - Parameter routeHandling: The handle whose overlay window will host
    ///   the returned view controller. Allows implementations to vary the
    ///   obscuration screen per scene if needed.
    func preferredContentObscurationViewController(for routeHandling: any RouteHandleProtocol) -> UIViewController

    /// Whether the routing layer should expand the initial view controller's
    /// declared preceding chain into the navigation stack at launch.
    ///
    /// When `true`, the routing handle walks
    /// ``RoutingViewControlling/preferredPrecedingViewController()`` starting
    /// from the initial view controller and seeds the stack with the full
    /// `[oldest, …, initial]` chain — so deep-linking targets can launch
    /// with the back stack their UX expects. When `false`, the stack starts
    /// as a single-controller navigation rooted on the initial view
    /// controller.
    var allowsPrecedingStackOnInitialRoute: Bool { get }

    /// The view controller installed on the navigation stack once the splash
    /// dismisses.
    ///
    /// Called once at the end of the launch sequence. Implementations branch on
    /// `routeHandling.authSessionHandle.sessionStatus` to return the signed-in or
    /// signed-out entry point. When state restoration recovered a screen for this
    /// scene, it's handed in as `restoring` — return it (or a controller seeded
    /// from it) to resume where the user left off instead of the default entry
    /// point.
    ///
    /// - Parameters:
    ///   - routeHandling: The handle whose scene is being launched; consult its
    ///     ``RouteHandleProtocol/authSessionHandle`` for the session status.
    ///   - restoring: The screen recovered by state restoration, or `nil` when
    ///     there was nothing to restore (see ``RouteStateRestoration/restoreState(for:)``).
    func preferredInitialViewController(for routeHandling: any RouteHandleProtocol, with restoring: (any StateRestoring)?) -> any RoutingViewControlling

    /// Decides what should happen to a pending ``SceneIntent`` given the current
    /// top view controller — run it now, deny it for later, or treat it as
    /// already handled. The routing layer calls this both at launch (replaying
    /// seeded intents) and while running (inbound deep links / activities /
    /// quick actions), and acts on the returned ``SceneIntentExecutionPermission``.
    ///
    /// - Parameters:
    ///   - sceneIntent: The intent awaiting a decision.
    ///   - viewController: The current top view controller, or `nil` before the
    ///     stack is installed. Branch on it to avoid re-pushing a screen that's
    ///     already visible.
    ///   - routeHandling: The handle whose scene the intent targets.
    func shouldExecute(pending sceneIntent: SceneIntent, current viewController: UIViewController?, for routeHandling: any RouteHandleProtocol) -> SceneIntentExecutionPermission

    /// The screen a `sceneIntent` should open. Called only after
    /// ``shouldExecute(pending:current:for:)`` decides to run the intent; the
    /// returned view controller is pushed honouring its own navigation action.
    func preferredViewController(_ sceneIntent: SceneIntent, for routeHandling: any RouteHandleProtocol) -> any RoutingViewControlling

    /// Hook the routing layer calls when an auth-session event lands on the
    /// handle and a route update may be warranted. Implementations decide
    /// whether the event should mutate the navigation stack, and how.
    ///
    /// The default implementation is a no-op, so a router only needs to
    /// override when it wants to react to specific events — for example,
    /// hard-cut the stack on ``AuthSessionDelegateEvent/logout(error:)``,
    /// push a recovery screen on ``AuthSessionDelegateEvent/failure(error:)``,
    /// or refresh visible state on
    /// ``AuthSessionDelegateEvent/userUpdate``.
    ///
    /// ## When this fires
    ///
    /// - Always for ``AuthSessionDelegateEvent/sessionFetch(isInitial:)``,
    ///   ``AuthSessionDelegateEvent/login``,
    ///   ``AuthSessionDelegateEvent/logout(error:)``,
    ///   ``AuthSessionDelegateEvent/failure(error:)``, and
    ///   ``AuthSessionDelegateEvent/userUpdate`` — regardless of whether
    ///   the launch sequence has completed.
    /// - For ``AuthSessionDelegateEvent/sessionStatusChanged(oldValue:newValue:)``
    ///   only *after* the launch sequence has installed the initial
    ///   navigation stack. During launch, the same event drives the splash-
    ///   dismissal gate and does not reach this hook.
    ///
    /// - Parameters:
    ///   - routeHandling: The handle whose navigation stack the
    ///     implementation may mutate (via
    ///     ``RouteHandleProtocol/push(to:animated:)`` /
    ///     ``RouteHandleProtocol/pop(animated:)``).
    ///   - sessionEvent: The translated auth-session callback.
    func updateRouteIfNeeded(for routeHandling: any RouteHandleProtocol, sessionEvent: AuthSessionDelegateEvent)

    /// Gate consulted before the handle pushes a routed screen: return `false`
    /// to veto the transition from `sourceViewController` to
    /// `destinationViewController` (e.g. suppress a duplicate push or block a
    /// screen the current state shouldn't allow).
    func canPushViewController(on routeHandling: any RouteHandleProtocol,from sourceViewController: UIViewController?, to destinationViewController: any RoutingViewControlling) -> Bool

    /// Called once, at the tail of the launch sequence, after the initial
    /// navigation stack is installed and ``RouteHandleProtocol/isRouteInitialized``
    /// has flipped to `true`. A hook for post-launch setup that needs a live
    /// route.
    func initialRouteDidInitialize(for routeHandling: any RouteHandleProtocol)

    /// Called when a pending intent could not be executed — e.g. the router
    /// denied it (``SceneIntentExecutionPermission/executionDenied``). Surfaces the
    /// per-intent `error` so the app can log or react; the intent itself stays
    /// queued for a later retry.
    func sceneIntentExecutionDidFailed(for routeHandling: any RouteHandleProtocol, error: any Error)
}

extension RouterProtocol {

    /// Default implementation: always show the splash.
    public func shouldShowSplashViewController(for routeHandling: any RouteHandleProtocol) -> Bool {
        true
    }

    /// Default implementation: obscure content when the session is signed in
    /// and no manual reauthentication is pending. Signed-out sessions and
    /// manual-reauth flows skip obscuration — the former has nothing to
    /// protect, the latter is already covering the content path on its own.
    public func shouldObscureContentWhenInactive(for routeHandling: any RouteHandleProtocol) -> Bool {
        if routeHandling.authSessionHandle.isManualAuthenticationRequired == true {
            return false
        }else if routeHandling.authSessionHandle.sessionStatus.isSignedIn {
            return true
        }
        return false
    }

    /// Default implementation: returns RouteKit's built-in system-blur view
    /// controller. Override to supply a custom obscuration screen.
    public func preferredContentObscurationViewController(for routeHandling: any RouteHandleProtocol) -> UIViewController {
        return ContentObscurationViewController()
    }
    
    /// Default implementation: no-op. Override to react to specific
    /// ``AuthSessionDelegateEvent`` cases that warrant a route change.
    public func updateRouteIfNeeded(for routeHandling: any RouteHandleProtocol, sessionEvent: AuthSessionDelegateEvent) {

    }
    
    /// Default implementation: allow every push. Override to veto specific
    /// transitions.
    public func canPushViewController(on routeHandling: any RouteHandleProtocol,from sourceViewController: UIViewController?, to destinationViewController: any RoutingViewControlling) -> Bool {
        true
    }

    /// Default implementation: no-op. Override for post-launch setup.
    public func initialRouteDidInitialize(for routeHandling: any RouteHandleProtocol) {}

    /// Default implementation: no-op. Override to observe denied-intent failures.
    public func sceneIntentExecutionDidFailed(for routeHandling: any RouteHandleProtocol, error: any Error) {}
}
