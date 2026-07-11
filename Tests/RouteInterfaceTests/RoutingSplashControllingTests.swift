import Testing
import UIKit
@testable import RouteInterface

extension RouteInterfaceModuleTests {

    @Suite("RoutingSplashControlling defaults")
    @MainActor
    struct RoutingSplashControllingTests {

        @Test("default preferredAnimationTiming returns .default")
        func defaultTiming() {
            let sut = StubSplashViewController()
            if case .default = sut.preferredAnimationTiming() {
                // expected
            } else {
                Issue.record("default preferredAnimationTiming() did not return .default")
            }
        }

        @Test("startAnimating invokes its hook and retains the completion until release")
        func startAnimatingCapturesCompletion() {
            let sut = StubSplashViewController()
            let window = UIWindow()
            var fired = false

            sut.startAnimating(over: window) {
                fired = true
            }

            #expect(sut.startAnimatingCallCount == 1)
            #expect(sut.capturedCompletion != nil)

            sut.capturedCompletion?()
            #expect(fired)
        }

        @Test("startAnimating with nil completion is allowed")
        func startAnimatingNilCompletion() {
            let sut = StubSplashViewController()
            let window = UIWindow()
            sut.startAnimating(over: window, completion: nil)
            #expect(sut.startAnimatingCallCount == 1)
            #expect(sut.capturedCompletion == nil)
        }

        @Test("stopAnimating fires its hook")
        func stopAnimating() {
            let sut = StubSplashViewController()
            sut.stopAnimating()
            #expect(sut.stopAnimatingCallCount == 1)
        }
    }
}
