//
//  WorkspaceTabViewModel.swift
//  Permanent
//
//  Created by GitHub Copilot on 17.12.2025.
//

import Foundation
import Combine

enum WorkspaceType: Int, CaseIterable {
    case `private` = 0
    case shared
    case `public`
    
    var title: String {
        switch self {
        case .private: return .privateWorkspace
        case .shared: return .sharedWorkspace
        case .public: return .publicWorkspace
        }
    }
    
    var iconName: String {
        switch self {
        case .private: return "lock.fill"
        case .shared: return "person.2.fill"
        case .public: return "globe"
        }
    }
}

class WorkspaceTabViewModel: ObservableObject {
    @Published var selectedWorkspace: WorkspaceType = .private
    @Published var showPlusButton: Bool = false
    @Published var showChecklistButton: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    private var currentArchive: ArchiveVOData? {
        return AuthenticationManager.shared.session?.selectedArchive
    }
    
    init() {
        setupNotificationObservers()
        updateButtonVisibility()
    }
    
    deinit {
        cancellables.removeAll()
    }
    
    private func setupNotificationObservers() {
        // Listen for archive changes
        NotificationCenter.default.publisher(for: ArchivesViewModel.didChangeArchiveNotification)
            .sink { [weak self] _ in
                self?.updateButtonVisibility()
            }
            .store(in: &cancellables)
    }
    
    private func updateButtonVisibility() {
        let archivePermissions = currentArchive?.permissions() ?? [Permission.read]
        
        // Show plus button only if user has create AND upload permissions
        let hasCreatePermission = archivePermissions.contains(Permission.create)
        let hasUploadPermission = archivePermissions.contains(Permission.upload)
        showPlusButton = hasCreatePermission && hasUploadPermission
        
        // Checklist button visibility is managed externally
        // It will be set from MainViewController based on member checklist state
    }
    
    func updateChecklistVisibility(_ shouldShow: Bool) {
        showChecklistButton = shouldShow
    }
}
