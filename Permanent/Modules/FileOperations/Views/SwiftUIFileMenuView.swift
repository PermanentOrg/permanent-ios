import SwiftUI
import SDWebImageSwiftUI
import UIKit

// Helper class to handle file sharing operations using modern iOS APIs
class FileShareHelper {
    static let shared = FileShareHelper()
    private let fileHelper = FileHelper()
    
    /// Shares a file with other apps using the native iOS share sheet (UIActivityViewController)
    /// This provides access to AirDrop, Messages, Mail, third-party apps, and system extensions
    func shareWithOtherApps(file: FileModel, from viewController: UIViewController) {
        print("🔄 FileShareHelper: Starting shareWithOtherApps for file: \(file.name)")
        print("🔄 FileShareHelper: Presenting from: \(type(of: viewController))")
        print("🔄 FileShareHelper: View controller can present: \(viewController.presentedViewController == nil)")
        
        // If the view controller is already presenting something, dismiss it first
        if viewController.presentedViewController != nil {
            print("⚠️ FileShareHelper: View controller already presenting, dismissing first")
            viewController.dismiss(animated: false) {
                self.shareWithOtherApps(file: file, from: viewController)
            }
            return
        }
        
        if let localURL = fileHelper.url(forFileNamed: file.uploadFileName) {
            print("✅ FileShareHelper: File found locally, presenting share sheet")
            presentShareSheet(url: localURL, from: viewController, file: file)
        } else {
            print("⚠️ FileShareHelper: File not found locally, starting download")
            downloadAndShare(file: file, from: viewController)
        }
    }
    
