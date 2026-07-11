//
//  SplashAnimationTiming.swift
//  RouteKit
//
//  Created by kavi gevariya on 15/05/26.
//  Copyright © 2026 Kavi Gevariya (@kaVish2214).
//  Licensed under the Business Source License 1.1. See LICENSE.
//

import Foundation

/// Controls how the routing layer coordinates the initial view controller transition
/// with the splash animation.
public enum SplashAnimationTiming: Sendable {

    /// The initial view controller is installed as soon as the auth session finishes
    /// loading, even if the splash animation is still in flight. The splash is
    /// dismissed once the session is ready.
    case `default`

    /// The initial view controller is not installed until the splash animation
    /// signals completion. Use this when the splash animation must be allowed to
    /// finish before the app's UI appears.
    case waitUntilAnimationComplete
}
