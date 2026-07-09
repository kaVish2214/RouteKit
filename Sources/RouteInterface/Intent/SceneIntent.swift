//
//  SceneIntent.swift
//  RouteKit
//
//  Created by kavi gevariya on 30/06/26.
//

import Foundation
import UIKit


/// A declarative description of an inbound launch / routing intent a scene is
/// allowed to handle: a deep-link `URL`, an `NSUserActivity` (by
/// `activityType`), or a Home Screen quick action (by `type`).
///
/// A configurator registers the set of intents its scenes recognise (see
/// ``SceneConfiguratorProtocol/registerIntents()``); the scene handle
/// rejects any inbound value that doesn't match one of them.
///
/// Matching is by **identity** (see the `==` / `hash(into:)` implementations):
/// a `.url` compares by its full URL string, a `.userActivity` by its
/// `activityType` alone (the ``DictionarySceneIntentContext`` payload is *not*
/// part of identity), and a `.shortcutItem` by its `type`. That payload
/// independence is what lets a statically-registered intent match an inbound
/// one carrying a runtime `context`.
public enum SceneIntent: Hashable, Sendable, Codable {

    /// Matches a deep-link `URL` by its full string form.
    case url(URL?)

    /// Matches an `NSUserActivity` by its `activityType`.
    case userActivity(activityType: String, context: DictionarySceneIntentContext?)

    /// Matches a `UIApplicationShortcutItem` (Home Screen quick action) by its
    /// `type`.
    case shortcutItem(type:String)
}

extension SceneIntent: CustomStringConvertible {

    /// A human-readable, log-friendly description naming the case and its key
    /// (URL string / activityType / shortcut type). The `.userActivity` context
    /// payload is omitted — mirroring how it's excluded from identity.
    public var description: String {
        switch self {
        case .url(let url):
            return "SceneIntent : url(\(url?.absoluteString ?? "nil"))"
        case .userActivity(let activityType, _):
            return "SceneIntent : userActivity(\(activityType))"
        case .shortcutItem(let type):
            return "SceneIntent : shortcutItem(\(type))"
        }
    }
}

extension SceneIntent {

    /// The stable identity of an intent, used for equality and hashing.
    ///
    /// Two intents are the *same* intent when their identities match. Identity
    /// deliberately excludes the user-activity `context` payload and compares
    /// URLs by their string form — so an intent registered statically (with no
    /// payload) still matches an inbound one that arrives carrying a runtime
    /// payload. The case is prefixed so identities can't collide across cases
    /// (e.g. a shortcut typed `"url:x"` never equals a URL).
    private var identity: String {
        switch self {
        case .url(let url):
            return "url:\(url?.absoluteString ?? "")"
        case .userActivity(let activityType, _):
            return "userActivity:\(activityType)"
        case .shortcutItem(let type):
            return "shortcutItem:\(type)"
        }
    }

    /// Two intents are equal iff their ``identity`` strings match.
    ///
    /// This is *not* a structural comparison: a `.url` compares by full URL
    /// string, a `.userActivity` by its `activityType` **alone** (the
    /// `context` payload is deliberately excluded from identity), and a
    /// `.shortcutItem` by its `type`. Excluding the payload is what lets a
    /// statically-registered intent — which carries no payload — compare equal
    /// to an inbound one that arrives with a runtime `context`, so membership
    /// tests against the registered `Set` succeed.
    public static func == (lhs: SceneIntent, rhs: SceneIntent) -> Bool {
        return lhs.identity == rhs.identity
    }

    /// Hashes on ``identity`` alone, keeping `Hashable` consistent with the
    /// payload-independent equality above: registered and inbound variants of
    /// the same intent land in the same `Set` bucket regardless of any
    /// `.userActivity` context payload.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(identity)
    }
}
