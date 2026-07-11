//
//  SceneIntentExecutionPermission.swift
//  RouteKit
//
//  Created by kavi gevariya on 01/07/26.
//  Copyright © 2026 Kavi Gevariya (@kaVish2214).
//  Licensed under the Business Source License 1.1. See LICENSE.
//

import Foundation




/// The router's verdict on a pending ``SceneIntent``, returned from
/// ``RouterProtocol/shouldExecute(pending:current:for:)`` and acted on by the
/// route handle.
public enum SceneIntentExecutionPermission: Hashable, Sendable {

    /// Execute the intent now — push its screen, animating the transition when
    /// `isAnimated` is `true`. The intent is then cleared from the queue.
    case executeIntent(isAnimated: Bool)

    /// The intent may not run in the current state (e.g. signed out). It is
    /// kept queued and retried later; the handle reports the denial through the
    /// intent's completion channel.
    case executionDenied

    /// The intent is already satisfied (the target screen is current). Nothing
    /// is pushed; the intent is simply cleared from the queue.
    case intentExecuted
}
