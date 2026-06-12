//
//  FileMenuViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 22.07.2025.
//

import SwiftUI
import UIKit
import Foundation

@MainActor
class FileMenuViewModel: ObservableObject {
    
    // MARK: - MenuItem Definition
    struct MenuItem: Equatable {
        enum ItemType: String, Equatable, CaseIterable {
            case download = "download"
            case copy = "copy"
            case move = "move"
            case delete = "delete"
            case unshare = "unshare"
            case rename = "rename"
            case publish = "publish"
            case shareToPermanent = "shareToPermanent"
            case shareToAnotherApp = "shareToAnotherApp"
            case editMetadata = "editMetadata"
        }
        
        let type: ItemType
        let action: (() -> Void)?
        
        static func == (lhs: MenuItem, rhs: MenuItem) -> Bool {
            return lhs.type == rhs.type
        }
    }
    
    // MARK: - Published Properties
    @Published var isPresented: Bool = true
    @Published var isAnimating: Bool = false
    @Published var dragOffset: CGFloat = 0
    @Published var shouldLoadImage: Bool = false
    @Published var imageOpacity: Double = 0.0
    @Published var isDragging: Bool = false
    @Published var skeletonOffset: CGFloat = -200
    @Published var shouldShowThumbnail: Bool = false
    @Published var thumbnailURL: URL?
    @Published var pressedMenuItemId: String?
    @Published var specialMenuItemRequested: MenuItem?
    
    @Published var showDeleteConfirmation: Bool = false
    @Published var showLeaveShareConfirmation: Bool = false
    @Published var pendingDeleteAction: (() -> Void)?
    @Published var pendingLeaveShareAction: (() -> Void)?
    @Published var isExecutingAction: Bool = false
    
    @Published var dynamicMenuItems: [MenuItem] = []
    @Published var dynamicHeight: CGFloat = 0
    
    // MARK: - Input Properties
    var fileViewModel: FileModel
    let menuItems: [MenuItem]
    let selectedItemCount: Int?
    let selectedFiles: [FileModel]?
    let onDismiss: () -> Void
    let showArchiveInfo: Bool
    
    // MARK: - Cached/Computed Properties
    let cachedFormattedFileSize: String?
    let cachedFormattedDate: String
    let preCalculatedHeight: CGFloat
    let archiveName: String?
    
    // MARK: - Private Properties
    private var dragStartTime: Date = Date()
    private var downloadTask: DispatchWorkItem?
    private var downloadTimeoutTask: DispatchWorkItem?
    private weak var currentPreparingAlert: UIAlertController?
    private let fileHelper = FileHelper()
    private let documentInteractionController = UIDocumentInteractionController()
    
    // MARK: - Dependencies
    typealias DownloadHandler = (FileModel, @escaping (URL?, Error?) -> Void) -> Void
    typealias MenuItemsGenerator = (FileModel) -> [MenuItem]
    typealias FileModelUpdateHandler = (FileModel) -> Void
    private var downloadHandler: DownloadHandler?
    private var menuItemsGenerator: MenuItemsGenerator?
    private var fileModelUpdateHandler: FileModelUpdateHandler?
    var viewControllerProvider: (() -> UIViewController?)?
    private var capturedPresentingViewController: UIViewController?
    
