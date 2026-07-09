//
//  RoutingViewControlling.swift
//  RouteKit
//
//  Created by kavi gevariya on 12/05/26.
//

import UIKit
import DependencyResolver
import AuthSessionInterface

/// A view controller managed by the routing layer.
///
/// Conforming view controllers participate in two routing decisions:
/// 1. How they want to be placed on the navigation stack when *they* are
///    pushed (``preferredNavigationActionWhenPushed()``).
/// 2. What the synthetic preceding chain should look like when they are
///    installed as the router's main-content screen
///    (``preferredPrecedingViewController()``).
public protocol RoutingViewControlling: ViewControlling {

    /// The navigation behaviour the routing layer should apply when the
    /// receiver is pushed onto the navigation stack. Defaults to
    /// ``NavigationAction/push`` — i.e. land on top of the existing stack
    /// without disturbing it.
    func preferredNavigationActionWhenPushed() -> any NavigationActionProtocol

    /// The view controller that should sit beneath the receiver in the navigation
    /// stack, allowing screens to declaratively rebuild the preceding chain when
    /// they are installed as the root of a fresh navigation flow. Return `nil`
    /// (the default) to terminate the chain.
    func preferredPrecedingViewController() -> (any RoutingViewControlling)?
}

extension RoutingViewControlling {

    /// Default implementation: returns ``NavigationAction/push``, meaning the
    /// incoming view controller is pushed without mutating the existing stack.
    public func preferredNavigationActionWhenPushed() -> any NavigationActionProtocol {
        NavigationAction.push
    }

    /// Default implementation: returns `nil`, terminating the synthetic
    /// preceding chain at the receiver.
    public func preferredPrecedingViewController() -> (any RoutingViewControlling)? {
        return nil
    }
}