    private func downloadAndShare(file: FileModel, from viewController: UIViewController) {
        print("🔄 FileShareHelper: Starting download for file: \(file.name)")
        
        // Check if view controller can present
        if viewController.presentedViewController != nil {
            print("⚠️ FileShareHelper: View controller already presenting, dismissing first")
            viewController.dismiss(animated: false) {
                self.downloadAndShare(file: file, from: viewController)
            }
            return
        }
        
        let preparingAlert = UIAlertController(title: "Preparing File..".localized(), message: nil, preferredStyle: .alert)
        preparingAlert.addAction(UIAlertAction(title: .cancel, style: .cancel))
        
        print("🔄 FileShareHelper: Presenting preparing alert")
        viewController.present(preparingAlert, animated: true) {
            print("✅ FileShareHelper: Preparing alert presented")
            
            // Try to download the file using the existing download infrastructure
            // For now, let's try to share the file name as text since we can't download
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                preparingAlert.dismiss(animated: true) {
                    print("🔄 FileShareHelper: Alert dismissed, attempting text share fallback")
                    
                    // Fallback: Share file information as text
                    let shareText = "File: \(file.name)"
                    let activityViewController = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
                    
                    // Configure for iPad
                    if let popover = activityViewController.popoverPresentationController {
                        popover.sourceView = viewController.view
                        popover.sourceRect = CGRect(x: viewController.view.bounds.midX, y: viewController.view.bounds.midY, width: 0, height: 0)
                        popover.permittedArrowDirections = []
                    }
                    
                    print("🔄 FileShareHelper: Presenting fallback text share")
                    viewController.present(activityViewController, animated: true) {
                        print("✅ FileShareHelper: Fallback share presented successfully")
                    }
                }
            }
        }
    }
    
    private func presentShareSheet(url: URL, from viewController: UIViewController, file: FileModel) {
        print("🔄 FileShareHelper: Presenting share sheet for URL: \(url)")
        print("🔄 FileShareHelper: View controller can present: \(viewController.presentedViewController == nil)")
        
        // Provide haptic feedback to indicate action started
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Create activity items with the file URL and optional filename
        var activityItems: [Any] = [url]
        
        // Add filename as a text item to help with context
        if !file.name.isEmpty {
            activityItems.append(file.name)
        }
        
        let activityViewController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        
        // Exclude some activities that don't make sense for file sharing
        activityViewController.excludedActivityTypes = [
            .assignToContact,
            .addToReadingList,
            .postToVimeo,
            .postToFlickr,
            .postToTencentWeibo,
            .postToWeibo
        ]
        
        // Configure for iPad
        if let popover = activityViewController.popoverPresentationController {
            popover.sourceView = viewController.view
            popover.sourceRect = CGRect(x: viewController.view.bounds.midX, y: viewController.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        // Add completion handler to track sharing success
        activityViewController.completionWithItemsHandler = { activityType, completed, returnedItems, error in
            if completed {
                // Success haptic feedback
                let successFeedback = UINotificationFeedbackGenerator()
                successFeedback.notificationOccurred(.success)
                print("✅ File shared successfully via \(activityType?.rawValue ?? "unknown service")")
            } else if let error = error {
                // Error haptic feedback
                let errorFeedback = UINotificationFeedbackGenerator()
                errorFeedback.notificationOccurred(.error)
                print("❌ Sharing failed: \(error.localizedDescription)")
            } else {
                print("ℹ️ Sharing cancelled by user")
            }
        }
        
        print("🔄 FileShareHelper: About to present UIActivityViewController")
        viewController.present(activityViewController, animated: true) {
            print("✅ FileShareHelper: UIActivityViewController presented successfully")
        }
    }
    
    func presentShareToPermanent(file: FileModel, from viewController: UIViewController) {
        print("🔄 FileShareHelper: presentShareToPermanent called")
        
        // Test with a simple text share to see if UIActivityViewController works at all
        let testActivityViewController = UIActivityViewController(activityItems: ["Test share - \(file.name)"], applicationActivities: nil)
        
        // Configure for iPad
        if let popover = testActivityViewController.popoverPresentationController {
            popover.sourceView = viewController.view
            popover.sourceRect = CGRect(x: viewController.view.bounds.midX, y: viewController.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        print("🔄 FileShareHelper: About to present test UIActivityViewController")
        viewController.present(testActivityViewController, animated: true) {
            print("✅ FileShareHelper: Test UIActivityViewController presented successfully")
        }
    }
}

struct SwiftUIFileMenuView: View {
    struct MenuItem {
        enum ItemType {
            case download
            case copy
            case move
            case delete
            case unshare
            case rename
            case publish
            case shareToPermanent
            case shareToAnotherApp
            case getLink
            case editMetadata
        }
        
        let type: ItemType
        let action: (() -> Void)?
    }
    
    let fileViewModel: FileModel
    let menuItems: [MenuItem]
    let selectedItemCount: Int?
    let onDismiss: () -> Void
    
    @State private var isPresented: Bool = true
    @State private var isAnimating: Bool = false
    @State private var dragOffset: CGFloat = 0
    @State private var shouldLoadImage: Bool = false
    @State private var imageOpacity: Double = 0.0
    @State private var isDragging: Bool = false
    @State private var dragStartTime: Date = Date()
    @State private var skeletonOffset: CGFloat = -200
    
    // Cache formatted values to avoid repeated calculations
    private let cachedFormattedFileSize: String?
    private let cachedFormattedDate: String
    private let initStartTime: Date = Date()
    private let preCalculatedHeight: CGFloat
    
    private var contentHeight: CGFloat {
        let itemHeight: CGFloat = 56
        let regularItemsCount = menuItems.filter { $0.type != .delete }.count
        let hasDelete = menuItems.contains { $0.type == .delete }
        let deleteSection: CGFloat = hasDelete ? (itemHeight + 16) : 0 // +16 for divider
        let paddingHeight: CGFloat = 48 // Top (16) and bottom (16) padding for content
        
        return CGFloat(regularItemsCount) * itemHeight + deleteSection + paddingHeight
    }
    
    private var maxContentHeight: CGFloat {
        return UIScreen.main.bounds.height * 0.85 - 120 // Total max height minus header
    }
    
    private var needsScrolling: Bool {
        return contentHeight > maxContentHeight
    }
    
    private var thumbnailPlaceholder: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(Color.gray.opacity(0.3))
            .overlay(
                // Skeleton loading animation - only for files that have thumbnails
                Group {
                    if !fileViewModel.type.isFolder && fileViewModel.thumbnailURL != nil && !fileViewModel.thumbnailURL!.isEmpty {
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
                            .offset(x: skeletonOffset)
                            .mask(RoundedRectangle(cornerRadius: 6))
                            .onAppear {
                                withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                                    skeletonOffset = 200
                                }
                            }
                    }
                }
            )
            .overlay(
                Image(systemName: fileViewModel.type.isFolder ? "folder.fill" : "doc.fill")
                    .foregroundColor(.white.opacity(0.7))
                    .font(.system(size: 16))
            )
    }
    
    init(fileViewModel: FileModel, menuItems: [MenuItem], selectedItemCount: Int? = nil, onDismiss: @escaping () -> Void) {
        let startTime = Date()
        print("🔍 SwiftUIFileMenuView: [+0.0ms] Init started")
        self.fileViewModel = fileViewModel
        self.menuItems = menuItems
        self.selectedItemCount = selectedItemCount
        self.onDismiss = onDismiss
        
        // Pre-calculate formatted values to avoid repeated computation
        let formattingStart = Date()
        if fileViewModel.size > 0 {
            let formatter = ByteCountFormatter()
            formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB]
            formatter.countStyle = .file
            self.cachedFormattedFileSize = formatter.string(fromByteCount: fileViewModel.size)
        } else {
            self.cachedFormattedFileSize = nil
        }
        
        if !fileViewModel.date.isEmpty && fileViewModel.date != "-" {
            let inputFormatter = DateFormatter()
            inputFormatter.dateFormat = "yyyy-MM-dd"
            let outputFormatter = DateFormatter()
            outputFormatter.dateFormat = "MMM. d, yyyy"
            
            if let date = inputFormatter.date(from: fileViewModel.date) {
                self.cachedFormattedDate = outputFormatter.string(from: date)
            } else {
                self.cachedFormattedDate = fileViewModel.date
            }
        } else {
            self.cachedFormattedDate = ""
        }
        
        let formattingElapsed = Date().timeIntervalSince(formattingStart) * 1000
        let totalElapsed = Date().timeIntervalSince(startTime) * 1000
        
        // Pre-calculate height to avoid computed property delays in presentationDetents
        let headerHeight: CGFloat = 120
        let itemHeight: CGFloat = 56
        let regularItemsCount = menuItems.filter { $0.type != .delete }.count
        let hasDelete = menuItems.contains { $0.type == .delete }
        let deleteSection: CGFloat = hasDelete ? (itemHeight + 16) : 0
        let paddingHeight: CGFloat = 48 // Top (16) and bottom (16) padding for content
        let totalHeight = headerHeight + CGFloat(regularItemsCount) * itemHeight + deleteSection + paddingHeight
        self.preCalculatedHeight = min(totalHeight, UIScreen.main.bounds.height * 0.85)
        
        print("🔍 SwiftUIFileMenuView: [+\(String(format: "%.1f", formattingElapsed))ms] Formatting completed")
        print("🔍 SwiftUIFileMenuView: [+\(String(format: "%.1f", totalElapsed))ms] Init completed - \(menuItems.count) items, height: \(self.preCalculatedHeight)")
    }
    
    var body: some View {
        let elapsed = Date().timeIntervalSince(initStartTime) * 1000
        print("🔍 SwiftUIFileMenuView: [+\(String(format: "%.1f", elapsed))ms] Body evaluation started")
        
        return ZStack {
            // Background overlay
            let backgroundOpacity: Double = isAnimating ? max(0.0, 0.3 * (1.0 - Double(dragOffset / preCalculatedHeight))) : 0.0
            Color.black.opacity(backgroundOpacity)
                .ignoresSafeArea()
                .onTapGesture {
                    let elapsed = Date().timeIntervalSince(initStartTime) * 1000
                    print("🔍 SwiftUIFileMenuView: [+\(String(format: "%.1f", elapsed))ms] Background tapped - dismissing")
                    dismissWithAnimation()
                }
            
            // Bottom sheet content
            VStack {
                Spacer()
                
                VStack(spacing: 0) {
                    let elapsed = Date().timeIntervalSince(initStartTime) * 1000
                    let _ = print("🔍 SwiftUIFileMenuView: [+\(String(format: "%.1f", elapsed))ms] Sheet content building started")
                    
                    // Header with handle bar and file info
                    VStack(spacing: 0) {
                        // Handle bar for visual indication
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white.opacity(0.5))
                            .frame(width: 32, height: 4)
                            .padding(.top, 8)
                        
                        // File info with dismiss button
                        HStack(spacing: 12) {
                            // File thumbnail - optimized for immediate display
                            ZStack {
                                // Always show placeholder as background
                                thumbnailPlaceholder
                                    .frame(width: 40, height: 40)
                                    .opacity(1.0 - imageOpacity) // Fade out as image fades in
                                
                                // Show WebImage only for files (not folders) when ready to load
                                if !fileViewModel.type.isFolder,
                                   let thumbnailURL = fileViewModel.thumbnailURL, 
                                   !thumbnailURL.isEmpty, 
                                   shouldLoadImage {
                                    WebImage(url: URL(string: thumbnailURL))
                                        .onSuccess { _, _, _ in
                                            let elapsed = Date().timeIntervalSince(initStartTime) * 1000
                                            let _ = print("🔍 SwiftUIFileMenuView: [+\(String(format: "%.1f", elapsed))ms] WebImage loaded successfully")
                                            withAnimation(.easeIn(duration: 0.3)) {
                                                imageOpacity = 1.0
                                            }
                                        }
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 40, height: 40)
                                        .opacity(imageOpacity)
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            
                            // File details
                            VStack(alignment: .leading, spacing: 4) {
                                Text(displayTitle)
                                    .font(.custom("Inter", size: 16))
                                    .fontWeight(.medium)
                                    .foregroundColor(Color.primary)
                                    .lineLimit(1)
                                
                                HStack(spacing: 8) {
                                    if let size = cachedFormattedFileSize {
                                        Text(size)
                                            .font(.custom("Inter", size: 12))
                                            .foregroundColor(Color.primary.opacity(0.8))
                                    }
                                    
                                    if cachedFormattedFileSize != nil && !cachedFormattedDate.isEmpty {
                                        Text("•")
                                            .font(.custom("Inter", size: 12))
                                            .foregroundColor(Color.primary.opacity(0.6))
                                    }
                                    
                                    if !cachedFormattedDate.isEmpty {
                                        Text(cachedFormattedDate)
                                            .font(.custom("Inter", size: 12))
                                            .foregroundColor(Color.primary.opacity(0.8))
                                    }
                                }
                            }
                            
                            Spacer()
                            
                            // Dismiss button
                            Button(action: {
                                let elapsed = Date().timeIntervalSince(initStartTime) * 1000
                                print("🔍 SwiftUIFileMenuView: [+\(String(format: "%.1f", elapsed))ms] Dismiss button tapped")
                                dismissWithAnimation()
                            }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                                    .frame(width: 30, height: 30)
                                    .background(Color.primary.opacity(0.2))
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        .padding(.bottom, 16)
                    }
                    .background(Color.blue25)
                    
                    // Menu items container
                    ScrollView(showsIndicators: false) {
                        menuContent
                    }
                    .scrollDisabled(!needsScrolling)
                    .frame(maxHeight: needsScrolling ? maxContentHeight : nil)
                    .background(Color.white)
                    .frame(maxWidth: .infinity)
                    .allowsHitTesting(!isDragging) // Disable button interactions while dragging
                    
                    Spacer(minLength: 0)
                }
                .frame(height: preCalculatedHeight)
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .cornerRadius(16, corners: [.topLeft, .topRight])
                .offset(y: isAnimating ? dragOffset : preCalculatedHeight)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            // Only allow downward dragging
                            if value.translation.height > 0 {
                                if !isDragging {
                                    isDragging = true
                                    dragStartTime = Date()
                                }
                                dragOffset = value.translation.height
                            }
                        }
                        .onEnded { value in
                            isDragging = false
                            let threshold = preCalculatedHeight * 0.3 // 30% of sheet height
                            
                            if value.translation.height > threshold || value.predictedEndTranslation.height > threshold {
                                // Dismiss if dragged down enough or with enough velocity
                                let elapsed = Date().timeIntervalSince(initStartTime) * 1000
                                print("🔍 SwiftUIFileMenuView: [+\(String(format: "%.1f", elapsed))ms] Swipe to dismiss triggered")
                                dismissWithAnimation()
                            } else {
                                // Snap back to original position
                                withAnimation(.easeOut(duration: 0.3)) {
                                    dragOffset = 0
                                }
                            }
                        }
                )
                .onAppear {
                    let elapsed = Date().timeIntervalSince(initStartTime) * 1000
                    print("🔍 SwiftUIFileMenuView: [+\(String(format: "%.1f", elapsed))ms] Sheet appeared on screen")
                    
                    withAnimation(.easeOut(duration: 0.3)) {
                        isAnimating = true
                    }
                    
                    // Delay image loading until after the sheet animation completes
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        shouldLoadImage = true
                    }
                }
            }
        }
        .ignoresSafeArea(.container, edges: .bottom)
    }
    
    private func dismissWithAnimation() {
        let elapsed = Date().timeIntervalSince(initStartTime) * 1000
        print("🔍 SwiftUIFileMenuView: [+\(String(format: "%.1f", elapsed))ms] Starting dismissal animation")
        
        withAnimation(.easeIn(duration: 0.25)) {
            isAnimating = false
            dragOffset = preCalculatedHeight // Animate to fully off-screen
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            let elapsed = Date().timeIntervalSince(self.initStartTime) * 1000
            print("🔍 SwiftUIFileMenuView: [+\(String(format: "%.1f", elapsed))ms] Calling onDismiss")
            onDismiss()
        }
    }
    
    @ViewBuilder
    private var menuContent: some View {
        LazyVStack(spacing: 16) {
            // Regular menu items (excluding delete)
            ForEach(regularMenuItems.indices, id: \.self) { index in
                MenuItemRow(item: regularMenuItems[index]) {
                    let menuItem = regularMenuItems[index]
                    let elapsed = Date().timeIntervalSince(initStartTime) * 1000
                    print("🔍 SwiftUIFileMenuView: [+\(String(format: "%.1f", elapsed))ms] Menu item tapped: \(menuItem.type)")
                    
                    // Always let handleMenuItemAction decide the flow
                    // It will handle sharing items specially
                    if menuItem.type == .shareToAnotherApp || menuItem.type == .shareToPermanent {
                        print("🔍 SwiftUIFileMenuView: Sharing item detected, letting handleMenuItemAction manage everything")
                        handleMenuItemAction(menuItem)
                    } else if menuItem.action != nil {
                        // Has action - execute and dismiss
                        print("🔍 SwiftUIFileMenuView: Item has action, executing and dismissing")
                        handleMenuItemAction(menuItem)
                        dismissWithAnimation()
                    } else {
                        // No action - let handleMenuItemAction manage dismissal timing
                        print("🔍 SwiftUIFileMenuView: Item has no action, letting handleMenuItemAction manage timing")
                        handleMenuItemAction(menuItem)
                    }
                }
            }
            
            // Divider and delete item if present
            if let deleteItem = deleteMenuItem {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 1)
                    //.padding(.vertical, 8)
                    .padding(.horizontal, -24)
                
                MenuItemRow(item: deleteItem, isDestructive: true) {
                    if deleteItem.action != nil {
                        // Has action - execute and dismiss
                        handleMenuItemAction(deleteItem)
                        dismissWithAnimation()
                    } else {
                        // No action - let handleMenuItemAction manage dismissal timing
                        handleMenuItemAction(deleteItem)
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 20)
    }
    
    // MARK: - Action Handling
    private func handleMenuItemAction(_ menuItem: MenuItem) {
        let elapsed = Date().timeIntervalSince(initStartTime) * 1000
        print("🔍 SwiftUIFileMenuView: [+\(String(format: "%.1f", elapsed))ms] handleMenuItemAction called for: \(menuItem.type)")
        print("🔍 SwiftUIFileMenuView: Action is nil: \(menuItem.action == nil)")
        
        // Check if this is a sharing item that needs special handling
        if menuItem.type == .shareToAnotherApp || menuItem.type == .shareToPermanent {
            print("🔍 SwiftUIFileMenuView: Detected sharing item, using special handling regardless of action")
            // Handle sharing items specially - dismiss first, then present
            dismissWithAnimation()
            
            // Delay to allow dismissal animation to complete
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                print("🔍 SwiftUIFileMenuView: Delay completed, calling handleSpecialMenuItems for sharing")
                self.handleSpecialMenuItems(menuItem)
            }
            return
        }
        
        if let action = menuItem.action {
            print("🔍 SwiftUIFileMenuView: Executing provided action")
            action()
        } else {
            // Handle other special cases where action is nil
            print("🔍 SwiftUIFileMenuView: No action provided, handling special menu item")
            dismissWithAnimation()
            
            // Delay to allow dismissal animation to complete
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                print("🔍 SwiftUIFileMenuView: Delay completed, calling handleSpecialMenuItems")
                self.handleSpecialMenuItems(menuItem)
            }
        }
    }
    
    private func handleSpecialMenuItems(_ menuItem: MenuItem) {
        print("🔄 SwiftUIFileMenuView: handleSpecialMenuItems called for type: \(menuItem.type)")
        
        // Get the top-most view controller to present sharing UI
        // We need to find a view controller that's actually in the window hierarchy
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            print("❌ SwiftUIFileMenuView: Could not find window scene")
            return
        }
        
        guard let window = windowScene.windows.first else {
            print("❌ SwiftUIFileMenuView: Could not find first window")
            return
        }
        
        guard let rootViewController = window.rootViewController else {
            print("❌ SwiftUIFileMenuView: Could not find root view controller")
            return
        }
        
        // Find a view controller that's actually in the window hierarchy
        // Skip any hosting controllers that might be getting dismissed
        let topViewController = rootViewController.findPresentableViewController()
        print("✅ SwiftUIFileMenuView: Found presentable view controller: \(type(of: topViewController))")
        print("✅ SwiftUIFileMenuView: Can present: \(topViewController.presentedViewController == nil)")
        print("✅ SwiftUIFileMenuView: View is in window hierarchy: \(topViewController.view.window != nil)")
        
        switch menuItem.type {
        case .shareToAnotherApp:
            print("🔄 SwiftUIFileMenuView: Initiating share to another app")
            FileShareHelper.shared.shareWithOtherApps(file: fileViewModel, from: topViewController)
        case .shareToPermanent:
            print("🔄 SwiftUIFileMenuView: Initiating share to Permanent")
            FileShareHelper.shared.presentShareToPermanent(file: fileViewModel, from: topViewController)
        default:
            // For other types, we don't have a default implementation
            print("ℹ️ SwiftUIFileMenuView: No implementation for \(menuItem.type)")
            let alert = UIAlertController(title: "Not Implemented", message: "This action is not yet implemented.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            topViewController.present(alert, animated: true)
        }
    }
    
    // MARK: - Computed Properties
    
    private var regularMenuItems: [MenuItem] {
        return menuItems.filter { $0.type != .delete }
    }
    
    private var deleteMenuItem: MenuItem? {
        return menuItems.first { $0.type == .delete }
    }
    
    private var displayTitle: String {
        if let selectedItemCount = selectedItemCount, selectedItemCount > 1 {
            return "\(selectedItemCount) Items selected"
        } else {
            return fileViewModel.name
        }
    }
}

