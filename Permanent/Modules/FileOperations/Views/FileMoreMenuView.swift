//
//  MenuItemRow.swift
//  Permanent
//
//  Created by Lucian Cerbu on 28.07.2025.

import SwiftUI
import SDWebImageSwiftUI
import UIKit

struct FileMoreMenuView: View {
    @ObservedObject private var viewModel: FileMenuViewModel
    private let onShareManagementRequested: ((FileModel) -> Void)?
    private let onRenameRequested: ((FileModel) -> Void)?
    private let onDeleteConfirmed: (([FileModel]) -> Void)?
    private let onLeaveShareConfirmed: ((FileModel) -> Void)?

    init(viewModel: FileMenuViewModel,
         onShareManagementRequested: ((FileModel) -> Void)? = nil,
         onRenameRequested: ((FileModel) -> Void)? = nil,
         onDeleteConfirmed: (([FileModel]) -> Void)? = nil,
         onLeaveShareConfirmed: ((FileModel) -> Void)? = nil) {
        self.viewModel = viewModel
        self.onShareManagementRequested = onShareManagementRequested
        self.onRenameRequested = onRenameRequested
        self.onDeleteConfirmed = onDeleteConfirmed
        self.onLeaveShareConfirmed = onLeaveShareConfirmed
    }
    
