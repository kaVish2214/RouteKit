import Testing
import Foundation
@testable import RouteInterface

extension RouteInterfaceModuleTests {

    @Suite("SceneRoutingError")
    struct SceneRoutingErrorTests {

        @Test("multipleScenesNotSupported has a stable description")
        func multipleScenes() {
            #expect(SceneRoutingError.multipleScenesNotSupported.errorDescription == "Multiple scenes are not supported.")
        }

        @Test("unregisteredIntent embeds the offending intent")
        func unregistered() {
            let error = SceneRoutingError.unregisteredIntent(.shortcutItem(type: "com.x"))
            #expect(error.errorDescription?.contains("is not registered") == true)
        }

        @Test("sceneIntentExecutionDenied surfaces the intent")
        func denied() {
            let intent = SceneIntent.shortcutItem(type: "quick")
            let error = SceneRoutingError.sceneIntentExecutionDenied(intent)
            #expect(error.errorDescription?.contains("not allowed to be executed") == true)
        }

        @Test("sceneNotRegistered surfaces the offending scene")
        func notRegistered() {
            let error = SceneRoutingError.sceneNotRegistered(TestScene.settings)
            #expect(error.errorDescription?.contains("is not registered") == true)
        }

        @Test("sceneAlreadyActive reports the scene as already active")
        func alreadyActive() {
            let error = SceneRoutingError.sceneAlreadyActive(TestScene.home)
            #expect(error.errorDescription?.contains("is already active") == true)
        }
    }
}
