# RouteKit

A UIKit routing engine for scene-based iOS apps that own their own auth session.
RouteKit pairs a host app's view controllers with an `AuthSessionHandle` and
drives on-screen navigation as the session loads, transitions between signed-in
and signed-out states, or as the scene moves between active and inactive — while
also owning **scene lifecycle** and **inbound intent routing** (deep links,
Handoff / Spotlight activities, and Home Screen quick actions) across one or
many windows.

RouteKit is distributed as a **precompiled binary**: `Route` (the engine) ships
as an `xcframework` while `RouteInterface` (the protocols and value types you
program against) ships as source. Usage is identical to a source package —
`import Route` / `import RouteInterface`.

> [!IMPORTANT]
> Before shipping, read [**⚠️ Integration checklist — do NOT skip**](#️-integration-checklist--do-not-skip):
> forward the scene **and** app delegate callbacks (notably
> `application(_:didDiscardSceneSessions:)`, which purges orphaned restoration
> storage), declare RouteKit's scene activity types in `Info.plist`, and keep
> restoration state tiny. Each of these fails **silently** if missed.

---

## Installation

Add RouteKit via SwiftPM:

```swift
.package(url: "https://github.com/kaVish2214/RouteKit.git", from: "0.1.1")
```

```swift
.target(
    name: "App",
    dependencies: [
        .product(name: "Route", package: "RouteKit"),
        .product(name: "RouteInterface", package: "RouteKit"),
    ]
)
```

The `Route` engine is delivered as an `xcframework` bundled with the package, so
SwiftPM fetches it while resolving the dependency — no separate download step.

---

## Why

A typical iOS app with authentication and scenes has to coordinate a lot at
launch and throughout a session:

- Show a splash while the auth session is still loading.
- Pick a different entry screen for signed-in vs. signed-out states.
- React to sign-in / sign-out by swapping the navigation stack (and, on
  sign-out, closing protected windows).
- Hide the app's content when a scene becomes inactive while signed in.
- Route a deep link, activity, or quick action into the right window — the
  current one, a new one, or an existing one — and survive it arriving before
  the UI is ready.

RouteKit owns all of that. The host app declares *what* each scene, screen, and
intent is; RouteKit decides *where* and *when* to show it.

---

## Products

RouteKit ships two SwiftPM products with a deliberate split:

| Product | Contains | Depend on it from |
|---|---|---|
| **`RouteInterface`** | Public protocols and value types: routing (`RouterProtocol`, `RouteHandleProtocol`, `RouteHandleConfigurable`), scenes (`SceneHandleProtocol`, `SceneConfiguratorProtocol`, `SceneRepresentable`, `SceneConnectionConfigurable`, `SceneTerminationPolicy`/`Request`), intents (`SceneIntent`, `SceneRoutingBehavior`, `SceneRoutingError`, `SceneIntentContext`, `SceneIntentControllerProtocol`, `SceneIntentExecutionPermission`), navigation (`NavigationAction`), presentation (`PresentationSource`), state restoration (`StateRestoring`, `StateRepresentable`, `StateRestorableStorage`, `RouteStateRestoration`), and view controllers (`ViewControlling`, `RoutingViewControlling`, `RoutingSplashControlling`, `SplashAnimationTiming`). No run-time engine. | Modules that only need to *conform* — every routed view-controller module and every router / configurator implementation. |
| **`Route`** | The concrete engine you instantiate at the composition root: `SceneManager` (the scene handle) and `RouteHandle` (the per-scene routing engine), plus the run-time machinery behind scene-intent queuing, state restoration, and auth-event reactions. | The composition root only (the `UIWindowSceneDelegate` module). |

The auth-event vocabulary (`AuthSessionDelegateEvent`, …) lives upstream in
AuthSessionKit's `AuthSessionInterface`; `RouteInterface` re-exports it
transitively.

---

## Architecture

```
                        ┌───────────────────────┐
                        │     AuthSessionKit    │
                        └───────────┬───────────┘
                                    │ auth session callbacks
                                    ▼
┌──────────────────────────────────────────────────────────────────────┐
│                         SceneManager (per app)                       │
│  • caches configurator's registered scenes + intents                 │
│  • builds one RouteHandle per connected UIWindowScene                │
│  • activates / closes scenes; routes inbound intents                 │
└───────────────┬──────────────────────────────────────┬───────────────┘
                │ asks                                   │ builds
                ▼                                        ▼
   ┌────────────────────────┐              ┌──────────────────────────┐
   │ SceneConfiguratorProto │              │   RouteHandle (per scene)│
   │ (host: names scenes,   │              │  • primary + overlay     │
   │  intents, builds handle)│             │    windows               │
   └────────────────────────┘              │  • splash / obscuration  │
                                           │  • pending-intent queue  │
                                           └────────────┬─────────────┘
                                                        │ asks at each decision
                                                        ▼
                                            ┌──────────────────────┐
                                            │    RouterProtocol    │
                                            │   (host-app impl)    │
                                            └──────────────────────┘
```

One **`SceneManager`** per app owns every scene; one **`RouteHandle`** per
`UIWindowScene` owns that scene's windows and navigation. The host supplies two
plug-ins: a **`SceneConfiguratorProtocol`** (names scenes and intents, builds
route handles) and a **`RouterProtocol`** (per-screen decisions).

---

## Core concepts

### Scene layer

- **`SceneManager`** (`Route`) — the concrete `SceneHandleProtocol`. Hold one per
  app. UIKit's scene-delegate callbacks are forwarded to it.
- **`SceneConfiguratorProtocol`** — the host's scene plug-in. Declares
  `registerScenes`, `registerIntents`, and the `primaryScene` fallback, builds
  each connecting scene's `RouteHandle` (`routeHandle(for:with:within:)`), and
  returns a `sceneTerminationPolicy`. (A connecting window's identity is
  recovered from its scene-identity activity / persisted session info, falling
  back to `primaryScene`.)
- **`SceneRepresentable`** — the host's scene-identity type (typically a
  `String`-backed enum); its `rawValue` survives activity round-trips.
