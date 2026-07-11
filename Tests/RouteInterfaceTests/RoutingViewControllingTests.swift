//
//  RoutingViewControllingTests.swift
//  RouteKit
//
//  Copyright © 2026 Kavi Gevariya (@kaVish2214).
//  Licensed under the Business Source License 1.1. See LICENSE.
//

import Testing
import UIKit
import Factory
@testable import RouteInterface

extension RouteInterfaceModuleTests {

    @Suite("RoutingViewControlling defaults")
    @MainActor
    struct RoutingViewControllingTests {

        init() {
            Container.shared.manager.reset()
        }

        // MARK: - preferredNavigationActionWhenPushed default

        @Test("default preferredNavigationActionWhenPushed returns NavigationAction.push")
        func defaultActionIsPush() {
            let sut = StubRoutingViewController()
            let action = sut.preferredNavigationActionWhenPushed()
            #expect(action.isPush)
            #expect(!action.isReplaceCurrent)
            #expect(!action.isReplaceAll)
        }

        @Test("subclasses can override preferredNavigationActionWhenPushed to return a custom action")
        func overrideAction() {
            let sut = ActionRoutingViewController(action: NavigationAction.replaceAll)
            let action = sut.preferredNavigationActionWhenPushed()
            #expect(action.isReplaceAll)
        }

        @Test("subclasses can return a custom NavigationActionProtocol conformer")
        func overrideCustomConformer() {
            let custom = CustomNavigationAction(isPush: false, isReplaceCurrent: true, isReplaceAll: false)
            let sut = ActionRoutingViewController(action: custom)
            #expect(sut.preferredNavigationActionWhenPushed().isReplaceCurrent)
        }

        // MARK: - preferredPrecedingViewController default

        @Test("default preferredPrecedingViewController returns nil")
        func defaultPrecedingIsNil() {
            let sut = StubRoutingViewController()
            #expect(sut.preferredPrecedingViewController() == nil)
        }

        @Test("subclasses can return a non-nil preceding view controller")
        func overridePreceding() {
            let preceding = StubRoutingViewController()
            let sut = ChainedRoutingViewController(preceding: preceding)
            #expect(sut.preferredPrecedingViewController() === preceding)
        }

        @Test("subclasses can chain multiple preceding view controllers")
        func chainOfPreceding() {
            let root = StubRoutingViewController()
            let middle = ChainedRoutingViewController(preceding: root)
            let leaf = ChainedRoutingViewController(preceding: middle)

            #expect(leaf.preferredPrecedingViewController() === middle)
            #expect(middle.preferredPrecedingViewController() === root)
            #expect(root.preferredPrecedingViewController() == nil)
        }

        // MARK: - routeHandle default

        @Test("default routeHandle returns nil when no RouteHandleProtocol is registered with the container")
        func routeHandleNilWhenUnregistered() {
            let sut = StubRoutingViewController()
            #expect(sut.routeHandle == nil)
        }
    }
}
