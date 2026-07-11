//
//  ViewControlling.swift
//  RouteKit
//
//  Created by kavi gevariya on 02/07/26.
//  Copyright © 2026 Kavi Gevariya (@kaVish2214).
//  Licensed under the Business Source License 1.1. See LICENSE.
//

import UIKit
import DependencyResolver



/// The base capability every routed view controller gets: a back-reference to
/// the ``RouteHandleProtocol`` that owns its scene, so feature code can push or
/// pop from inside a view controller without threading the handle through
/// initializers.
///
/// `UIViewController` conforms via the associated-object accessor in
/// `UIViewController+RouteHandle.swift`, so any view controller can reach its
/// handle; ``RoutingViewControlling`` refines this with the navigation
/// affordances a *routed* screen declares. Conforms to `DependencyResolver` so
/// the default `routeHandle` can be resolved from the shared container.
public protocol ViewControlling: UIViewController, DependencyResolver, StateRestorable {

    /// The routing handle that owns the receiver, used to push or pop other
    /// view controllers from inside it. The default implementation resolves
    /// the handle from the dependency container and returns `nil` if no
    /// handle has been registered.
    var routeHandle: (any RouteHandleProtocol)? { get }
}

extension ViewControlling {

    /// Default implementation: forwards to the owning
    /// ``routeHandle``'s ``StateRestorable/requestStoreState()``, so a screen
    /// can ask RouteKit to snapshot the scene without holding the handle
    /// directly. No-op when no handle is attached.
    public func requestStoreState() {
        routeHandle?.requestStoreState()
    }

    /// Default implementation: forwards to the owning
    /// ``routeHandle``'s ``StateRestorable/requestDiscardState()``. No-op when
    /// no handle is attached.
    public func requestDiscardState() {
        routeHandle?.requestDiscardState()
    }
}