- **Multi-scene.** `SceneHandleProtocol.allowsMultipleScenes` reflects
  `UIApplication.supportsMultipleScenes`. `requestSceneActivation` reports
  `SceneRoutingError.multipleScenesNotSupported` on a single-scene app, and
  intent routing degrades to the current window instead of opening a new one.
- **Activation & destruction.** `requestSceneActivation` opens a scene in its
  own window; `requestSceneDestruction` tears one down (an `executionHandler`
  picks *which* windows via `UISceneExecutionPolicy` when several back one
  identity). The configurator's `sceneTerminationPolicy(for:with:within:)`
  answers per trigger (`SceneTerminationRequestType.system` vs
  `.authenticationSession`): `isSystemTerminationAllowed` drives the window's
  `isClosable`, and `isAuthSessionTerminationAllowed` gates the close-on-sign-out
  sweep.
- **One window per identity.** Under `WindowBehavior.windowPerScene` (the
  default), only one window may exist per scene identity — enforced on **both**
  paths. A programmatic `requestSceneActivation` of an already-open identity
  reports `SceneRoutingError.sceneAlreadyActive`; and a **system-initiated** new
  window for an already-open identity (App Exposé, ⌘N on Mac, a `.multiWindow`
  activity) is refused at connection time — the duplicate session is destroyed
  rather than opening a second window. Use `WindowBehavior.undefined` to allow
  multiple windows of the same identity.

### Scene intents & deep linking

`SceneIntent` describes an inbound launch/route trigger:

| Case | Source | Identity (how it matches) |
|---|---|---|
| `.url(URL?)` | a deep-link URL | the full URL string |
| `.userActivity(activityType:context:)` | Handoff / Spotlight / Siri | `activityType` **only** (the `context` payload is excluded) |
| `.shortcutItem(type:)` | a Home Screen quick action | the shortcut `type` |

The configurator declares the accepted set via `registerIntents`; an inbound
value matching none is rejected with `SceneRoutingError.unregisteredIntent`.
Matching is by **identity** — payload-independent — so a statically registered
intent still matches an inbound one carrying a runtime `context`.

`SceneRoutingBehavior` (from `routingBehavior(for:within:)`) decides *where* a
registered intent lands:

- **`.currentScene`** — route into the window that received it (default).
- **`.newScene(SceneObject)`** — open a new window for that scene.
- **`.preferExisting(SceneObject)`** — bring an existing matching window
  forward, else open one.

Intents that arrive before a scene's route is live are **queued** and replayed
once the launch sequence completes — so a cold-launch deep link survives. The
router decides each intent's fate via `shouldExecute(pending:current:for:)` →
`SceneIntentExecutionPermission` (`executeIntent` / `executionDenied` /
`intentExecuted`); denied intents stay queued for retry (e.g. after sign-in).

### `RouterProtocol`
The host's per-screen decision-maker:

- `preferredSplashViewController(for:)` — the splash.
- `preferredInitialViewController(for:with:)` — the post-splash entry screen
  (branch on `routeHandling.authSessionHandle.sessionStatus`, or resume the
  `with restoring:` screen recovered by state restoration).
- `shouldExecute(pending:current:for:)` / `preferredViewController(_:for:)` —
  whether/what to route for a pending `SceneIntent`.
- `canPushViewController(on:from:to:)` — veto a push.
- `shouldObscureContentWhenInactive(for:)` / `preferredContentObscurationViewController(for:)`.
- `allowsPrecedingStackOnInitialRoute` — expand the initial VC's back-chain.
- `updateRouteIfNeeded(for:sessionEvent:)` — react to post-launch auth events.
- `initialRouteDidInitialize(for:)` — post-launch hook.
- `sceneIntentExecutionDidFailed(for:error:)` — a pending intent was denied.

