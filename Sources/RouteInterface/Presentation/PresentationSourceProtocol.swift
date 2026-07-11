//
//  PresentationSourceProtocol.swift
//  RouteKit
//
//  Created by kavi gevariya on 03/07/26.
//  Copyright © 2026 Kavi Gevariya (@kaVish2214).
//  Licensed under the Business Source License 1.1. See LICENSE.
//

import Foundation


/// Where a modal presentation should originate on a scene's navigation stack —
/// passed to ``RouteHandleProtocol/present(_:with:animated:completion:)``.
///
/// Expressed as flags (like ``NavigationActionProtocol``) so host apps can
/// supply custom conformers; ``PresentationSource`` is the shipped enum.
public protocol PresentationSourceProtocol: Sendable {

    /// Present from the navigation controller itself (covers the whole stack).
    var isRootViewController: Bool { get }

    /// Present from the top-most view controller.
    var isCurrentViewController: Bool { get }
}

