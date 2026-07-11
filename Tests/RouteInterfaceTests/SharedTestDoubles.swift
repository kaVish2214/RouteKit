import UIKit
import Foundation
@testable import RouteInterface

// `StubSessionStatus` is shared with the RouteInterface test suite — see
// `RouteInterfaceTests/RouteInterfaceTestHelpers.swift`.

/// A ``RoutingViewControlling`` whose preceding pointer is settable after init,
/// so tests can build cycles like A → B → A that would otherwise be impossible
/// to construct at initialization time.
final class CyclableRoutingViewController: UIViewController, RoutingViewControlling {

    var preceding: (any RoutingViewControlling)?

    func preferredPrecedingViewController() -> (any RoutingViewControlling)? {
        return preceding
    }
}

// MARK: - SceneRepresentable test doubles

/// A minimal ``SceneRepresentable`` for exercising scene-identity / configuration logic
/// without a real `UIWindowScene`. String-backed so its `rawValue` survives the
/// `NSUserActivity` `userInfo` and `SceneRepresentableContext` decode round-trips.
enum TestScene: String, SceneRepresentable {
    case home
    case settings
    case profile
}

/// A permissive ``SceneTerminationPolicy`` for the configurator stub.
struct StubTerminationPolicy: SceneTerminationPolicy {
    var isSystemTerminationAllowed: Bool = true
    var isAuthSessionTerminationAllowed: Bool = true
}

/// Minimal ``SceneConfiguratorProtocol`` conformer.
///
/// Returns fixed registration sets and a `.currentScene` behaviour so
/// `SceneManager`'s registration + validation surface can be unit-tested
/// without ever connecting a `UIWindowScene`. `routeHandle(for:…)` returns
/// `nil`, which keeps the inbound-intent defer a safe no-op (routing into a
/// nil handle) — so tests can exercise the accept path without UIKit.
@MainActor
final class StubSceneConfigurator: SceneConfiguratorProtocol {

    typealias SceneObject = TestScene

    var scenes: Set<TestScene> = [.home, .settings]
    var intents: Set<SceneIntent> = [.shortcutItem(type: "known"), .url(URL(string: "myapp://home"))]
    var windowBehavior: WindowBehavior = .windowPerScene

    func registerScenes() -> Set<TestScene> { scenes }

    func registerIntents() -> Set<SceneIntent> { intents }

    func registerWindowBehavior() -> WindowBehavior { windowBehavior }

    func routingBehavior(for intent: SceneIntent, within sceneHandle: any SceneHandleProtocol) -> SceneRoutingBehavior<TestScene> { .currentScene }

    func primaryScene(for sceneHandle: any SceneHandleProtocol) -> TestScene { .home }

    func routeHandle(for scene: TestScene, with configuration: any RouteHandleConfigurable, within sceneHandle: any SceneHandleProtocol) -> (any RouteHandleProtocol)? { nil }

    func sceneTerminationPolicy(for uiScene: UIScene, with terminationRequest: any SceneTerminationRequest, within sceneHandle: any SceneHandleProtocol) -> any SceneTerminationPolicy { StubTerminationPolicy() }

    func restorationStorageExecution(for restorable: (any StateRestoring)?, didFailedWith error: any Error) {}
}