Conforms to `DependencyResolver` so factories can resolve their view controllers
through the shared container.

### `RouteHandleProtocol`
Drives one scene. Built by the configurator, retained via the scene's storage.
Exposes `push(to:animated:)` / `pop(animated:)` / `present(_:with:animated:completion:)`
for feature code, `route(to:completion:)` / `executePendingSceneIntents(completion:)`
for intents, `requestStoreState()` / `requestDiscardState()` for restoration, and
`authSessionHandle` / `isRouteInitialized` / `currentViewController` for
diagnostics. `RouteHandle` is the default conformer.

> **Completion semantics.** The `completion` on `route(to:)` and the inbound
> forwarders is a **per-intent error/denial channel** — invoked only when an
> intent can't be honoured, never on success, and once per failing intent in a
> fan-out. It is not a once-only completion.

### `ViewControlling` / `RoutingViewControlling`
Every `UIViewController` gains a `routeHandle` back-reference (stamped as
controllers enter the stack), so feature code can push/pop without threading the
handle through initializers. `RoutingViewControlling` adds two affordances:
`preferredNavigationActionWhenPushed()` (`.push`, `.replaceCurrent`,
`.replaceAll`, `*WithChain`) and `preferredPrecedingViewController()` (a
synthetic back-stack).

### Auth-event reactions
RouteKit observes the app's `AuthSessionHandle` and reacts to session changes:
post-launch, each auth event is delivered to the router's
`updateRouteIfNeeded(for:sessionEvent:)`; globally, a sign-out closes the
scenes whose termination policy opts into `isAuthSessionTerminationAllowed`.

### Content obscuration
When a scene leaves foreground-active, RouteKit consults
`shouldObscureContentWhenInactive(for:)`; if opted in, it raises an overlay
window above `.alert + 1` and installs the obscuration VC (default: system
blur), tearing it down with a fade on return. Session-state gating (signed-in,
no pending manual reauth) lives inside the default implementation.

### State restoration
A screen opts in by conforming to `StateRestoring`: it declares a small
`Codable` `StateRepresentable` snapshot, captures it in `restoringState()`, and
rebuilds itself in `restore(with:)`. RouteKit persists **one record per scene
session** (keyed by `session.persistentIdentifier`), snapshotting only the
navigation stack's *top* controller — `requestStoreState()` is called after
every push/pop automatically, so tracking is hands-off. At launch, the recovered
screen is handed to `preferredInitialViewController(for:with:)`; the router seeds
the rest of the back stack from the screen's `preferredPrecedingViewController()`
chain.

Restoration is **auth-gated** — a record captures the signed-in flag it was
saved under and is ignored on an auth mismatch, so a signed-in screen never
rehydrates into a signed-out app. Storage is swappable via
`StateRestorationConfigurable.registerStateRecordableStorage()` (default: one
property-list file per session under Application Support); forward
`application(_:didDiscardSceneSessions:)` to `discardSceneSessions(for:)` to
clean up.

> **Keep snapshots lightweight.** A `StateRepresentable` should be the
> *coordinates* to rebuild a screen — an item id, a scroll offset — not the
> screen's content. The default store warns (`payloadTooLarge`) past ~100 KB;
> treat that as a design smell, not a limit to raise.

---

## Launch sequence

1. The `UIWindowSceneDelegate` forwards `scene(_:willConnectTo:options:)` to the
   app's `SceneManager`.
2. `SceneManager` resolves the scene identity, collects the intents that
   accompanied the connection, and asks the configurator to build the
   `RouteHandle` (seeded with those intents).
3. `RouteHandle` presents the router's splash above the app content while the
   auth session loads.
4. Once the session is loaded (or the splash's animation completes, per
   `SplashAnimationTiming`), RouteKit installs the initial navigation stack,
   replays any queued intents, drives the splash off (or into obscuration), and
   flips `isRouteInitialized = true`.

---

## Quick start

