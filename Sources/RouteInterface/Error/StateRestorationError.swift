//
//  StateRestorationError.swift
//  RouteKit
//
//  Created by kavi gevariya on 06/07/26.
//  Copyright © 2026 Kavi Gevariya (@kaVish2214).
//  Licensed under the Business Source License 1.1. See LICENSE.
//

import Foundation


/// Failures surfaced by the state-restoration pipeline, delivered to the host
/// through ``StateRestorationConfigurable/restorationStorageExecution(for:didFailedWith:)``.
///
/// Where a case carries a `reason`, it is a short, human-readable summary meant
/// for logging. The enum is `Sendable` so it can be delivered safely across
/// concurrency domains.
public enum StateRestorationError: Error, Sendable {

    /// An operation was attempted before ``StateRestorableStorage/initializeStorage()``
    /// succeeded.
    case storageNotInitialized

    /// The storage backend failed to come up during
    /// ``StateRestorableStorage/initializeStorage()``.
    case storageInitializationFailed

    /// A record's ``StateRestorableRecord/stateData`` could not be encoded for
    /// writing.
    case encodingFailed(reason: String)

    /// The encoded record could not be written to the backing store.
    case writeFailed(reason: String)

    /// The stored record could not be read back from the backing store.
    case readFailed(reason: String)

    /// A record was read but could not be decoded (the stored shape no longer
    /// matches the type — e.g. after an incompatible ``StateRepresentable``
    /// change).
    case decodingFailed(reason: String)

    /// A record could not be removed from the backing store. For batch removals,
    /// `reason` joins the per-key failures.
    case removalFailed(reason: String)

    /// **Advisory warning, not a hard failure.** A record's encoded size crossed
    /// the store's configured size limit; the record is *still written*. Treat it
    /// as a signal that the snapshot should be slimmed down (see the design note
    /// on ``StateRepresentable``).
    case payloadTooLarge(identifier: String, bytes: Int, limit: Int)

    /// A record's ``StateRestorableRecord/restoringTargetIdentifier`` could not
    /// be resolved back to a live type — typically because the ``StateRestoring``
    /// class was renamed or moved since the record was saved.
    case targetNotFound(identifier: String)
}

extension StateRestorationError : LocalizedError {
    
    public var errorDescription: String? {
        switch self {
        case .storageNotInitialized:
            return "Storage not initialized"
        case .storageInitializationFailed:
            return "Failed to initialize storage."
        case .encodingFailed(let reason):
            return "Failed to encode state (underlying: \(reason))"
        case .writeFailed(let reason):
            return "Failed to write state (underlying: \(reason))"
        case .readFailed(let reason):
            return "Failed to read state (underlying: \(reason))"
        case .decodingFailed(let reason):
            return "Failed to decode state (underlying: \(reason))"
        case .removalFailed(let reason):
            return "Failed to remove state (underlying: \(reason))"
        case .payloadTooLarge(let identifier, let bytes, let limit):
            return "Payload too large for \(identifier). Current size: \(bytes), limit: \(limit)"
        case .targetNotFound(let identifier):
            return "Target not found: \(identifier)"
        }
    }
}
