//
//  AppDelegate.swift
//  Permanent
//
//  Created by Lucian Cerbu on 04/08/2020.
//

import Firebase
import FirebaseMessaging
import UIKit
import GooglePlaces
import GoogleMaps
import StripeApplePay
import SwiftUI
import KeychainSwift
import os.log
import ActivityKit
import WidgetKit
import SDWebImage

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    static let navigateToFolderNotifName = NSNotification.Name("AppDelegate.navigateToFolderNotifName")
    static let willNavigateToFolderNotifName = NSNotification.Name("AppDelegate.willNavigateToFolderNotifName")

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        if CommandLine.arguments.contains("--AddTextClearButton") {
            UITextField.appearance().clearButtonMode = .always
        }

        #if DEBUG
        // UI tests flip the Stela V2 navigation flag at launch (see BaseUITestCase /
        // TEST_RUNNER_STELA_NAV) so the SAME suite can prove parity against both the V2
        // path and the V1 failsafe without a rebuild. Parsed here, before anything reads
        // the flag. No effect in Release, where the flag is an immutable `let`.
        if CommandLine.arguments.contains("--forceStelaNavigation") {
            FeatureFlags.useStelaNavigation = true
        } else if CommandLine.arguments.contains("--forceLegacyNavigation") {
            FeatureFlags.useStelaNavigation = false
        }
        #endif

        clearShareDeepLinks()

        initFirebase()
        initNotifications()
        configureLogging()
        configureImageCache()
        ReachabilityManager.shared.startMonitoring()
        #if DEBUG
        if CommandLine.arguments.contains("--forceOffline") {
            ReachabilityManager.shared.forceOffline = true
            if let restoreArg = CommandLine.arguments.first(where: { $0.hasPrefix("--restoreConnectivityAfter=") }),
               let seconds = Double(restoreArg.split(separator: "=").last ?? "") {
                DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
                    ReachabilityManager.shared.forceOffline = false
                }
            }
        }
        #endif

        StripeAPI.defaultPublishableKey = stripeServiceInfo.publishableKey

        // Must be called during didFinishLaunching, or iOS won't deliver wakes.
        BackgroundUploadDrainTask.register()

        // LEGACY DRAIN PATH — remove after one release cycle.
        // The upload pipeline no longer uses background URLSession; new uploads
        // run through the foreground session. This call exists to drain any
        // in-flight background tasks left over from older app versions so
        // those files don't get orphaned.
        BackgroundUploadSessionManager.shared.reconnectToExistingSession()
        
        // Reattach to in-flight Live Activity or end orphans from a previous session
        UploadLiveActivityManager.shared.reconcileOnLaunch()
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = RootViewController()
        window?.makeKeyAndVisible()

        return true
    }
    
    // LEGACY DRAIN PATH — remove after one release cycle.
    // The upload pipeline no longer creates background URLSession tasks. iOS
    // only calls this if an older app version left tasks in flight; this
    // handler exists to let them complete cleanly before the system suspends
    // us again.
    func application(_ application: UIApplication,
                     handleEventsForBackgroundURLSession identifier: String,
                     completionHandler: @escaping () -> Void) {
        if identifier == BackgroundUploadSessionManager.backgroundSessionIdentifier {
            BackgroundUploadSessionManager.shared.backgroundSessionCompletionHandler = completionHandler
            BackgroundUploadSessionManager.shared.reconnectToExistingSession()
        }
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        clearShareDeepLinks()
        
        // Fallback for Live Activity taps that don't have a widgetURL
        if userActivity.activityType == NSUserActivityTypeLiveActivity {
            return handleLiveActivityLaunch()
        }
        
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb, let url = userActivity.webpageURL, url.pathComponents.count > 1
        else {
            return false
        }
        
        switch url.pathComponents[1] {
        case "share":
            if url.absoluteString.contains("targetArchiveNbr")
            {
                let pathComponents = url.pathComponents
                let queryItems = URLComponents(string: url.absoluteString)?.queryItems
                
                let shareIdOpt = pathComponents.count > 3 ? pathComponents[3] : nil
                let folderLinkIdOpt = pathComponents.count > 4 ? pathComponents[4] : nil
                
                let targetArchiveNbrOpt = queryItems?.first(where: { $0.name == "targetArchiveNbr" })?.value
                
                guard let shareId: Int = Int(shareIdOpt ?? ""),
                      let folderLinkId: Int = Int(folderLinkIdOpt ?? "") else {
                    return true
                }
                
                // Add API request here
                let apiOperation = APIOperation(ShareEndpoint.getShareForPreview(shareId: shareId, folder_linkId: folderLinkId))
                apiOperation.execute(in: APIRequestDispatcher()) { [weak self] result in
                    switch result {
                    case .json(let response, _):
                        
                        guard let model: APIResults<ShareVO> = JSONHelper.decoding( from: response, with: APIResults<ShareVO>.decoder),
                              let data = model.results.first?.data,
                              let shareVO = data.first?.shareVO
                        else {
                            return
                        }
                        guard
                            let toArchiveId: Int = shareVO.archiveID else {
                            return
                        }
                        // Store the API value (access.role.*), NOT the localized groupName
                        // ("Owner"/"Editor"): the consumer (ArchiveVOData.permissions(forAccessRole:)
                        // → AccessRole.roleForValue) only parses api values, so a groupName fell
                        // through to .viewer and the share opened read-only.
                        let accessRole: String = AccessRole.roleForValue(shareVO.accessRole ?? "").apiValue
                        let toArchiveNbr: String = targetArchiveNbrOpt ?? ""
                        let toArchiveName: String = ""

                        if let name: String = shareVO.recordVO?.displayName as? String,
                           let recordId: Int = shareVO.recordVO?.recordID {
                    DispatchQueue.main.async {
                        guard
                            let archiveNbrInt = shareVO.recordVO?.archiveID else {
                            return
                        }
                        let archiveNbr: String = String(archiveNbrInt)
                        
                        let shareNotifPayload = ShareNotificationPayload(name: name, recordId: recordId, folderLinkId: folderLinkId, archiveNbr: archiveNbr, type: FileType.miscellaneous.rawValue, toArchiveId: toArchiveId, toArchiveNbr: toArchiveNbr, toArchiveName: toArchiveName, accessRole: accessRole)
                        try? PreferencesManager.shared.setNonPlistObject(shareNotifPayload, forKey: Constants.Keys.StorageKeys.sharedFileKey)
                        
                        if let drawerVC = self?.rootViewController.current as? DrawerViewController {
                            drawerVC.dismiss(animated: false) {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    if let sharesVC = drawerVC.rootViewController.visibleViewController as? SharesViewController {
                                        sharesVC.segmentedControl.selectedSegmentIndex = 1
                                        sharesVC.segmentedControlValueChanged(sharesVC.segmentedControl)
                                        
                                        _ = sharesVC.checkSavedFile()
                                    } else {
                                        let sharesVC = UIViewController.create(withIdentifier: .shares, from: .share) as! SharesViewController
                                        sharesVC.selectedIndex = ShareListType.sharedWithMe.rawValue
                                        
                                        drawerVC.leftSideMenuController.selectedMenuOption = TableViewData.drawerData[DrawerSection.navigationScreens]![0]
                                        
                                        self?.rootViewController.changeDrawerRoot(viewController: sharesVC)
                                    }
                                }
                            }
                        }
                    }
                } else if let sharedFolderName: String = shareVO.folderVO?.displayName as? String {
                    DispatchQueue.main.async {
                        guard
                            let archiveNbrInt = shareVO.folderVO?.archiveID else {
                            return
                        }
                        let archiveNbr: String = String(archiveNbrInt)
                        
                        let shareNotifPayload = ShareNotificationPayload(name: sharedFolderName, recordId: 0, folderLinkId: folderLinkId, archiveNbr: archiveNbr, type: FileType.miscellaneous.rawValue, toArchiveId: toArchiveId, toArchiveNbr: toArchiveNbr, toArchiveName: toArchiveName, accessRole: accessRole)
                        try? PreferencesManager.shared.setNonPlistObject(shareNotifPayload, forKey: Constants.Keys.StorageKeys.sharedFolderKey)
                        
                        if let drawerVC = self?.rootViewController.current as? DrawerViewController {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                if drawerVC.rootViewController.visibleViewController is SharesViewController == false {
                                    let sharesVC: SharesViewController = UIViewController.create(withIdentifier: .shares, from: .share) as! SharesViewController
                                    
                                    drawerVC.leftSideMenuController.selectedMenuOption = TableViewData.drawerData[DrawerSection.navigationScreens]![0]
                                    
                                    self?.rootViewController.changeDrawerRoot(viewController: sharesVC)
                                } else {
                                    let sharesVC = drawerVC.rootViewController.visibleViewController as! SharesViewController
                                    sharesVC.segmentedControl.selectedSegmentIndex = 1
                                    sharesVC.segmentedControlValueChanged(sharesVC.segmentedControl)
                                    
                                    _ = sharesVC.checkSavedFolder()
                                }
                            }
                        }
                    }
                }
                        
                    case .error(_, _):
                        break
                        
                    default:
                        break
                    }
                }
                return true
            } else {
                if rootViewController.isDrawerRootActive {
                    return navigateFromUniversalLink(url: url)
                } else {
                    saveUnivesalLinkToken(url.lastPathComponent)
                    return false
                }
            }
            
        case "p":
            // Guard the only unguarded subscript in this handler: a truncated /p link
            // (e.g. "permanent.org/p" shared by hand) would crash on [3].
            guard url.pathComponents.count > 3 else { return false }
            let archiveNbr: String = url.pathComponents[3]
            
            var folderArchiveNbr: String?
            if url.pathComponents.count > 4 {
                folderArchiveNbr = url.pathComponents[4]
            }
            var folderLinkId: String?
            if url.pathComponents.count > 5 {
                folderLinkId = url.pathComponents[5]
            }
            
            let publicDeeplinkPayload: PublicProfileDeeplinkPayload

            if url.pathComponents.count >= 8 && url.pathComponents[6] == "record" {
                let fileArchiveNbr = url.pathComponents[7]

                publicDeeplinkPayload = PublicProfileDeeplinkPayload(archiveNbr: archiveNbr, folderArchiveNbr: folderArchiveNbr, folderLinkId: folderLinkId, fileArchiveNbr: fileArchiveNbr)
            } else {
                publicDeeplinkPayload = PublicProfileDeeplinkPayload(archiveNbr: archiveNbr, folderArchiveNbr: folderArchiveNbr, folderLinkId: folderLinkId, fileArchiveNbr: "")
            }
            
            if rootViewController.isDrawerRootActive {
                return navigateFromPublicLink(publicDeeplinkPayload)
            } else {
                savePublicLinkToken(publicDeeplinkPayload)
                return false
            }
            
        case "app":
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: true)
            {
                if components.path == "/app/auth/signup",
                   let inviteCode = components.queryItems?.first(where: { $0.name == "inviteCode" })?.value {
                    
                    // Check if user is already logged in
                    if let authData = KeychainSwift().getData(SessionKeychainHandler.keychainAuthDataKey),
                       let session = try? JSONDecoder().decode(PermSession.self, from: authData),
                       let archiveId = session.selectedArchive?.archiveID,
                       archiveId != .zero {
                        
                        // User is logged in - show popup that they can't create an account
                        DispatchQueue.main.async {
                            self.showAlreadyLoggedInAlert()
                        }
                        return true
                    } else {
                        // User is not logged in - store invite code for later use during signup
                        InviteCodeManager.shared.storeInviteCode(inviteCode)
                        
                        // Always navigate to signup screen when we have an invite code and user is not logged in
                        DispatchQueue.main.async {
                            // If user was in main flow, logout first
                            if self.rootViewController.isDrawerRootActive {
                                AuthenticationManager.shared.logout()
                            }
                            // Navigate directly to signup screen
                            self.rootViewController.setRoot(named: .signUp, from: .authentication, showRegisterView: true)
                        }
                        return true
                    }
                }
                
                if let redeemCode = components.queryItems?.first(where: { $0.name == "promoCode" })?.value {
                    if let authData = KeychainSwift().getData(SessionKeychainHandler.keychainAuthDataKey),
                       let session = try? JSONDecoder().decode(PermSession.self, from: authData),
                       let archiveId = session.selectedArchive?.archiveID,
                       archiveId != .zero {
                        let storageViewModel = StateObject(wrappedValue: StorageViewModel(reddemCode: redeemCode))
                        let storageView = StorageView(viewModel: storageViewModel)
                        
                        let host = UIHostingController(rootView: storageView)
                        // Present from the topmost VC, not the root: if a modal (a sheet,
                        // file preview, etc.) is already up, presenting on the root silently
                        // fails ("presentation is in progress") and the promo never appears.
                        (self.getTopMostViewController() ?? self.window?.rootViewController)?.present(host, animated: true, completion: nil)

                        return true
                    }
                }
                if components.path == "/app/pr/manage" {
                    if rootViewController.isDrawerRootActive {
                        return navigateFromSharedArchive()
                    } else {
                        saveSharedArchiveToken()
                        return false
                    }
                }
            }
            return false
            
        default: return false
        }
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        os_log("AppDelegate open URL: %{public}@", log: .default, type: .info, url.absoluteString)
        
        // Handle Live Activity deep link to navigate to the upload folder
        if url.scheme == "permanent", url.host == "upload-folder" {
            return handleUploadFolderDeepLink(url: url)
        }
        
        return false
    }
    
    private func handleUploadFolderDeepLink(url: URL) -> Bool {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let archiveNo = components?.queryItems?.first(where: { $0.name == "archiveNo" })?.value ?? ""
        let folderLinkId = Int(components?.queryItems?.first(where: { $0.name == "folderLinkId" })?.value ?? "") ?? 0
        
        os_log("Deep link parsed — archiveNo: %{public}@, folderLinkId: %{public}d", log: .default, type: .info, archiveNo, folderLinkId)
        
        guard !archiveNo.isEmpty, folderLinkId > 0 else {
            os_log("Deep link params invalid — skipping navigation", log: .default, type: .error)
            return false
        }
        
        scheduleUploadFolderNavigation(archiveNo: archiveNo, folderLinkId: folderLinkId)
        return true
    }
    
    /// Fallback for Live Activity taps when no widgetURL is available.
    /// Reads folder info from the currently running Live Activity's attributes.
    private func handleLiveActivityLaunch() -> Bool {
        if #available(iOS 16.2, *) {
            let activities = Activity<UploadActivityAttributes>.activities
            // Skip ended/dismissed activities that iOS hasn't cleaned up yet — navigating
            // from a stale (completed-upload) activity would drop the user into the wrong
            // folder. Only a still-live activity reflects the current upload's destination.
            guard let activity = activities.first(where: { $0.activityState != .ended }) else { return false }

            let archiveNo = activity.attributes.archiveNo
            let folderLinkId = activity.attributes.folderLinkId
            
            os_log("Live Activity fallback — archiveNo: %{public}@, folderLinkId: %{public}d", log: .default, type: .info, archiveNo, folderLinkId)
            
            guard !archiveNo.isEmpty, folderLinkId > 0 else { return false }
            
            scheduleUploadFolderNavigation(archiveNo: archiveNo, folderLinkId: folderLinkId)
            return true
        }
        return false
    }
    
    /// Saves the folder navigation data and schedules a delayed navigation.
    /// The delay lets the foreground transition and any root content loading complete first.
    /// MainViewController's onFilesFetchCompletion also calls navigationToShareFolderLink(),
    /// so if root content reloads, the natural chain handles it. The notification is a fallback
    /// for cases where no reload happens (e.g., uploads in progress skip foreground refresh).
    private func scheduleUploadFolderNavigation(archiveNo: String, folderLinkId: Int) {
        let navData = NavigationDataForShareFolderLink(
            archiveNo: archiveNo,
            folderLinkId: folderLinkId,
            folderName: nil
        )
        try? PreferencesManager.shared.setCodableObject(navData, forKey: Constants.Keys.StorageKeys.navigationToShareFolderLink)

        // Tell MainViewController to show its spinner immediately so the user
        // gets feedback during the 1.0s settle delay below + the navigateMin
        // fetch that follows. Without this, an LA tap looks like a 2–3s freeze
        // before the destination folder loads in.
        NotificationCenter.default.post(name: AppDelegate.willNavigateToFolderNotifName, object: nil)

        // Give the app time to finish foregrounding and any root content loading,
        // then trigger navigation. If onFilesFetchCompletion already consumed the
        // saved data, navigationToShareFolderLink() will be a no-op.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            os_log("Posting navigateToFolderNotifName notification", log: .default, type: .info)
            NotificationCenter.default.post(name: AppDelegate.navigateToFolderNotifName, object: nil)
        }
    }

    fileprivate func initFirebase() {
        let firebaseOpts = FirebaseOptions(googleAppID: googleServiceInfo.googleAppId, gcmSenderID: googleServiceInfo.gcmSenderId)
        firebaseOpts.clientID = googleServiceInfo.clientId
        firebaseOpts.apiKey = googleServiceInfo.apiKey
        firebaseOpts.projectID = googleServiceInfo.projectId
        firebaseOpts.storageBucket = googleServiceInfo.storageBucket

        FirebaseApp.configure(options: firebaseOpts)
        _ = RCValues.sharedInstance
        
        GMSServices.provideAPIKey(googleServiceInfo.apiKey)
        GMSPlacesClient.provideAPIKey(googleServiceInfo.apiKey)
    }
    
    fileprivate func configureLogging() {
        #if STAGING_ENVIRONMENT
            // Staging: verbose logging incl. capped request/response bodies.
            NetworkLogger.enableLogging()
        #elseif DEBUG
            // TEMP(VSP-1770 · Stela migration): verbose logging for DEBUG builds that point
            // at PRODUCTION, so a prod-scheme Xcode run shows whether a call went V1 or V2
            // while the migration is being verified. Deliberately DEBUG-only: Release
            // (TestFlight / App Store) still takes the errors-only branch below, so real
            // users never pay the body-stringify cost and no user data reaches their logs.
            // REMOVE this branch once the epic ships — grep TEMP(VSP-1770).
            NetworkLogger.enableLogging()
        #else
            // Production: errors only, never bodies — the previous enableLogging() here
            // stringified every full response body on the main thread in App Store builds.
            NetworkLogger.enableErrorLogging()
        #endif
    }
    
    fileprivate func configureImageCache() {
        let cache = SDImageCache.shared
        cache.config.maxDiskSize = 300 * 1024 * 1024 // 300 MB disk cap
        cache.config.maxMemoryCost = 50 * 1024 * 1024 // 50 MB memory cap
    }
    
    fileprivate func initNotifications() {
        UNUserNotificationCenter.current().delegate = self
        
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: {_, _ in }
        )
        
        Messaging.messaging().delegate = self
        
        UIApplication.shared.registerForRemoteNotifications()
    }
    
    fileprivate func navigateFromUniversalLink(url: URL) -> Bool {
        let hostingController = SharePreviewHostingController(shareToken: url.lastPathComponent)
        hostingController.navigateTo = { [weak self] params in
            self?.navigateToFolder(params: params)
        }
        hostingController.wireCallbacks()
        let viewController: UIViewController = hostingController
        
        // Dismiss any presented SwiftUI views or modal controllers before navigating
        dismissPresentedViewsAndNavigate(to: viewController)
        
        return true
    }
    
    private func dismissPresentedViewsAndNavigate(to viewController: UIViewController) {
        // First, dismiss any presented modal view controllers (like SwiftUI sheets)
        var topMostPresentedVC: UIViewController = rootViewController
        while let presentedVC = topMostPresentedVC.presentedViewController {
            topMostPresentedVC = presentedVC
        }
        
        // If there are presented view controllers, dismiss them first
        if topMostPresentedVC != rootViewController {
            rootViewController.dismiss(animated: false) { [weak self] in
                self?.navigateAfterDismissal(to: viewController)
            }
        } else {
            navigateAfterDismissal(to: viewController)
        }
    }
    
    private func navigateAfterDismissal(to viewController: UIViewController) {
        // If the root is a DrawerViewController, update its navigation stack to remove any
        // existing SharePreviewHostingController instances and other SwiftUI views
        if let drawer = rootViewController.current as? DrawerViewController {
            let nav = drawer.rootViewController
            
            // Filter out SharePreviewHostingController and other UIHostingControllers (SwiftUI views)
            let filteredStack = nav.viewControllers.filter { vc in
                // Keep only non-SwiftUI view controllers (like MainViewController, FilesViewController, etc.)
                let isSharePreview = vc is SharePreviewHostingController
                let isHostingController = String(describing: type(of: vc)).contains("UIHostingController")
                return !isSharePreview && !isHostingController
            }
            
            var newStack = filteredStack
            newStack.append(viewController)
            // Replace the stack without animation so any SwiftUI views are removed immediately
            nav.setViewControllers(newStack, animated: false)
            return
        }

        // Otherwise navigate directly
        rootViewController.navigateTo(viewController: viewController)
    }
    
    fileprivate func navigateToFolder(params: NavigateMinParams) {
        if let drawerVC = self.rootViewController.current as? DrawerViewController {
            try? PreferencesManager.shared.setCodableObject(NavigationDataForShareFolderLink(archiveNo: params.archiveNo, folderLinkId: params.folderLinkId, folderName: params.folderName), forKey: Constants.Keys.StorageKeys.navigationToShareFolderLink)
            if let mainVC = drawerVC.rootViewController.visibleViewController as? MainViewController {
                mainVC.navigationToShareFolderLink()
            } else {
                self.rootViewController.setDrawerRoot()
            }
        }
    }
    
    fileprivate func saveUnivesalLinkToken(_ token: String) {
        PreferencesManager.shared.set(token, forKey: Constants.Keys.StorageKeys.shareURLToken)
    }
    
    fileprivate func navigateFromPublicLink(_ publicDeeplinkPayload: PublicProfileDeeplinkPayload) -> Bool {
        let newRootVC = UIViewController.create(withIdentifier: .publicArchive, from: .profile) as! PublicArchiveViewController
        newRootVC.deeplinkPayload = publicDeeplinkPayload
        let newNav = NavigationController(rootViewController: newRootVC)
        
        if let presentedVC = rootViewController.presentedViewController {
            presentedVC.dismiss(animated: false) {
                self.rootViewController.present(newNav, animated: true)
            }
        } else {
            rootViewController.present(newNav, animated: true)
        }
        
        return true
    }

    fileprivate func savePublicLinkToken(_ publicDeeplinkPayload: PublicProfileDeeplinkPayload) {
        try? PreferencesManager.shared.setCodableObject(publicDeeplinkPayload, forKey: Constants.Keys.StorageKeys.publicURLToken)
    }
    
    fileprivate func navigateFromSharedArchive() -> Bool {
        let screenView = ViewRepresentableContainer(viewRepresentable: ArchivesViewControllerRepresentable(), title: ArchivesViewControllerRepresentable().title)
        let host = UIHostingController(rootView: screenView)
        host.modalPresentationStyle = .fullScreen
        self.rootViewController.present(host, animated: true, completion: nil)

        return true
    }
    
    fileprivate func  saveSharedArchiveToken() {
        PreferencesManager.shared.set(true, forKey: Constants.Keys.StorageKeys.sharedArchiveToken)
    }
}

