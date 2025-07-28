import SwiftUI
import SDWebImageSwiftUI
import UIKit

struct FileMenuView: View {
    @ObservedObject private var viewModel: FileMenuViewModel
    
    init(fileViewModel: FileModel, menuItems: [FileMenuViewModel.MenuItem], selectedItemCount: Int? = nil, onDismiss: @escaping () -> Void, downloadHandler: FileMenuViewModel.DownloadHandler? = nil) {
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
                        Image(.folderThumbnailV2)
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
                    // Header with handle bar and file info
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
                MenuItemRow(item: viewModel.regularMenuItems[index], viewModel: viewModel) {
                    viewModel.handleMenuItemTap(viewModel.regularMenuItems[index])
                }
            }
            
            if let deleteItem = viewModel.deleteMenuItem {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 1)
                    .padding(.horizontal, -24)
                
                MenuItemRow(item: deleteItem, viewModel: viewModel, isDestructive: true) {
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