struct MenuItemRow: View {
    let item: SwiftUIFileMenuView.MenuItem
    let action: () -> Void
    let isDestructive: Bool
    
    @State private var isPressed: Bool = false
    @State private var tapStartTime: Date = Date()
    
    init(item: SwiftUIFileMenuView.MenuItem, isDestructive: Bool = false, action: @escaping () -> Void) {
        self.item = item
        self.isDestructive = isDestructive
        self.action = action
    }
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: iconName)
                .font(.system(size: 20))
                .foregroundColor(isDestructive ? .red : Color.primary)
                .frame(width: 24, height: 24)
            
            Text(title)
                .font(.custom("Inter", size: 16))
                .foregroundColor(isDestructive ? .red : .black)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .background(isPressed ? Color.gray.opacity(0.1) : Color.clear)
        .onTapGesture {
            // Only trigger action if it was a quick tap (not a slow drag)
            let tapDuration = Date().timeIntervalSince(tapStartTime)
            if tapDuration < 0.5 { // Max 500ms for a valid tap
                action()
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    if !isPressed {
                        isPressed = true
                        tapStartTime = Date()
                    }
                    
                    // If user drags more than 10 points, it's not a tap
                    let dragDistance = sqrt(pow(value.translation.width, 2) + pow(value.translation.height, 2))
                    if dragDistance > 10 {
                        isPressed = false
                    }
                }
                .onEnded { value in
                    isPressed = false
                    
                    // Check if it was a fast swipe down (high velocity downward)
                    let swipeVelocity = value.predictedEndLocation.y - value.location.y
                    let dragDistance = sqrt(pow(value.translation.width, 2) + pow(value.translation.height, 2))
                    
                    // If it's a fast downward swipe or long drag, don't trigger the button
                    if swipeVelocity > 100 || dragDistance > 20 {
                        // This was likely a swipe gesture, not a button press
                        return
                    }
                }
        )
    }
    
    private var iconName: String {
        switch item.type {
        case .download:
            return "arrow.down.circle"
        case .copy:
            return "doc.on.doc"
        case .move:
            return "folder"
        case .delete:
            return "trash"
        case .unshare:
            return "person.crop.circle.badge.minus"
        case .rename:
            return "pencil"
        case .publish:
            return "globe"
        case .shareToPermanent:
            return "square.and.arrow.up"
        case .shareToAnotherApp:
            return "square.and.arrow.up"
        case .getLink:
            return "link"
        case .editMetadata:
            return "info.circle"
        }
    }
    
    private var title: String {
        switch item.type {
        case .download:
            return "Download"
        case .copy:
            return "Copy"
        case .move:
            return "Move"
        case .delete:
            return "Delete"
        case .unshare:
            return "Unshare"
        case .rename:
            return "Rename"
        case .publish:
            return "Publish"
        case .shareToPermanent:
            return "Share to Permanent"
        case .shareToAnotherApp:
            return "Share to Another App"
        case .getLink:
            return "Get Link"
        case .editMetadata:
            return "Edit Metadata"
        }
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

// Extension to find the top-most view controller
extension UIViewController {
    func topMostViewController() -> UIViewController {
        if let presentedViewController = presentedViewController {
            return presentedViewController.topMostViewController()
        }
        
        if let navigationController = self as? UINavigationController {
            return navigationController.visibleViewController?.topMostViewController() ?? self
        }
        
        if let tabBarController = self as? UITabBarController {
            return tabBarController.selectedViewController?.topMostViewController() ?? self
        }
        
        return self
    }
    
    func findPresentableViewController() -> UIViewController {
        // First try to find a non-hosting controller that's in the window hierarchy
        var current = self
        
        // Traverse up to find a stable view controller
        while let parent = current.parent {
            current = parent
        }
        
        // Now traverse down to find the best presentable controller
        return current.findDeepestPresentableController()
    }
    
    private func findDeepestPresentableController() -> UIViewController {
        // Skip hosting controllers if possible, they might be getting dismissed
        if let navigationController = self as? UINavigationController {
            if let visibleVC = navigationController.visibleViewController {
                // If the visible controller is a hosting controller, prefer the nav controller
                if visibleVC.view.window != nil && !(visibleVC is UIHostingController<SwiftUIFileMenuView>) {
                    return visibleVC.findDeepestPresentableController()
                } else {
                    return navigationController
                }
            }
            return navigationController
        }
        
        if let tabBarController = self as? UITabBarController {
            if let selectedVC = tabBarController.selectedViewController {
                return selectedVC.findDeepestPresentableController()
            }
            return tabBarController
        }
        
        // For hosting controllers, check if they're being dismissed
        if self is UIHostingController<SwiftUIFileMenuView> {
            // If this hosting controller doesn't have a window, find the parent
            if view.window == nil, let parent = parent {
                return parent.findDeepestPresentableController()
            }
        }
        
        // If this view controller is already presenting something, try to dismiss it first
        if presentedViewController != nil {
            print("⚠️ UIViewController: Found presenting controller, will dismiss before use")
        }
        
        return self
    }
}
