//
//  UISceneExecutionPolicy.swift
//  RouteKit
//
//  Created by kavi gevariya on 03/07/26.
//

import UIKit



/// Which live window(s) a scene-level operation should target when **several
/// `UIScene`s back the same scene identity** (multi-window iPad/Mac apps can
/// have many windows of one ``SceneRepresentable``).
///
/// Consulted wherever an operation resolved a scene *identity* but must act on
/// concrete windows: routing a backdropped intent
/// (``SceneConfiguratorProtocol/sceneIntentExecutionPolicy(for:within:)``) and
/// destroying a scene's windows
/// (``SceneHandleProtocol/requestSceneDestruction(_:executionHandler:errorHandler:)``).
public enum UISceneExecutionPolicy {

    /// Act on the first matching window only (the manager's default lookup).
    case `default`

    /// Act on every window currently backing the scene identity.
    case allScenes

    /// Act on exactly this window.
    case scene(UIScene)
}
