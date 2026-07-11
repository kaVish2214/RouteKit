//
//  RouteInterfaceTestHelpers.swift
//  RouteKit
//
//  Copyright © 2026 Kavi Gevariya (@kaVish2214).
//  Licensed under the Business Source License 1.1. See LICENSE.
//

import UIKit
import AuthSessionInterface
@testable import RouteInterface

// MARK: - Stub session status

/// Hand-rolled ``AuthSessionStatusProtocol`` for tests that need to exercise
/// branches keyed on session state without spinning up a real auth session.
struct StubSessionStatus: AuthSessionStatusProtocol {
    var isSyncing: Bool = false
    var isSignedIn: Bool = false
    var isSignedOut: Bool = false
    var isValidating: Bool = false
    var isBiometricAuthentication: Bool = false
}

extension StubSessionStatus {

    /// A fully-loaded, signed-in session.
    static let signedIn: StubSessionStatus = .init(isSignedIn: true)

    /// A fully-loaded, signed-out session.
    static let signedOut: StubSessionStatus = .init(isSignedOut: true)

    /// A session currently syncing (drives `isLoadingStatus == true`).
    static let syncing: StubSessionStatus = .init(isSyncing: true)
}

// MARK: - Stub view controllers

/// Minimum-viable ``RoutingViewControlling`` for tests that need a concrete
/// conforming view controller.
final class StubRoutingViewController: UIViewController, RoutingViewControlling { }

/// Convenience subclass that lets tests override the preceding chain so the
/// preceding-stack walker has something interesting to traverse.
final class ChainedRoutingViewController: UIViewController, RoutingViewControlling {

    private let preceding: (any RoutingViewControlling)?

    init(preceding: (any RoutingViewControlling)? = nil) {
        self.preceding = preceding
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) unavailable") }

    func preferredPrecedingViewController() -> (any RoutingViewControlling)? {
        return preceding
    }
}

/// Convenience subclass that lets tests override the action this view
/// controller declares when it is the *incoming* push target.
final class ActionRoutingViewController: UIViewController, RoutingViewControlling {

    private let action: any NavigationActionProtocol

    init(action: any NavigationActionProtocol) {
        self.action = action
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) unavailable") }

    func preferredNavigationActionWhenPushed() -> any NavigationActionProtocol {
        return action
    }
}

// MARK: - Stub splash

/// Minimum-viable ``RoutingSplashControlling``. Captures the most recent
/// `startAnimating` and `stopAnimating` invocations so tests can assert on
/// them.
final class StubSplashViewController: UIViewController, RoutingSplashControlling {

    private(set) var startAnimatingCallCount: Int = 0
    private(set) var stopAnimatingCallCount: Int = 0
    private(set) var capturedCompletion: (@MainActor @Sendable () -> Void)?

    func startAnimating(over window: UIWindow, completion: (@MainActor @Sendable () -> Void)?) {
        startAnimatingCallCount += 1
        capturedCompletion = completion
    }

    func stopAnimating() {
        stopAnimatingCallCount += 1
    }
}

// MARK: - Stub router

/// Minimum-viable ``RouterProtocol`` conformer.
///
/// Implements the two factory hooks that don't require a
/// ``RouteHandleProtocol`` parameter, plus the
/// ``RouterProtocol/allowsPrecedingStackOnInitialRoute`` flag. The two
/// route-handle-scoped hooks
/// (``RouterProtocol/shouldObscureContentWhenInactive(for:)`` and
/// ``RouterProtocol/preferredContentObscurationViewController(for:)``)
/// inherit the protocol's default implementations and are exercised in
/// host-app integration tests rather than at the unit-test level — see the
/// comment block in `RouterInterfaceTests.swift`.
///
/// `final class` because ``RouterProtocol`` is `AnyObject`-bound.
@MainActor
final class StubRouter: RouterProtocol {

    var allowsPrecedingStackOnInitialRoute: Bool = false

    func preferredSplashViewController(for routeHandling: any RouteHandleProtocol) -> any RoutingSplashControlling {
        return StubSplashViewController()
    }

    func preferredInitialViewController(for routeHandling: any RouteHandleProtocol, with restoring: (any StateRestoring)?) -> any RoutingViewControlling {
        return StubRoutingViewController()
    }

    func shouldExecute(pending sceneIntent: SceneIntent, current viewController: UIViewController?, for routeHandling: any RouteHandleProtocol) -> SceneIntentExecutionPermission {
        return .executeIntent(isAnimated: false)
    }

    func preferredViewController(_ sceneIntent: SceneIntent, for routeHandling: any RouteHandleProtocol) -> any RoutingViewControlling {
        return StubRoutingViewController()
    }

    func initialRouteDidInitialize(for routeHandling: any RouteHandleProtocol) { }
}

// MARK: - Custom navigation action

/// A custom ``NavigationActionProtocol`` conformer used to verify that
/// non-`NavigationAction` types are usable on the public API.
///
/// The trailing "keep preceding stack" flags default to `false` so existing
/// test call sites don't have to spell them out; tests that want to exercise
/// those branches can pass `true` explicitly.
struct CustomNavigationAction: NavigationActionProtocol {
    var isPush: Bool
    var isReplaceCurrent: Bool
    var isReplaceAll: Bool
    var isReplaceCurrentWithChain: Bool = false
    var isReplaceAllWithChain: Bool = false
}
