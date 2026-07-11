//
//  NavigationActionProtocol.swift
//  RouteKit
//
//  Created by kavi gevariya on 16/05/26.
//  Copyright © 2026 Kavi Gevariya (@kaVish2214).
//  Licensed under the Business Source License 1.1. See LICENSE.
//

import Foundation

/// Describes how a view controller wants to be placed on the navigation
/// stack when it is pushed.
///
/// Conforming types let an incoming view controller declare whether it
/// should land on top of the existing stack, take the current top's place,
/// or replace the entire stack — with or without its declared preceding
/// chain. ``NavigationAction`` is the default-supplied conforming type.
public protocol NavigationActionProtocol: Sendable {

    /// `true` when the incoming view controller should be pushed on top of
    /// the existing stack without removing anything.
    var isPush: Bool { get }

    /// `true` when the currently-visible view controller should be removed
    /// from the stack as the incoming view controller is pushed in its
    /// place.
    var isReplaceCurrent: Bool { get }

    /// `true` when the entire navigation stack should be cleared and the
    /// incoming view controller installed as the new root.
    var isReplaceAll: Bool { get }

    /// `true` when the currently-visible view controller should be removed
    /// *and* the incoming view controller pushed together with its declared
    /// preceding chain (so the incoming screen brings its own back-stack
    /// underneath itself).
    var isReplaceCurrentWithChain: Bool { get }

    /// `true` when the entire navigation stack should be cleared and the
    /// incoming view controller installed together with its declared
    /// preceding chain.
    var isReplaceAllWithChain: Bool { get }
}
