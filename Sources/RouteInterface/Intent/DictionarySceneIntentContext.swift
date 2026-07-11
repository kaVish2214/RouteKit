//
//  DictionarySceneIntentContext.swift
//  RouteKit
//
//  Created by kavi gevariya on 30/06/26.
//  Copyright © 2026 Kavi Gevariya (@kaVish2214).
//  Licensed under the Business Source License 1.1. See LICENSE.
//

import Foundation



/// A ``SceneIntentContext`` that backs an `[AnyHashable: Any]` `userInfo`
/// dictionary — the natural payload of an `NSUserActivity` — with a binary
/// property-list `Data` blob as its serializable storage form.
///
/// Because the backing store is a property list, the source dictionary must be
/// property-list serializable (only plist-compatible value types, keyed by
/// property-list-legal keys); ``init(_:)`` is failable and returns `nil` when
/// the dictionary can't be encoded.
public struct DictionarySceneIntentContext: SceneIntentContext, Codable {

    /// The `userInfo`-style dictionary this context carries.
    public typealias Input = [AnyHashable: Any]

    /// The dictionary encoded as a binary property list.
    private let base: Data

    /// Creates a context from `input`, returning `nil` when the dictionary is
    /// not property-list serializable.
    public init?(_ input: Input) {
        guard let val = Self.encode(input) else { return nil }
        self.base = val
    }

    /// Encodes `input` as binary property-list `Data`, or `nil` when it isn't
    /// property-list serializable.
    public static func encode(_ input: Input) -> Data? {
        do {
            return try PropertyListSerialization.data(fromPropertyList: input, format: .binary, options: 0)
        }catch {
            return nil
        }
    }
    
    /// Rebuilds the original dictionary from the stored property-list `Data`,
    /// or `nil` when the blob can't be deserialized back into an `Input`.
    public func decode() -> [AnyHashable : Any]? {
        return try? PropertyListSerialization.propertyList(from: base, format: nil) as? Input
    }
}
