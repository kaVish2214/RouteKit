import Testing
@testable import RouteInterface

extension RouteInterfaceModuleTests {

    @Suite("NavigationAction")
    struct NavigationActionTests {

        // MARK: - .push

        @Test(".push reports isPush == true")
        func pushIsPush() {
            #expect(NavigationAction.push.isPush == true)
        }

        @Test(".push reports isReplaceCurrent == false")
        func pushNotReplaceCurrent() {
            #expect(NavigationAction.push.isReplaceCurrent == false)
        }

        @Test(".push reports isReplaceAll == false")
        func pushNotReplaceAll() {
            #expect(NavigationAction.push.isReplaceAll == false)
        }

        // MARK: - .replaceCurrent

        @Test(".replaceCurrent reports isReplaceCurrent == true")
        func replaceCurrentIsReplaceCurrent() {
            #expect(NavigationAction.replaceCurrent.isReplaceCurrent == true)
        }

        @Test(".replaceCurrent reports isPush == false")
        func replaceCurrentNotPush() {
            #expect(NavigationAction.replaceCurrent.isPush == false)
        }

        @Test(".replaceCurrent reports isReplaceAll == false")
        func replaceCurrentNotReplaceAll() {
            #expect(NavigationAction.replaceCurrent.isReplaceAll == false)
        }

        // MARK: - .replaceAll

        @Test(".replaceAll reports isReplaceAll == true")
        func replaceAllIsReplaceAll() {
            #expect(NavigationAction.replaceAll.isReplaceAll == true)
        }

        @Test(".replaceAll reports isPush == false")
        func replaceAllNotPush() {
            #expect(NavigationAction.replaceAll.isPush == false)
        }

        @Test(".replaceAll reports isReplaceCurrent == false")
        func replaceAllNotReplaceCurrent() {
            #expect(NavigationAction.replaceAll.isReplaceCurrent == false)
        }

        // MARK: - .replaceCurrentWithChain

        @Test(".replaceCurrentWithChain reports isReplaceCurrentWithChain == true")
        func replaceCurrentWithChainIsItself() {
            #expect(NavigationAction.replaceCurrentWithChain.isReplaceCurrentWithChain == true)
        }

        @Test(".replaceCurrentWithChain reports the other four accessors false")
        func replaceCurrentWithChainOthersFalse() {
            let action = NavigationAction.replaceCurrentWithChain
            #expect(action.isPush == false)
            #expect(action.isReplaceCurrent == false)
            #expect(action.isReplaceAll == false)
            #expect(action.isReplaceAllWithChain == false)
        }

        // MARK: - .replaceAllWithChain

        @Test(".replaceAllWithChain reports isReplaceAllWithChain == true")
        func replaceAllWithChainIsItself() {
            #expect(NavigationAction.replaceAllWithChain.isReplaceAllWithChain == true)
        }

        @Test(".replaceAllWithChain reports the other four accessors false")
        func replaceAllWithChainOthersFalse() {
            let action = NavigationAction.replaceAllWithChain
            #expect(action.isPush == false)
            #expect(action.isReplaceCurrent == false)
            #expect(action.isReplaceAll == false)
            #expect(action.isReplaceCurrentWithChain == false)
        }

        // MARK: - Mutual exclusivity

        @Test("exactly one accessor is true for every case", arguments: [
            NavigationAction.push,
            NavigationAction.replaceCurrent,
            NavigationAction.replaceAll,
            NavigationAction.replaceCurrentWithChain,
            NavigationAction.replaceAllWithChain
        ])
        func exactlyOneAccessorIsTrue(action: NavigationAction) {
            let trueCount = [
                action.isPush,
                action.isReplaceCurrent,
                action.isReplaceAll,
                action.isReplaceCurrentWithChain,
                action.isReplaceAllWithChain
            ].filter { $0 }.count
            #expect(trueCount == 1)
        }

