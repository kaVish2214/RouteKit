//
//  PresentationSource.swift
//  RouteKit
//
//  Created by kavi gevariya on 03/07/26.
//  Copyright © 2026 Kavi Gevariya (@kaVish2214).
//  Licensed under the Business Source License 1.1. See LICENSE.
//

import Foundation

/// The shipped ``PresentationSourceProtocol`` conformer: present a modal from
/// the top-most controller (`.currentController`, the default) or from the
/// navigation controller itself (`.rootController`, covering the whole stack).
public enum PresentationSource {

    /// Present from the top-most view controller.
    case currentController

    /// Present from the navigation controller (above the entire stack).
    case rootController
}

extension PresentationSource: PresentationSourceProtocol {

    /// `true` for ``rootController``.
    public var isRootViewController: Bool {
        if case .rootController = self {
            return true
        }
        return false
    }
    
    /// `true` for ``currentController``.
    public var isCurrentViewController: Bool {
        if case .currentController = self {
            return true
        }
        return false
    }
}
