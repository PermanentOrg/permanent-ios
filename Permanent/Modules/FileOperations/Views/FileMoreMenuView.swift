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
    private let onGetLinkRequested: ((FileModel) -> Void)?
    
    init(fileViewModel: FileModel, menuItems: [FileMenuViewModel.MenuItem], selectedItemCount: Int? = nil, onDismiss: @escaping () -> Void, onShareManagementRequested: ((FileModel) -> Void)? = nil, onGetLinkRequested: ((FileModel) -> Void)? = nil, downloadHandler: FileMenuViewModel.DownloadHandler? = nil) {
        let newViewModel = FileMenuViewModel(
            fileViewModel: fileViewModel,
            menuItems: menuItems,
            selectedItemCount: selectedItemCount,
            onDismiss: onDismiss
        )
        
        if let downloadHandler = downloadHandler {
            newViewModel.setDownloadHandler(downloadHandler)
        }
        
        self.viewModel = newViewModel
        self.onShareManagementRequested = onShareManagementRequested
        self.onGetLinkRequested = onGetLinkRequested
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
                .frame(height: viewModel.preCalculatedHeight)
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .cornerRadius(16, corners: [.topLeft, .topRight])
                .offset(y: viewModel.isAnimating ? viewModel.dragOffset : viewModel.preCalculatedHeight)
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
                    viewModel.startPresentationAnimation()
                }
                .onChange(of: viewModel.specialMenuItemRequested) { menuItem in
                    if let menuItem = menuItem {
                        handleSpecialMenuItems(menuItem)
                        viewModel.clearSpecialMenuItemRequest()
                    }
                }
            }
        }
        .ignoresSafeArea(.container, edges: .bottom)
    }
    
    
    @ViewBuilder
    private var menuContent: some View {
        LazyVStack(spacing: 16) {
            ForEach(viewModel.regularMenuItems.indices, id: \.self) { index in
                FileMoreMenuItemRow(item: viewModel.regularMenuItems[index], viewModel: viewModel) {
                    viewModel.handleMenuItemTap(viewModel.regularMenuItems[index])
                }
            }
            
            if let deleteItem = viewModel.deleteMenuItem {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 1)
                    .padding(.horizontal, -24)
                
                FileMoreMenuItemRow(item: deleteItem, viewModel: viewModel, isDestructive: true) {
                    viewModel.handleMenuItemTap(deleteItem)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 20)
    }
    
    // MARK: - Special Menu Item Handling
    private func handleSpecialMenuItems(_ menuItem: FileMenuViewModel.MenuItem) {
        switch menuItem.type {
        case .shareToPermanent:
            // Use the callback instead of presenting directly
            if let callback = onShareManagementRequested {
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
                
                presentShareManagement(from: topViewController)
            }
        case .getLink:
            // Use the callback instead of the special menu item flow
            if let callback = onGetLinkRequested {
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
    
    private func presentShareManagement(from viewController: UIViewController) {
        guard let manageLinkVC = UIViewController.create(withIdentifier: .shareManagement, from: .share) as? ShareManagementViewController else {
            return
        }
        
        let shareViewModel = ShareLinkViewModel(fileViewModel: viewModel.fileViewModel)
        manageLinkVC.viewModel = shareViewModel
        
        let navController = NavigationController(rootViewController: manageLinkVC)
        viewController.present(navController, animated: true, completion: nil)
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

// Extension to add corner radius to specific corners
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
