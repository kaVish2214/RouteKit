//
//  SceneRepresentable.swift
//  RouteKit
//
//  Created by kavi gevariya on 30/06/26.
//  Copyright © 2026 Kavi Gevariya (@kaVish2214).
//  Licensed under the Business Source License 1.1. See LICENSE.
//

import Foundation


/// A host-defined identity for one *kind* of scene the app can present.
///
/// The host app models its scene types as a `RawRepresentable` value (typically
/// a `String`-backed enum — `.main`, `.settings`, …) and conforms it to
/// `SceneRepresentable`. That value becomes the `SceneObject` associated type
/// threaded through ``SceneConfiguratorProtocol`` and ``SceneHandleProtocol``,
/// so the whole scene layer is type-safe over the app's own scene vocabulary.
///
/// ## Why `RawRepresentable`
///
/// The `rawValue` is what survives a trip through the system: it's stashed in an
/// `NSUserActivity`'s `userInfo` when RouteKit activates or restores a scene, and
/// decoded back into a `SceneRepresentable` on the receiving side. `RawValue: Hashable` lets
/// scenes live in a `Set` and act as dictionary keys during intent fan-out.
///
/// > Important: `rawValue` **must be a property-list type** — `String` or `Int`
/// > backed enums are recommended. Beyond activity `userInfo`, RouteKit also
/// > persists the resolved identity into `UISceneSession.userInfo`, which UIKit
/// > serializes to disk with the session (that's what lets a window keep its
/// > identity across relaunches and even force-quit). A non-plist raw value
/// > fails that persistence silently.
///
/// `Sendable` because scene identities cross the concurrency boundary when
/// encoded into activities; `Hashable` for set/dictionary membership.
public protocol SceneRepresentable: Hashable, Sendable, RawRepresentable where RawValue: Hashable {

    /// Rebuilds a scene from a `rawValue` recovered out of an activity's
    /// `userInfo`; `nil` for a value that maps to no case.
    init?(rawValue: RawValue)

    /// The stable identifier persisted into scene-identity activities.
    var rawValue: RawValue { get }
}
