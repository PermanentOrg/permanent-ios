//
//  FolderNavigationView.swift
//  Permanent
//
//  Created on 18.12.2025
//  Phase 3: Navigation Migration - SwiftUI NavigationStack-based folder navigation
//

import SwiftUI

// MARK: - SwiftUIFolderNavigationView

/// A SwiftUI view that provides NavigationStack-based folder browsing.
/// Uses `FileNavigationDestination` for type-safe navigation path management.
@available(iOS 17, *)
struct SwiftUIFolderNavigationView: View {
    @ObservedObject var state: MainViewState
    weak var coordinator: EnhancedFileListCoordinatorProtocol?
    
    /// Callback for folder tap navigation
    var onFolderTap: ((FileModel) -> Void)?
    
    var body: some View {
        NavigationStack(path: $state.swiftUINavigationPath) {
            // Root content
            rootContent
                .navigationDestination(for: FileNavigationDestination.self) { destination in
                    destinationView(for: destination)
                }
        }
        .overlay(alignment: .center) {
            navigationLoadingOverlay
        }
        .overlay(alignment: .bottom) {
            toastOverlay
        }
    }
    
    // MARK: - Root Content
    
    private var rootContent: some View {
        EnhancedFileListView(
            state: state,
            coordinator: coordinator,
            onFolderTap: { folder in
                handleFolderTap(folder)
            }
        )
        .navigationTitle(state.rootFolderName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            rootToolbarContent
        }
        .toolbarBackground(.hidden, for: .navigationBar)
    }
    
    // MARK: - Destination View
    
    @ViewBuilder
    private func destinationView(for destination: FileNavigationDestination) -> some View {
        EnhancedFileListView(
            state: state,
            coordinator: coordinator,
            onFolderTap: { folder in
                handleFolderTap(folder)
            }
        )
        .navigationTitle(destination.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            folderToolbarContent(for: destination)
        }
        .toolbarBackground(.hidden, for: .navigationBar)
    }
    
    // MARK: - Toolbar Content
    
    @ToolbarContentBuilder
    private var rootToolbarContent: some ToolbarContent {
        // Empty for root - no back button needed
        ToolbarItem(placement: .principal) {
            Text(state.rootFolderName)
                .font(.custom("Usual-Medium", size: 17))
                .foregroundColor(Color(UIColor.darkBlue))
        }
    }
    
    @ToolbarContentBuilder
    private func folderToolbarContent(for destination: FileNavigationDestination) -> some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text(destination.displayName)
                .font(.custom("Usual-Medium", size: 17))
                .foregroundColor(Color(UIColor.darkBlue))
        }
    }
    
    // MARK: - Navigation Loading Overlay
    
    @ViewBuilder
    private var navigationLoadingOverlay: some View {
        if state.isNavigating {
            ZStack {
                Color.black.opacity(0.1)
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color(UIColor.darkBlue)))
                        .scaleEffect(1.5)
                    
                    Text("Loading folder...")
                        .font(.custom("Usual-Regular", size: 14))
                        .foregroundColor(Color(UIColor.darkBlue))
                }
                .padding(32)
                .background(.ultraThinMaterial)
                .cornerRadius(16)
            }
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.2), value: state.isNavigating)
        }
    }
    
    // MARK: - Toast Overlay
    
    @ViewBuilder
    private var toastOverlay: some View {
        if let message = state.toastMessage {
            ToastView(
                message: message,
                type: state.toastType,
                onDismiss: {
                    state.dismissToast()
                }
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: state.toastMessage)
            .onAppear {
                // Auto-dismiss after 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    state.dismissToast()
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func handleFolderTap(_ folder: FileModel) {
        guard folder.type.isFolder else { return }
        
        // Call external handler if provided
        onFolderTap?(folder)
        
        // Trigger async navigation
        Task {
            await state.navigateToFolderAsync(
                archiveNo: folder.archiveNo,
                folderLinkId: folder.folderLinkId,
                name: folder.name
            )
        }
    }
}

// MARK: - Toast View

@available(iOS 17, *)
struct ToastView: View {
    let message: String
    let type: ToastType
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: type.icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            Text(message)
                .font(.custom("Usual-Regular", size: 14))
                .foregroundColor(.white)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(type.backgroundColor)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Preview

#if DEBUG
@available(iOS 17, *)
struct SwiftUIFolderNavigationView_Previews: PreviewProvider {
    static var previews: some View {
        Text("SwiftUIFolderNavigationView Preview")
            .font(.headline)
    }
}
#endif
