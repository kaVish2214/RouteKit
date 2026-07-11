//
//  StateRepresentable.swift
//  RouteKit
//
//  Created by kavi gevariya on 05/07/26.
//  Copyright © 2026 Kavi Gevariya (@kaVish2214).
//  Licensed under the Business Source License 1.1. See LICENSE.
//

import Foundation


/// The serializable snapshot a ``StateRestoring`` screen hands to RouteKit to
/// describe "what I need in order to come back".
///
/// A `StateRepresentable` is a plain `Codable` value — an identifier, a small
/// bag of fields, enough to reconstruct the screen and no more. It is *not* a
/// place to stash view hierarchies, images, model graphs, or anything the
/// screen can re-fetch on its own.
///
/// > Design note: **Keep it lightweight.** RouteKit persists one of these per
/// > scene session, on the main-actor path, and the default storage warns (via
/// > ``StateRestorationError/payloadTooLarge(identifier:bytes:limit:)``) once a
/// > snapshot crosses ~100 KB. Treat the warning as a design smell: a restoration
/// > state should be the *coordinates* to rebuild a screen, not the screen's
/// > contents. Store an item ID and let the screen reload the item; don't store
/// > the item.
///
/// `Sendable` because a snapshot crosses the concurrency boundary between the
/// main-actor capture point and the storage backend's serial I/O queue.
public protocol StateRepresentable: Codable, Sendable {

    /// Serializes the snapshot to `Data`. The default folds it through a
    /// `JSONEncoder`; override only when a value needs a bespoke wire format.
    func encoded() throws -> Data
}

extension StateRepresentable {

    /// Default implementation: JSON-encodes the value. Paired with the
    /// `JSONDecoder` the default restoration handle uses when rebuilding a
    /// screen from its stored ``StateRestoring/State``.
    public func encoded() throws -> Data {
        try JSONEncoder().encode(self)
    }
}
