//
//  WorkspaceContainerView.swift
//  Permanent
//
//  Created on 18.12.2025.
//

import SwiftUI

/// Main SwiftUI container for workspace navigation (iOS 26+)
/// Replaces UIKit DrawerViewController with full SwiftUI implementation
/// Features:
/// - Fade transitions between workspaces
/// - Fixed tab bar that never recreates
/// - Preserved state across workspace switches
@available(iOS 26, *)
struct WorkspaceContainerView: View {
    @StateObject private var viewModel = WorkspaceContainerViewModel()
    
    // Weak reference to app delegate for navigation callbacks
    private var appDelegate: AppDelegate? {
        return AppDelegate.shared
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Content area - switches based on selected workspace
            Group {
                switch viewModel.selectedWorkspace {
                case .private:
                    if let privateVM = viewModel.privateFilesVM {
                        FileListContainerView(
                            filesViewModel: privateVM,
                            workspaceType: .private
                        )
                        .id("private-workspace")
                    }
                    
                case .shared:
                    SharedFilesContainerView()
                        .id("shared-workspace")
                    
                case .public:
                    if let publicVM = viewModel.publicFilesVM {
                        FileListContainerView(
                            filesViewModel: publicVM,
                            workspaceType: .public
                        )
                        .id("public-workspace")
                    }
                }
            }
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.25), value: viewModel.selectedWorkspace)
            .ignoresSafeArea(.all, edges: .bottom)
            
            // Liquid Glass Tab Bar - always visible, fixed at bottom
            WorkspaceTabBarView(
                viewModel: viewModel.tabBarViewModel,
                onWorkspaceSelected: { workspace in
                    withAnimation(.easeInOut(duration: 0.25)) {
                        viewModel.selectWorkspace(workspace)
                    }
                },
                onPlusButtonTapped: {
                    handlePlusButtonTapped()
                },
                onChecklistButtonTapped: {
                    handleChecklistButtonTapped()
                }
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
        .background(Color(UIColor.systemBackground))
        .onAppear {
            setupNotificationHandlers()
        }
    }
    
    // MARK: - Action Handlers
    
    private func handlePlusButtonTapped() {
        // Show upload menu through AppDelegate
        if let rootVC = appDelegate?.rootViewController.current as? DrawerViewController {
            rootVC.showUploadMenu()
        }
    }
    
    private func handleChecklistButtonTapped() {
        // Show checklist through AppDelegate
        if let rootVC = appDelegate?.rootViewController.current as? DrawerViewController {
            rootVC.showChecklist()
        }
    }
    
    private func setupNotificationHandlers() {
        // Listen for upload menu requests
        NotificationCenter.default.addObserver(
            forName: .init("WorkspaceContainer.showUploadMenu"),
            object: nil,
            queue: .main
        ) { _ in
            handlePlusButtonTapped()
        }
        
        // Listen for checklist requests
        NotificationCenter.default.addObserver(
            forName: .init("WorkspaceContainer.showChecklist"),
            object: nil,
            queue: .main
        ) { _ in
            handleChecklistButtonTapped()
        }
    }
}

// MARK: - Preview

#if DEBUG
@available(iOS 26, *)
struct WorkspaceContainerView_Previews: PreviewProvider {
    static var previews: some View {
        WorkspaceContainerView()
    }
}
#endif
