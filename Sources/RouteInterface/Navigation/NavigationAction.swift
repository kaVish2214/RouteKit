//
//  NavigationAction.swift
//  RouteKit
//
//  Created by kavi gevariya on 16/05/26.
//  Copyright © 2026 Kavi Gevariya (@kaVish2214).
//  Licensed under the Business Source License 1.1. See LICENSE.
//

import Foundation

/// The default ``NavigationActionProtocol`` implementation supplied by
/// RouteKit.
///
/// Return a `NavigationAction` value from
/// ``RoutingViewControlling/preferredNavigationActionWhenPushed()`` to tell
/// the routing layer how to place the receiver on the navigation stack
/// when it is pushed.
public enum NavigationAction: Hashable, Sendable {

    /// Push the incoming view controller on top of the existing stack,
    /// leaving everything below it untouched.
    case push

    /// Drop the current top of the stack and push the incoming view
    /// controller in its place, producing a "replace" effect with a single
    /// transition.
    case replaceCurrent

    /// Clear the entire navigation stack and install the incoming view
    /// controller as the new root.
    case replaceAll

    /// Drop the current top of the stack, then push the incoming view
    /// controller **together with its declared preceding chain**. Useful
    /// when the incoming screen carries its own back-stack that should sit
    /// beneath it.
    ///
    /// Equivalent to ``replaceCurrent`` when the incoming view controller's
    /// ``RoutingViewControlling/preferredPrecedingViewController()`` returns
    /// `nil`.
    case replaceCurrentWithChain

    /// Clear the entire navigation stack and install the incoming view
    /// controller together with its declared preceding chain as the new
    /// stack.
    ///
    /// Equivalent to ``replaceAll`` when the incoming view controller's
    /// ``RoutingViewControlling/preferredPrecedingViewController()`` returns
    /// `nil`.
    case replaceAllWithChain
}

/// Maps the enum cases onto ``NavigationActionProtocol``'s boolean flags — each
/// accessor is simply "am I this case?". See the protocol for the routing
/// semantics of each flag.
extension NavigationAction: NavigationActionProtocol {

    /// `true` for ``push``.
    public var isPush: Bool {
        self == .push
    }

    /// `true` for ``replaceCurrent``.
    public var isReplaceCurrent: Bool {
        self == .replaceCurrent
    }

    /// `true` for ``replaceAll``.
    public var isReplaceAll: Bool {
        self == .replaceAll
    }

    /// `true` for ``replaceCurrentWithChain``.
    public var isReplaceCurrentWithChain: Bool {
        self == .replaceCurrentWithChain
    }

    /// `true` for ``replaceAllWithChain``.
    public var isReplaceAllWithChain: Bool {
        self == .replaceAllWithChain
    }
}