extension AppDelegate {
    static var shared: AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }

    // TODO: Maybe make these optional?
    var rootViewController: RootViewController {
        return window!.rootViewController as! RootViewController
    }
}

extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        if let fcmToken = fcmToken {
            #if STAGING_ENVIRONMENT
            print("Saving push token: " + fcmToken)
            #endif
            PreferencesManager.shared.set(fcmToken, forKey: Constants.Keys.StorageKeys.fcmPushTokenKey)
            
            if rootViewController.isDrawerRootActive && AuthenticationManager.shared.session != nil {
                rootViewController.sendPushNotificationToken()
            }
        }
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    // Called when app is in the foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.list, .banner])
    }

    // Called after the user interacts with the notification
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        clearShareDeepLinks()
        
        guard response.actionIdentifier == UNNotificationDefaultActionIdentifier else { return }
        
        let userInfo = response.notification.request.content.userInfo
        if let notificationType = userInfo["notificationType"] as? String {
            switch notificationType {
            case "type.notification.share":
                openShareNotification(response.notification)
                
            case "type.notification.pa_response_non_transfer":
                openPARequestNotification(response.notification)
                
            case "type.notification.sharelink.request", "type.notification.share.invitation.acceptance":
                openShareLinkRequestNotification(response.notification)
                
            default:
                break
            }
        }
        
        completionHandler()
    }
    
    func openShareLinkRequestNotification(_ notification: UNNotification) {
        let userInfo = notification.request.content.userInfo
        let name: String
        let folderLinkId: Int
        let recordId: Int
        let isFolder: Bool
        
        // Check for record (file) first - most specific check
        if let itemName = userInfo["recordName"] as? String,
           let linkId: Int = Int(userInfo["recordLinkId"] as? String ?? userInfo["folderLinkId"] as? String ?? "") {
            folderLinkId = linkId
            name = itemName
            isFolder = false
            // Try to get recordId if available
            recordId = Int(userInfo["recordId"] as? String ?? "") ?? 0
        } else if let linkId: Int = Int(userInfo["shareFolderLinkId"] as? String ?? ""),
        let itemName = userInfo["shareName"] as? String {
            folderLinkId = linkId
            name = itemName
            isFolder = true
            recordId = 0
        } else if let linkId: Int = Int(userInfo["folderLinkId"] as? String ?? ""),
            let itemName = userInfo["folderName"] as? String {
            folderLinkId = linkId
            name = itemName
            isFolder = true
            recordId = 0
        } else {
            return
        }
        
        guard
            let toArchiveNbr: String = userInfo["toArchiveNumber"] as? String,
            let toArchiveName: String = userInfo["toArchiveName"] as? String,
            let toArchiveId: Int = Int(userInfo["toArchiveId"] as? String ?? "") else {
            return
        }
        
        DispatchQueue.main.async {
            let requestAccessNotifPayload = RequestLinkAccessNotificationPayload(name: name, folderLinkId: folderLinkId, isFolder: isFolder, recordId: recordId, toArchiveId: toArchiveId, toArchiveNbr: toArchiveNbr, toArchiveName: toArchiveName)
            try? PreferencesManager.shared.setNonPlistObject(requestAccessNotifPayload, forKey: Constants.Keys.StorageKeys.requestLinkAccess)
            
            if let drawerVC = self.rootViewController.current as? DrawerViewController {
                drawerVC.dismiss(animated: false) {
                    if let mainVC = drawerVC.rootViewController.visibleViewController as? MainViewController {
                        mainVC.checkForRequestShareAccess()
                    } else {
                        let rootVC = UIViewController.create(withIdentifier: .main, from: .main) as! MainViewController
                        rootVC.viewModel = MyFilesViewModel()
                        self.rootViewController.changeDrawerRoot(viewController: rootVC)
                    }
                }
            }
        }
    }
    
    func openShareNotification(_ notification: UNNotification) {
        let userInfo = notification.request.content.userInfo
        
        guard
            let folderLinkId: Int = Int(userInfo["folderLinkId"] as? String ?? ""),
            let archiveNbr: String = userInfo["fromArchiveId"] as? String,
            let toArchiveNbr: String = userInfo["toArchiveNumber"] as? String,
            let toArchiveName: String = userInfo["toArchiveName"] as? String,
            let toArchiveId: Int = Int(userInfo["toArchiveId"] as? String ?? ""),
            let accessRole: String = userInfo["accessRole"] as? String else {
            return
        }
        
        if let name: String = userInfo["recordName"] as? String,
        let recordId: Int = Int(userInfo["recordId"] as? String ?? "") {
            DispatchQueue.main.async {
                let shareNotifPayload = ShareNotificationPayload(name: name, recordId: recordId, folderLinkId: folderLinkId, archiveNbr: archiveNbr, type: FileType.miscellaneous.rawValue, toArchiveId: toArchiveId, toArchiveNbr: toArchiveNbr, toArchiveName: toArchiveName, accessRole: accessRole)
                try? PreferencesManager.shared.setNonPlistObject(shareNotifPayload, forKey: Constants.Keys.StorageKeys.sharedFileKey)
                
                if let drawerVC = self.rootViewController.current as? DrawerViewController {
                    // For record notifications, ALWAYS navigate to SharesViewController first
                    // Don't show preview from MainViewController
                    drawerVC.dismiss(animated: false) {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            if let sharesVC = drawerVC.rootViewController.visibleViewController as? SharesViewController {
                                sharesVC.segmentedControl.selectedSegmentIndex = 1
                                sharesVC.segmentedControlValueChanged(sharesVC.segmentedControl)
                                
                                _ = sharesVC.checkSavedFile()
                            } else {
                                let sharesVC = UIViewController.create(withIdentifier: .shares, from: .share) as! SharesViewController
                                sharesVC.selectedIndex = ShareListType.sharedWithMe.rawValue
                                
                                drawerVC.leftSideMenuController.selectedMenuOption = TableViewData.drawerData[DrawerSection.navigationScreens]![0]
                                
                                self.rootViewController.changeDrawerRoot(viewController: sharesVC)
                            }
                        }
                    }
                }
            }
        } else if let sharedFolderName: String = userInfo["folderName"] as? String {
            DispatchQueue.main.async {
                let shareNotifPayload = ShareNotificationPayload(name: sharedFolderName, recordId: 0, folderLinkId: folderLinkId, archiveNbr: archiveNbr, type: FileType.miscellaneous.rawValue, toArchiveId: toArchiveId, toArchiveNbr: toArchiveNbr, toArchiveName: toArchiveName, accessRole: accessRole)
                try? PreferencesManager.shared.setNonPlistObject(shareNotifPayload, forKey: Constants.Keys.StorageKeys.sharedFolderKey)
                
                if let drawerVC = self.rootViewController.current as? DrawerViewController {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        if drawerVC.rootViewController.visibleViewController is SharesViewController == false {
                            let sharesVC: SharesViewController = UIViewController.create(withIdentifier: .shares, from: .share) as! SharesViewController
                            
                            drawerVC.leftSideMenuController.selectedMenuOption = TableViewData.drawerData[DrawerSection.navigationScreens]![0]
                            
                            self.rootViewController.changeDrawerRoot(viewController: sharesVC)
                        } else {
                            let sharesVC = drawerVC.rootViewController.visibleViewController as! SharesViewController
                            sharesVC.segmentedControl.selectedSegmentIndex = 1
                            sharesVC.segmentedControlValueChanged(sharesVC.segmentedControl)
                            
                            _ = sharesVC.checkSavedFolder()
                        }
                    }
                }
            }
        } else {
            return
        }
    }
    
    func openPARequestNotification(_ notification: UNNotification) {
        let userInfo = notification.request.content.userInfo
        
        guard
            let toArchiveNbr: String = userInfo["toArchiveNumber"] as? String,
            let toArchiveName: String = userInfo["toArchiveName"] as? String,
            let toArchiveId: Int = Int(userInfo["toArchiveId"] as? String ?? "") else {
            return
        }
        
        DispatchQueue.main.async {
            let notifPayload = PARequestNotificationPayload(toArchiveId: toArchiveId, toArchiveNbr: toArchiveNbr, toArchiveName: toArchiveName)
            try? PreferencesManager.shared.setNonPlistObject(notifPayload, forKey: Constants.Keys.StorageKeys.requestPAAccess)
            
            if let drawerVC = self.rootViewController.current as? DrawerViewController {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    let rootVC: UIViewController
                    
                    rootVC = UIViewController.create(withIdentifier: .members, from: .members) as! MembersViewController
                    self.rootViewController.changeDrawerRoot(viewController: rootVC)
                    
                    drawerVC.leftSideMenuController.selectedMenuOption = TableViewData.drawerData[DrawerSection.navigationScreens]![1]
                }
            }
        }
    }
    
    func clearShareDeepLinks() {
        PreferencesManager.shared.removeValues(
            forKeys: [
            Constants.Keys.StorageKeys.requestPAAccess,
            Constants.Keys.StorageKeys.sharedFolderKey,
            Constants.Keys.StorageKeys.sharedFileKey,
            Constants.Keys.StorageKeys.requestLinkAccess,
            Constants.Keys.StorageKeys.shareURLToken,
            Constants.Keys.StorageKeys.publicURLToken,
            Constants.Keys.StorageKeys.sharedArchiveToken,
            Constants.Keys.StorageKeys.pendingInviteCode
            ]
        )
    }
    
    fileprivate func showAlreadyLoggedInAlert() {
        let alert = UIAlertController(
            title: "Already Signed In",
            message: "You are already signed in to Permanent. To create a new account with this invite code, please sign out first.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        if let topViewController = getTopMostViewController() {
            topViewController.present(alert, animated: true, completion: nil)
        }
    }
    
    fileprivate func getTopMostViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return self.window?.rootViewController
        }
        
        var topViewController = window.rootViewController
        
        while let presentedViewController = topViewController?.presentedViewController {
            topViewController = presentedViewController
        }
        
        return topViewController
    }
}

extension AppDelegate {
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return Constants.Design.orientationLock
    }
}
