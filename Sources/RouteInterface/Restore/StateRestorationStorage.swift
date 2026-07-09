//
//  StateRestorationStorage.swift
//  RouteKit
//
//  Created by kavi gevariya on 05/07/26.
//

import Foundation
import AuthSessionInterface


/// The persistence backend behind state restoration — a keyed store of
/// ``StateRestorableRecord`` values, one per scene session.
///
/// The restoration handle talks to this protocol, never to files directly, so
/// the *where* and *how* of persistence is swappable: the default
/// `StateRecordStorage` (in the `Route` module) writes property-list files under
/// Application Support, but a host can register its own conformer via
/// ``StateRestorationConfigurable/registerStateRecordableStorage()`` — an app
/// group, an encrypted store, or an in-memory double for tests.
///
/// ## Threading contract
///
/// The store owns its own I/O. Mutating operations (`persist`, `remove*`) are
/// **asynchronous** and report failures back on the **main actor** via their
/// `errorHandler`; read operations (`restoreRecord`, `hasRecord`) are
/// **synchronous** and must observe any still-pending write for the same key
/// (the default backend funnels everything through one serial queue, so a read
/// drains queued writes first — read-after-write stays consistent).
///
/// `Sendable` because the store is shared across the main actor and its own I/O
/// executor; `AnyObject` for stable identity across a session's lifetime.
public protocol StateRestorableStorage: Sendable, AnyObject {

    /// Whether ``initializeStorage()`` has run successfully. Reads before
    /// initialization report "no record" rather than trapping.
    var isStorageInitialized: Bool { get }

    /// Creates a store that emits a
    /// ``StateRestorationError/payloadTooLarge(identifier:bytes:limit:)`` warning
    /// once a record's encoded size exceeds `payloadWarningLimit` bytes. The
    /// record is still written — the limit is advisory, a nudge to keep
    /// snapshots lightweight.
    init(payloadWarningLimit: Int)

    /// Prepares the backing store (creates directories, opens handles).
    /// Idempotent; throws when the store can't be brought up.
    func initializeStorage() throws

    /// Writes `record` under `persistentIdentifier`, overwriting any existing
    /// record for that key. Asynchronous; failures (and the soft
    /// payload-size warning) arrive on `errorHandler` on the main actor.
    func persistRecord(_ record: some StateRestorableRecord, to persistentIdentifier: String, errorHandler: @escaping @MainActor (any Error) -> Void)

    /// Reads and decodes the record for `persistentIdentifier` as `Record`.
    /// Synchronous; throws ``StateRestorationError`` on missing/unreadable/
    /// undecodable data.
    func restoreRecord<Record>(_ typeOf: Record.Type, from persistentIdentifier: String) throws -> Record where Record: StateRestorableRecord

    /// Whether a record exists for `persistentIdentifier`. `false` when the
    /// store isn't initialized ("no record you could fetch" is still false).
    func hasRecord(for persistentIdentifier: String) -> Bool

    /// Removes the record for `persistentIdentifier`. Asynchronous; failures on
    /// `errorHandler`. A missing record is not an error.
    func removeRecord(for persistentIdentifier: String, errorHandler: @escaping @MainActor (any Error) -> Void)

    /// Removes records for several keys in one pass, reporting at most one
    /// batched failure on `errorHandler`.
    func removeRecords(for persistentIdentifiers: Set<String>, errorHandler: @escaping @MainActor (any Error) -> Void)

    /// Clears the entire store. Asynchronous; failures on `errorHandler`.
    func removeAllRecords(errorHandler: @escaping @MainActor (any Error) -> Void)
}