```swift
import Route
import RouteInterface
import AuthSessionInterface

// 1. Scene identity.
enum AppScene: String, SceneRepresentable { case main }

// 2. Router — per-screen decisions.
@MainActor
final class AppRouter: RouterProtocol {

    var allowsPrecedingStackOnInitialRoute: Bool { true }

    func preferredSplashViewController(for routeHandling: any RouteHandleProtocol) -> any RoutingSplashControlling {
        AppSplashViewController()
    }

    func preferredInitialViewController(for routeHandling: any RouteHandleProtocol,
                                        with restoring: (any StateRestoring)?) -> any RoutingViewControlling {
        if let restored = restoring as? any RoutingViewControlling { return restored }
        return routeHandling.authSessionHandle.sessionStatus.isSignedIn
            ? HomeViewController() : SignInViewController()
    }

    func shouldExecute(pending sceneIntent: SceneIntent, current viewController: UIViewController?,
                       for routeHandling: any RouteHandleProtocol) -> SceneIntentExecutionPermission {
        routeHandling.authSessionHandle.sessionStatus.isSignedIn ? .executeIntent(isAnimated: true)
                                                                 : .executionDenied
    }

    func preferredViewController(_ sceneIntent: SceneIntent,
                                 for routeHandling: any RouteHandleProtocol) -> any RoutingViewControlling {
        // Map the intent onto a screen.
        DeepLinkViewController(intent: sceneIntent)
    }
}

// 3. Configurator — names scenes + intents, builds handles.
@MainActor
final class AppSceneConfigurator: SceneConfiguratorProtocol {

    func registerScenes() -> Set<AppScene> { [.main] }

    func registerIntents() -> Set<SceneIntent> {
        [ .url(URL(string: "myapp://home")), .shortcutItem(type: "new-message") ]
    }

    func primaryScene(for sceneHandle: any SceneHandleProtocol) -> AppScene { .main }

    func routeHandle(for scene: AppScene, with configuration: any RouteHandleConfigurable,
                     within sceneHandle: any SceneHandleProtocol) -> (any RouteHandleProtocol)? {
        RouteHandle(configuration,
                    authenticationSessionHandle: AppDependencies.authSession,
                    router: AppRouter())
    }

    func sceneTerminationPolicy(for scene: AppScene, with terminationRequest: any SceneTerminationRequest,
                                within sceneHandle: any SceneHandleProtocol) -> any SceneTerminationPolicy {
        AppTerminationPolicy()  // your SceneTerminationPolicy conformer
    }
}

// 4. Composition root — one SceneManager per app, forwarded to from each scene delegate.
final class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    // Hold the single app-wide manager (e.g. via your DI container / AppDelegate).
    private let sceneManager = AppDependencies.sceneManager   // SceneManager(sceneConfigurator: AppSceneConfigurator())

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        sceneManager.scene(windowScene, willConnectTo: session, options: connectionOptions) { error in
            debugPrint("routing error:", error)
        }
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        sceneManager.scene(scene, openURLContexts: URLContexts) { error in debugPrint(error) }
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        sceneManager.scene(scene, continue: userActivity) { error in debugPrint(error) }
    }

    func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem,
                     completionHandler: @escaping (Bool) -> Void) {
        sceneManager.scene(windowScene, performActionFor: shortcutItem,
                           completionHandler: completionHandler) { error in debugPrint(error) }
    }
}

// State restoration cleanup — forward from the *app* delegate:
extension AppDelegate {
    func application(_ application: UIApplication, didDiscardSceneSessions sessions: Set<UISceneSession>) {
        sceneManager.discardSceneSessions(for: sessions)
    }
}
```

Feature view controllers conform to `RoutingViewControlling` and reach back
through `routeHandle` to push and pop:

```swift
final class ProfileViewController: UIViewController, RoutingViewControlling {
    func openSettings() {
        routeHandle?.push(to: SettingsViewController(), animated: true)
    }
}
```

---

## ⚠️ Integration checklist — do NOT skip

RouteKit is only as correct as the host wiring around it. The three items below
live in **your** app process and Info.plist — RouteKit physically cannot do them
for you, and skipping any of them **fails silently** (no crash, no log in
release — just missing behaviour or a growing disk footprint).

### 1. Forward every delegate callback — including the app-delegate one

Routing is entirely driven by callbacks you forward. Miss one and that whole
capability quietly disappears:

| Delegate method | Lives on | Forward to | If you skip it |
|---|---|---|---|
| `scene(_:willConnectTo:options:)` | `UIWindowSceneDelegate` | `sceneManager.scene(_:willConnectTo:options:errorHandler:)` | **Nothing routes at all** — no window, no splash, no stack. |
| `scene(_:openURLContexts:)` | `UIWindowSceneDelegate` | `sceneManager.scene(_:openURLContexts:errorHandler:)` | Deep links are dropped. |
| `scene(_:continue:)` | `UIWindowSceneDelegate` | `sceneManager.scene(_:continue:errorHandler:)` | Handoff / Spotlight / Siri activities are dropped. |
| `windowScene(_:performActionFor:completionHandler:)` | `UIWindowSceneDelegate` | `sceneManager.scene(_:performActionFor:completionHandler:errorHandler:)` | Home Screen quick actions are dropped. |
| `application(_:didDiscardSceneSessions:)` | **`UIApplicationDelegate`** | `sceneManager.discardSceneSessions(for:)` | **Restoration records for discarded windows leak forever.** |

> [!CAUTION]
> `didDiscardSceneSessions` is on **`UIApplicationDelegate`**, *not* the scene
> delegate — it's easy to miss because everything else is scene-scoped. It is the
> **only** hook that purges restoration state for windows the user swiped away in
> the app switcher. Skip it and the on-disk store grows **unbounded** with orphaned
> records that will never be read again.

### 2. Declare RouteKit's scene activity types in Info.plist

