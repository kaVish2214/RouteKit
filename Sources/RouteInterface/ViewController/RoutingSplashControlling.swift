//
//  RoutingSplashControlling.swift
//  RouteKit
//
//  Created by kavi gevariya on 14/05/26.
//

import UIKit

/// A view controller that performs the app's splash animation while the auth
/// session loads.
///
/// The routing layer installs the splash on a dedicated overlay window above the
/// app's primary window. The receiver's ``preferredAnimationTiming()``
/// determines whether the routing layer waits for ``startAnimating(over:completion:)``
/// to fire its completion before installing the initial view controller, or
/// proceeds as soon as the auth session reports a non-loading status.
public protocol RoutingSplashControlling: UIViewController {

    /// The animation timing contract this splash uses. Defaults to
    /// ``SplashAnimationTiming/default``.
    func preferredAnimationTiming() -> SplashAnimationTiming

    /// Begin the splash animation inside the given overlay window.
    ///
    /// - Parameters:
    ///   - window: The overlay window the splash is hosted in. Implementations may
    ///     mutate the window (e.g. to add subviews to the root view), but must not
    ///     hide it — the routing layer owns the window's visibility.
    ///   - completion: Invoked on the main actor when the animation has fully
    ///     played out. Only consulted when ``preferredAnimationTiming()``
    ///     returns ``SplashAnimationTiming/waitUntilAnimationComplete``.
    func startAnimating(over window: UIWindow, completion: (@MainActor @Sendable () -> Void)?)

    /// Stop the splash animation. Called by the routing layer when the splash is
    /// being dismissed in the ``SplashAnimationTiming/default`` flow.
    func stopAnimating()
}

extension RoutingSplashControlling {

    /// Default implementation: returns ``SplashAnimationTiming/default``,
    /// letting the routing layer install the initial view controller as soon as
    /// the auth session is ready, without waiting for the splash animation to
    /// finish.
    public func preferredAnimationTiming() -> SplashAnimationTiming {
        return .default
    }
}
