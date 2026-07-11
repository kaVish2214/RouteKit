//
//  ContentObscurationViewController.swift
//  RouteKit
//
//  Created by kavi gevariya on 15/05/26.
//  Copyright © 2026 Kavi Gevariya (@kaVish2214).
//  Licensed under the Business Source License 1.1. See LICENSE.
//

import UIKit

/// RouteKit's built-in content-obscuration view controller — a system
/// ultra-thin-material blur layered over a clear background.
///
/// Returned by ``RouterProtocol``'s default
/// ``RouterProtocol/preferredContentObscurationViewController(for:)``. Routers
/// that want a custom obscuration treatment (a solid splash image, a brand
/// graphic, a custom blur style) override the factory and return their own
/// `UIViewController` subclass — this class is intentionally kept internal
/// so the public API surface stays just the protocol-level hook.
final class ContentObscurationViewController: UIViewController {

    /// Installs a `UIVisualEffectView` (system ultra-thin material) as the
    /// root view. Overrides `loadView()` instead of populating `viewDidLoad`
    /// so the effect view *is* the root, avoiding the extra container that a
    /// default `UIView`-rooted `viewDidLoad` setup would impose.
    override func loadView() {
        view = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialLight))
        view.backgroundColor = .clear
    }
}
