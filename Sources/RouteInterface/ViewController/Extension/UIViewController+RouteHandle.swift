//
//  UIViewController+RouteHandle.swift
//  RouteKit
//
//  Created by kavi gevariya on 02/07/26.
//  Copyright © 2026 Kavi Gevariya (@kaVish2214).
//  Licensed under the Business Source License 1.1. See LICENSE.
//

import UIKit

// MARK: - Design note
//
// `ViewControlling.routeHandle` must be available on *every* `UIViewController`
// (see the retroactive `UIViewController: ViewControlling` conformance at the
// bottom), but a protocol-extension property can't add stored storage to a class
// it doesn't own. The classic escape hatch is an **Objective-C associated
// object**: an out-of-line slot keyed by a static address that ARC attaches to
// the instance. This file is the whole of that mechanism.
//
// Two subtleties drive the shape of the code:
//
//  1. **The handle must be held *weakly*.** The ownership chain is
//     scene → route handle → navigation controller → view controllers. If a VC
//     held its handle strongly we'd close a retain cycle (handle ⇢ nav ⇢ VC ⇢
//     handle) and leak the entire scene. But `objc_setAssociatedObject` only
//     offers `RETAIN`/`COPY`/`ASSIGN` policies — there is no "weak" policy, and
//     `ASSIGN` (unsafe-unretained) would dangle after the handle deallocs. So we
//     `RETAIN` a small `WeakBox` that *itself* holds the handle weakly: the box
//     is owned by the VC, the handle is not. Reading a released handle yields
//     `nil`, never a dangling pointer.
//
//  2. **`withUnsafePointer(to:)` on the key.** `objc_get/setAssociatedObject`
//     want a stable `UnsafeRawPointer` key. Taking the address of the `static var`
//     gives every VC the same slot; `nonisolated(unsafe)` opts the mutable global
//     out of Swift 6 concurrency checking — its address, not its value, is all we
//     use, so there's no actual shared-mutable-state hazard.

extension UIViewController {

    /// Address-only holder for the associated-object key. Its *value* is never
    /// read or written — only `&`-taken to yield a stable, per-property pointer
    /// shared by all view controllers. `nonisolated(unsafe)` because only the
    /// address is used, so the mutable global is not a real data race.
    fileprivate struct AssociatedKeys {
        nonisolated(unsafe)
        static var __viewControllerAssociatedRoutHandleKey: UInt8 = 0
    }

    /// A `RETAIN`-able wrapper whose contents are weak — the trick that gives a
    /// view controller a *weak* reference to its route handle even though
    /// associated objects have no weak storage policy. The VC strongly owns the
    /// box; the box only weakly owns the handle, so no retain cycle forms and a
    /// deallocated handle reads back as `nil`.
    fileprivate final class WeakBox {

        /// The route handle, held weakly so it can outlive-independently of the
        /// view controller.
        weak let value: (any RouteHandleProtocol)?

        init(value: (any RouteHandleProtocol)?) {
            self.value = value
        }
    }
}

extension ViewControlling where Self: UIViewController {

    /// The route handle that owns this view controller's scene.
    ///
    /// Backed by a weak associated object (see the design note above), so it is
    /// `nil` until the handle stamps itself on (when the VC first enters a routed
    /// navigation stack) and becomes `nil` again if the handle deallocs.
    /// `private(set)` publicly — feature code reads it; only RouteKit sets it.
    private(set) public weak var routeHandle: (any RouteHandleProtocol)? {
        get {
            return withUnsafePointer(to: &AssociatedKeys.__viewControllerAssociatedRoutHandleKey) { t in
                objc_getAssociatedObject(self, t) as? WeakBox
            }?.value
        }set {
            // Store `nil` directly (clears the slot) rather than boxing a nil, so
            // a cleared handle doesn't leave an empty box hanging on the VC.
            withUnsafePointer(to: &AssociatedKeys.__viewControllerAssociatedRoutHandleKey) { t in
                objc_setAssociatedObject(self, t, newValue == nil ? nil : WeakBox(value: newValue), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
    }

    /// Stamps `routeHandle` onto the receiver **once**, the first time it enters
    /// a routed navigation stack.
    ///
    /// Called by RouteKit's routed navigation controller for every VC it hosts. The
    /// `guard self.routeHandle == nil` makes it idempotent and, crucially,
    /// *non-overriding*: a VC that already carries a handle (e.g. it belongs to a
    /// different scene and was moved) keeps its original owner rather than being
    /// re-parented. `package` so only RouteKit's own navigation controller can
    /// call it — host code sees `routeHandle` as read-only.
    package func __sanitized(with routeHandle: (any RouteHandleProtocol)?) {
        guard self.routeHandle == nil else {
            return
        }
        self.routeHandle = routeHandle
    }
}

/// Retroactively conforms *every* `UIViewController` to ``ViewControlling`` so
/// the ``ViewControlling/routeHandle`` accessor is universally available —
/// including on system controllers RouteKit didn't author.
extension UIViewController: ViewControlling { }
