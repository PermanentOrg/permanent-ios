//
//  SceneLifecycleTests.swift
//  PermanentTests
//

import Testing
import UIKit
@testable import Permanent

@MainActor
struct SceneLifecycleTests {

    // MARK: - Manifest

    @Test("Info.plist declares one window scene served by SceneDelegate, built in code")
    func manifestDeclaresOneCodeBuiltWindowScene() throws {
        let manifest = try #require(Bundle.main.object(forInfoDictionaryKey: "UIApplicationSceneManifest") as? [String: Any])
        #expect(manifest["UIApplicationSupportsMultipleScenes"] as? Bool == false)

        let configurations = try #require(manifest["UISceneConfigurations"] as? [String: Any])
        #expect(Array(configurations.keys) == ["UIWindowSceneSessionRoleApplication"])
        let entries = try #require(configurations["UIWindowSceneSessionRoleApplication"] as? [[String: Any]])
        #expect(entries.count == 1)

        let entry = try #require(entries.first)
        let className = try #require(entry["UISceneDelegateClassName"] as? String)
        #expect(NSClassFromString(className) is SceneDelegate.Type)
        #expect(entry["UISceneStoryboardFile"] == nil)
        #expect(Bundle.main.object(forInfoDictionaryKey: "UIMainStoryboardFile") == nil)
    }

    // MARK: - Window handoff

    @Test("The connected scene's window is AppDelegate's window")
    func connectedSceneWindowIsAppDelegateWindow() async throws {
        let (scene, sceneDelegate) = try await connectedSceneDelegate()
        let window = try #require(sceneDelegate.window)

        #expect(AppDelegate.shared.window === window)
        #expect(window.windowScene === scene)
        #expect(window.isHidden == false)
        #expect(window.rootViewController is RootViewController)
        #expect(window.rootViewController?.isViewLoaded == true)
        #expect(AppDelegate.shared.connectedRootViewController === window.rootViewController)
    }

    @Test("With no window yet, the optional root is nil instead of trapping")
    func connectedRootIsNilWithoutWindow() {
        #expect(AppDelegate().connectedRootViewController == nil)
    }

    // MARK: - Links

    @Test("An upload-folder link without a usable folder is ignored")
    func uploadFolderLinkWithoutFolderIsIgnored() throws {
        let url = try #require(URL(string: "permanent://upload-folder?archiveNo=&folderLinkId=0"))
        #expect(AppDelegate.shared.handleOpenURL(url) == false)
    }

    @Test("Each link is passed on exactly once, to the handler for its kind")
    func forwardPassesEachLinkOnce() throws {
        let shareActivity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
        shareActivity.webpageURL = URL(string: "https://app.staging.permanent.org/share/abc123")
        let publicActivity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
        publicActivity.webpageURL = URL(string: "https://app.staging.permanent.org/p/archive/0000-0000")
        let uploadFolderURL = try #require(URL(string: "permanent://upload-folder?archiveNo=0000-0000&folderLinkId=1"))
        let otherURL = try #require(URL(string: "permanent://upload-folder?archiveNo=0000-0001&folderLinkId=2"))

        var passedActivities: [NSUserActivity] = []
        var passedURLs: [URL] = []
        let sceneDelegate = SceneDelegate()
        sceneDelegate.handleUserActivity = { passedActivities.append($0) }
        sceneDelegate.handleOpenURL = { passedURLs.append($0) }

        sceneDelegate.forward(userActivities: [shareActivity, publicActivity], urls: [uploadFolderURL, otherURL])
        #expect(passedActivities.count == 2)
        #expect(passedActivities.filter { $0 === shareActivity }.count == 1)
        #expect(passedActivities.filter { $0 === publicActivity }.count == 1)
        #expect(passedURLs == [uploadFolderURL, otherURL])

        passedActivities = []
        passedURLs = []
        sceneDelegate.forward(userActivities: [], urls: [uploadFolderURL])
        #expect(passedActivities.isEmpty)
        #expect(passedURLs == [uploadFolderURL])
    }

    @Test("A universal link that reaches the running scene is passed on once, as an activity")
    func continueUserActivityPassesTheActivityOnce() async throws {
        let (scene, _) = try await connectedSceneDelegate()
        let activity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
        activity.webpageURL = URL(string: "https://app.staging.permanent.org/share/abc123")

        var passedActivities: [NSUserActivity] = []
        var passedURLs: [URL] = []
        let sceneDelegate = SceneDelegate()
        sceneDelegate.handleUserActivity = { passedActivities.append($0) }
        sceneDelegate.handleOpenURL = { passedURLs.append($0) }

        sceneDelegate.scene(scene, continue: activity)

        #expect(passedActivities.count == 1 && passedActivities.first === activity)
        #expect(passedURLs.isEmpty)
    }

    @Test("By default a universal link reaches AppDelegate, which parks the share token")
    func defaultActivityHandlerReachesAppDelegate() async throws {
        let (scene, _) = try await connectedSceneDelegate()
        let root = try #require(AppDelegate.shared.connectedRootViewController)
        try #require(root.isDrawerRootActive == false, "A signed-in host would navigate instead of parking the token")
        let activity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
        activity.webpageURL = URL(string: "https://app.staging.permanent.org/share/abc123")
        defer { AppDelegate.shared.clearShareDeepLinks() }

        SceneDelegate().scene(scene, continue: activity)

        let token: String? = PreferencesManager.shared.getValue(forKey: Constants.Keys.StorageKeys.shareURLToken)
        #expect(token == "abc123")
    }

    // MARK: - Helpers

    /// The scene connects just after launch, so the first test to run may need to wait for it.
    private func connectedSceneDelegate() async throws -> (UIWindowScene, SceneDelegate) {
        var match: (UIWindowScene, SceneDelegate)?
        for _ in 0..<50 {
            for case let scene as UIWindowScene in UIApplication.shared.connectedScenes {
                if let sceneDelegate = scene.delegate as? SceneDelegate {
                    match = (scene, sceneDelegate)
                }
            }
            if match != nil { break }
            try await Task.sleep(for: .milliseconds(100))
        }
        return try #require(match, "No window scene with a SceneDelegate connected within 5 s")
    }
}
