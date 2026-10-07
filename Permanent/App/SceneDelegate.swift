//
//  SceneDelegate.swift
//  Permanent
//
//  Created by Lucian Cerbu on 29.09.2026.
//

import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    /// Tests swap these to count what is passed on without running AppDelegate's handlers.
    var handleUserActivity: (NSUserActivity) -> Void = { AppDelegate.shared.handleUserActivity($0) }
    var handleOpenURL: (URL) -> Void = { AppDelegate.shared.handleOpenURL($0) }

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = RootViewController()
        self.window = window
        // AppDelegate.shared.rootViewController reads this window, so hand it over before the root loads.
        AppDelegate.shared.window = window
        window.makeKeyAndVisible()

        // Push taps are left out: the notification center delegate already receives them.
        forward(userActivities: connectionOptions.userActivities, urls: connectionOptions.urlContexts.map(\.url))
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        forward(userActivities: [userActivity], urls: [])
    }

    func scene(_ scene: UIScene, openURLContexts urlContexts: Set<UIOpenURLContext>) {
        forward(userActivities: [], urls: urlContexts.map(\.url))
    }

    func forward(userActivities: Set<NSUserActivity>, urls: [URL]) {
        for userActivity in userActivities {
            handleUserActivity(userActivity)
        }
        for url in urls {
            handleOpenURL(url)
        }
    }
}
