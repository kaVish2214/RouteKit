//
//  UIApplicationStateProtocol.swift
//  RouteKit
//
//  Created by kavi gevariya on 06/07/26.
//

import Foundation


/// The app-wide "are we still launching?" flag, owned by the
/// ``SceneHandleProtocol`` and read/flipped by route handles.
///
/// It exists so a route handle can tell whether *its* scene is part of the
/// app's cold launch (the very first scene to connect) or a later connection —
/// a distinction that matters for one-time launch work and for splash timing.
/// The first scene's route handle calls ``applicationLaunched()`` once its
/// navigation stack is live, flipping the app out of its launch phase for every
/// scene that connects afterward.
///
/// `@MainActor` because it's read and mutated on the UIKit scene-lifecycle path.
@MainActor
public protocol UIApplicationStateProtocol: AnyObject {
    
    /// `true` until the first scene finishes its launch sequence; flipped once
    /// via ``applicationLaunched()``. Lets the handle distinguish the app's cold
    /// launch from subsequent scene connections.
    var isApplicationBeingLaunched: Bool { get }
    
    
    /// Marks the app's launch sequence complete (flips ``isApplicationBeingLaunched``
    /// to `false`). Idempotent — called by the first scene's route handle once
    /// its navigation stack is live.
    @_spi(SceneHandleInjection)
    func applicationLaunched()
}