    // MARK: - Initialization
    init(fileViewModel: FileModel, menuItems: [MenuItem], selectedItemCount: Int? = nil, selectedFiles: [FileModel]? = nil, showArchiveInfo: Bool = false, onDismiss: @escaping () -> Void) {
        self.fileViewModel = fileViewModel
        self.menuItems = menuItems
        self.selectedItemCount = selectedItemCount
        self.selectedFiles = selectedFiles
        self.showArchiveInfo = showArchiveInfo
        self.onDismiss = onDismiss
        
        // Calculate size and date based on selection
        if let selectedFiles = selectedFiles, selectedFiles.count > 1 {
            // Multiple files selected
            let files = selectedFiles.filter { !$0.type.isFolder }
            let folders = selectedFiles.filter { $0.type.isFolder }
            
            // Calculate total file size (only for files, not folders)
            let totalSize = files.reduce(Int64(0)) { $0 + $1.size }
            self.cachedFormattedFileSize = totalSize > 0 ? Self.formatFileSize(totalSize) : nil
            
            // If there are folders, use the date of the first folder, otherwise use the date of the first file
            if let firstFolder = folders.first {
                self.cachedFormattedDate = Self.formatDate(firstFolder.date)
            } else if let firstFile = files.first {
                self.cachedFormattedDate = Self.formatDate(firstFile.date)
            } else {
                self.cachedFormattedDate = ""
            }
        } else {
            // Single file selected
            self.cachedFormattedFileSize = Self.formatFileSize(fileViewModel.size)
            self.cachedFormattedDate = Self.formatDate(fileViewModel.date)
        }
        
        if showArchiveInfo, let sharedByArchive = fileViewModel.sharedByArchive {
            self.archiveName = sharedByArchive.name
        } else {
            self.archiveName = nil
        }
        
        self.preCalculatedHeight = Self.calculateSheetHeight(for: menuItems, showArchiveInfo: showArchiveInfo && fileViewModel.sharedByArchive != nil)
        
        // Initialize dynamic properties
        self.dynamicMenuItems = menuItems
        self.dynamicHeight = self.preCalculatedHeight
    }
    
    deinit {
        downloadTask?.cancel()
        downloadTimeoutTask?.cancel()
    }
    
    // MARK: - File Formatting Logic
    static func formatFileSize(_ size: Int64) -> String? {
        guard size > 0 else { return nil }
        
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
    
    static func formatDate(_ dateString: String) -> String {
        guard !dateString.isEmpty && dateString != "-" else { return "" }
        
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd"
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "MMM. d, yyyy"
        
        if let date = inputFormatter.date(from: dateString) {
            return outputFormatter.string(from: date)
        } else {
            return dateString
        }
    }
    
    // MARK: - Layout Calculations
    static func calculateSheetHeight(for menuItems: [MenuItem], showArchiveInfo: Bool = false) -> CGFloat {
        let headerHeight: CGFloat = 88
        let archiveInfoHeight: CGFloat = showArchiveInfo ? 54 : 0
        let itemHeight: CGFloat = 56
        let regularItemsCount = menuItems.filter { $0.type != .delete && $0.type != .unshare }.count
        let hasDestructiveItem = menuItems.contains { $0.type == .delete || $0.type == .unshare }
        
        let totalItemCount = regularItemsCount + (hasDestructiveItem ? 1 : 0)
        
        // If there are no menu items, only show header (and archive info if present)
        guard totalItemCount > 0 else {
            return headerHeight + archiveInfoHeight
        }
        
        let topPadding: CGFloat = 24
        var bottomPadding: CGFloat = (regularItemsCount == 0 && hasDestructiveItem) ? 16 : 24
        if #available(iOS 26.0, *) { bottomPadding += 16 }
        
        let menuItemsHeight: CGFloat = CGFloat(totalItemCount) * itemHeight
        
        let menuSectionHeight = topPadding + menuItemsHeight + bottomPadding
        let totalHeight = headerHeight + archiveInfoHeight + menuSectionHeight
        return min(totalHeight, UIScreen.main.bounds.height * 0.85)
    }
    
    // MARK: - Computed Properties
    var contentHeight: CGFloat {
        let itemHeight: CGFloat = 56
        let regularItemsCount = menuItems.filter { $0.type != .delete && $0.type != .unshare }.count
        let hasDestructiveItem = menuItems.contains { $0.type == .delete || $0.type == .unshare }
        
        let topPadding: CGFloat = 24
        var bottomPadding: CGFloat = (regularItemsCount == 0 && hasDestructiveItem) ? 16 : 24
        let additionalBottomPaddingiOS26: CGFloat = 16.0
        
        let totalItemCount = regularItemsCount + (hasDestructiveItem ? 1 : 0)
        let menuItemsHeight: CGFloat = CGFloat(totalItemCount) * itemHeight
        
        if #available(iOS 26.0, *) {
            bottomPadding += additionalBottomPaddingiOS26
        }

        
        return topPadding + menuItemsHeight + bottomPadding
    }
    
    var maxContentHeight: CGFloat {
        return UIScreen.main.bounds.height * 0.85 - 88
    }
    
