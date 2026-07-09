//
//  StateRestorableRecord.swift
//  RouteKit
//
//  Created by kavi gevariya on 06/07/26.
//

import Foundation


/// The on-disk unit of state restoration: one persisted record standing in for
/// one restorable screen.
///
/// A record is the flattened, `Codable` pairing of *which* screen was saved
/// (``restoringTargetIdentifier``) and *its* encoded snapshot
/// (``stateData``). The ``StateRestorableStorage`` backend writes and reads
/// records keyed by scene-session identifier; the restoration handle later
/// resolves the identifier back to a type and decodes the data through
/// ``StateRestoring/restore(with:)``.
///
/// Conformers may carry extra bookkeeping alongside the two required members —
/// the default record, for instance, also stores the signed-in flag it was
/// captured under so restoration can be auth-gated (a signed-in screen is never
/// restored into a signed-out app, and vice versa).
///
/// `Sendable` so a record can be built on the main actor and written on the
/// storage backend's serial I/O queue.
public protocol StateRestorableRecord: Sendable, Codable {

    /// The saved screen's ``StateRestoring/restoringTargetIdentifier`` — used to
    /// recover the concrete type on relaunch.
    var restoringTargetIdentifier: String { get }

    /// The screen's ``StateRepresentable`` snapshot, already encoded to `Data`.
    var stateData: Data { get }

    /// Builds a record by snapshotting `restoring` now. Runs on the main actor
    /// (it reads live UIKit state) and throws when the snapshot can't be
    /// encoded.
    @MainActor
    init(restoring: any StateRestoring) throws
}
