import Testing
import Foundation
@testable import RouteInterface

extension RouteInterfaceModuleTests {

    @Suite("SceneIntent")
    struct SceneIntentTests {

        // MARK: - Equality / hashing

        @Test("shortcut intents are equal iff their type matches")
        func shortcutEquality() {
            #expect(SceneIntent.shortcutItem(type: "a") == .shortcutItem(type: "a"))
            #expect(SceneIntent.shortcutItem(type: "a") != .shortcutItem(type: "b"))
        }

        @Test("url intents compare by whole URL, not scheme/host")
        func urlEquality() {
            let a = SceneIntent.url(URL(string: "myapp://profile/1"))
            let b = SceneIntent.url(URL(string: "myapp://profile/1"))
            let c = SceneIntent.url(URL(string: "myapp://profile/2"))
            #expect(a == b)
            #expect(a != c)
        }

        // A statically-registered intent (no payload) must match an inbound
        // one that carries a runtime payload — identity is keyed on the
        // activityType alone, not the context.
        @Test("userActivity intents match on activityType regardless of context")
        func userActivityMatchesIgnoringContext() {
            let payload = DictionarySceneIntentContext(["k": "v"])
            #expect(payload != nil)
            let registered = SceneIntent.userActivity(activityType: "com.x", context: nil)
            let inbound = SceneIntent.userActivity(activityType: "com.x", context: payload)
            #expect(registered == inbound)
            #expect(Set([registered]).contains(inbound))
        }

        @Test("userActivity intents with different activityTypes stay distinct")
        func userActivityDistinctByType() {
            #expect(SceneIntent.userActivity(activityType: "a", context: nil)
                    != .userActivity(activityType: "b", context: nil))
        }

        // MARK: - Codable

        @Test("a set of intents round-trips through Codable")
        func codableRoundTrip() throws {
            let original: Set<SceneIntent> = [
                .url(URL(string: "myapp://home")),
                .userActivity(activityType: "com.x", context: DictionarySceneIntentContext(["k": "v"])),
                .shortcutItem(type: "quick")
            ]
            let data = try JSONEncoder().encode(original)
            let decoded = try JSONDecoder().decode(Set<SceneIntent>.self, from: data)
            #expect(decoded == original)
        }

        @Test("a url intent with no URL round-trips")
        func codableNilURL() throws {
            let original = SceneIntent.url(nil)
            let data = try JSONEncoder().encode(original)
            let decoded = try JSONDecoder().decode(SceneIntent.self, from: data)
            #expect(decoded == original)
        }
    }
}