    var needsScrolling: Bool {
        return contentHeight > maxContentHeight
    }
    
    var backgroundOpacity: Double {
        isAnimating ? max(0.0, 0.3 * (1.0 - Double(dragOffset / dynamicHeight))) : 0.0
    }
    
    var regularMenuItems: [MenuItem] {
        return dynamicMenuItems.filter { $0.type != .delete && $0.type != .unshare }
    }
    
    var destructiveMenuItem: MenuItem? {
        return dynamicMenuItems.first { $0.type == .delete || $0.type == .unshare }
    }
    
    var displayTitle: String {
        if let selectedItemCount = selectedItemCount, selectedItemCount > 1 {
            return "\(selectedItemCount) Items selected"
        } else {
            return fileViewModel.name
        }
    }
    
    var accessRoleName: String? {
        guard showArchiveInfo, fileViewModel.sharedByArchive != nil else {
            return nil
        }
        // For file sharing, display curator when backend returns manager
        let displayRole = fileViewModel.accessRole == .manager ? AccessRole.curator : fileViewModel.accessRole
        return displayRole.title.uppercased()
    }
    
    // MARK: - Access Role Update
    func fetchUpdatedAccessRole() {
        guard showArchiveInfo, fileViewModel.sharedByArchive != nil else {
            return
        }
        
        let itemInfo = (folderLinkId: fileViewModel.folderLinkId, parentFolderLinkId: fileViewModel.parentFolderLinkId)
        
        let endpoint: FilesEndpoint
        if fileViewModel.type.isFolder {
            endpoint = FilesEndpoint.getFolder(itemInfo: itemInfo)
        } else {
            endpoint = FilesEndpoint.getRecord(itemInfo: itemInfo)
        }
        
        let apiOperation = APIOperation(endpoint)
        
        apiOperation.execute(in: APIRequestDispatcher()) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .json(let response, _):
                    if self.fileViewModel.type.isFolder {
                        guard let model: APIResults<FolderVO> = JSONHelper.decoding(
                            from: response,
                            with: APIResults<FolderVO>.decoder
                        ),
                        model.isSuccessful,
                        let folderData = model.results.first?.data?.first?.folderVO else {
                            return
                        }
                        
                        var accessRoleString: String?
                        if let accessVO = folderData.accessVO?.value as? [String: Any],
                           let role = accessVO["accessRole"] as? String {
                            accessRoleString = role
                        } else if let role = folderData.accessRole {
                            accessRoleString = role
                        }
                        
                        guard let accessRoleString = accessRoleString else {
                            return
                        }
                        
                        let newAccessRole = AccessRole.roleForValue(accessRoleString)
                        if self.fileViewModel.accessRole != newAccessRole {
                            self.fileViewModel.accessRole = newAccessRole
                            self.updatePermissions(forAccessRole: accessRoleString)
                            self.regenerateMenuItemsAndAnimateHeight()
                        }
                    } else {
                        guard let model: APIResults<RecordVO> = JSONHelper.decoding(
                            from: response,
                            with: APIResults<RecordVO>.decoder
                        ),
                        model.isSuccessful,
                        let recordData = model.results.first?.data?.first?.recordVO else {
                            return
                        }
                        
                        var accessRoleString: String?
                        if let accessVO = recordData.accessVO?.value as? [String: Any],
                           let role = accessVO["accessRole"] as? String {
                            accessRoleString = role
                        } else if let role = recordData.accessRole {
                            accessRoleString = role
                        }
                        
                        guard let accessRoleString = accessRoleString else {
                            return
                        }
                        
                        let newAccessRole = AccessRole.roleForValue(accessRoleString)
                        if self.fileViewModel.accessRole != newAccessRole {
                            self.fileViewModel.accessRole = newAccessRole
                            self.updatePermissions(forAccessRole: accessRoleString)
                            self.regenerateMenuItemsAndAnimateHeight()
                        }
                    }
                    
                case .error:
                    break
                    
                default:
                    break
                }
            }
        }
    }
    
    private func updatePermissions(forAccessRole accessRoleString: String) {
        let newPermissions = ArchiveVOData.permissions(forAccessRole: accessRoleString)
        self.fileViewModel.permissions = newPermissions
    }
    
    private func regenerateMenuItemsAndAnimateHeight() {
        fileModelUpdateHandler?(fileViewModel)
        
        guard let generator = menuItemsGenerator else {
            return
        }
        
        let newMenuItems = generator(fileViewModel)
        let newHeight = Self.calculateSheetHeight(for: newMenuItems, showArchiveInfo: showArchiveInfo && fileViewModel.sharedByArchive != nil)
        
        withAnimation(.easeInOut(duration: 0.3)) {
            self.dynamicMenuItems = newMenuItems
            self.dynamicHeight = newHeight
        }
    }
    
    // MARK: - Animation Control
    func startPresentationAnimation() {
        withAnimation(.easeOut(duration: 0.3)) {
            isAnimating = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            self.shouldLoadImage = true
        }
        
        withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
            skeletonOffset = 200
        }
    }
    
    // MARK: - Thumbnail Logic
    func prepareThumbnailForLoading() {
        if !fileViewModel.type.isFolder,
           let thumbnailURLString = fileViewModel.thumbnailURL,
           !thumbnailURLString.isEmpty,
           let url = URL(string: thumbnailURLString) {
            thumbnailURL = url
            shouldShowThumbnail = true
        } else {
            thumbnailURL = nil
            shouldShowThumbnail = false
        }
    }
    
    var shouldShowSkeletonAnimation: Bool {
        return shouldShowThumbnail && imageOpacity < 1.0
    }
    
    var thumbnailPlaceholderOpacity: Double {
        return 1.0 - imageOpacity
    }
    
    // MARK: - Menu Item Row Interaction Logic
    func handleMenuItemPressed(_ itemType: MenuItem.ItemType) {
        pressedMenuItemId = itemType.rawValue
    }
    
    func handleMenuItemReleased() {
        pressedMenuItemId = nil
    }
    
    func isMenuItemPressed(_ itemType: MenuItem.ItemType) -> Bool {
        return pressedMenuItemId == itemType.rawValue
    }
    
    func validateTapGesture(tapDuration: TimeInterval, dragDistance: CGFloat, swipeVelocity: CGFloat) -> Bool {
        let isQuickTap = tapDuration < 0.5
        let isNotDrag = dragDistance <= 20
        let isNotSwipe = swipeVelocity <= 100
        
        return isQuickTap && isNotDrag && isNotSwipe
    }
    
    // MARK: - Dependencies Setup
    func setViewControllerProvider(_ provider: @escaping () -> UIViewController?) {
        viewControllerProvider = provider
        if let viewController = provider() {
            capturedPresentingViewController = viewController.presentingViewController
        }
    }
    
    func setDownloadHandler(_ handler: @escaping DownloadHandler) {
        downloadHandler = handler
    }
    
    func setMenuItemsGenerator(_ generator: @escaping MenuItemsGenerator) {
        menuItemsGenerator = generator
    }
    
    func setFileModelUpdateHandler(_ handler: @escaping FileModelUpdateHandler) {
        fileModelUpdateHandler = handler
    }
    
    func dismissWithAnimation() {
        withAnimation(.easeIn(duration: 0.25)) {
            isAnimating = false
            dragOffset = dynamicHeight
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            self.onDismiss()
        }
    }
    
    func onImageLoadSuccess() {
        withAnimation(.easeIn(duration: 0.3)) {
            imageOpacity = 1.0
        }
    }
    
    // MARK: - Drag Gesture Handling
    func handleDragChanged(_ value: DragGesture.Value) {
        if value.translation.height > 0 {
            if !isDragging {
                isDragging = true
                dragStartTime = Date()
            }
            dragOffset = value.translation.height
        }
    }
    
    func handleDragEnded(_ value: DragGesture.Value) {
        isDragging = false
        let threshold = dynamicHeight * 0.3
        
        if value.translation.height > threshold || value.predictedEndTranslation.height > threshold {
            dismissWithAnimation()
        } else {
            withAnimation(.easeOut(duration: 0.3)) {
                dragOffset = 0
            }
        }
    }
    
    // MARK: - Action Handling Logic
    func handleMenuItemTap(_ menuItem: MenuItem) {
        if menuItem.type == .delete {
            pendingDeleteAction = menuItem.action
            showDeleteConfirmation = true
            return
        } else if menuItem.type == .unshare {
            pendingLeaveShareAction = menuItem.action
            showLeaveShareConfirmation = true
            return
        }
        
        if menuItem.type == .shareToAnotherApp || menuItem.type == .shareToPermanent {
            handleMenuItemAction(menuItem)
        } else if menuItem.type == .editMetadata {
            // Dismiss menu first, then execute edit metadata action
            dismissWithAnimation()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if let action = menuItem.action {
                    action()
                }
            }
        } else if menuItem.action != nil {
            handleMenuItemAction(menuItem)
            dismissWithAnimation()
        } else {
            handleMenuItemAction(menuItem)
        }
    }
    
    private func handleMenuItemAction(_ menuItem: MenuItem) {
        if menuItem.type == .shareToAnotherApp || menuItem.type == .shareToPermanent {
            if let viewController = self.viewControllerProvider?() {
                self.executeSpecialMenuItem(menuItem, with: viewController)
            } else {
                self.specialMenuItemRequested = menuItem
            }
            return
        }
        
        if let action = menuItem.action {
            action()
        } else {
            dismissWithAnimation()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.handleSpecialMenuItems(menuItem)
            }
        }
    }
    
    private func handleSpecialMenuItems(_ menuItem: MenuItem) {
        if let viewController = self.viewControllerProvider?() {
            self.executeSpecialMenuItem(menuItem, with: viewController)
        } else {
            self.specialMenuItemRequested = menuItem
        }
    }
    
    // MARK: - Public Methods for View Layer
    func executeSpecialMenuItem(_ menuItem: MenuItem, with viewController: UIViewController) {
        switch menuItem.type {
        case .shareToAnotherApp:
            shareWithOtherApps(from: viewController)
        case .shareToPermanent:
            shareWithPermanent(from: viewController)
        case .rename:
            rename(from: viewController)
        default:
            presentNotImplementedAlert(from: viewController)
        }
    }
    
    // MARK: - File Sharing Logic
    private func shareWithOtherApps(from viewController: UIViewController) {
        if let localURL = getLocalFileURL() {
            self.dismissWithAnimation()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                var presentingViewController: UIViewController?
                
                if let captured = self.capturedPresentingViewController, captured.view.window != nil {
                    presentingViewController = captured
                } else if let presentingVC = viewController.presentingViewController {
                    presentingViewController = presentingVC
                } else {
                    var current: UIViewController? = viewController
                    while current != nil {
                        if let presenting = current?.presentingViewController {
                            presentingViewController = presenting
                            break
                        }
                        current = current?.parent
                    }
                }
                
                if presentingViewController == nil {
                    if let rootVC = self.viewControllerProvider?() {
                        presentingViewController = rootVC
                    }
                }
                
                if let validViewController = presentingViewController {
                    self.presentShareSheet(url: localURL, from: validViewController)
                } else {
                    self.presentShareSheet(url: localURL, from: viewController)
                }
            }
        } else {
            downloadAndShare(from: viewController)
        }
    }
    
    // MARK: - Special Menu Item Methods
    private func shareWithPermanent(from viewController: UIViewController) {
        // Dismiss the menu first, then trigger the special menu item
        dismissWithAnimation()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            // This triggers the view layer to handle the share management presentation
            self.specialMenuItemRequested = MenuItem(type: .shareToPermanent, action: nil)
        }
    }
    
    private func rename(from viewController: UIViewController) {
        dismissWithAnimation()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.specialMenuItemRequested = MenuItem(type: .rename, action: nil)
        }
    }
    
    // MARK: - File Download and Sharing
    
    private func downloadAndShare(from viewController: UIViewController) {
        let strongSelf = self
        
        self.dismissWithAnimation()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            var presentingViewController: UIViewController?
            
            if let captured = strongSelf.capturedPresentingViewController, captured.view.window != nil {
                presentingViewController = captured
            } else if let presentingVC = viewController.presentingViewController {
                presentingViewController = presentingVC
            } else {
                var current: UIViewController? = viewController
                while current != nil {
                    if let presenting = current?.presentingViewController {
                        presentingViewController = presenting
                        break
                    }
                    current = current?.parent
                }
            }
            
            if presentingViewController == nil {
                if let rootVC = strongSelf.viewControllerProvider?() {
                    presentingViewController = rootVC
                }
            }
            
            guard let validViewController = presentingViewController else {
                strongSelf.presentActivityViewController(from: viewController)
                return
            }
            
            let preparingAlert = strongSelf.createPreparingAlert()
            strongSelf.currentPreparingAlert = preparingAlert
            
            validViewController.present(preparingAlert, animated: true) {
                strongSelf.downloadTask?.cancel()
                
                if let downloadHandler = strongSelf.downloadHandler {
                    strongSelf.downloadTask = DispatchWorkItem {
                        // This work item just marks that download is in progress
                    }
                    
                    // Set up a timeout to automatically dismiss the alert if download callback is never called
                    strongSelf.downloadTimeoutTask = DispatchWorkItem {
                        DispatchQueue.main.async {
                            if let currentAlert = strongSelf.currentPreparingAlert,
                               currentAlert.presentingViewController != nil {
                                currentAlert.dismiss(animated: true) {
                                    strongSelf.currentPreparingAlert = nil
                                    strongSelf.downloadTask = nil
                                    strongSelf.downloadTimeoutTask = nil
                                    strongSelf.presentActivityViewController(from: validViewController)
                                }
                            }
                        }
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 30.0, execute: strongSelf.downloadTimeoutTask!)
                    
                    downloadHandler(strongSelf.fileViewModel) { downloadedURL, error in
                        DispatchQueue.main.async {
                            // Cancel the timeout task since we got a response
                            strongSelf.downloadTimeoutTask?.cancel()
                            strongSelf.downloadTimeoutTask = nil
                            
                            // Check if the task was cancelled
                            guard let downloadTask = strongSelf.downloadTask, !downloadTask.isCancelled else {
                                return
                            }
                            
                            strongSelf.downloadTask = nil
                            
                            // Dismiss the alert if it's still being presented
                            if let currentAlert = strongSelf.currentPreparingAlert,
                               currentAlert.presentingViewController != nil {
                                currentAlert.dismiss(animated: true) {
                                    strongSelf.currentPreparingAlert = nil
                                    
                                    if let downloadedURL = downloadedURL {
                                        strongSelf.presentShareSheet(url: downloadedURL, from: validViewController)
                                    } else if error != nil {
                                        strongSelf.presentActivityViewController(from: validViewController)
                                    } else {
                                        strongSelf.presentActivityViewController(from: validViewController)
                                    }
                                }
                            } else {
                                strongSelf.currentPreparingAlert = nil
                                
                                if let downloadedURL = downloadedURL {
                                    strongSelf.presentShareSheet(url: downloadedURL, from: validViewController)
                                } else {
                                    strongSelf.presentActivityViewController(from: validViewController)
                                }
                            }
                        }
                    }
                } else {
                    // No download handler available, present share immediately
                    preparingAlert.dismiss(animated: true) {
                        strongSelf.presentActivityViewController(from: validViewController)
                    }
                }
            }
        }
    }
    
    private func presentSimpleShare(from viewController: UIViewController) {
        presentActivityViewController(from: viewController)
        self.dismissWithAnimation()
    }
    
    private func presentActivityViewController(from viewController: UIViewController) {
        // Try to get the local file URL if available
        let activityItems: [Any]
        if let localURL = getLocalFileURL(), FileManager.default.fileExists(atPath: localURL.path) {
            activityItems = [localURL]
        } else {
            // Fallback to sharing file name as text
            activityItems = ["File: \(fileViewModel.name)"]
        }
        
        let activityViewController = UIActivityViewController(
            activityItems: activityItems, 
            applicationActivities: nil
        )
        
        if let popover = activityViewController.popoverPresentationController {
            popover.sourceView = viewController.view
            popover.sourceRect = CGRect(
                x: viewController.view.bounds.midX, 
                y: viewController.view.bounds.midY, 
                width: 0, 
                height: 0
            )
            popover.permittedArrowDirections = []
        }
        
        viewController.present(activityViewController, animated: true)
    }
    
    private func createPreparingAlert() -> UIAlertController {
        let alert = UIAlertController(
            title: "Preparing File...", 
            message: nil, 
            preferredStyle: .alert
        )
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            self?.downloadTask?.cancel()
            self?.downloadTask = nil
            self?.downloadTimeoutTask?.cancel()
            self?.downloadTimeoutTask = nil
            self?.currentPreparingAlert = nil
        }
        alert.addAction(cancelAction)
        
        return alert
    }
    
    private func getLocalFileURL() -> URL? {
        let fileExtension = (fileViewModel.uploadFileName as NSString).pathExtension
        let fileName = !fileExtension.isEmpty ? "\(fileViewModel.name).\(fileExtension)" : fileViewModel.name
        
        if let url = fileHelper.url(forFileNamed: fileName) {
            return url
        }
        
        if fileExtension.uppercased() == "HEIC" {
            let convertedFileName = "\(fileViewModel.name).JPG"
            if let url = fileHelper.url(forFileNamed: convertedFileName) {
                return url
            }
        }
        
        return nil
    }
    
    private func presentShareSheet(url: URL, from viewController: UIViewController) {
        let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        
        // For iPad support
        if let popover = activityViewController.popoverPresentationController {
            popover.sourceView = viewController.view
            popover.sourceRect = CGRect(x: viewController.view.bounds.midX, y: viewController.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        viewController.present(activityViewController, animated: true)
    }
    
    // MARK: - Special Menu Item Handling
    func presentNotImplementedAlert(from viewController: UIViewController) {
        let alert = UIAlertController(title: "Not Implemented", message: "This action is not yet implemented.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        viewController.present(alert, animated: true)
    }
    
    func clearSpecialMenuItemRequest() {
        specialMenuItemRequested = nil
    }
    
    // MARK: - Confirmation Actions
    func executeDeleteAction() {
        dismissWithAnimation()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.pendingDeleteAction?()
            self.pendingDeleteAction = nil
        }
    }
    
    func executeLeaveShareAction() {
        dismissWithAnimation()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.pendingLeaveShareAction?()
            self.pendingLeaveShareAction = nil
        }
    }
    
    func cancelDeleteAction() {
        showDeleteConfirmation = false
        pendingDeleteAction = nil
    }
    
    func cancelLeaveShareAction() {
        showLeaveShareConfirmation = false
        pendingLeaveShareAction = nil
    }
    
    // MARK: - Menu Item Row Helpers
    func getIconImage(for itemType: MenuItem.ItemType) -> Image {
        switch itemType {
        case .download:
            return Image(.downloadV1)
        case .copy:
            return Image(.copyV1)
        case .move:
            return Image(.moveV1)
        case .delete:
            return Image(.deleteV1)
        case .unshare:
            return Image(.publishRevokeLink)
        case .rename:
            return Image(.renameV1)
        case .publish:
            return Image(.publishOnWebV1)
        case .shareToPermanent:
            return Image(.shareAndManageV1)
        case .shareToAnotherApp:
            return Image(.saveOrShareV1)
        case .editMetadata:
            return Image(.fileInfoV1)
        }
    }
    
    func getTitle(for itemType: MenuItem.ItemType) -> String {
        switch itemType {
        case .download:
            return "Save"
        case .copy:
            return "Copy to another folder"
        case .move:
            return "Move to another folder"
        case .delete:
            return "Delete"
        case .unshare:
            return "Leave share"
        case .rename:
            return "Rename"
        case .publish:
            return "Publish on the web"
        case .shareToPermanent:
            return "Share and manage access"
        case .shareToAnotherApp:
            return "Save or send a copy"
        case .editMetadata:
            return "Edit Metadata"
        }
    }

    func shouldShowPendingInvitationBadge(for itemType: MenuItem.ItemType) -> Bool {
        pendingInvitationBadgeCount(for: itemType) > 0
    }

    func pendingInvitationBadgeCount(for itemType: MenuItem.ItemType) -> Int {
        guard itemType == .shareToPermanent else {
            return 0
        }

        let count = fileViewModel.minArchiveVOS.filter {
            ArchiveVOData.Status(rawValue: $0.shareStatus) == .pending
        }.count
        
        return count
    }
}