    init(fileViewModel: FileModel, menuItems: [FileMenuViewModel.MenuItem], selectedItemCount: Int? = nil, selectedFiles: [FileModel]? = nil, showArchiveInfo: Bool = false, onDismiss: @escaping () -> Void, onShareManagementRequested: ((FileModel) -> Void)? = nil, onRenameRequested: ((FileModel) -> Void)? = nil, onDeleteConfirmed: (([FileModel]) -> Void)? = nil, onLeaveShareConfirmed: ((FileModel) -> Void)? = nil, downloadHandler: FileMenuViewModel.DownloadHandler? = nil, menuItemsGenerator: FileMenuViewModel.MenuItemsGenerator? = nil, fileModelUpdateHandler: FileMenuViewModel.FileModelUpdateHandler? = nil) {
        let newViewModel = FileMenuViewModel(
            fileViewModel: fileViewModel,
            menuItems: menuItems,
            selectedItemCount: selectedItemCount,
            selectedFiles: selectedFiles,
            showArchiveInfo: showArchiveInfo,
            onDismiss: onDismiss
        )
        
        if let downloadHandler = downloadHandler {
            newViewModel.setDownloadHandler(downloadHandler)
        }
        
        if let menuItemsGenerator = menuItemsGenerator {
            newViewModel.setMenuItemsGenerator(menuItemsGenerator)
        }
        
        if let fileModelUpdateHandler = fileModelUpdateHandler {
            newViewModel.setFileModelUpdateHandler(fileModelUpdateHandler)
        }
        
        self.viewModel = newViewModel
        self.onShareManagementRequested = onShareManagementRequested
        self.onRenameRequested = onRenameRequested
        self.onDeleteConfirmed = onDeleteConfirmed
        self.onLeaveShareConfirmed = onLeaveShareConfirmed
    }
    
    
    private var thumbnailPlaceholder: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(Color.blue25)
            .overlay(
                Group {
                    if viewModel.shouldShowSkeletonAnimation {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.clear,
                                        Color.white.opacity(0.4),
                                        Color.clear
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .offset(x: viewModel.skeletonOffset)
                            .mask(RoundedRectangle(cornerRadius: 6))
                    }
                }
            )
            .overlay(
                Group {
                    if viewModel.fileViewModel.type.isFolder {
                        Image(.folderThumbnailV1)
                    } else {
                        Image(systemName: "doc.fill")
                            .foregroundColor(.white.opacity(0.7))
                            .font(.system(size: 14))
                    }
                }
            )
    }
    
    
    var body: some View {
        ZStack {
            Color.black.opacity(viewModel.backgroundOpacity)
                .ignoresSafeArea()
                .onTapGesture {
                    viewModel.dismissWithAnimation()
                }
            
            VStack {
                Spacer()
                
                VStack(spacing: 0) {
                    // Header components
                    VStack(spacing: 0) {
                        HStack(spacing: 16) {
                            VStack(spacing: 0) {
                                ZStack {
                                    thumbnailPlaceholder
                                        .frame(width: 40, height: 40)
                                        .opacity(viewModel.thumbnailPlaceholderOpacity)
                                    
                                    if viewModel.shouldShowThumbnail,
                                       let thumbnailURL = viewModel.thumbnailURL,
                                       viewModel.shouldLoadImage {
                                        WebImage(url: thumbnailURL)
                                            .onSuccess { _, _, _ in
                                                viewModel.onImageLoadSuccess()
                                            }
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 40, height: 40)
                                            .opacity(viewModel.imageOpacity)
                                    }
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                
                                // Multiple files indicator
                                if let selectedItemCount = viewModel.selectedItemCount, selectedItemCount > 1 {
                                    Image(.publishMultipleFiles)
                                        .frame(width: 33.33333, height: 6)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(viewModel.displayTitle)
                                    .font(
                                        .custom("Usual-Regular", size: 14))
                                    .fontWeight(.medium)
                                    .foregroundColor(Color.blue900)
                                    .lineLimit(1)
                                
                                HStack(spacing: 8) {
                                    if let size = viewModel.cachedFormattedFileSize {
                                        Text(size)
                                            .font(
                                                .custom("Usual-Regular", size: 12))
                                            .foregroundColor(Color.blue400)
                                    }
                                    
                                    if viewModel.cachedFormattedFileSize != nil && !viewModel.cachedFormattedDate.isEmpty {
                                        Text("•")
                                            .font(
                                                .custom("Usual-Regular", size: 12))
                                            .foregroundColor(Color.blue400)
                                    }
                                    
                                    if !viewModel.cachedFormattedDate.isEmpty {
                                        Text(viewModel.cachedFormattedDate)
                                            .font(
                                                .custom("Usual-Regular", size: 12))
                                            .foregroundColor(Color.blue400)
                                    }
                                }
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                viewModel.dismissWithAnimation()
                            }) {
                                Image(.closeButtonV2)
                                    .frame(width: 24, height: 24)
                            }
                        }
                        .padding(24)
                    }
                    .background(Color.blue25)
                    
                    ScrollView(showsIndicators: false) {
                        menuContent
                    }
                    .scrollDisabled(!viewModel.needsScrolling)
                    .frame(maxHeight: viewModel.needsScrolling ? viewModel.maxContentHeight : nil)
                    .background(Color.white)
                    .frame(maxWidth: .infinity)
                    .allowsHitTesting(!viewModel.isDragging)
                    
                    Spacer(minLength: 0)
                }
                .frame(height: viewModel.dynamicHeight)
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .cornerRadius(16, corners: [.topLeft, .topRight])
                .offset(y: viewModel.isAnimating ? viewModel.dragOffset : viewModel.dynamicHeight)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            viewModel.handleDragChanged(value)
                        }
                        .onEnded { value in
                            viewModel.handleDragEnded(value)
                        }
                )
                .onAppear {
                    viewModel.setViewControllerProvider { () -> UIViewController? in
                        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                              let window = windowScene.windows.first,
                              let rootViewController = window.rootViewController else {
                            return nil
                        }
                        var topController = rootViewController
                        while let presented = topController.presentedViewController {
                            topController = presented
                        }
                        return topController
                    }
                    
                    viewModel.prepareThumbnailForLoading()
                    viewModel.fetchUpdatedAccessRole()
                    viewModel.startPresentationAnimation()
                }
                .onChange(of: viewModel.specialMenuItemRequested) { menuItem in
                    if let menuItem = menuItem {
                        handleSpecialMenuItems(menuItem)
                        viewModel.clearSpecialMenuItemRequest()
                    }
                }
            }
            
            ConfirmationBottomAlertView(
                isPresented: $viewModel.showDeleteConfirmation,
                fileName: viewModel.fileViewModel.name,
                actionType: .delete,
                onConfirm: {
                    handleDeleteConfirmation()
                },
                onCancel: {
                    viewModel.cancelDeleteAction()
                },
                isMultipleItems: (viewModel.selectedItemCount ?? 1) > 1,
                isFolder: viewModel.fileViewModel.type.isFolder
            )
            
            ConfirmationBottomAlertView(
                isPresented: $viewModel.showLeaveShareConfirmation,
                fileName: viewModel.fileViewModel.name,
                actionType: .leaveShare,
                onConfirm: {
                    handleLeaveShareConfirmation()
                },
                onCancel: {
                    viewModel.cancelLeaveShareAction()
                },
                isMultipleItems: false,
                isFolder: viewModel.fileViewModel.type.isFolder
            )
            
            if viewModel.isExecutingAction {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                    )
            }
        }
        .ignoresSafeArea(.container, edges: .bottom)
    }
    
    
    @ViewBuilder
    private var menuContent: some View {
        LazyVStack(spacing: 0) {
            // Archive info section (only shown in Shared With Me)
            if viewModel.showArchiveInfo, let archiveName = viewModel.archiveName, let accessRole = viewModel.accessRoleName {
                archiveInfoSection(archiveName: archiveName, accessRole: accessRole)
            }
            
            if !viewModel.regularMenuItems.isEmpty || viewModel.destructiveMenuItem != nil {
                VStack(spacing: 16) {
                    ForEach(viewModel.regularMenuItems.indices, id: \.self) { index in
                        FileMoreMenuItemRow(item: viewModel.regularMenuItems[index], viewModel: viewModel) {
                            viewModel.handleMenuItemTap(viewModel.regularMenuItems[index])
                        }
                    }
                    
                    if let destructiveItem = viewModel.destructiveMenuItem {
                        if !viewModel.regularMenuItems.isEmpty {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 1)
                                .padding(.horizontal, -24)
                        }
                        
                        FileMoreMenuItemRow(item: destructiveItem, viewModel: viewModel, isDestructive: true) {
                            viewModel.handleMenuItemTap(destructiveItem)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, viewModel.regularMenuItems.isEmpty && viewModel.destructiveMenuItem != nil ? 16 : 24)
            }
        }
    }
    
    // MARK: - Archive Info Section
    @ViewBuilder
    private func archiveInfoSection(archiveName: String, accessRole: String) -> some View {
        HStack(alignment: .center, spacing: 16) {
            Group {
                if let thumbnailURLString = viewModel.fileViewModel.sharedByArchive?.thumbnail,
                   let thumbnailURL = URL(string: thumbnailURLString) {
                    WebImage(url: thumbnailURL)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 24, height: 24, alignment: .center)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                } else {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.blue100)
                        .frame(width: 24, height: 24, alignment: .center)
                        .overlay(
                            Text(String(archiveName.prefix(1)).uppercased())
                                .font(.custom("Usual-Regular", size: 16))
                                .fontWeight(.semibold)
                                .foregroundColor(Color.blue900)
                        )
                }
            }
            .padding(.horizontal, 8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("FROM")
                    .font(.custom("Usual-Regular", size: 10))
                    .foregroundColor(Color.blue400)
                    .kerning(1.6)
                
                HStack {
                    Text("The") +
                    Text(" \(archiveName) ")
                        .bold() +
                    Text("Archive")
                }
                .font(.custom("Usual-Regular", size: 12))
                .foregroundColor(Color.blue900)
                .lineLimit(1)
            }
            
            Spacer()
            
            Text(accessRole)
                .font(.custom("Usual-Regular", size: 8))
                .kerning(1.28)
                .foregroundColor(Color.blue900)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white)
                .cornerRadius(4)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
        .background(Color.blue25)
    }
    
    // MARK: - Special Menu Item Handling
    private func handleSpecialMenuItems(_ menuItem: FileMenuViewModel.MenuItem) {
        switch menuItem.type {
        case .shareToPermanent:
            // Prefer delegating to the host (UIKit controller) to present after dismissing the menu
            if let callback = onShareManagementRequested {
                callback(viewModel.fileViewModel)
            } else {
                // Fallback: present via a safe presenter (the presentingViewController of this menu if available)
                presentShareManagementSafely()
            }
        case .rename:
            if let callback = onRenameRequested {
                callback(viewModel.fileViewModel)
            } else {
                // Fallback to the old method if callback not provided
                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                      let window = windowScene.windows.first,
                      let rootViewController = window.rootViewController else {
                    return
                }
                
                var topViewController = rootViewController
                while let presented = topViewController.presentedViewController {
                    topViewController = presented
                }
                
                viewModel.executeSpecialMenuItem(menuItem, with: topViewController)
            }
        default:
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first,
                  let rootViewController = window.rootViewController else {
                return
            }
            
            var topViewController = rootViewController
            while let presented = topViewController.presentedViewController {
                topViewController = presented
            }
            
            viewModel.executeSpecialMenuItem(menuItem, with: topViewController)
        }
    }
    
    // MARK: - Safe UIKit Presentation Fallback
    private func presentShareManagementSafely() {
        DispatchQueue.main.async {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first,
                  let root = window.rootViewController else { return }
            
            // Find the top-most controller
            var top: UIViewController = root
            while let presented = top.presentedViewController {
                top = presented
            }
            
            // If the top is our menu's hosting controller (being dismissed), use its presenter
            let presenter = top.presentingViewController ?? top
            
            // Create SwiftUI ShareItemView directly
            let shareItemView = ShareItemView(fileModel: viewModel.fileViewModel)
            
            // Present with UIHostingController
            let hostingController = UIHostingController(rootView: shareItemView)
            hostingController.modalPresentationStyle = .fullScreen
            
            presenter.present(hostingController, animated: true)
        }
    }

    // MARK: - Confirmation Actions
    private func handleDeleteConfirmation() {
        viewModel.showDeleteConfirmation = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.viewModel.dismissWithAnimation()
            
            // Wait for menu dismiss animation to complete before executing action
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                if let onDeleteConfirmed = self.onDeleteConfirmed {
                    let filesToDelete = self.viewModel.selectedFiles ?? [self.viewModel.fileViewModel]
                    onDeleteConfirmed(filesToDelete)
                } else {
                    self.viewModel.executeDeleteAction()
                }
            }
        }
    }
    
    private func handleLeaveShareConfirmation() {
        viewModel.showLeaveShareConfirmation = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.viewModel.dismissWithAnimation()
            
            // Wait for menu dismiss animation to complete before executing action
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                if let onLeaveShareConfirmed = self.onLeaveShareConfirmed {
                    onLeaveShareConfirmed(self.viewModel.fileViewModel)
                } else {
                    self.viewModel.executeLeaveShareAction()
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    private func formatFileSize(_ size: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
    
    private func showInfoAlert(title: String, message: String) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            return
        }
        
        var topViewController = rootViewController
        while let presented = topViewController.presentedViewController {
            topViewController = presented
        }
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        topViewController.present(alert, animated: true)
    }
    
    private func shareURL(_ url: URL) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            return
        }
        
        var topViewController = rootViewController
        while let presented = topViewController.presentedViewController {
            topViewController = presented
        }
        
        let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = topViewController.view
        topViewController.present(activityViewController, animated: true, completion: nil)
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

private extension View {
    @ViewBuilder
    func ifAvailableiOS16<Content: View>(_ transform: (Self) -> Content) -> some View {
        if #available(iOS 16.0, *) {
            transform(self)
        } else {
            self
        }
    }
}
