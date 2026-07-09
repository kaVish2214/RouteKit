//
//  SceneIntentControllerProtocol.swift
//  RouteKit
//
//  Created by kavi gevariya on 01/07/26.
//

import Foundation



/// Holds a scene's pending ``SceneIntent`` set and drives them toward
/// execution.
///
/// The concrete implementation (`SceneIntentController` in the `Route` module)
/// tracks two disjoint queues: intents that matched the scene's registered set
/// and are waiting to run, and a separate "unknown" set of inbound intents that
/// arrived without a matching registration. As intents are handled they leave
/// the queue via ``execute(_:)``; one that can't run yet is put back with
/// ``insert(_:)`` to be retried later (for example, once the user signs in).
public protocol SceneIntentControllerProtocol: AnyObject, Sendable {

    /// The registered, still-pending intents awaiting execution.
    var sceneIntents: Set<SceneIntent> { get }

    /// Inbound intents that arrived without a matching registration, kept
    /// separate from the executable ``sceneIntent`` queue.
    var unregisteredSceneIntents: Set<SceneIntent> { get }

    /// Designated initializer.
    ///
    /// - Parameters:
    ///   - proceedingIntents: The intents that arrived with the scene connection
    ///     and should be replayed once routing goes live.
    ///   - registeredSceneIntents: The configurator's registered intent set,
    ///     used to sort inbound intents into the pending queue versus the
    ///     ``unregisteredSceneIntents`` holding set.
    init(_ proceedingIntents: Set<SceneIntent>, registeredSceneIntents: Set<SceneIntent>)

    /// Whether `intent` matches the registered set — i.e. belongs in the
    /// executable queue rather than being held aside as unregistered.
    func canHandle(_ intent: SceneIntent) -> Bool

    /// Runs `intent` and removes it from the pending set once handled.
    @discardableResult
    func execute(_ intent: SceneIntent) -> Bool

    /// Re-queues `intent` into the pending set because it couldn't run yet.
    @discardableResult
    func insert(_ intent: SceneIntent) -> (inserted: Bool, insertedIntent: SceneIntent)
}