If your app supports multiple windows, add these to the **`NSUserActivityTypes`**
array in `Info.plist`:

```xml
<key>NSUserActivityTypes</key>
<array>
    <string>com.route.sceneActivity.multiWindow</string>
    <string>com.route.sceneActivity.sceneForwarding</string>
</array>
```

> [!IMPORTANT]
> UIKit only delivers an activation's `NSUserActivity` to the new scene when its
> `activityType` is declared here. RouteKit rides a window's **scene identity** (and
> any forwarded intents) on these activities — undeclared, UIKit drops them and every
> new window opens as your `primaryScene` **with no intents**, silently. RouteKit
> fires a **debug-build assertion** at launch to catch this early; release builds just
> misbehave.

### 3. Keep restoration state tiny

> [!WARNING]
> A `StateRepresentable` is persisted **synchronously on the main actor**, one record
> per scene session, capturing only the navigation stack's **top** view controller.
> Store the *coordinates* to rebuild a screen — an item id, a scroll offset — **never**
> the screen's content, images, or model graphs. The default store emits a
> `payloadTooLarge` warning past **~100 KB**: treat it as a design smell to fix, not a
> ceiling to raise. Everything below the top screen is rebuilt for free from
> `preferredPrecedingViewController()`.

---

## In-depth walkthrough — a two-window Notes app

The Quick start above wires a single scene. This section builds a fuller,
realistic app that touches **every** RouteKit surface: two scene identities
(a main window and a detachable compose window), all three inbound intent kinds,
per-intent routing across windows, a splash that gates on its own animation,
auth-driven re-routing, content obscuration, scene-termination policy, and
lightweight state restoration.

> Screens are abbreviated (`// …`) to keep the focus on the RouteKit wiring.

### 1. Scene identity

```swift
import RouteInterface

/// Two kinds of window. `String`-backed so the raw value survives the
/// activity / `userInfo` round-trips RouteKit uses to re-identify a window.
enum NotesScene: String, SceneRepresentable {
    case main       // the notes list + detail
    case compose    // a standalone "new note" window (iPad/Mac)
}
```

### 2. A restorable screen with a back-stack

A routed screen declares how it enters the stack, what sits beneath it, and
(optionally) how to snapshot itself for restoration.

```swift
import UIKit
import RouteInterface

/// The snapshot: just enough to rebuild the screen. Keep it tiny.
struct NoteState: StateRepresentable, Equatable {
    let noteID: String
}

final class NoteDetailViewController: UIViewController, RoutingViewControlling, StateRestoring {

    let noteID: String
    init(noteID: String) { self.noteID = noteID; super.init(nibName: nil, bundle: nil) }
    @available(*, unavailable) required init?(coder: NSCoder) { fatalError() }

    // MARK: RoutingViewControlling

    /// Opening a note replaces whatever detail was showing, in one transition.
    func preferredNavigationActionWhenPushed() -> any NavigationActionProtocol {
        NavigationAction.replaceCurrentWithChain
    }

    /// The list always sits beneath a detail — so a deep-linked note launches
    /// with a working back button even on a cold start.
    func preferredPrecedingViewController() -> (any RoutingViewControlling)? {
        NotesListViewController()
    }

    // MARK: StateRestoring

    func restoringState() -> NoteState { NoteState(noteID: noteID) }

    static func restore(with state: NoteState) -> any StateRestoring {
        NoteDetailViewController(noteID: state.noteID)   // rebuilt on relaunch
    }
}
```

### 3. The splash

```swift
import UIKit
import RouteInterface

final class NotesSplashViewController: UIViewController, RoutingSplashControlling {

    /// Hold the initial screen back until the logo animation finishes.
    func preferredAnimationTiming() -> SplashAnimationTiming { .waitUntilAnimationComplete }

    func startAnimating(over window: UIWindow, completion: (@MainActor @Sendable () -> Void)?) {
        UIView.animate(withDuration: 0.6, animations: { /* … */ }) { _ in
            completion?()   // MUST be called, or launch stalls (a debug watchdog warns).
        }
    }

    func stopAnimating() { /* … */ }
}
```

### 4. The router — every per-screen decision

