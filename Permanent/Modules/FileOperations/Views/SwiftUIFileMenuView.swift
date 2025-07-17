import SwiftUI
import SDWebImageSwiftUI

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
                                    .opacity(1.0 - imageOpacity) // Fade out as image fades in
                                
                                // Show WebImage only when ready to load
                                if let thumbnailURL = fileViewModel.thumbnailURL, !thumbnailURL.isEmpty, shouldLoadImage {
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
                                        .opacity(imageOpacity)
                                }
                            }
                            .frame(width: 40, height: 40)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            
                            // File details
                            VStack(alignment: .leading, spacing: 4) {
                                Text(displayTitle)
                                    .font(.custom("Inter", size: 16))
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                
                                HStack(spacing: 8) {
                                    if let size = cachedFormattedFileSize {
                                        Text(size)
                                            .font(.custom("Inter", size: 12))
                                            .foregroundColor(.white.opacity(0.8))
                                    }
                                    
                                    if cachedFormattedFileSize != nil && !cachedFormattedDate.isEmpty {
                                        Text("•")
                                            .font(.custom("Inter", size: 12))
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                    
                                    if !cachedFormattedDate.isEmpty {
                                        Text(cachedFormattedDate)
                                            .font(.custom("Inter", size: 12))
                                            .foregroundColor(.white.opacity(0.8))
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
                                    .background(Color.white.opacity(0.2))
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
                    
                    // Start loading image immediately when sheet appears
                    shouldLoadImage = true
                }
            }
        }
        .ignoresSafeArea(.container, edges: .bottom)
    }
    
    private func dismissWithAnimation() {
        withAnimation(.easeIn(duration: 0.25)) {
            isAnimating = false
            dragOffset = preCalculatedHeight // Animate to fully off-screen
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            onDismiss()
        }
    }
    
    @ViewBuilder
    private var menuContent: some View {
        LazyVStack(spacing: 16) {
            // Regular menu items (excluding delete)
            ForEach(regularMenuItems.indices, id: \.self) { index in
                MenuItemRow(item: regularMenuItems[index]) {
                    regularMenuItems[index].action?()
                    dismissWithAnimation()
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
                    deleteItem.action?()
                    dismissWithAnimation()
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 20)
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
