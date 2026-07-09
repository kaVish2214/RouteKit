//
//  SceneIntentContext.swift
//  RouteKit
//
//  Created by kavi gevariya on 30/06/26.
//

import Foundation


/// A `Codable`-friendly, `Hashable` payload carried alongside a
/// ``SceneIntent/userActivity(activityType:context:)`` intent.
///
/// The context wraps a live, often non-`Codable` `Input` (such as an
/// `NSUserActivity` `userInfo` dictionary) in a serializable `Output` storage
/// form so the intent can be persisted and hashed. Note that context is
/// deliberately excluded from ``SceneIntent`` identity — it rides *with* an
/// intent as its payload but does not participate in matching against the
/// registered set.
///
/// Conformers round-trip an `Input` through their `Output` storage:
/// ``encode(_:)`` folds an `Input` into `Output`, ``init(_:)`` builds a context
/// from an `Input` (storing the encoded form), and ``decode()`` recovers the
/// original `Input`.
public protocol SceneIntentContext: Hashable, Sendable, Equatable {

    /// The live value the context is built from and recovers to — typically not
    /// itself `Codable`.
    associatedtype Input

    /// The serializable storage form the `Input` is folded into.
    associatedtype Output

    /// Creates a context from `input`, failing when the input cannot be encoded
    /// into the `Output` storage form.
    init?(_ input: Input)

    /// Folds `input` into its serializable `Output` form, or `nil` when it
    /// isn't representable.
    static func encode(_ input: Input) -> Output?

    /// Recovers the original `Input` from the stored `Output`, or `nil` when
    /// decoding fails.
    func decode() -> Input?
}