```swift
import UIKit
import RouteInterface
import AuthSessionInterface

@MainActor
final class NotesRouter: RouterProtocol {

    // Expand the initial screen's preceding chain (list under detail) at launch.
    var allowsPrecedingStackOnInitialRoute: Bool { true }

    // — Launch —

    func preferredSplashViewController(for r: any RouteHandleProtocol) -> any RoutingSplashControlling {
        NotesSplashViewController()
    }

    func preferredInitialViewController(for r: any RouteHandleProtocol,
                                        with restoring: (any StateRestoring)?) -> any RoutingViewControlling {
        // Resume a restored note if one survived the last session…
        if let note = restoring as? NoteDetailViewController { return note }
        // …otherwise branch on auth state.
        return r.authSessionHandle.sessionStatus.isSignedIn
            ? NotesListViewController()
            : SignInViewController()
    }

    func initialRouteDidInitialize(for r: any RouteHandleProtocol) {
        // Live route now exists — safe to kick off analytics, prefetch, etc.
    }

    // — Intents —

    func shouldExecute(pending intent: SceneIntent, current vc: UIViewController?,
                       for r: any RouteHandleProtocol) -> SceneIntentExecutionPermission {
        guard r.authSessionHandle.sessionStatus.isSignedIn else {
            return .executionDenied            // keep it queued; retried after sign-in
        }
        if let note = vc as? NoteDetailViewController, case .url(let url) = intent,
           url?.lastPathComponent == note.noteID {
            return .intentExecuted             // already on that note — nothing to push
        }
        return .executeIntent(isAnimated: true)
    }

    func preferredViewController(_ intent: SceneIntent, for r: any RouteHandleProtocol) -> any RoutingViewControlling {
        switch intent {
        case .url(let url):                 return NoteDetailViewController(noteID: url?.lastPathComponent ?? "")
        case .userActivity(_, let ctx):     return NoteDetailViewController(noteID: (ctx?.decode()?["noteID"] as? String) ?? "")
        case .shortcutItem:                 return ComposeViewController()
        }
    }

    func sceneIntentExecutionDidFailed(for r: any RouteHandleProtocol, error: any Error) {
        // A pending intent was denied (e.g. still signed out) — log / surface.
    }

    // — Guards & reactions —

    func canPushViewController(on r: any RouteHandleProtocol,
                               from source: UIViewController?,
                               to destination: any RoutingViewControlling) -> Bool {
        // Suppress pushing the same note twice in a row.
        !(source is NoteDetailViewController && destination is NoteDetailViewController)
    }

    func updateRouteIfNeeded(for r: any RouteHandleProtocol, sessionEvent: AuthSessionDelegateEvent) {
        // Hard-cut to the signed-out root the moment the session drops.
        if case .logout = sessionEvent { r.push(to: SignInViewController(), animated: true) }
    }

    // — Content obscuration — (defaults already gate on signed-in + no manual reauth;
    //   override only to customise the cover.)
    func preferredContentObscurationViewController(for r: any RouteHandleProtocol) -> UIViewController {
        BrandBlurViewController()
    }
}
```

### 5. The configurator — scenes, intents, restoration, termination

```swift
import UIKit
import Route
import RouteInterface

/// Per-trigger teardown policy.
struct NotesTerminationPolicy: SceneTerminationPolicy {
    let isSystemTerminationAllowed: Bool
    let isAuthSessionTerminationAllowed: Bool
}

@MainActor
final class NotesSceneConfigurator: SceneConfiguratorProtocol {

    // — Registration —

    func registerScenes() -> Set<NotesScene> { [.main, .compose] }

    func registerIntents() -> Set<SceneIntent> {
        [ .url(URL(string: "notes://note")),                                   // notes://note/<id>
          .userActivity(activityType: "com.notes.viewing", context: nil),      // Handoff
          .shortcutItem(type: "new-note") ]                                    // quick action
    }

    /// One window per identity: a second "new-note" request reuses the open
    /// compose window instead of stacking duplicates.
    func registerWindowBehavior() -> WindowBehavior { .windowPerScene }

    /// Fallback when a connecting window carries no recoverable identity.
    func primaryScene(for handle: any SceneHandleProtocol) -> NotesScene { .main }

    // — Routing —

    /// Where a *running* intent lands. Deep links stay in the current window;
    /// "new note" prefers opening/repurposing the dedicated compose window.
    func routingBehavior(for intent: SceneIntent, within handle: any SceneHandleProtocol) -> SceneRoutingBehavior<NotesScene> {
        if case .shortcutItem(let type) = intent, type == "new-note" {
            return .preferExisting(.compose)   // reuse compose window if open, else spawn it
        }
        return .currentScene
    }

    /// When several windows back one identity, choose which run a backdropped intent.
    func sceneIntentExecutionPolicy(for intent: SceneIntent, within handle: any SceneHandleProtocol) -> UISceneExecutionPolicy {
        .default   // first matching window
    }

    // — Handle construction —

    func routeHandle(for scene: NotesScene, with configuration: any RouteHandleConfigurable,
                     within handle: any SceneHandleProtocol) -> (any RouteHandleProtocol)? {
        RouteHandle(configuration,
                    authenticationSessionHandle: AppDependencies.authSession,
                    router: NotesRouter())
    }

    // — Termination —

    func sceneTerminationPolicy(for uiScene: UIScene, with request: any SceneTerminationRequest,
                                within handle: any SceneHandleProtocol) -> any SceneTerminationPolicy {
        NotesTerminationPolicy(
            isSystemTerminationAllowed: true,                       // user may close any window
            isAuthSessionTerminationAllowed: request.isAuthSessionTermination  // sign-out closes protected windows
        )
    }

    func sceneTermination(for uiScene: UIScene?, didFailedWith error: Error,
                          within handle: any SceneHandleProtocol) {
        // A requested teardown failed — log / retry.
    }

    // — State restoration (from StateRestorationConfigurable) —

    /// Return `nil` for the built-in Application-Support file store, or supply
    /// your own (app group, encrypted, in-memory) here.
    func registerStateRecordableStorage() -> (any StateRestorableStorage)? { nil }

    func restorationStorageExecution(for restorable: (any StateRestoring)?, didFailedWith error: any Error) {
        // Note: `payloadTooLarge` arrives here as a *warning* — the record is still written.
    }
}
```