        // MARK: - Hashable / Equatable

        @Test("equal cases compare equal")
        func equalCasesEqual() {
            #expect(NavigationAction.push == NavigationAction.push)
            #expect(NavigationAction.replaceCurrent == NavigationAction.replaceCurrent)
            #expect(NavigationAction.replaceAll == NavigationAction.replaceAll)
            #expect(NavigationAction.replaceCurrentWithChain == NavigationAction.replaceCurrentWithChain)
            #expect(NavigationAction.replaceAllWithChain == NavigationAction.replaceAllWithChain)
        }

        @Test("distinct cases compare unequal")
        func distinctCasesUnequal() {
            #expect(NavigationAction.push != NavigationAction.replaceCurrent)
            #expect(NavigationAction.push != NavigationAction.replaceAll)
            #expect(NavigationAction.replaceCurrent != NavigationAction.replaceAll)
            #expect(NavigationAction.replaceCurrent != NavigationAction.replaceCurrentWithChain)
            #expect(NavigationAction.replaceAll != NavigationAction.replaceAllWithChain)
            #expect(NavigationAction.replaceCurrentWithChain != NavigationAction.replaceAllWithChain)
        }

        @Test("hashes match for equal cases")
        func hashesMatch() {
            var seen: Set<NavigationAction> = []
            seen.insert(.push)
            seen.insert(.push)
            seen.insert(.replaceCurrent)
            seen.insert(.replaceAll)
            seen.insert(.replaceCurrentWithChain)
            seen.insert(.replaceAllWithChain)
            #expect(seen.count == 5)
        }

        // MARK: - Custom conformer

        @Test("a custom NavigationActionProtocol type can report only isPush")
        func customConformerPushOnly() {
            let action = CustomNavigationAction(isPush: true, isReplaceCurrent: false, isReplaceAll: false)
            #expect(action.isPush)
            #expect(!action.isReplaceCurrent)
            #expect(!action.isReplaceAll)
        }

        @Test("a custom NavigationActionProtocol type can report only isReplaceCurrent")
        func customConformerReplaceCurrentOnly() {
            let action = CustomNavigationAction(isPush: false, isReplaceCurrent: true, isReplaceAll: false)
            #expect(!action.isPush)
            #expect(action.isReplaceCurrent)
            #expect(!action.isReplaceAll)
        }

        @Test("a custom NavigationActionProtocol type can report only isReplaceAll")
        func customConformerReplaceAllOnly() {
            let action = CustomNavigationAction(isPush: false, isReplaceCurrent: false, isReplaceAll: true)
            #expect(!action.isPush)
            #expect(!action.isReplaceCurrent)
            #expect(action.isReplaceAll)
        }

        // MARK: - Ambiguous conformers (documented behavior)
        //
        // The protocol does not forbid conformers that report multiple flags as
        // `true` simultaneously, nor conformers that report all flags as
        // `false`. Both are permitted at the type level. The production
        // `RouteHandle.push(to:animated:)` resolves ambiguity with an
        // if/else-if chain in the order push → replaceCurrent → replaceAll, so
        // the first `true` flag wins; an all-false conformer is silently
        // dropped (no-op).

        @Test("conformer with all three flags true type-checks (push wins at the call site)")
        func ambiguousConformerAllTrue() {
            let action = CustomNavigationAction(isPush: true, isReplaceCurrent: true, isReplaceAll: true)
            #expect(action.isPush)
            #expect(action.isReplaceCurrent)
            #expect(action.isReplaceAll)
        }

        @Test("conformer with all three flags false type-checks (call site falls through to no-op)")
        func ambiguousConformerAllFalse() {
            let action = CustomNavigationAction(isPush: false, isReplaceCurrent: false, isReplaceAll: false)
            #expect(!action.isPush)
            #expect(!action.isReplaceCurrent)
            #expect(!action.isReplaceAll)
        }
    }
}
