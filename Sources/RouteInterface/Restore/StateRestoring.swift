//
//  StateRestoring.swift
//  RouteKit
//
//  Created by kavi gevariya on 05/07/26.
//

import Foundation


/// A screen that can save a lightweight snapshot of itself and be rebuilt from
/// it after the app (or a single scene) is relaunched.
///
/// Conform a routed view controller to `StateRestoring` to opt it into state
/// restoration. The contract is a round-trip:
///
/// 1. When RouteKit decides to persist the scene (see
///    ``RouteStateRestoration/storeState(for:)``), it reads the *top* view
///    controller. If that controller is a `StateRestoring`, it calls
///    ``restoringState()`` to capture a ``State`` snapshot and stores it keyed
///    by the scene session, tagged with the controller's
///    ``restoringTargetIdentifier``.
/// 2. On relaunch, RouteKit looks the record up, resolves the type back from
///    the identifier, decodes the ``State``, and calls
///    ``restore(with:)`` to build the replacement controller.
///
/// ## Type recovery is by class name
///
/// The default ``restoringTargetIdentifier`` is `NSStringFromClass(Self.self)`,
/// and the default restoration handle resolves it back with `NSClassFromString`.
/// That means the conforming type must be an Obj-C-visible class name that is
/// stable across launches — **renaming or moving the class between modules
/// breaks any record already on disk** (restoration simply fails with
/// ``StateRestorationError/targetNotFound(identifier:)`` and the screen falls
/// back to its normal launch path). Override `restoringTargetIdentifier` with a
/// hand-picked stable string if you need rename-safety.
///
/// ## Keep the snapshot small
///
/// ``State`` is a ``StateRepresentable`` — persist only what you need to
/// *rebuild* the screen (an item ID, a tab index), not the screen's content.
/// See the design note on ``StateRepresentable``.
///
/// `@MainActor` because both capture and rebuild happen on the UIKit path;
/// `AnyObject` because the conformers are view controllers.
@MainActor
public protocol StateRestoring: AnyObject {

    /// The lightweight, `Codable` snapshot type this screen saves and restores
    /// from.
    associatedtype State: StateRepresentable

    /// The stable identity persisted with the record and used to recover the
    /// concrete type on relaunch. Defaults to the Obj-C class name; override
    /// with a fixed string when the class may be renamed or relocated.
    static var restoringTargetIdentifier: String { get }

    /// Captures the current screen as a ``State`` snapshot. Called on the main
    /// actor at persistence time; return the minimum needed to reconstruct.
    func restoringState() -> State

    /// Rebuilds a screen from a previously captured ``State``. Called on the
    /// main actor during restoration; the returned instance takes the place of
    /// the screen that was saved.
    static func restore(with state: State) -> any StateRestoring
}

extension StateRestoring {

    /// Default identity: the Obj-C class name. Stable within a build but *not*
    /// across a rename or a module move — override when that matters.
    public static var restoringTargetIdentifier: String {
        NSStringFromClass(Self.self)
    }
}