### 6. Composition root — wire the delegates (all of them)

```swift
// One manager for the whole app (store it in your DI container / AppDelegate).
let notesSceneManager = SceneManager(sceneConfigurator: NotesSceneConfigurator())

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    private var manager: SceneManager<NotesSceneConfigurator> { AppDependencies.sceneManager }

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession,
               options opts: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        manager.scene(windowScene, willConnectTo: session, options: opts) { print("route error:", $0) }
    }
    func scene(_ scene: UIScene, openURLContexts ctxs: Set<UIOpenURLContext>) {
        manager.scene(scene, openURLContexts: ctxs) { print($0) }
    }
    func scene(_ scene: UIScene, continue activity: NSUserActivity) {
        manager.scene(scene, continue: activity) { print($0) }
    }
    func windowScene(_ ws: UIWindowScene, performActionFor item: UIApplicationShortcutItem,
                     completionHandler done: @escaping (Bool) -> Void) {
        manager.scene(ws, performActionFor: item, completionHandler: done) { print($0) }
    }
}

extension AppDelegate {
    // On UIApplicationDelegate — the ONLY hook that purges restoration records
    // for windows the user threw away. Skipping it leaks storage forever.
    func application(_ app: UIApplication, didDiscardSceneSessions sessions: Set<UISceneSession>) {
        AppDependencies.sceneManager.discardSceneSessions(for: sessions)
    }
}
```

### 7. Info.plist (multi-window apps only)

```xml
<key>NSUserActivityTypes</key>
<array>
    <string>com.notes.viewing</string>                       <!-- your Handoff activity -->
    <string>com.route.sceneActivity.multiWindow</string>     <!-- required by RouteKit -->
    <string>com.route.sceneActivity.sceneForwarding</string> <!-- required by RouteKit -->
</array>
```

### 8. Driving it at runtime

```swift
// From anywhere with the manager: open the compose window explicitly.
notesSceneManager.requestSceneActivation(.compose) { print("activation failed:", $0) }

// From inside a routed screen — push, present, and snapshot without the handle in your init.
final class NotesListViewController: UIViewController, RoutingViewControlling {
    func open(_ id: String) {
        routeHandle?.push(to: NoteDetailViewController(noteID: id), animated: true)
        routeHandle?.requestStoreState()   // persist the new top screen
    }
    func showFilters() {
        routeHandle?.present(FiltersViewController(), with: PresentationSource.currentController, animated: true)
    }
}
```

That's the whole surface: identity → registration → routing behaviour → handle
construction → per-screen decisions → restoration → termination → runtime
control, with the delegate wiring that makes it all fire.

---

## Support & commercial use

RouteKit is **free for personal use, indie developers, and small teams** — use it
and ship it, no strings attached.

If RouteKit saves you time, you can support its development:

