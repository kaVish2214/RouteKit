//
//  SceneTerminationPolicy.swift
//  RouteKit
//
//  Created by kavi gevariya on 30/06/26.
//

import Foundation


/// Whether a scene may be torn down, answered per termination trigger.
///
/// Returned by ``SceneConfiguratorProtocol/sceneTerminationPolicy(for:with:within:)``
/// for a given ``SceneTerminationRequest``. The handle reads
/// ``isSystemTerminationAllowed`` to drive the scene's
/// `UIWindowScene.windowingBehaviors.isClosable` (iOS 16+), so a policy of
/// `false` keeps the OS "close window" affordance disabled.
public protocol SceneTerminationPolicy: Sendable {

    /// Whether the user / system may close this scene's window (maps to
    /// `windowingBehaviors.isClosable`).
    var isSystemTerminationAllowed: Bool { get }

    /// Whether an auth-session event (e.g. sign-out) is allowed to tear this
    /// scene down.
    var isAuthSessionTerminationAllowed: Bool { get }
}


