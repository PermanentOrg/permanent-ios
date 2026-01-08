//
//  WorkspaceContainerViewModel.swift
//  Permanent
//
//  Created on 18.12.2025.
//

import Foundation
import SwiftUI
import Combine

/// View model for the full SwiftUI workspace container
/// Manages state for all three workspaces and coordinates tab bar behavior
@available(iOS 26, *)
@MainActor
class WorkspaceContainerViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var selectedWorkspace: WorkspaceType = .private
    @Published var showPlusButton: Bool = false
    @Published var showChecklistButton: Bool = false
    
    // MARK: - Child View Models
    
    /// Tab bar view model
    let tabBarViewModel: WorkspaceTabViewModel
    
    /// Private workspace files view model
    private(set) var privateFilesVM: MyFilesViewModel?
    
    /// Shared workspace view model
    private(set) var sharedFilesVM: MyFilesViewModel?
    
    /// Public workspace files view model
    private(set) var publicFilesVM: PublicFilesViewModel?
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    
    private var currentArchive: ArchiveVOData? {
        return AuthenticationManager.shared.session?.selectedArchive
    }
    
    // MARK: - Initialization
    
    init() {
        self.tabBarViewModel = WorkspaceTabViewModel()
        setupWorkspaceViewModels()
        bindToTabBarViewModel()
        setupNotificationObservers()
        updateButtonVisibility()
    }
    
    // MARK: - Setup
    
    private func setupWorkspaceViewModels() {
        // Create view models for each workspace
        privateFilesVM = MyFilesViewModel()
        publicFilesVM = PublicFilesViewModel()
        // Note: SharesViewController still uses UIKit, so we don't create a VM here
    }
    
    private func bindToTabBarViewModel() {
        // Sync selected workspace with tab bar
        tabBarViewModel.$selectedWorkspace
            .sink { [weak self] workspace in
                self?.selectedWorkspace = workspace
            }
            .store(in: &cancellables)
        
        // Sync button visibility
        tabBarViewModel.$showPlusButton
            .assign(to: &$showPlusButton)
        
        tabBarViewModel.$showChecklistButton
            .assign(to: &$showChecklistButton)
    }
    
    private func setupNotificationObservers() {
        // Listen for archive changes to refresh data
        NotificationCenter.default.publisher(for: ArchivesViewModel.didChangeArchiveNotification)
            .sink { [weak self] _ in
                self?.handleArchiveChange()
            }
            .store(in: &cancellables)
        
        // Listen for floating island show/hide
        NotificationCenter.default.publisher(for: WorkspaceTabViewModel.showFloatingIslandNotification)
            .sink { [weak self] _ in
                self?.updateButtonVisibility()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: WorkspaceTabViewModel.hideFloatingIslandNotification)
            .sink { [weak self] _ in
                self?.updateButtonVisibility()
            }
            .store(in: &cancellables)
    }
    
    private func updateButtonVisibility() {
        let isPrivate = selectedWorkspace == .private
        let isPublic = selectedWorkspace == .public
        
        showPlusButton = isPrivate || isPublic
        showChecklistButton = currentArchive?.type == "type.archive.person" && (isPrivate || isPublic)
    }
    
    // MARK: - Public Methods
    
    func selectWorkspace(_ workspace: WorkspaceType) {
        selectedWorkspace = workspace
        tabBarViewModel.selectedWorkspace = workspace
        updateButtonVisibility()
    }
    
    func showUploadMenu() {
        // Post notification for upload menu
        NotificationCenter.default.post(name: .init("WorkspaceContainer.showUploadMenu"), object: nil)
    }
    
    func showChecklist() {
        // Post notification for checklist
        NotificationCenter.default.post(name: .init("WorkspaceContainer.showChecklist"), object: nil)
    }
    
    // MARK: - Private Methods
    
    private func handleArchiveChange() {
        // Refresh all workspace view models when archive changes
        privateFilesVM = MyFilesViewModel()
        publicFilesVM = PublicFilesViewModel()
        updateButtonVisibility()
    }
}