- ❤️ [**Sponsor on GitHub**](https://github.com/sponsors/kaVish2214) — one-time or recurring.

### Sponsorship tiers

Sponsorship is entirely optional — RouteKit stays free either way. If you'd like to
back its development, these are the planned tiers:

| Tier | Suggested | What you get |
|---|---|---|
| ☕ **Coffee** | $3 / mo or one-time | My thanks, and your name in the project's backers list. |
| 🙌 **Supporter** | $10 / mo | The above — plus GitHub shows a Sponsor badge on your profile automatically. |
| 🧭 **Priority** | $25 / mo | The above, plus your questions and issues are looked at first. |
| 🏢 **Team / Company** | $100–250 / mo | Priority support, a short periodic check-in on your RouteKit integration, and your logo + link in this README. |

A few things kept deliberately fair:

- The **Sponsor badge** on a sponsor's profile is applied by GitHub automatically — there's nothing to claim, and it costs you nothing to receive.
- **Names and logos are only listed for _public_ sponsors.** Sponsor privately and you stay private; reach out any time if you'd like to be credited (or removed).
- Support tiers are **best-effort from a solo maintainer** — genuinely prioritised, but not a contractual SLA. If you need guaranteed, contracted support, that's the [Custom work & consulting](#custom-work--consulting) route instead.
- Cancel anytime; recurring tiers are month-to-month with no lock-in.

**Using RouteKit inside a company?** If your organisation depends on RouteKit and
you'd like to support its continued development — or discuss priority support and
commercial terms — reach out on
[LinkedIn](https://www.linkedin.com/in/kavi-gevariya-58650b125).

> Today RouteKit is free for everyone. Commercial licensing terms for organisations
> may apply to **future** releases; already-released versions keep the terms they
> shipped under.

---

## Custom work & consulting

**Kavi Gevariya** — Senior iOS Engineer · Mobile Architecture & SDK Design
*Building iOS platforms that scale — modular, testable, and boring in all the right places.*

RouteKit is a distillation of how I approach production iOS: isolate concerns behind
clean interfaces, ship engines as versioned binaries, and let feature teams move fast
without stepping on each other. I work with teams that have outgrown a single-target
app and need an architecture that holds up as the codebase, the team, and the feature
set grow.

Where I help:

- 🧩 **Modular architecture at scale** — decomposing monolithic apps into independent
  SPM modules with explicit public interfaces, enforced dependency boundaries, and
  parallelizable build/test units that keep CI fast and teams unblocked.
- 📦 **SDK & binary distribution** — designing library-facing APIs, shipping sealed
  `xcframework` binaries with library evolution, versioning, and source-vs-binary
  split strategies (the exact model RouteKit uses).
- 🧭 **App lifecycle & navigation** — scene management, routing, deep-linking, intent
  handling, and state restoration for multi-window UIKit apps.
- 🎛️ **UIKit ↔ SwiftUI hybrid** — incrementally adopting SwiftUI inside established
  UIKit codebases (and vice versa) with interop that stays predictable at the
  navigation and lifecycle seams, rather than fighting each framework's ownership model.
- 🔐 **Auth, security & DI** — session/auth flows, biometric gating, and
  dependency-injection design that stays testable across module boundaries.

If your team is untangling a large iOS codebase, standing up an internal SDK, or
planning a UIKit-to-SwiftUI migration, I can help — as an architect, an embedded
contributor, or a reviewer.

📩 **Open to consulting, architecture reviews, and contract work** — reach out on
[LinkedIn](https://www.linkedin.com/in/kavi-gevariya-58650b125).

---

## Dependencies

| Package | Role |
|---|---|
| [`UtilityKit`](https://github.com/kaVish2214/UtilityKit) | `DependencyResolver` (Factory-backed container) inherited by the router / configurator / view controllers. |
| [`AuthSessionKit`](https://github.com/kaVish2214/AuthSessionKit) | The auth-session protocols and the `AuthSessionDelegateEvent` vocabulary RouteKit reacts to. |

Transitively: `AuthSessionKit` pulls `BiometricAuthKit`; `UtilityKit` pulls `Factory`.

---

## Requirements

- Swift toolchain 6.3, built with `swiftLanguageModes: [.v6]` (strict
  concurrency on).
- **Platforms:** iOS 14+ (iPhone **and** iPad — universal UIKit) and Mac
  Catalyst 14.0+. RouteKit is scene-based, so multi-window behaviour lights up
  automatically wherever the host declares `UIApplicationSupportsMultipleScenes`
  (iPad and Mac); single-window hosts degrade gracefully to current-window
  routing.
- UIKit (`UIWindow`, `UINavigationController`, `UIVisualEffectView`).

---

## Contributing

Feedback and bug reports are genuinely appreciated — please open an issue with a clear
reproduction and your environment details.

**Code contributions** are handled a little differently. RouteKit is maintained by a
single author, and its licensing model (see [License](#license)) depends on unified
copyright ownership so that future releases can be relicensed cleanly. To keep those
options open for everyone, pull requests are accepted only under a **Contributor License
Agreement (CLA)**. If you'd like to contribute code, please **open an issue to propose
the change before submitting a pull request** — the CLA will be shared there before any
code is merged.

## Acknowledgements

RouteKit is built on the shoulders of excellent open-source work, with gratitude:

- [**Factory**](https://github.com/hmlongco/Factory) — a Swift dependency-injection
  container by **Michael Long**, licensed under the **MIT License** (© 2022 Michael
  Long). RouteKit uses it indirectly, through UtilityKit's `DependencyResolver`; Factory
  is fetched by SwiftPM from its own repository, where its license applies in full.

It also develops alongside its sibling packages
[**UtilityKit**](https://github.com/kaVish2214/UtilityKit) and
[**AuthSessionKit**](https://github.com/kaVish2214/AuthSessionKit).

---

## License

RouteKit is licensed under the [Business Source License 1.1](LICENSE) (BSL 1.1).

- **Free to use in production, without limitation**, for everyone today.
- Each released version automatically converts to the **Apache License 2.0** on
  its Change Date (four years after release).
- The license applies **per version** — a version keeps the terms it shipped
  under, and future releases may carry a different Additional Use Grant.

For alternative or commercial licensing arrangements, contact
[Kavi Gevariya on LinkedIn](https://www.linkedin.com/in/kavi-gevariya-58650b125).
