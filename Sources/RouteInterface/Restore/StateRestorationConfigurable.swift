//
//  StateRestorationConfigurable.swift
//  RouteKit
//
//  Created by kavi gevariya on 06/07/26.
//  Copyright © 2026 Kavi Gevariya (@kaVish2214).
//  Licensed under the Business Source License 1.1. See LICENSE.
//

import Foundation


/// The host app's opt-in surface for state restoration: choose a storage
/// backend and observe restoration failures.
///
/// This is folded into ``SceneConfiguratorProtocol`` (which refines it), so an
/// app configures restoration in the same place it configures scenes.
/// ``registerStateRecordableStorage()`` has a default (RouteKit's built-in
/// file-backed store), so supply one only to change *where* records live.
/// ``restorationStorageExecution(for:didFailedWith:)`` has **no** default —
/// implement it to observe (log or surface) restoration failures.
@MainActor
public protocol StateRestorationConfigurable: AnyObject {

    /// The storage backend records are persisted to. Return `nil` (the default)
    /// to use RouteKit's built-in file-backed store (`StateRecordStorage`);
    /// return a custom ``StateRestorableStorage`` to persist elsewhere (an app
    /// group, an encrypted container, a test double).
    func registerStateRecordableStorage() -> (any StateRestorableStorage)?

    /// Called whenever a store / restore / discard operation fails. `restorable`
    /// is the screen involved when one is known (`nil` for storage-init or
    /// bulk-cleanup failures). Note that a
    /// ``StateRestorationError/payloadTooLarge(identifier:bytes:limit:)`` arrives
    /// here as a *warning* — the record is still written.
    func restorationStorageExecution(for restorable: (any StateRestoring)?, didFailedWith error: any Error)
}

extension StateRestorationConfigurable {

    /// Default: no custom storage — the handle falls back to RouteKit's
    /// file-backed `StateRecordStorage`.
    public func registerStateRecordableStorage() -> (any StateRestorableStorage)? {
        return nil
    }
}
